import Foundation

extension Comparable {
    /// Clamps the value between two bounds, given in either order.
    ///
    /// ```swift
    /// 15.wf_clamped(0, 10)   // 10
    /// 15.wf_clamped(10, 0)   // 10
    /// ```
    public func wf_clamped(_ first: Self, _ second: Self) -> Self {
        let lower = Swift.min(first, second)
        let upper = Swift.max(first, second)
        return Swift.min(Swift.max(self, lower), upper)
    }
}
