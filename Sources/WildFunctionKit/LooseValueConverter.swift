import Foundation

/// Lenient value conversion behind the `[String: Any]` accessors. Internal.
enum LooseValueConverter {
    private static let trueLiterals: Set<String> = ["1", "true", "yes"]
    private static let falseLiterals: Set<String> = ["0", "false", "no"]

    /// Converts to `T`: a direct cast first, then Int / String / Double / Bool conversions.
    static func convert<T>(_ value: Any, to type: T.Type) -> T? {
        if type == Bool.self { return bool(value) as? T }
        if type == String.self { return string(value) as? T }
        if type == Int.self { return int(value) as? T }
        if type == Double.self { return double(value) as? T }
        return value as? T
    }

    static func string(_ value: Any) -> String? {
        if let string = value as? String { return string }
        if isBoolean(value), let bool = value as? Bool { return bool ? "true" : "false" }
        if let int = value as? Int { return String(int) }
        if let double = value as? Double { return String(double) }
        return nil
    }

    static func int(_ value: Any) -> Int? {
        if isBoolean(value), let bool = value as? Bool { return bool ? 1 : 0 }
        if let int = value as? Int { return int }
        if let double = value as? Double { return int(fromDouble: double) }
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let int = Int(trimmed) { return int }
            if let double = Double(trimmed) { return int(fromDouble: double) }
        }
        return nil
    }

    static func double(_ value: Any) -> Double? {
        if isBoolean(value), let bool = value as? Bool { return bool ? 1 : 0 }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let string = value as? String {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    static func bool(_ value: Any) -> Bool? {
        if isBoolean(value), let bool = value as? Bool { return bool }
        if let int = value as? Int { return int != 0 }
        if let double = value as? Double { return double != 0 }
        if let string = value as? String {
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trueLiterals.contains(normalized) { return true }
            if falseLiterals.contains(normalized) { return false }
        }
        return nil
    }

    /// Tells real booleans from numbers that happen to be 0 or 1 (`NSNumber(1) as? Bool` succeeds).
    private static func isBoolean(_ value: Any) -> Bool {
        if value is Bool, !(value is NSNumber) { return true }
        guard let number = value as? NSNumber else { return false }
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    /// Returns `nil` instead of trapping for NaN, infinity and out-of-range values.
    private static func int(fromDouble double: Double) -> Int? {
        Int(exactly: double.rounded(.towardZero))
    }
}
