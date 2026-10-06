import Foundation
import Testing
@testable import WildFunctionKit

@Suite("Dictionary+WF")
struct DictionaryWFTests {
    /// Built with JSONSerialization so the values are real NSNumber / NSString / NSNull.
    private static var json: [String: Any] {
        let text = """
        {"int": 7, "double": 2.5, "boolTrue": true, "boolFalse": false, "one": 1, "zero": 0,
         "intString": "42", "doubleString": "3.9", "word": "hello", "null": null,
         "yes": "YES", "no": "no", "trueString": " true ", "falseString": "False",
         "dict": {"k": "v"}, "mixed": [1, "2", 3.0, "x", null, true], "huge": 1e300}
        """
        // The fixture is hardcoded valid JSON; a parse failure means the test itself is wrong.
        return (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] ?? [:]
    }

    private static var native: [String: Any] { ["int": 7, "double": 2.5, "bool": true, "string": "s"] }

    @Test("wf_int conversion matrix", arguments: [
        ("int", 7), ("double", 2), ("boolTrue", 1), ("boolFalse", 0),
        ("intString", 42), ("doubleString", 3), ("word", -1), ("null", -1), ("missing", -1),
        ("dict", -1), ("huge", -1),
    ] as [(String, Int)])
    func intMatrix(key: String, expected: Int) {
        #expect(Self.json.wf_int(key, default: -1) == expected)
    }

    @Test("wf_double conversion matrix", arguments: [
        ("int", 7.0), ("double", 2.5), ("boolTrue", 1.0), ("intString", 42.0),
        ("doubleString", 3.9), ("word", -1.0), ("null", -1.0), ("missing", -1.0),
    ] as [(String, Double)])
    func doubleMatrix(key: String, expected: Double) {
        #expect(Self.json.wf_double(key, default: -1) == expected)
    }

    @Test("wf_string conversion matrix", arguments: [
        ("word", "hello"), ("int", "7"), ("one", "1"), ("double", "2.5"),
        ("boolTrue", "true"), ("boolFalse", "false"), ("null", "?"), ("missing", "?"), ("dict", "?"),
    ] as [(String, String)])
    func stringMatrix(key: String, expected: String) {
        #expect(Self.json.wf_string(key, default: "?") == expected)
    }

    @Test("wf_bool accepts booleans, numbers and string forms", arguments: [
        ("boolTrue", true), ("boolFalse", false), ("one", true), ("zero", false),
        ("yes", true), ("no", false), ("trueString", true), ("falseString", false),
        ("int", true), ("double", true),
    ] as [(String, Bool)])
    func boolMatrix(key: String, expected: Bool) {
        #expect(Self.json.wf_bool(key, default: !expected) == expected)
    }

    @Test("wf_bool falls back to the default when unrecognized", arguments: ["word", "null", "missing", "dict"])
    func boolFallsBack(key: String) {
        #expect(Self.json.wf_bool(key, default: true))
        #expect(!Self.json.wf_bool(key, default: false))
    }

    @Test("wf_bool parses \"1\" and \"0\"")
    func boolFromDigitStrings() {
        let dict: [String: Any] = ["a": "1", "b": "0"]
        #expect(dict.wf_bool("a"))
        #expect(!dict.wf_bool("b", default: true))
    }

    @Test("Native Swift values work too")
    func nativeSwiftValues() {
        #expect(Self.native.wf_int("int") == 7)
        #expect(Self.native.wf_string("int") == "7")
        #expect(Self.native.wf_int("bool") == 1)
        #expect(Self.native.wf_string("bool") == "true")
        #expect(Self.native.wf_bool("int"))
        #expect(Self.native.wf_double("int") == 7)
        #expect(Self.native.wf_int("double") == 2)
    }

    @Test("Default arguments")
    func defaultArguments() {
        let empty: [String: Any] = [:]
        #expect(empty.wf_string("k") == "")
        #expect(empty.wf_int("k") == 0)
        #expect(empty.wf_double("k") == 0)
        #expect(!empty.wf_bool("k"))
    }

