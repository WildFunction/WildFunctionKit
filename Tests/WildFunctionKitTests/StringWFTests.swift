import Foundation
import Testing
@testable import WildFunctionKit

@Suite("String+WF")
struct StringWFTests {
    @Test("wf_substring(from:length:) clamps to valid bounds", arguments: [
        (0, 5, "hello"),
        (6, 100, "world"),
        (-3, 2, "he"),
        (11, 1, ""),
        (99, 1, ""),
        (2, 0, ""),
        (2, -1, ""),
        (3, Int.max, "lo world"),
    ] as [(Int, Int, String)])
    func substringFromLength(from: Int, length: Int, expected: String) {
        #expect("hello world".wf_substring(from: from, length: length) == expected)
    }

    @Test("wf_substring(in:)", arguments: [
        (0..<5, "hello"),
        (6..<99, "world"),
        (-4..<2, "he"),
        (11..<12, ""),
        (3..<3, ""),
    ] as [(Range<Int>, String)])
    func substringInRange(range: Range<Int>, expected: String) {
        #expect("hello world".wf_substring(in: range) == expected)
    }

    @Test("wf_substring(from:) / wf_substring(to:)")
    func substringFromAndTo() {
        #expect("hello".wf_substring(from: 3) == "lo")
        #expect("hello".wf_substring(from: -1) == "hello")
        #expect("hello".wf_substring(from: 9) == "")
        #expect("hello".wf_substring(to: 2) == "he")
        #expect("hello".wf_substring(to: 99) == "hello")
        #expect("hello".wf_substring(to: -1) == "")
    }

    @Test("Works on Characters, not UTF-16 units")
    func handlesGraphemes() {
        #expect("你好👨‍👩‍👧世界".wf_substring(from: 2, length: 2) == "👨‍👩‍👧世")
        #expect("你好👨‍👩‍👧世界".wf_character(at: 2) == "👨‍👩‍👧")
        #expect("".wf_substring(from: 0, length: 3) == "")
    }

    @Test("wf_character(at:) returns nil when out of bounds")
    func characterAt() {
        #expect("abc".wf_character(at: 0) == "a")
        #expect("abc".wf_character(at: 2) == "c")
        #expect("abc".wf_character(at: 3) == nil)
        #expect("abc".wf_character(at: -1) == nil)
        #expect("".wf_character(at: 0) == nil)
    }

    @Test("wf_truncated")
    func truncated() {
        #expect("hello world".wf_truncated(to: 5) == "hello…")
        #expect("hello".wf_truncated(to: 5) == "hello")
        #expect("hello".wf_truncated(to: 2, trailing: "") == "he")
        #expect("hello".wf_truncated(to: 0) == "")
        #expect("hello".wf_truncated(to: -3) == "")
    }

    @Test("wf_isBlank / wf_nilIfBlank")
    func blank() {
        #expect("".wf_isBlank)
        #expect(" \n\t".wf_isBlank)
        #expect(!" a ".wf_isBlank)
        #expect(" ".wf_nilIfBlank == nil)
        #expect(" a ".wf_nilIfBlank == " a ")
    }

    @Test("wf_intValue", arguments: [
        ("42", 42), (" 7 ", 7), ("-3", -3), ("3.9", 3), ("abc", nil), ("", nil), ("1e400", nil),
    ] as [(String, Int?)])
    func intValue(text: String, expected: Int?) {
        #expect(text.wf_intValue == expected)
    }

    @Test("wf_doubleValue", arguments: [("2.5", 2.5), (" 3 ", 3.0), ("abc", nil), ("", nil)] as [(String, Double?)])
    func doubleValue(text: String, expected: Double?) {
        #expect(text.wf_doubleValue == expected)
    }

    @Test("wf_boolValue", arguments: [
        ("1", true), ("0", false), ("true", true), ("FALSE", false),
        (" Yes ", true), ("no", false), ("maybe", nil), ("", nil), ("2", nil),
    ] as [(String, Bool?)])
    func boolValue(text: String, expected: Bool?) {
        #expect(text.wf_boolValue == expected)
    }

    @Test("wf_url trims whitespace and returns nil when blank")
    func url() {
        #expect(" https://example.com/a?b=1 \n".wf_url?.absoluteString == "https://example.com/a?b=1")
        #expect("myapp://detail?id=1".wf_url?.host() == "detail")
        #expect("".wf_url == nil)
        #expect("   ".wf_url == nil)
    }

    @Test("wf_jsonDictionary / wf_jsonArray return nil for invalid or mismatched JSON")
    func json() {
        #expect(#"{"a": 1}"#.wf_jsonDictionary?.wf_int("a") == 1)
        #expect(#"[1, 2]"#.wf_jsonArray?.count == 2)
        #expect(#"[1, 2]"#.wf_jsonDictionary == nil)
        #expect(#"{"a": 1}"#.wf_jsonArray == nil)
        #expect("not json".wf_jsonDictionary == nil)
        #expect("".wf_jsonArray == nil)
    }

    @Test("wf_trimmed / wf_isDigits")
    func trimmedAndDigits() {
        #expect("  a b \n".wf_trimmed == "a b")
        #expect("012345".wf_isDigits)
        #expect(!"".wf_isDigits)
        #expect(!"12a".wf_isDigits)
        #expect(!"1.5".wf_isDigits)
        #expect(!"１２３".wf_isDigits)
    }

    @Test("wf_urlEncoded also encodes separators")
    func urlEncoding() {
        #expect("a b&c=d+e?f/g".wf_urlEncoded == "a%20b%26c%3Dd%2Be%3Ff%2Fg")
        #expect("你好".wf_urlEncoded == "%E4%BD%A0%E5%A5%BD")
        #expect("safe-._~09azAZ".wf_urlEncoded == "safe-._~09azAZ")
        #expect("a%20b%26c".wf_urlDecoded == "a b&c")
        #expect("100%".wf_urlDecoded == "100%")
        #expect("a b&c=你".wf_urlEncoded.wf_urlDecoded == "a b&c=你")
    }

    @Test("wf_base64Encoded / wf_base64Decoded")
    func base64() {
        #expect("hello 你好".wf_base64Encoded.wf_base64Decoded == "hello 你好")
        #expect("aGVsbG8=".wf_base64Decoded == "hello")
        #expect("not base64!".wf_base64Decoded == nil)
        #expect("//8=".wf_base64Decoded == nil)
    }
}
