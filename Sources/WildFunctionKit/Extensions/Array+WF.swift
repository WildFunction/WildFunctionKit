import Foundation

// MARK: - Safe mutation

extension Array {
    /// Removes the element at `index`. Returns `nil` when out of bounds.
    @discardableResult
    public mutating func wf_remove(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return remove(at: index)
    }

    /// Inserts at `index` (valid range `0...count`). Returns `false` when out of bounds.
    @discardableResult
    public mutating func wf_insert(_ element: Element, at index: Int) -> Bool {
        guard index >= 0, index <= count else { return false }
        insert(element, at: index)
        return true
    }

    /// Replaces the element at `index`. Returns `false` when out of bounds.
    @discardableResult
    public mutating func wf_replace(at index: Int, with element: Element) -> Bool {
        guard indices.contains(index) else { return false }
        self[index] = element
        return true
    }

    /// Moves an element from `source` to `destination`. Returns `false` when either is out of bounds.
    @discardableResult
    public mutating func wf_move(from source: Int, to destination: Int) -> Bool {
        guard indices.contains(source), indices.contains(destination) else { return false }
        let element = remove(at: source)
        insert(element, at: destination)
        return true
    }

    /// Removes the first element. Returns `nil` on an empty array instead of trapping.
    @discardableResult
    public mutating func wf_removeFirst() -> Element? {
        isEmpty ? nil : removeFirst()
    }

    /// Removes the last element. Returns `nil` on an empty array instead of trapping.
    @discardableResult
    public mutating func wf_removeLast() -> Element? {
        isEmpty ? nil : removeLast()
    }

    /// Removes the first `count` elements, clamped to `0...self.count`.
    public mutating func wf_removeFirst(_ count: Int) {
        removeFirst(Swift.min(Swift.max(0, count), self.count))
    }

    /// Removes the last `count` elements, clamped to `0...self.count`.
    public mutating func wf_removeLast(_ count: Int) {
        removeLast(Swift.min(Swift.max(0, count), self.count))
    }

    /// Removes a range, clamped to valid bounds.
    public mutating func wf_removeSubrange(_ range: Range<Int>) {
        guard let clamped = wf_clampedRange(range) else { return }
        removeSubrange(clamped)
    }
}

// MARK: - Safe slicing

extension Array {
    /// Returns the elements in `range`, clamped to valid bounds.
    ///
    /// ```swift
    /// [1, 2, 3].wf_slice(1..<10)   // [2, 3]
    /// ```
    public func wf_slice(_ range: Range<Int>) -> [Element] {
        guard let clamped = wf_clampedRange(range) else { return [] }
        return Array(self[clamped])
    }

    /// Returns up to `length` elements starting at `from`, clamped to valid bounds.
    public func wf_slice(from: Int, length: Int) -> [Element] {
        guard length > 0 else { return [] }
        let lower = Swift.max(0, from)
        let (sum, overflow) = lower.addingReportingOverflow(length)
        return wf_slice(lower..<(overflow ? count : sum))
    }

    /// Splits into chunks of `size`. Returns `[]` when `size <= 0`.
    ///
    /// ```swift
    /// [1, 2, 3, 4, 5].wf_chunked(size: 2)   // [[1, 2], [3, 4], [5]]
    /// ```
    public func wf_chunked(size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { wf_slice(from: $0, length: size) }
    }

    /// Clamps a range to `0..<count`. Returns `nil` when the result is empty.
    private func wf_clampedRange(_ range: Range<Int>) -> Range<Int>? {
        let lower = Swift.max(0, range.lowerBound)
        let upper = Swift.min(count, range.upperBound)
        return lower < upper ? lower..<upper : nil
    }
}

// MARK: - Convenience

extension Array {
    /// Appends `element` only when it is non-nil.
    public mutating func wf_appendIfPresent(_ element: Element?) {
        guard let element else { return }
        append(element)
    }
}

extension Array where Element: Equatable {
    /// Removes every element equal to `element`. Returns how many were removed.
    @discardableResult
    public mutating func wf_removeAll(_ element: Element) -> Int {
        let before = count
        removeAll { $0 == element }
        return before - count
    }
}
