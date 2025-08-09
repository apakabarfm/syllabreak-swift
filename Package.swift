// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Syllabreak",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Syllabreak",
            targets: ["Syllabreak"]),
    ],
    targets: [
        .target(
            name: "Syllabreak"),
        .testTarget(
            name: "SyllabreakTests",
            dependencies: ["Syllabreak"]),
    ]
)