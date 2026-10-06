import CoreGraphics
import Testing
@testable import WildFunctionKit

@Suite("BinaryFloatingPoint+WF")
struct BinaryFloatingPointWFTests {
    @Test("wf_intValue returns nil when not representable", arguments: [
        (3.9, 3), (-3.9, -3), (0.0, 0), (.nan, nil), (.infinity, nil), (-.infinity, nil), (1e300, nil),
    ] as [(Double, Int?)])
    func intValue(value: Double, expected: Int?) {
        #expect(value.wf_intValue == expected)
    }

    @Test("wf_clampedInt clamps to the Int range and maps NaN to 0", arguments: [
        (3.9, 3), (.nan, 0), (.infinity, .max), (-.infinity, .min), (1e300, .max), (-1e300, .min),
    ] as [(Double, Int)])
    func clampedInt(value: Double, expected: Int) {
        #expect(value.wf_clampedInt == expected)
    }

    @Test("wf_finite replaces NaN and infinity")
    func finite() {
        #expect(1.5.wf_finite() == 1.5)
        #expect(Double.nan.wf_finite() == 0)
        #expect(Double.infinity.wf_finite(or: 44) == 44)
        #expect((CGFloat(1) / CGFloat(0)).wf_finite(or: 8) == 8)
    }

    @Test("Works for Float and CGFloat")
    func otherFloatingPointTypes() {
        #expect(Float(2.7).wf_intValue == 2)
        #expect(Float.nan.wf_intValue == nil)
        #expect(CGFloat(9.99).wf_clampedInt == 9)
        #expect(CGFloat.nan.wf_clampedInt == 0)
    }
}

@Suite("FixedWidthInteger+WF")
struct FixedWidthIntegerWFTests {
    @Test("wf_divided returns nil for a zero divisor or overflow")
    func divided() {
        #expect(7.wf_divided(by: 2) == 3)
        #expect((-7).wf_divided(by: 2) == -3)
        #expect(7.wf_divided(by: 0) == nil)
        #expect(Int.min.wf_divided(by: -1) == nil)
        #expect(UInt8(200).wf_divided(by: 0) == nil)
        #expect(UInt8(200).wf_divided(by: 100) == 2)
    }

    @Test("wf_remainder returns nil for a zero divisor or overflow")
    func remainder() {
        #expect(7.wf_remainder(dividingBy: 3) == 1)
        #expect(7.wf_remainder(dividingBy: 0) == nil)
        #expect(Int.min.wf_remainder(dividingBy: -1) == nil)
        #expect(Int64(10).wf_remainder(dividingBy: 4) == 2)
    }
}

@Suite("Comparable+WF")
struct ComparableWFTests {
    @Test("wf_clamped accepts bounds in either order", arguments: [
        (5, 0, 10, 5), (15, 0, 10, 10), (-5, 0, 10, 0), (15, 10, 0, 10), (-5, 10, 0, 0), (3, 3, 3, 3),
    ] as [(Int, Int, Int, Int)])
    func clamped(value: Int, first: Int, second: Int, expected: Int) {
        #expect(value.wf_clamped(first, second) == expected)
    }

    @Test("Works for other Comparable types")
    func otherComparableTypes() {
        #expect(1.5.wf_clamped(0, 1) == 1)
        #expect("m".wf_clamped("a", "f") == "f")
    }
}
