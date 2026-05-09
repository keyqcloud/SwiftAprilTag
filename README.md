# SwiftAprilTag

[![CI](https://github.com/keyqcloud/SwiftAprilTag/actions/workflows/ci.yml/badge.svg)](https://github.com/keyqcloud/SwiftAprilTag/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20Mac%20Catalyst%20%7C%20tvOS%20%7C%20Linux-blue.svg)](https://swift.org)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Swift wrapper around the [AprilTag](https://github.com/AprilRobotics/apriltag) fiducial-marker detection library, packaged for Swift Package Manager. Maintained by [KeyQ, Inc.](https://www.keyq.cloud)

Supports iOS 15+, macOS 12+, Mac Catalyst 15+, tvOS 15+, and Linux (Swift 5.9+).

## Why this package?

[AprilTag](https://april.eecs.umich.edu/software/apriltag) is a robust 2D fiducial-marker system from the APRIL Robotics Lab at the University of Michigan, widely used in robotics, AR/VR, and computer-vision research for tracking, pose estimation, and camera calibration. The reference implementation is a C library; until now there hasn't been a maintained, license-clean Swift wrapper that ships through Swift Package Manager.

SwiftAprilTag was extracted from a real-world iOS body-scanning calibration tool, where it's used to detect a printed reference tag in TrueDepth captures and compute per-device focal-length corrections. The API surface is intentionally small — sub-pixel corner detection in raw or synthetic images, plus a `CVPixelBuffer` convenience for AVFoundation captures.

Reach for SwiftAprilTag when you specifically need:

- **Sub-pixel corner accuracy** (typical ~0.1-0.3px) — the property that makes AprilTag useful for measurement, not just recognition
- **ID-verified detection** that rejects coincidentally-rectangular objects in the scene
- **A standardized fiducial format** documented across the robotics and AR/VR ecosystems, so what you build interoperates with other tools
- **Cross-platform Swift** (iOS, macOS, Linux) with no third-party dependencies

If you only need rough rectangle or QR detection without precision requirements, Apple's `VNDetectRectanglesRequest` and `VNDetectBarcodesRequest` may already be enough.

## Features

- All standard AprilTag families (`tag36h11`, `tag25h9`, `tag16h5`, `tag36h10`, `tagCircle21h7`, `tagCircle49h12`, `tagCustom48h12`, `tagStandard41h12`, `tagStandard52h13`)
- Sub-pixel corner localization
- Direct `CVPixelBuffer` luminance-plane support — no color-space conversion needed for AVFoundation captures
- Configurable detector parameters (thread count, decimation, blur, edge refinement, decode sharpening)
- Pure Swift API; vendored upstream C source compiles without external dependencies

## Installation

Add SwiftAprilTag as a Swift Package dependency.

In Xcode: **File → Add Package Dependencies…** and paste:

```
https://github.com/keyqcloud/SwiftAprilTag.git
```

Or in your `Package.swift`:

```swift
.package(url: "https://github.com/keyqcloud/SwiftAprilTag.git", from: "1.0.0")
```

## Usage

### Detect tags in a CVPixelBuffer (e.g. AVFoundation capture)

```swift
import SwiftAprilTag

let detector = try Detector(families: [.tag36h11])

// Inside your AVCaptureVideoDataOutput delegate:
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let detections = try detector.detect(pixelBuffer: pixelBuffer)
    for detection in detections {
        print("Tag id=\(detection.id), corners=\(detection.corners)")
    }
}
```

### Detect tags in raw luminance data

```swift
let detector = try Detector(families: [.tag36h11])

let detections = try detector.detect(
    luminance: pixelData,    // Data, height * stride bytes
    width: 640,
    height: 480,
    stride: 640              // optional; defaults to width
)
```

### Configure the detector

```swift
let detector = try Detector(families: [.tag36h11])
detector.threadCount = 4         // worker threads inside the detector
detector.quadDecimate = 2.0      // speed up quad detection at slight accuracy cost
detector.quadSigma = 0.8         // blur for noisy images; 0 = no blur
detector.refineEdges = true      // snap quad edges to gradients (only matters when decimating)
detector.decodeSharpening = 0.25 // default; helps with small tags
```

## Generating Tags

Pre-rendered tags from the upstream project are available at [github.com/AprilRobotics/apriltag-imgs](https://github.com/AprilRobotics/apriltag-imgs). For physical printing, the PostScript (`.ps`) files print at known dimensions on US Letter / A4 paper. PNG files in those repos are 8x or 10x base sizes — print them at a specific physical size for calibration use cases.

## License

The Swift wrapper code (under `Sources/SwiftAprilTag/`) is provided under the **MIT License** (see [`LICENSE`](LICENSE)).

The vendored upstream AprilTag C source code (under `Sources/CAprilTag/`) retains its original **BSD 2-Clause License** (see [`LICENSE-AprilRobotics.md`](LICENSE-AprilRobotics.md) and [`NOTICE`](NOTICE)).

## Acknowledgments

AprilTag was developed by the [APRIL Robotics Lab](https://april.eecs.umich.edu/) at the University of Michigan, under the direction of Edwin Olson. The vendored sources are taken verbatim from `github.com/AprilRobotics/apriltag` (BSD 2-Clause). Please cite their work in academic publications:

> John Wang and Edwin Olson, "AprilTag 2: Efficient and robust fiducial detection," *Proceedings of the IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS)*, October 2016.

## Contact

KeyQ, Inc. — info@keyqcloud.com — https://www.keyq.cloud
