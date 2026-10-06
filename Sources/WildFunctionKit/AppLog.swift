import Foundation
import os
import Synchronization

/// Log category, maps to the `os.Logger` category.
///
/// Apps can add their own:
/// ```swift
/// extension AppLogCategory {
///     static let payment = AppLogCategory(name: "payment")
/// }
/// ```
public struct AppLogCategory: Sendable, Hashable {
    /// Name shown in Console's category column.
    public let name: String

    /// Creates a custom category.
    public init(name: String) {
        self.name = name
    }

    /// General.
    public static let app = AppLogCategory(name: "app")
    /// Networking.
    public static let network = AppLogCategory(name: "network")
    /// UI.
    public static let ui = AppLogCategory(name: "ui")
    /// Page plugins.
    public static let plugin = AppLogCategory(name: "plugin")
    /// Page events.
    public static let event = AppLogCategory(name: "event")
    /// Routing.
    public static let router = AppLogCategory(name: "router")
}

/// Thin logging facade over `os.Logger`.
///
/// Subsystem is the main bundle identifier. `debug` only logs in DEBUG builds.
public enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "WildFunctionKit"
    private static let loggers = Mutex<[AppLogCategory: Logger]>([:])

    /// Debug log. Not emitted (or evaluated) in release builds.
    public static func debug(_ message: @autoclosure () -> String, category: AppLogCategory = .app) {
        #if DEBUG
        let text = message()
        logger(for: category).debug("\(text, privacy: .public)")
        #endif
    }

    /// Informational message.
    public static func info(_ message: @autoclosure () -> String, category: AppLogCategory = .app) {
        let text = message()
        logger(for: category).info("\(text, privacy: .public)")
    }

    /// Something unexpected happened but the flow can continue.
    public static func warning(_ message: @autoclosure () -> String, category: AppLogCategory = .app) {
        let text = message()
        logger(for: category).warning("\(text, privacy: .public)")
    }

    /// The flow was interrupted or the result is unreliable.
    public static func error(_ message: @autoclosure () -> String, category: AppLogCategory = .app) {
        let text = message()
        logger(for: category).error("\(text, privacy: .public)")
    }

    private static func logger(for category: AppLogCategory) -> Logger {
        loggers.withLock { cache in
            if let cached = cache[category] { return cached }
            let created = Logger(subsystem: subsystem, category: category.name)
            cache[category] = created
            return created
        }
    }
}
