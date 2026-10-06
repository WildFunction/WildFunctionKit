import Foundation

/// Applies to all fixed-width integers (`Int`, `Int64`, `UInt`, ...).
extension FixedWidthInteger {
    /// Divides safely. Returns `nil` for a zero divisor or overflow (e.g. `Int.min / -1`).
    public func wf_divided(by divisor: Self) -> Self? {
        guard divisor != 0 else { return nil }
        let (quotient, overflow) = dividedReportingOverflow(by: divisor)
        return overflow ? nil : quotient
    }

    /// Remainder, safely. Returns `nil` for a zero divisor or overflow.
    public func wf_remainder(dividingBy divisor: Self) -> Self? {
        guard divisor != 0 else { return nil }
        let (remainder, overflow) = remainderReportingOverflow(dividingBy: divisor)
        return overflow ? nil : remainder
    }
}
