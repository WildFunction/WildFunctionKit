import UIKit

// MARK: - From hex

extension UIColor {
    /// Creates a color from a hex string. Returns `nil` when the format is invalid.
    ///
    /// Accepts an optional `#` or `0x` prefix and 3 (`RGB`), 4 (`RGBA`), 6 (`RRGGBB`) or 8 (`RRGGBBAA`) digits.
    ///
    /// ```swift
    /// UIColor(wf_hex: "#FF8800")
    /// UIColor(wf_hex: "0xff8800cc")
    /// UIColor(wf_hex: "F80")
    /// UIColor(wf_hex: "#CCFF8800", alphaFirst: true)   // Android-style AARRGGBB
    /// ```
    ///
    /// - Parameters:
    ///   - hex: The hex string.
    ///   - alpha: Overrides the alpha in the string. Clamped to `0...1`.
    ///   - alphaFirst: Whether alpha leads in 4- and 8-digit forms (`ARGB` / `AARRGGBB`).
    public convenience init?(wf_hex hex: String, alpha: CGFloat? = nil, alphaFirst: Bool = false) {
        guard let components = HexColorParser.parse(hex, alphaFirst: alphaFirst) else { return nil }
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            alpha: alpha?.wf_finite(or: 1).wf_clamped(0, 1) ?? components.alpha
        )
    }

    /// Creates a color from a `0xRRGGBB` integer.
    ///
    /// ```swift
    /// UIColor(wf_hex: 0xFF8800)
    /// UIColor(wf_hex: 0xFF8800, alpha: 0.5)
    /// ```
    public convenience init(wf_hex hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: HexColorParser.unit(hex >> 16),
            green: HexColorParser.unit(hex >> 8),
            blue: HexColorParser.unit(hex),
            alpha: alpha.wf_finite(or: 1).wf_clamped(0, 1)
        )
    }

    /// Creates a color from a `0xRRGGBBAA` integer.
    public convenience init(wf_hexWithAlpha hex: UInt32) {
        self.init(
            red: HexColorParser.unit(hex >> 24),
            green: HexColorParser.unit(hex >> 16),
            blue: HexColorParser.unit(hex >> 8),
            alpha: HexColorParser.unit(hex)
        )
    }

    /// Creates a color from a hex string, or `fallback` when the format is invalid.
    public static func wf_hex(_ hex: String, alpha: CGFloat? = nil, fallback: UIColor = .clear) -> UIColor {
        UIColor(wf_hex: hex, alpha: alpha) ?? fallback
    }
}

// MARK: - To hex

extension UIColor {
    /// Returns an uppercase `#RRGGBB` or `#RRGGBBAA` string, or `nil` for colors without RGB components.
    public func wf_hexString(includeAlpha: Bool = false) -> String? {
        guard let rgba = wf_rgbaComponents else { return nil }
        let channels = includeAlpha ? [rgba.red, rgba.green, rgba.blue, rgba.alpha] : [rgba.red, rgba.green, rgba.blue]
        return "#" + channels.map(HexColorParser.hexByte).joined()
    }
}

// MARK: - Components and adjustments

extension UIColor {
    /// Creates a color from 0...255 integer components, clamped.
    ///
    /// ```swift
    /// UIColor(wf_red: 255, green: 136, blue: 0)
    /// ```
    public convenience init(wf_red red: Int, green: Int, blue: Int, alpha: CGFloat = 1) {
        self.init(
            red: HexColorParser.unit(UInt32(red.wf_clamped(0, 255))),
            green: HexColorParser.unit(UInt32(green.wf_clamped(0, 255))),
            blue: HexColorParser.unit(UInt32(blue.wf_clamped(0, 255))),
            alpha: alpha.wf_finite(or: 1).wf_clamped(0, 1)
        )
    }

    /// RGBA components in `0...1`, or `nil` for colors without RGB components (e.g. pattern colors).
    public var wf_rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (red, green, blue, alpha)
    }

    /// Blends with `other`. `ratio` 0 returns `self`, 1 returns `other`; clamped.
    public func wf_blended(with other: UIColor, ratio: CGFloat = 0.5) -> UIColor {
        guard let from = wf_rgbaComponents, let to = other.wf_rgbaComponents else { return self }
        let weight = ratio.wf_finite(or: 0).wf_clamped(0, 1)
        func mix(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat { lhs + (rhs - lhs) * weight }
        return UIColor(
            red: mix(from.red, to.red),
            green: mix(from.green, to.green),
            blue: mix(from.blue, to.blue),
            alpha: mix(from.alpha, to.alpha)
        )
    }

    /// Moves toward white by `amount` (`0...1`), keeping alpha.
    public func wf_lightened(by amount: CGFloat = 0.2) -> UIColor {
        wf_blended(with: .white, ratio: amount).withAlphaComponent(wf_rgbaComponents?.alpha ?? 1)
    }

    /// Moves toward black by `amount` (`0...1`), keeping alpha.
    public func wf_darkened(by amount: CGFloat = 0.2) -> UIColor {
        wf_blended(with: .black, ratio: amount).withAlphaComponent(wf_rgbaComponents?.alpha ?? 1)
    }

    /// Creates a dynamic color for light and dark mode.
    public static func wf_dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
}

/// Hex color parsing rules. Internal.
enum HexColorParser {
    struct Components: Equatable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    private static let prefixes = ["#", "0x"]
    private static let shortLengths: Set<Int> = [3, 4]
    private static let fullLengths: Set<Int> = [6, 8]
    private static let channelMax: CGFloat = 255

    static func parse(_ text: String, alphaFirst: Bool) -> Components? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let digits = prefixes.first(where: trimmed.hasPrefix).map { String(trimmed.dropFirst($0.count)) } ?? trimmed

        // ASCII only: full-width digits also report `isHexDigit` but cannot be parsed.
        guard digits.allSatisfy({ $0.isASCII && $0.isHexDigit }) else { return nil }

        // Short forms repeat each digit: F80 → FF8800.
        let expanded: String
        if shortLengths.contains(digits.count) {
            expanded = digits.map { "\($0)\($0)" }.joined()
        } else if fullLengths.contains(digits.count) {
            expanded = digits
        } else {
            return nil
        }

        let bytes = expanded.wf_chunked.compactMap { UInt8($0, radix: 16) }.map { CGFloat($0) / channelMax }
        switch (bytes.count, alphaFirst) {
        case (3, _):
            return Components(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: 1)
        case (4, false):
            return Components(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
        case (4, true):
            return Components(red: bytes[1], green: bytes[2], blue: bytes[3], alpha: bytes[0])
        default:
            return nil
        }
    }

    /// Maps the lowest 8 bits to `0...1`.
    static func unit(_ value: UInt32) -> CGFloat {
        CGFloat(value & 0xFF) / channelMax
    }

    /// Converts a `0...1` component to two uppercase hex digits.
    static func hexByte(_ component: CGFloat) -> String {
        let byte = (component.wf_finite(or: 0).wf_clamped(0, 1) * channelMax).rounded().wf_clampedInt
        return String(format: "%02X", byte)
    }
}

private extension String {
    /// Splits into two-character chunks.
    var wf_chunked: [String] {
        Array(self).wf_chunked(size: 2).map { String($0) }
    }
}
