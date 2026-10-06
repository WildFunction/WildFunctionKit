import Testing
@testable import WildFunctionKit

@Suite("Collection+WF / MutableCollection+WF")
struct CollectionWFTests {
    @Test("Safe subscript returns the element or nil", arguments: [(-1, nil), (0, 10), (2, 30), (3, nil)] as [(Int, Int?)])
    func safeSubscriptGet(index: Int, expected: Int?) {
        let items = [10, 20, 30]
        #expect(items[safe: index] == expected)
    }

    @Test("Safe subscript works on non-array collections")
    func safeSubscriptOnOtherCollections() {
        let slice = [1, 2, 3, 4][1...2]
        #expect(slice[safe: 0] == nil)
        #expect(slice[safe: 1] == 2)
        #expect(Array<Int>()[safe: 0] == nil)
    }

    @Test("Safe subscript setter ignores out-of-bounds and nil writes")
    func safeSubscriptSet() {
        var items = [1, 2, 3]
        items[safe: 1] = 20
        #expect(items == [1, 20, 3])
        items[safe: 9] = 99
        #expect(items == [1, 20, 3])
        items[safe: 0] = nil
        #expect(items == [1, 20, 3])
    }

    @Test("wf_nilIfEmpty")
    func nilIfEmpty() {
        #expect([Int]().wf_nilIfEmpty == nil)
        #expect([1].wf_nilIfEmpty == [1])
        #expect("".wf_nilIfEmpty == nil)
        #expect("a".wf_nilIfEmpty == "a")
    }

    @Test("wf_swapAt returns false when out of bounds")
    func swapAt() {
        var items = [1, 2, 3]
        let swapped = items.wf_swapAt(0, 2)
        #expect(swapped)
        #expect(items == [3, 2, 1])

        let outOfBounds = items.wf_swapAt(0, 3)
        let negative = items.wf_swapAt(-1, 0)
        #expect(!outOfBounds)
        #expect(!negative)
        #expect(items == [3, 2, 1])
    }
}