    @Test("wf_value casts arbitrary types directly")
    func genericValue() {
        let date = Date(timeIntervalSince1970: 1)
        let dict: [String: Any] = ["date": date, "list": [1, 2]]
        #expect(dict.wf_value("date", as: Date.self, default: .distantPast) == date)
        #expect(dict.wf_value("list", as: [Int].self, default: []) == [1, 2])
        #expect(dict.wf_value("date", as: URL?.self, default: nil) == nil)
    }

    @Test("wf_dict and wf_array")
    func nestedContainers() {
        #expect(Self.json.wf_dict("dict").wf_string("k") == "v")
        #expect(Self.json.wf_dict("word").isEmpty)
        #expect(Self.json.wf_dict("missing").isEmpty)

        #expect(Self.json.wf_array("mixed", of: Int.self) == [1, 2, 3, 1])
        #expect(Self.json.wf_array("mixed", of: String.self) == ["1", "2", "3", "x", "true"])
        #expect(Self.json.wf_array("word", of: Int.self).isEmpty)
        #expect(Self.json.wf_array("missing", of: Int.self).isEmpty)
    }

    @Test("Optional wf_value tells a missing key from a default value")
    func optionalValue() {
        #expect(Self.json.wf_value("intString", as: Int.self) == 42)
        #expect(Self.json.wf_value("zero", as: Int.self) == 0)
        #expect(Self.json.wf_value("missing", as: Int.self) == nil)
        #expect(Self.json.wf_value("null", as: String.self) == nil)
        #expect(Self.json.wf_value("word", as: Int.self) == nil)
    }

    @Test("wf_url only accepts non-empty strings")
    func url() {
        let dict: [String: Any] = ["link": " https://example.com/a ", "blank": "  ", "number": 1]
        #expect(dict.wf_url("link")?.absoluteString == "https://example.com/a")
        #expect(dict.wf_url("blank") == nil)
        #expect(dict.wf_url("number") == nil)
        #expect(dict.wf_url("missing") == nil)
    }

    @Test("wf_jsonString / wf_jsonData produce stable JSON")
    func jsonSerialization() {
        let dict: [String: Any] = ["b": 1, "a": ["x": true]]
        #expect(dict.wf_jsonString() == #"{"a":{"x":true},"b":1}"#)
        #expect(dict.wf_jsonString(prettyPrinted: true)?.contains("\n") == true)
        #expect(dict.wf_jsonData()?.wf_jsonDictionary?.wf_int("b") == 1)
    }

    @Test("wf_jsonString returns nil for unserializable values instead of crashing")
    func jsonSerializationRejectsInvalidObjects() {
        let withDate: [String: Any] = ["date": Date()]
        let withNaN: [String: Any] = ["value": Double.nan]
        #expect(withDate.wf_jsonString() == nil)
        #expect(withDate.wf_jsonData() == nil)
        #expect(withNaN.wf_jsonString() == nil)
    }

    @Test("wf_value(atPath:) walks nested dictionaries")
    func valueAtPath() {
        let payload: [String: Any] = ["data": ["user": ["age": "18", "name": "K"], "list": [1]], "top": 1]
        #expect(payload.wf_value(atPath: ["data", "user", "age"], as: Int.self) == 18)
        #expect(payload.wf_value(atPath: ["data", "user", "name"], as: String.self) == "K")
        #expect(payload.wf_value(atPath: ["top"], as: Int.self) == 1)
        #expect(payload.wf_value(atPath: ["data", "missing", "age"], as: Int.self) == nil)
        #expect(payload.wf_value(atPath: ["top", "deeper"], as: Int.self) == nil)
        #expect(payload.wf_value(atPath: ["data", "list", "0"], as: Int.self) == nil)
        #expect(payload.wf_value(atPath: [], as: Int.self) == nil)
    }

    @Test("wf_picking / wf_removing")
    func pickingAndRemoving() {
        let dict = ["a": 1, "b": 2, "c": 3]
        #expect(dict.wf_picking(keys: ["a", "c", "x"]) == ["a": 1, "c": 3])
        #expect(dict.wf_picking(keys: [String]()).isEmpty)
        #expect(dict.wf_removing(keys: ["a", "x"]) == ["b": 2, "c": 3])
        #expect(dict.wf_removing(keys: [String]()) == dict)
    }
}
