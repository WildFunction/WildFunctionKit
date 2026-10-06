import Foundation

extension Collection {
    /// Returns the element at `index`, or `nil` when out of bounds.
    ///
    /// ```swift
    /// let items = [1, 2, 3]
    /// items[safe: 5]   // nil
    /// ```
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Returns `nil` when empty, otherwise `self`.
    public var wf_nilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}
