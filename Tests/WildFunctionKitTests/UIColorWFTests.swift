import Testing
import UIKit
@testable import WildFunctionKit

@MainActor
@Suite("UIColor+WF")
struct UIColorWFTests {
    private func rgba(_ color: UIColor?) -> [Int]? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let color, color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }

    @Test("Valid string formats", arguments: [
        ("#FF8800", [255, 136, 0, 255]),
        ("FF8800", [255, 136, 0, 255]),
        ("ff8800", [255, 136, 0, 255]),
        ("0xFF8800", [255, 136, 0, 255]),
        ("0XFF8800", [255, 136, 0, 255]),
        ("  #ff8800\n", [255, 136, 0, 255]),
        ("#F80", [255, 136, 0, 255]),
        ("f80", [255, 136, 0, 255]),
        ("#F80C", [255, 136, 0, 204]),
        ("#FF8800CC", [255, 136, 0, 204]),
        ("0xff880000", [255, 136, 0, 0]),
        ("#000", [0, 0, 0, 255]),
        ("#FFFFFFFF", [255, 255, 255, 255]),
    ] as [(String, [Int])])
    func parsesValidStrings(hex: String, expected: [Int]) {
        #expect(rgba(UIColor(wf_hex: hex)) == expected)
    }

    @Test("Invalid strings return nil", arguments: [
        "", "   ", "#", "0x", "#12", "#12345", "#1234567", "#123456789",
        "#GGGGGG", "red", "#FF 88 00", "##FF8800", "#-F8800", "#１２３４５６",
    ])
    func rejectsInvalidStrings(hex: String) {
        #expect(UIColor(wf_hex: hex) == nil)
    }

    @Test("alphaFirst parses ARGB / AARRGGBB")
    func alphaFirst() {
        #expect(rgba(UIColor(wf_hex: "#CCFF8800", alphaFirst: true)) == [255, 136, 0, 204])
        #expect(rgba(UIColor(wf_hex: "#CF80", alphaFirst: true)) == [255, 136, 0, 204])
        #expect(rgba(UIColor(wf_hex: "#FF8800", alphaFirst: true)) == [255, 136, 0, 255])
    }

    @Test("Explicit alpha overrides the string's alpha and is clamped")
    func explicitAlpha() {
        #expect(rgba(UIColor(wf_hex: "#FF8800CC", alpha: 1)) == [255, 136, 0, 255])
        #expect(rgba(UIColor(wf_hex: "#FF8800", alpha: 0.2)) == [255, 136, 0, 51])
        #expect(rgba(UIColor(wf_hex: "#FF8800", alpha: 7)) == [255, 136, 0, 255])
        #expect(rgba(UIColor(wf_hex: "#FF8800", alpha: -1)) == [255, 136, 0, 0])
        #expect(rgba(UIColor(wf_hex: "#FF8800", alpha: .nan)) == [255, 136, 0, 255])
    }

    @Test("Creating from integers")
    func fromIntegers() {
        #expect(rgba(UIColor(wf_hex: 0xFF8800)) == [255, 136, 0, 255])
        #expect(rgba(UIColor(wf_hex: 0xFF8800, alpha: 0.2)) == [255, 136, 0, 51])
        #expect(rgba(UIColor(wf_hex: 0xAAFF8800)) == [255, 136, 0, 255])
        #expect(rgba(UIColor(wf_hex: 0x000000, alpha: 9)) == [0, 0, 0, 255])
        #expect(rgba(UIColor(wf_hexWithAlpha: 0xFF8800CC)) == [255, 136, 0, 204])
        #expect(rgba(UIColor(wf_hexWithAlpha: 0x00000000)) == [0, 0, 0, 0])
    }

    @Test("wf_hex returns the fallback for invalid input")
    func fallback() {
        #expect(rgba(UIColor.wf_hex("#FF8800")) == [255, 136, 0, 255])
        #expect(rgba(UIColor.wf_hex("#FF8800", alpha: 0.2)) == [255, 136, 0, 51])
        #expect(rgba(UIColor.wf_hex("oops")) == [0, 0, 0, 0])
        #expect(rgba(UIColor.wf_hex("oops", fallback: UIColor(wf_hex: 0x112233))) == [17, 34, 51, 255])
    }

    @Test("wf_hexString round-trips")
    func hexString() {
        #expect(UIColor(wf_hex: "#ff8800")?.wf_hexString() == "#FF8800")
        #expect(UIColor(wf_hex: "#ff8800cc")?.wf_hexString() == "#FF8800")
        #expect(UIColor(wf_hex: "#ff8800cc")?.wf_hexString(includeAlpha: true) == "#FF8800CC")
        #expect(UIColor(wf_hex: "#0a0")?.wf_hexString() == "#00AA00")
        #expect(UIColor(white: 1, alpha: 0).wf_hexString(includeAlpha: true) == "#FFFFFF00")
    }

    @Test("wf_hexString clamps extended-range components and returns nil for pattern colors")
    func hexStringEdgeCases() {
        let extended = UIColor(red: 1.4, green: -0.2, blue: 0.5, alpha: 1)
        #expect(extended.wf_hexString() == "#FF0080")

        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        #expect(UIColor(patternImage: image).wf_hexString() == nil)
    }

    @Test("hexByte handles invalid components")
    func hexByteIsTotal() {
        #expect(HexColorParser.hexByte(.nan) == "00")
        #expect(HexColorParser.hexByte(.infinity) == "00")
        #expect(HexColorParser.hexByte(0.5) == "80")
    }

    @Test("Creating from 0...255 components clamps out-of-range values")
    func fromIntComponents() {
        #expect(rgba(UIColor(wf_red: 255, green: 136, blue: 0)) == [255, 136, 0, 255])
        #expect(rgba(UIColor(wf_red: 999, green: -5, blue: 128, alpha: 0.2)) == [255, 0, 128, 51])
    }

    @Test("wf_rgbaComponents")
    func components() throws {
        let parts = try #require(UIColor(wf_hex: "#FF000080")?.wf_rgbaComponents)
        #expect(parts.red == 1)
        #expect(parts.green == 0)
        #expect(parts.blue == 0)
        #expect(abs(parts.alpha - 128.0 / 255.0) < 0.001)

        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        #expect(UIColor(patternImage: image).wf_rgbaComponents == nil)
    }

    @Test("wf_blended mixes by ratio and clamps it")
    func blended() {
        let black = UIColor(wf_hex: 0x000000)
        let white = UIColor(wf_hex: 0xFFFFFF)
        #expect(black.wf_blended(with: white).wf_hexString() == "#808080")
        #expect(black.wf_blended(with: white, ratio: 0).wf_hexString() == "#000000")
        #expect(black.wf_blended(with: white, ratio: 1).wf_hexString() == "#FFFFFF")
        #expect(black.wf_blended(with: white, ratio: 5).wf_hexString() == "#FFFFFF")
        #expect(black.wf_blended(with: white, ratio: .nan).wf_hexString() == "#000000")

        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        #expect(black.wf_blended(with: UIColor(patternImage: image)) === black)
    }

    @Test("wf_lightened / wf_darkened keep alpha")
    func lightenAndDarken() {
        let base = UIColor(wf_hexWithAlpha: 0x80808080)
        #expect(base.wf_lightened(by: 0.5).wf_hexString(includeAlpha: true) == "#C0C0C080")
        #expect(base.wf_darkened(by: 0.5).wf_hexString(includeAlpha: true) == "#40404080")
        #expect(base.wf_lightened(by: 0).wf_hexString() == "#808080")
        #expect(base.wf_darkened(by: 1).wf_hexString() == "#000000")
        #expect(base.wf_lightened().wf_hexString() != base.wf_hexString())
        #expect(base.wf_darkened().wf_hexString() != base.wf_hexString())
    }

    @Test("wf_dynamic follows light and dark mode")
    func dynamic() {
        let color = UIColor.wf_dynamic(light: UIColor(wf_hex: 0xFFFFFF), dark: UIColor(wf_hex: 0x000000))
        #expect(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).wf_hexString() == "#FFFFFF")
        #expect(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).wf_hexString() == "#000000")
    }
}
