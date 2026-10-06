import Foundation
import Testing
@testable import WildFunctionKit

@Suite("Data+WF")
struct DataWFTests {
    private let data = Data([0, 1, 2, 3, 4])

    @Test("wf_subdata clamps to valid bounds", arguments: [
        (1, 2, [1, 2]),
        (3, 99, [3, 4]),
        (-2, 2, [0, 1]),
        (5, 1, []),
        (0, 0, []),
        (0, -1, []),
        (2, Int.max, [2, 3, 4]),
    ] as [(Int, Int, [UInt8])])
    func subdata(from: Int, length: Int, expected: [UInt8]) {
        #expect(Array(data.wf_subdata(from: from, length: length)) == expected)
    }

    @Test("wf_subdata uses offsets relative to a slice's start")
    func subdataOnSlice() {
        let slice = data[2...]
        #expect(slice.startIndex == 2)
        #expect(Array(slice.wf_subdata(from: 1, length: 9)) == [3, 4])
    }

    @Test("wf_utf8String returns nil for invalid UTF-8")
    func utf8String() {
        #expect(Data("你好".utf8).wf_utf8String == "你好")
        #expect(Data([0xFF, 0xFE]).wf_utf8String == nil)
        #expect(Data().wf_utf8String == "")
    }

    @Test("wf_jsonDictionary / wf_jsonArray")
    func json() {
        #expect(Data(#"{"k": "v"}"#.utf8).wf_jsonDictionary?.wf_string("k") == "v")
        #expect(Data("[true]".utf8).wf_jsonArray?.count == 1)
        #expect(Data("[true]".utf8).wf_jsonDictionary == nil)
        #expect(Data().wf_jsonDictionary == nil)
        #expect(Data([0xFF]).wf_jsonArray == nil)
    }
}
