// swift-tools-version: 5.9
//
// CLI example for SwiftAprilTag.
// Run from this directory:
//
//   swift run DetectAprilTag path/to/image.png
//
// macOS-only (uses CoreGraphics + ImageIO for PNG/JPEG decoding).
//

import PackageDescription

let package = Package(
    name: "DetectAprilTag",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // Consume the parent SwiftAprilTag package by relative path so the
        // example always builds against the local source you have checked out.
        .package(name: "SwiftAprilTag", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "DetectAprilTag",
            dependencies: [
                .product(name: "SwiftAprilTag", package: "SwiftAprilTag")
            ],
            path: "Sources/DetectAprilTag"
        )
    ]
)
