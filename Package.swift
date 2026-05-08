// swift-tools-version: 5.9
//
// SwiftAprilTag — Swift wrapper around the AprilTag fiducial-marker detection library.
// Copyright (c) KeyQ, Inc. (https://www.keyq.cloud) — Licensed under MIT.
//
// Vendored C source from github.com/AprilRobotics/apriltag is BSD-2-Clause.
// See LICENSE for the wrapper license and LICENSE-AprilRobotics.md for the
// upstream library license.
//

import PackageDescription

let package = Package(
    name: "SwiftAprilTag",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v15)
    ],
    products: [
        .library(name: "SwiftAprilTag", targets: ["SwiftAprilTag"])
    ],
    targets: [
        .target(
            name: "CAprilTag",
            path: "Sources/CAprilTag",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                // common/*.c uses bare `#include "zarray.h"` style (siblings in
                // common/) while root-level .c files use `#include "common/zarray.h"`.
                // Both forms need to resolve.
                .headerSearchPath("include/common")
            ]
        ),
        .target(
            name: "SwiftAprilTag",
            dependencies: ["CAprilTag"],
            path: "Sources/SwiftAprilTag"
        ),
        .testTarget(
            name: "SwiftAprilTagTests",
            dependencies: ["SwiftAprilTag"],
            path: "Tests/SwiftAprilTagTests"
        )
    ]
)
