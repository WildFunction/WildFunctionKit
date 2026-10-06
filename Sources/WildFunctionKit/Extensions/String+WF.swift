import Foundation

// MARK: - Safe slicing

extension String {
    /// Returns the characters in `range` (by `Character` offset), clamped to valid bounds.
    ///
    /// ```swift
    /// "hello".wf_substring(in: 3..<99)   // "lo"
    /// ```
    public func wf_substring(in range: Range<Int>) -> String {
        let lower = Swift.max(0, range.lowerBound)
        let upper = Swift.min(count, range.upperBound)
        guard lower < upper else { return "" }
        let start = index(startIndex, offsetBy: lower)
        let end = index(startIndex, offsetBy: upper)
        return String(self[start..<end])
    }

    /// Returns up to `length` characters starting at `from`, clamped to valid bounds.
    public func wf_substring(from: Int, length: Int) -> String {
        guard length > 0 else { return "" }
        let lower = Swift.max(0, from)
        let (sum, overflow) = lower.addingReportingOverflow(length)
        return wf_substring(in: lower..<(overflow ? Int.max : sum))
    }

    /// Returns the characters from `from` to the end.
    public func wf_substring(from: Int) -> String {
        wf_substring(in: Swift.max(0, from)..<Int.max)
    }

    /// Returns the characters before `to`.
    public func wf_substring(to: Int) -> String {
        wf_substring(in: 0..<Swift.max(0, to))
    }

    /// Returns the character at `offset`, or `nil` when out of bounds.
    public func wf_character(at offset: Int) -> Character? {
        guard offset >= 0, let target = index(startIndex, offsetBy: offset, limitedBy: endIndex), target < endIndex else {
            return nil
        }
        return self[target]
    }

    /// Truncates to `length` characters and appends `trailing` when anything was cut.
    ///
    /// ```swift
    /// "hello world".wf_truncated(to: 5)   // "hello…"
    /// ```
    public func wf_truncated(to length: Int, trailing: String = "…") -> String {
        guard length > 0 else { return "" }
        return count > length ? wf_substring(to: length) + trailing : self
    }
}

// MARK: - Safe conversion

extension String {
    /// Whether the string is empty after trimming whitespace.
    public var wf_isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns `nil` for a blank string, otherwise `self` (untrimmed).
    public var wf_nilIfBlank: String? {
        wf_isBlank ? nil : self
    }

    /// Int value. Tolerates surrounding whitespace and decimals (`"3.9"` → 3).
    public var wf_intValue: Int? {
        LooseValueConverter.int(self)
    }

    /// Double value. Tolerates surrounding whitespace.
    public var wf_doubleValue: Double? {
        LooseValueConverter.double(self)
    }

    /// Bool value from `"1"/"0"`, `"true"/"false"`, `"yes"/"no"` (case-insensitive).
    public var wf_boolValue: Bool? {
        LooseValueConverter.bool(self)
    }

    /// URL from the trimmed string. Returns `nil` when blank.
    public var wf_url: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : URL(string: trimmed)
    }

    /// Parses a JSON object. Returns `nil` when invalid or the top level is not an object.
    public var wf_jsonDictionary: [String: Any]? {
        Data(utf8).wf_jsonDictionary
    }

    /// Parses a JSON array. Returns `nil` when invalid or the top level is not an array.
    public var wf_jsonArray: [Any]? {
        Data(utf8).wf_jsonArray
    }
}

// MARK: - Transforms

extension String {
    /// Trims leading and trailing whitespace and newlines.
    public var wf_trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the string is non-empty and contains only ASCII digits.
    public var wf_isDigits: Bool {
        !isEmpty && allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// Percent-encodes for use as a URL query value, including `&`, `=`, `+`, `?` and `/`.
    public var wf_urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: Self.wf_queryValueAllowed) ?? self
    }

    /// Percent-decodes. Returns `self` when the input is malformed.
    public var wf_urlDecoded: String {
        removingPercentEncoding ?? self
    }

    /// Base64 of the UTF-8 bytes.
    public var wf_base64Encoded: String {
        Data(utf8).base64EncodedString()
    }

    /// Decodes Base64 into a UTF-8 string. Returns `nil` when invalid.
    public var wf_base64Decoded: String? {
        Data(base64Encoded: self)?.wf_utf8String
    }

    /// RFC 3986 unreserved characters; everything else is encoded.
    private static let wf_queryValueAllowed = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )
}
