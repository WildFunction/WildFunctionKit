// swift-tools-version: 6.2
import PackageDescription

/// Warnings are errors only when WILDFUNCTIONKIT_STRICT is set (CI and local development).
/// It must stay off for consumers: Xcode suppresses warnings in remote packages,
/// and combining that with warnings-as-errors fails the build.
let strictSettings: [SwiftSetting] = Context.environment["WILDFUNCTIONKIT_STRICT"] == nil
    ? []
    : [.treatAllWarnings(as: .error)]

let package = Package(
    name: "WildFunctionKit",
    platforms: [
        .iOS("18.4"),
    ],
    products: [
        .library(name: "WildFunctionKit", targets: ["WildFunctionKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "7.0.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.13.0"),
    ],
    targets: [
        .target(
            name: "WildFunctionKit",
            dependencies: [
                .product(name: "SmartCodable", package: "SmartCodable"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            swiftSettings: strictSettings
        ),
        .testTarget(name: "WildFunctionKitTests", dependencies: ["WildFunctionKit"], swiftSettings: strictSettings),
    ],
    swiftLanguageModes: [.v6]
)
