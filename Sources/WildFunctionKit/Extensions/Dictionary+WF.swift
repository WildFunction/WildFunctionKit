import Foundation

// MARK: - Typed access

extension Dictionary where Key == String, Value == Any {
    /// Returns the value for `key` as `T`, converting between Int / String / Double / Bool when needed.
    public func wf_value<T>(_ key: String, as type: T.Type) -> T? {
        guard let raw = self[key], !(raw is NSNull) else { return nil }
        return LooseValueConverter.convert(raw, to: type)
    }

    /// Same as `wf_value(_:as:)`, falling back to `default` when missing or unconvertible.
    ///
    /// ```swift
    /// let payload: [String: Any] = ["count": "12"]
    /// payload.wf_value("count", as: Int.self, default: 0)   // 12
    /// ```
    public func wf_value<T>(_ key: String, as type: T.Type, default defaultValue: T) -> T {
        wf_value(key, as: type) ?? defaultValue
    }

    /// String value. Numbers and booleans are stringified.
    public func wf_string(_ key: String, default defaultValue: String = "") -> String {
        wf_value(key, as: String.self, default: defaultValue)
    }

    /// Int value. Accepts numeric strings, doubles (truncated) and booleans.
    public func wf_int(_ key: String, default defaultValue: Int = 0) -> Int {
        wf_value(key, as: Int.self, default: defaultValue)
    }

    /// Double value. Accepts numeric strings, ints and booleans.
    public func wf_double(_ key: String, default defaultValue: Double = 0) -> Double {
        wf_value(key, as: Double.self, default: defaultValue)
    }

    /// Bool value. Accepts `true/false`, `1/0`, `"1"/"0"`, `"true"/"false"`, `"yes"/"no"` (case-insensitive).
    public func wf_bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        wf_value(key, as: Bool.self, default: defaultValue)
    }

    /// URL value from a non-empty string.
    public func wf_url(_ key: String) -> URL? {
        (self[key] as? String)?.wf_url
    }

    /// Nested dictionary, or `[:]` when missing or of another type.
    public func wf_dict(_ key: String) -> [String: Any] {
        self[key] as? [String: Any] ?? [:]
    }

    /// Array value. Elements that cannot be converted to `T` are dropped.
    public func wf_array<T>(_ key: String, of type: T.Type) -> [T] {
        guard let raw = self[key] as? [Any] else { return [] }
        return raw.compactMap { element in
            element is NSNull ? nil : LooseValueConverter.convert(element, to: type)
        }
    }
}

// MARK: - Key path access

extension Dictionary where Key == String, Value == Any {
    /// Walks nested dictionaries along `path`. Returns `nil` when any level is missing.
    ///
    /// ```swift
    /// // {"data": {"user": {"age": "18"}}}
    /// payload.wf_value(atPath: ["data", "user", "age"], as: Int.self)   // 18
    /// ```
    public func wf_value<T>(atPath path: [String], as type: T.Type) -> T? {
        guard let last = path.last else { return nil }
        var current = self
        for key in path.dropLast() {
            guard let next = current[key] as? [String: Any] else { return nil }
            current = next
        }
        return current.wf_value(last, as: type)
    }
}

// MARK: - Safe serialization

extension Dictionary where Key == String, Value == Any {
    /// Serializes to JSON data with sorted keys. Returns `nil` for invalid JSON objects instead of raising.
    public func wf_jsonData(prettyPrinted: Bool = false) -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        let options: JSONSerialization.WritingOptions = prettyPrinted ? [.sortedKeys, .prettyPrinted] : [.sortedKeys]
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }

    /// Serializes to a JSON string. Returns `nil` for invalid JSON objects.
    public func wf_jsonString(prettyPrinted: Bool = false) -> String? {
        wf_jsonData(prettyPrinted: prettyPrinted)?.wf_utf8String
    }
}

// MARK: - Convenience

extension Dictionary {
    /// Keeps only the given keys.
    public func wf_picking(keys: some Sequence<Key>) -> [Key: Value] {
        keys.reduce(into: [:]) { result, key in
            if let value = self[key] { result[key] = value }
        }
    }

    /// Returns a copy without the given keys.
    public func wf_removing(keys: some Sequence<Key>) -> [Key: Value] {
        let excluded = Set(keys)
        return filter { !excluded.contains($0.key) }
    }
}
