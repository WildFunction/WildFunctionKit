import Foundation
@_exported import SmartCodable
import Synchronization

/// A problem found while decoding JSON.
public struct SafeJSONIssue: Sendable, Equatable {
    /// Kind of problem.
    public enum Kind: Sendable, Equatable {
        /// Decoding failed entirely.
        case decodeFailed
        /// Decoding succeeded, but SmartCodable patched missing or mistyped fields.
        case fieldCompatibility
    }

    /// Kind of problem.
    public let kind: Kind
    /// Target model type. Empty for field issues; the model name is in `message`.
    public let typeName: String
    /// Human-readable description.
    public let message: String

    /// Creates an issue.
    public init(kind: Kind, typeName: String, message: String) {
        self.kind = kind
        self.typeName = typeName
        self.message = message
    }
}

/// Entry point for SmartCodable: lenient decoding plus issue reporting.
///
/// Models conform to `SmartCodableX` (or `SmartDecodable`). SmartCodable is re-exported from this module.
///
/// ```swift
/// struct DemoItem: SmartCodableX {
///     var id = ""
///     var name = ""
/// }
/// let item = SafeJSON.decode(DemoItem.self, from: data)
/// ```
public enum SafeJSON {
    /// Issue callback. May be called on any thread.
    public typealias IssueHandler = @Sendable (SafeJSONIssue) -> Void

    private struct Configuration {
        var onIssue: IssueHandler?
        var isSentinelInstalled = false
    }

    private static let configuration = Mutex(Configuration())

    /// Called when decoding fails or fields are patched. Defaults to `AppLog.warning` when `nil`.
    public static var onIssue: IssueHandler? {
        get { configuration.withLock { $0.onIssue } }
        set { configuration.withLock { $0.onIssue = newValue } }
    }

    /// Turns field-level diagnostics on or off. On by default in DEBUG, off in release (it has a cost).
    public static func setFieldDiagnosticsEnabled(_ isEnabled: Bool) {
        configuration.withLock { $0.isSentinelInstalled = true }
        SmartSentinel.debugMode = isEnabled ? .alert : .none
        guard isEnabled else { return }
        SmartSentinel.onLogGenerated { log in
            report(SafeJSONIssue(kind: .fieldCompatibility, typeName: "", message: log))
        }
    }

    /// Decodes a model from `Data`. Returns `nil` on failure.
    public static func decode<T: SmartDecodable>(_ type: T.Type, from data: Data) -> T? {
        finish(T.deserialize(from: data), type: type, source: "Data(\(data.count) bytes)")
    }

    /// Decodes a model from a JSON string. Returns `nil` on failure.
    public static func decode<T: SmartDecodable>(_ type: T.Type, from string: String) -> T? {
        finish(T.deserialize(from: string), type: type, source: "String(\(string.count) chars)")
    }

    /// Decodes a model from a dictionary. Returns `nil` on failure.
    public static func decode<T: SmartDecodable>(_ type: T.Type, from dict: [String: Any]) -> T? {
        finish(T.deserialize(from: dict), type: type, source: "Dictionary(\(dict.count) keys)")
    }

    /// Decodes an array of models from `Data`. Returns `[]` on failure.
    public static func decodeArray<T: SmartDecodable>(_ type: T.Type, from data: Data) -> [T] {
        finish([T].deserialize(from: data), type: type, source: "Data(\(data.count) bytes)") ?? []
    }

    private static func finish<Result, T>(_ result: Result?, type: T.Type, source: String) -> Result? {
        installDefaultDiagnosticsIfNeeded()
        if result == nil {
            let typeName = String(describing: type)
            report(SafeJSONIssue(
                kind: .decodeFailed,
                typeName: typeName,
                message: "Failed to decode \(typeName) from \(source)"
            ))
        }
        return result
    }

    private static func installDefaultDiagnosticsIfNeeded() {
        #if DEBUG
        let needsInstall = configuration.withLock { config in
            defer { config.isSentinelInstalled = true }
            return !config.isSentinelInstalled
        }
        if needsInstall { setFieldDiagnosticsEnabled(true) }
        #endif
    }

    private static func report(_ issue: SafeJSONIssue) {
        if let handler = onIssue {
            handler(issue)
        } else {
            AppLog.warning("[SafeJSON] \(issue.message)")
        }
    }
}
