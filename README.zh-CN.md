# WildFunctionKit

[English](README.md) | 简体中文

WildFunction iOS App 的基础工具库：不会崩溃的类型扩展、hex 颜色、远程图片、JSON 容错解析、日志。

## 环境要求

- iOS 18.4+，UIKit，Swift 6 语言模式，Xcode 26+
- 依赖：SmartCodable（JSON）、Kingfisher（图片）

## 安装

```swift
.package(url: "https://github.com/WildFunction/WildFunctionKit.git", from: "0.2.1")
// target 依赖：.product(name: "WildFunctionKit", package: "WildFunctionKit")
```

## API

除 `subscript(safe:)` 外，所有扩展成员都带 `wf_` 前缀。

```swift
import WildFunctionKit

// 集合
items[safe: 10]                          // 越界返回 nil
items.wf_remove(at: 10)                  // 越界返回 nil，不做任何事
items.wf_removeFirst()                   // 空数组返回 nil
items.wf_slice(2..<99)                   // 区间自动收缩
items.wf_removingDuplicates(by: \.id)    // 去重并保持顺序

// 字符串
"hello".wf_substring(from: 3, length: 99)   // 自动收缩
"hello".wf_character(at: 9)                 // nil
"3.9".wf_intValue                           // 3
" yes ".wf_boolValue                        // true
"a b&c".wf_urlEncoded                       // "a%20b%26c"

// [String: Any]
payload.wf_int("count")                                  // "12" → 12
payload.wf_bool("enabled")                               // true / 1 / "1" / "true" / "yes"
payload.wf_value("count", as: Int.self)                  // 取不到为 nil
payload.wf_value(atPath: ["data", "user", "age"], as: Int.self)
payload.wf_jsonString()                                  // 返回 nil，不抛 ObjC 异常

// 数值
ratio.wf_finite(or: 0)         // 替换 NaN / 无穷大
total.wf_divided(by: count)    // 除数为 0 返回 nil
value.wf_clampedInt            // Double → Int 不 trap

// UIColor
UIColor(wf_hex: "#FF8800")                       // 也支持 "FF8800"、"0xFF8800"、"#F80"、"#FF8800CC"
UIColor(wf_hex: "#CCFF8800", alphaFirst: true)   // AARRGGBB
UIColor(wf_hex: 0xFF8800, alpha: 0.5)
UIColor.wf_hex(serverValue, fallback: .label)
color.wf_hexString()                             // "#FF8800"

// UIResponder
view.wf_nearestViewController                    // 顺着响应链往上最近的视图控制器

// 远程图片（带缓存，按视图尺寸降采样，cell 复用安全）
imageView.wf_setImage(with: url, placeholder: placeholderImage)
imageView.wf_setImage(with: "https://example.com/a.png",
                      options: RemoteImageOptions(failureImage: brokenImage)) { result in }
imageView.wf_cancelImageLoad()

// JSON 容错：字段缺失、类型不符、null 都不会让整个模型解析失败
struct DemoItem: SmartCodableX { var id = ""; var name = "" }
let item = SafeJSON.decode(DemoItem.self, from: data)   // Data、String 或 [String: Any]
SafeJSON.onIssue = { issue in /* 上报 */ }

// 日志（os.Logger；debug 只在 DEBUG 构建输出）
AppLog.info("loaded", category: .network)
```

## 约定

- 图片地址只允许 `https`、`http`、`file`，其余以 `RemoteImageError.invalidURL` 失败。
- 业务代码不要 `import Kingfisher`，只有 `wf_` 接口是稳定的。
- 新扩展放在 `Sources/WildFunctionKit/Extensions/<类型>+WF.swift`，每个被扩展的类型一个文件。

## 测试

```bash
WILDFUNCTIONKIT_STRICT=1 xcodebuild test -scheme WildFunctionKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

依赖 UIKit，不能用 `swift test`。

## 相关

[WFRouter](https://github.com/WildFunction/WFRouter)（路由） · [KirbyiOS](https://github.com/WildFunction/KirbyiOS)（页面框架）

## 开源协议

MIT，见 [LICENSE](LICENSE)。
