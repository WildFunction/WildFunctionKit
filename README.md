# WildFunctionKit

English | [简体中文](README.zh-CN.md)

Base utilities for WildFunction iOS apps: crash-safe type extensions, hex colors, remote images, lenient JSON decoding, logging.

## Requirements

- iOS 18.4+, UIKit, Swift 6 language mode, Xcode 26+
- Dependencies: SmartCodable (JSON), Kingfisher (images)

## Install

```swift
.package(url: "https://github.com/WildFunction/WildFunctionKit.git", from: "0.2.1")
// target dependency: .product(name: "WildFunctionKit", package: "WildFunctionKit")
```

## API

Every extension member is prefixed `wf_`, except `subscript(safe:)`.

```swift
import WildFunctionKit

// Collections
items[safe: 10]                          // nil when out of bounds
items.wf_remove(at: 10)                  // nil / no-op when out of bounds
items.wf_removeFirst()                   // nil on an empty array
items.wf_slice(2..<99)                   // clamped
items.wf_removingDuplicates(by: \.id)    // keeps order

// String
"hello".wf_substring(from: 3, length: 99)   // clamped
"hello".wf_character(at: 9)                 // nil
"3.9".wf_intValue                           // 3
" yes ".wf_boolValue                        // true
"a b&c".wf_urlEncoded                       // "a%20b%26c"

// [String: Any]
payload.wf_int("count")                                  // "12" → 12
payload.wf_bool("enabled")                               // true / 1 / "1" / "true" / "yes"
payload.wf_value("count", as: Int.self)                  // nil when missing
payload.wf_value(atPath: ["data", "user", "age"], as: Int.self)
payload.wf_jsonString()                                  // nil instead of an ObjC exception

// Numbers
ratio.wf_finite(or: 0)         // replaces NaN / infinity
total.wf_divided(by: count)    // nil for a zero divisor
value.wf_clampedInt            // Double → Int without trapping

// UIColor
UIColor(wf_hex: "#FF8800")                       // also "FF8800", "0xFF8800", "#F80", "#FF8800CC"
UIColor(wf_hex: "#CCFF8800", alphaFirst: true)   // AARRGGBB
UIColor(wf_hex: 0xFF8800, alpha: 0.5)
UIColor.wf_hex(serverValue, fallback: .label)
color.wf_hexString()                             // "#FF8800"

// Remote images (cached, downsampled to the view, safe in reused cells)
imageView.wf_setImage(with: url, placeholder: placeholderImage)
imageView.wf_setImage(with: "https://example.com/a.png",
                      options: RemoteImageOptions(failureImage: brokenImage)) { result in }
imageView.wf_cancelImageLoad()

// Lenient JSON: missing, mistyped or null fields never fail the whole model
struct DemoItem: SmartCodableX { var id = ""; var name = "" }
let item = SafeJSON.decode(DemoItem.self, from: data)   // Data, String or [String: Any]
SafeJSON.onIssue = { issue in /* report */ }

// Logging (os.Logger; debug is DEBUG-only)
AppLog.info("loaded", category: .network)
```

## Rules

- Image URLs must be `https`, `http` or `file`; anything else fails with `RemoteImageError.invalidURL`.
- Do not `import Kingfisher` in app code; only the `wf_` API is stable.
- New extensions go in `Sources/WildFunctionKit/Extensions/<Type>+WF.swift`, one file per extended type.

## Test

```bash
WILDFUNCTIONKIT_STRICT=1 xcodebuild test -scheme WildFunctionKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

`swift test` does not work (UIKit).

## Related

[WFRouter](https://github.com/WildFunction/WFRouter) (routing) · [KirbyiOS](https://github.com/WildFunction/KirbyiOS) (page framework)

## License

MIT. See [LICENSE](LICENSE).
