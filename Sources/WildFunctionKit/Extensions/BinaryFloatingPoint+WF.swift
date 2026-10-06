import Foundation

/// Applies to `Double`, `Float` and `CGFloat`.
extension BinaryFloatingPoint {
    /// Truncates to `Int`. Returns `nil` for NaN, infinity or out-of-range values instead of trapping.
    public var wf_intValue: Int? {
        Int(exactly: rounded(.towardZero))
    }

    /// Truncates to `Int`, clamped to `Int.min...Int.max`. NaN becomes 0.
    public var wf_clampedInt: Int {
        if isNaN { return 0 }
        if self >= Self(Int.max) { return .max }
        if self <= Self(Int.min) { return .min }
        return Int(self)
    }

    /// Returns `fallback` for NaN or infinity. Use before feeding a division result into layout.
    public func wf_finite(or fallback: Self = 0) -> Self {
        isFinite ? self : fallback
    }
}
