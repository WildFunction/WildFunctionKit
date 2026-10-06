import Foundation
import Synchronization
import Testing
@testable import WildFunctionKit

private struct DemoItem: SmartCodableX {
    var id = ""
    var name = "unnamed"
    var rating = 0.0
    var isOpen = false
    var tags: [String] = []
    var owner: Owner?
}

/// Used only by the diagnostics-disabled test so its logs can be told apart.
private struct SilentItem: SmartCodableX {
    var id = ""
    var tags: [String] = []
}

private struct Owner: SmartCodableX {
    var name = ""
}

private final class IssueRecorder: Sendable {
    private let storage = Mutex<[SafeJSONIssue]>([])
    var issues: [SafeJSONIssue] { storage.withLock { $0 } }
    func record(_ issue: SafeJSONIssue) { storage.withLock { $0.append(issue) } }
}

/// `onIssue` is global, so this suite runs serially.
@Suite("SafeJSON", .serialized)
struct SafeJSONTests {
    @Test("Decodes from Data, String and Dictionary")
    func decodesFromAllSources() {
        let json = #"{"id": "p1", "name": "Cafe", "rating": 4.5, "isOpen": true, "tags": ["a"], "owner": {"name": "K"}}"#
        let expected = ("p1", "Cafe", 4.5, true, ["a"], "K")

        let fromString = SafeJSON.decode(DemoItem.self, from: json)
        let fromData = SafeJSON.decode(DemoItem.self, from: Data(json.utf8))
        let fromDict = SafeJSON.decode(DemoItem.self, from: [
            "id": "p1", "name": "Cafe", "rating": 4.5, "isOpen": true, "tags": ["a"], "owner": ["name": "K"],
        ])

        for item in [fromString, fromData, fromDict] {
            #expect(item?.id == expected.0)
            #expect(item?.name == expected.1)
            #expect(item?.rating == expected.2)
            #expect(item?.isOpen == expected.3)
            #expect(item?.tags == expected.4)
            #expect(item?.owner?.name == expected.5)
        }
    }

    @Test("Missing fields use property defaults")
    func missingFieldsUseDefaults() {
        let item = SafeJSON.decode(DemoItem.self, from: #"{"id": "p1"}"#)
        #expect(item?.id == "p1")
        #expect(item?.name == "unnamed")
        #expect(item?.tags == [])
        #expect(item?.owner == nil)
    }

    @Test("Mistyped fields are converted or fall back to defaults")
    func typeMismatchIsTolerated() {
        let item = SafeJSON.decode(DemoItem.self, from: #"{"id": 123, "rating": "4.5", "isOpen": 1, "tags": "oops", "owner": []}"#)
        #expect(item?.id == "123")
        #expect(item?.rating == 4.5)
        #expect(item?.isOpen == true)
        #expect(item?.tags == [])
        #expect(item?.owner == nil)
    }

    @Test("Null fields fall back to defaults")
    func nullIsTolerated() {
        let item = SafeJSON.decode(DemoItem.self, from: #"{"id": null, "name": null, "tags": null, "owner": null}"#)
        #expect(item?.id == "")
        #expect(item?.name == "unnamed")
        #expect(item?.tags == [])
        #expect(item?.owner == nil)
    }

    @Test("decodeArray decodes, or returns [] on failure")
    func decodesArrays() {
        let list = SafeJSON.decodeArray(DemoItem.self, from: Data(#"[{"id": "a"}, {"id": "b"}]"#.utf8))
        #expect(list.map(\.id) == ["a", "b"])
        #expect(SafeJSON.decodeArray(DemoItem.self, from: Data("not json".utf8)).isEmpty)
    }

    @Test("Decode failures are reported through onIssue")
    func reportsDecodeFailure() {
        let recorder = IssueRecorder()
        SafeJSON.onIssue = { recorder.record($0) }
        defer { SafeJSON.onIssue = nil }

        #expect(SafeJSON.decode(DemoItem.self, from: "not json") == nil)
        #expect(SafeJSON.decode(DemoItem.self, from: Data()) == nil)

        let failures = recorder.issues.filter { $0.kind == .decodeFailed }
        #expect(failures.count == 2)
        #expect(failures.allSatisfy { $0.typeName == "DemoItem" })
        #expect(failures.first?.message.contains("DemoItem") == true)
    }

    @Test("Without onIssue, failures go to the default log")
    func defaultHandlerDoesNotCrash() {
        SafeJSON.onIssue = nil
        #expect(SafeJSON.onIssue == nil)
        #expect(SafeJSON.decode(DemoItem.self, from: "{") == nil)
    }

    @Test("Patched fields are reported through onIssue")
    func reportsFieldCompatibility() async {
        let recorder = IssueRecorder()
        SafeJSON.onIssue = { recorder.record($0) }
        SafeJSON.setFieldDiagnosticsEnabled(true)
        defer { SafeJSON.onIssue = nil }

        _ = SafeJSON.decode(DemoItem.self, from: #"{"id": "p1", "tags": "oops"}"#)

        // SmartSentinel aggregates logs asynchronously, and logs from earlier tests may arrive first,
        // so poll for the report about this test's own field.
        func hasReport() -> Bool {
            recorder.issues.contains { $0.kind == .fieldCompatibility && $0.message.contains("tags") }
        }
        for _ in 0..<500 where !hasReport() {
            try? await Task.sleep(for: .milliseconds(20))
        }
        #expect(hasReport())
    }

    @Test("Disabling field diagnostics stops field reports")
    func diagnosticsCanBeDisabled() async {
        let recorder = IssueRecorder()
        SafeJSON.onIssue = { recorder.record($0) }
        SafeJSON.setFieldDiagnosticsEnabled(false)
        defer {
            SafeJSON.onIssue = nil
            SafeJSON.setFieldDiagnosticsEnabled(true)
        }

        _ = SafeJSON.decode(SilentItem.self, from: #"{"id": "p1", "tags": "oops"}"#)
        try? await Task.sleep(for: .milliseconds(200))
        // Logs from the previous test may arrive late, so only check this test's own model.
        #expect(!recorder.issues.contains { $0.message.contains("SilentItem") })
    }
}

@Suite("AppLog")
struct AppLogTests {
    @Test("Every level logs and custom categories work")
    func logsAtEveryLevel() {
        let custom = AppLogCategory(name: "payment")
        #expect(custom.name == "payment")
        #expect(custom != .app)
        #expect(Set([AppLogCategory.app, .network, .ui, .plugin, .event, .router]).count == 6)

        AppLog.debug("debug", category: custom)
        AppLog.info("info")
        AppLog.warning("warning", category: .network)
        AppLog.error("error", category: .router)
    }

    @Test("info and above always evaluate the message")
    func evaluatesMessage() {
        var evaluated = 0
        func message() -> String { evaluated += 1; return "m" }
        AppLog.info(message())
        AppLog.warning(message())
        AppLog.error(message())
        #expect(evaluated == 3)
    }
}
