import Foundation

extension MutableCollection {
    /// Safe subscript. Out-of-bounds reads return `nil`; out-of-bounds or `nil` writes are ignored.
    public subscript(safe index: Index) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
        set {
            guard let newValue, indices.contains(index) else { return }
            self[index] = newValue
        }
    }

    /// Swaps two elements. Returns `false` when either index is out of bounds.
    @discardableResult
    public mutating func wf_swapAt(_ first: Index, _ second: Index) -> Bool {
        guard indices.contains(first), indices.contains(second) else { return false }
        swapAt(first, second)
        return true
    }
}
