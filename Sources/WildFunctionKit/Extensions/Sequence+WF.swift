import Foundation

extension Sequence where Element: Hashable {
    /// Removes duplicates, keeping first occurrences in order.
    ///
    /// ```swift
    /// [3, 1, 3, 2, 1].wf_removingDuplicates()   // [3, 1, 2]
    /// ```
    public func wf_removingDuplicates() -> [Element] {
        wf_removingDuplicates(by: \.self)
    }
}

extension Sequence {
    /// Removes duplicates by a key, keeping first occurrences in order.
    ///
    /// ```swift
    /// items.wf_removingDuplicates(by: \.id)
    /// ```
    public func wf_removingDuplicates<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    /// Sorts by a comparable key.
    public func wf_sorted<Value: Comparable>(by keyPath: KeyPath<Element, Value>, ascending: Bool = true) -> [Element] {
        sorted { lhs, rhs in
            ascending ? lhs[keyPath: keyPath] < rhs[keyPath: keyPath] : lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
        }
    }

    /// Splits into matching and non-matching elements, preserving order.
    public func wf_partitioned(by condition: (Element) throws -> Bool) rethrows -> (matching: [Element], rest: [Element]) {
        var matching: [Element] = []
        var rest: [Element] = []
        for element in self {
            if try condition(element) {
                matching.append(element)
            } else {
                rest.append(element)
            }
        }
        return (matching, rest)
    }

    /// Sums a numeric key. Returns zero for an empty sequence.
    public func wf_sum<Value: AdditiveArithmetic>(of keyPath: KeyPath<Element, Value>) -> Value {
        reduce(.zero) { $0 + $1[keyPath: keyPath] }
    }
}
