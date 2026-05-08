# SwiftAprilTag

A Swift wrapper around the [AprilTag](https://github.com/AprilRobotics/apriltag) fiducial-marker detection library, packaged for Swift Package Manager. Maintained by [KeyQ, Inc.](https://www.keyq.cloud)

Supports iOS 15+, macOS 12+, Mac Catalyst 15+, and tvOS 15+.

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
