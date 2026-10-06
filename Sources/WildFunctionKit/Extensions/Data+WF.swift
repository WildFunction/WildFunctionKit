import Foundation

extension Data {
    /// Returns up to `length` bytes starting at byte offset `from`, clamped to valid bounds.
    public func wf_subdata(from: Int, length: Int) -> Data {
        guard length > 0 else { return Data() }
        let lower = Swift.max(0, from)
        let (sum, overflow) = lower.addingReportingOverflow(length)
        let upper = Swift.min(count, overflow ? count : sum)
        guard lower < upper else { return Data() }
        return subdata(in: (startIndex + lower)..<(startIndex + upper))
    }

    /// Decodes as UTF-8. Returns `nil` for invalid data.
    public var wf_utf8String: String? {
        String(data: self, encoding: .utf8)
    }

    /// Parses a JSON object. Returns `nil` when invalid or the top level is not an object.
    public var wf_jsonDictionary: [String: Any]? {
        (try? JSONSerialization.jsonObject(with: self)) as? [String: Any]
    }

    /// Parses a JSON array. Returns `nil` when invalid or the top level is not an array.
    public var wf_jsonArray: [Any]? {
        (try? JSONSerialization.jsonObject(with: self)) as? [Any]
    }
}
