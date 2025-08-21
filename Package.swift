// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Syllabreak",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Syllabreak",
            targets: ["Syllabreak"]),
    ],
    dependencies: [
        .package(url: "https://github.com/botforge-pro/swift-embed", from: "1.2.0"),
        .package(url: "https://github.com/swiftlang/swift-testing", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "Syllabreak",
            resources: [.process("Resources")]),
        .testTarget(
            name: "SyllabreakTests",
            dependencies: [
                "Syllabreak",
                .product(name: "SwiftEmbed", package: "swift-embed"),
                .product(name: "Testing", package: "swift-testing")
            ],
            resources: [.process("Resources")]),
    ]
)