// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EVA",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        // HaishinKit per RTMP streaming
        .package(url: "https://github.com/shogo4405/HaishinKit.swift", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "EVA",
            dependencies: [
                .product(name: "HaishinKit", package: "HaishinKit.swift")
            ]
        )
    ]
)

