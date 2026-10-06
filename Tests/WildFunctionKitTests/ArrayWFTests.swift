import Testing
@testable import WildFunctionKit

@Suite("Array+WF")
struct ArrayWFTests {
    @Test("wf_remove(at:) returns the element, or nil when out of bounds")
    func removeAt() {
        var items = ["a", "b", "c"]
        let removed = items.wf_remove(at: 1)
        #expect(removed == "b")
        #expect(items == ["a", "c"])

        let tooLarge = items.wf_remove(at: 5)
        let negative = items.wf_remove(at: -1)
        #expect(tooLarge == nil)
        #expect(negative == nil)
        #expect(items == ["a", "c"])
    }

    @Test("wf_insert accepts 0...count and rejects anything else")
    func insert() {
        var items = [1, 3]
        let middle = items.wf_insert(2, at: 1)
        let end = items.wf_insert(4, at: 3)
        #expect(middle)
        #expect(end)
        #expect(items == [1, 2, 3, 4])

        let tooLarge = items.wf_insert(9, at: 6)
        let negative = items.wf_insert(9, at: -1)
        #expect(!tooLarge)
        #expect(!negative)
        #expect(items == [1, 2, 3, 4])
    }

    @Test("wf_replace rejects out-of-bounds indices")
    func replace() {
        var items = [1, 2]
        let replaced = items.wf_replace(at: 1, with: 20)
        let outOfBounds = items.wf_replace(at: 2, with: 30)
        #expect(replaced)
        #expect(!outOfBounds)
        #expect(items == [1, 20])
    }

    @Test("wf_move leaves the array untouched when out of bounds")
    func move() {
        var items = ["a", "b", "c", "d"]
        let forward = items.wf_move(from: 0, to: 2)
        #expect(forward)
        #expect(items == ["b", "c", "a", "d"])

        let backward = items.wf_move(from: 3, to: 0)
        #expect(backward)
        #expect(items == ["d", "b", "c", "a"])

        let badSource = items.wf_move(from: 4, to: 0)
        let badDestination = items.wf_move(from: 0, to: 4)
        #expect(!badSource)
        #expect(!badDestination)
        #expect(items == ["d", "b", "c", "a"])
    }

    @Test("wf_removeFirst / wf_removeLast return nil on an empty array")
    func removeFirstAndLast() {
        var items = [1, 2, 3]
        let first = items.wf_removeFirst()
        let last = items.wf_removeLast()
        #expect(first == 1)
        #expect(last == 3)
        #expect(items == [2])

        var empty: [Int] = []
        let noFirst = empty.wf_removeFirst()
        let noLast = empty.wf_removeLast()
        #expect(noFirst == nil)
        #expect(noLast == nil)
    }

    @Test("Removing by count clamps negative and oversized counts", arguments: [
        (-1, [1, 2, 3], [1, 2, 3]),
        (0, [1, 2, 3], [1, 2, 3]),
        (2, [3], [1]),
        (9, [], []),
    ] as [(Int, [Int], [Int])])
    func removeByCount(count: Int, afterRemovingFirst: [Int], afterRemovingLast: [Int]) {
        var head = [1, 2, 3]
        var tail = [1, 2, 3]
        head.wf_removeFirst(count)
        tail.wf_removeLast(count)
        #expect(head == afterRemovingFirst)
        #expect(tail == afterRemovingLast)
    }

    @Test("wf_removeSubrange clamps the range")
    func removeSubrange() {
        var items = [0, 1, 2, 3, 4]
        items.wf_removeSubrange(3..<99)
        #expect(items == [0, 1, 2])
        items.wf_removeSubrange(-5..<1)
        #expect(items == [1, 2])
        items.wf_removeSubrange(7..<9)
        items.wf_removeSubrange(1..<1)
        #expect(items == [1, 2])
    }

    @Test("wf_slice clamps the range", arguments: [
        (0..<2, [0, 1]),
        (3..<99, [3, 4]),
        (-3..<2, [0, 1]),
        (5..<9, []),
        (2..<2, []),
        (-9 ..< -1, []),
    ] as [(Range<Int>, [Int])])
    func sliceRange(range: Range<Int>, expected: [Int]) {
        #expect([0, 1, 2, 3, 4].wf_slice(range) == expected)
    }

    @Test("wf_slice(from:length:)", arguments: [
        (1, 2, [1, 2]),
        (3, Int.max, [3, 4]),
        (-2, 2, [0, 1]),
        (9, 1, []),
        (0, 0, []),
        (0, -1, []),
    ] as [(Int, Int, [Int])])
    func sliceFromLength(from: Int, length: Int, expected: [Int]) {
        #expect([0, 1, 2, 3, 4].wf_slice(from: from, length: length) == expected)
    }

    @Test("wf_chunked returns [] for an invalid size")
    func chunked() {
        #expect([1, 2, 3, 4, 5].wf_chunked(size: 2) == [[1, 2], [3, 4], [5]])
        #expect([1, 2].wf_chunked(size: 5) == [[1, 2]])
        #expect([Int]().wf_chunked(size: 2).isEmpty)
        #expect([1, 2].wf_chunked(size: 0).isEmpty)
        #expect([1, 2].wf_chunked(size: -1).isEmpty)
    }

    @Test("wf_appendIfPresent skips nil")
    func appendIfPresent() {
        var items = [1]
        items.wf_appendIfPresent(nil)
        items.wf_appendIfPresent(2)
        #expect(items == [1, 2])
    }

    @Test("wf_removeAll(_:) returns the number removed")
    func removeAllEqual() {
        var items = [1, 2, 1, 3, 1]
        let removed = items.wf_removeAll(1)
        let none = items.wf_removeAll(9)
        #expect(removed == 3)
        #expect(none == 0)
        #expect(items == [2, 3])
    }
}

@Suite("Sequence+WF")
struct SequenceWFTests {
    private struct Item: Equatable {
        let id: Int
        let name: String
    }

    private let items = [Item(id: 2, name: "b"), Item(id: 1, name: "a"), Item(id: 2, name: "c"), Item(id: 3, name: "a")]

    @Test("wf_removingDuplicates keeps first occurrences in order")
    func removingDuplicates() {
        #expect([3, 1, 3, 2, 1].wf_removingDuplicates() == [3, 1, 2])
        #expect([Int]().wf_removingDuplicates().isEmpty)
        #expect(items.wf_removingDuplicates(by: \.id).map(\.name) == ["b", "a", "a"])
        #expect(items.wf_removingDuplicates(by: \.name).map(\.id) == [2, 1, 2])
    }

    @Test("wf_sorted(by:)")
    func sortedByKeyPath() {
        #expect(items.wf_sorted(by: \.name).map(\.name) == ["a", "a", "b", "c"])
        #expect(items.wf_sorted(by: \.id, ascending: false).map(\.id) == [3, 2, 2, 1])
    }

    @Test("wf_partitioned preserves order in both groups")
    func partitioned() {
        let (even, odd) = [1, 2, 3, 4, 5].wf_partitioned { $0.isMultiple(of: 2) }
        #expect(even == [2, 4])
        #expect(odd == [1, 3, 5])
    }

    @Test("wf_sum(of:)")
    func sum() {
        #expect(items.wf_sum(of: \.id) == 8)
        #expect([Item]().wf_sum(of: \.id) == 0)
        #expect([1.5, 2.5].wf_sum(of: \.self) == 4)
    }
}
