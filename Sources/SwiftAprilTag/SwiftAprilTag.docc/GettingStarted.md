# Getting Started

Set up a detector, feed it images, read back tag positions.

## Installation

Add SwiftAprilTag as a Swift Package dependency.

In Xcode: **File → Add Package Dependencies…** and paste:

```
https://github.com/keyqcloud/SwiftAprilTag.git
```

In a `Package.swift`:

```swift
.package(url: "https://github.com/keyqcloud/SwiftAprilTag.git", from: "1.2.0")
```

## Create a detector

A ``Detector`` is allocated with one or more tag families. Most users only need ``TagFamily/tag36h11`` — the most widely deployed family in robotics and AR.

```swift
import SwiftAprilTag

let detector = try Detector(families: [.tag36h11])
```

Detectors are not thread-safe; create one per worker thread or guard with external synchronization. Internally each detector spawns its own pool of worker threads, configurable via ``Detector/threadCount``.

## Run detection

There are several entry points depending on where your image data comes from:

**UIImage (iOS / tvOS / Mac Catalyst)**
```swift
let detections = try detector.detect(uiImage: someUIImage)
```

**CGImage (any Apple platform)**
```swift
let detections = try detector.detect(cgImage: someCGImage)
```

**CVPixelBuffer (AVFoundation video / depth output)**
```swift
let detections = try detector.detect(pixelBuffer: pixelBuffer, plane: 0)
```

**Raw luminance bytes (cross-platform, Linux included)**
```swift
let detections = try detector.detect(
    luminance: pixelData,
    width: 640,
    height: 480,
    stride: 640
)
```

All paths return `[Detection]`. An empty array means no tags were found in the image — it does not throw.

## Read the result

Each ``Detection`` carries:

- ``Detection/id`` — the decoded tag ID within its family
- ``Detection/corners`` — four sub-pixel `CGPoint`s, counter-clockwise around the tag's outer black border
- ``Detection/center`` — the tag's center in image-pixel coordinates
- ``Detection/decisionMargin`` — quality score; values around 30+ indicate confident decodes
- ``Detection/homography`` — the 3×3 perspective transform from ideal tag space to image pixels

## Tune for performance

Live-camera streams (~30 fps) need the detector to keep up. Two knobs help:

```swift
detector.quadDecimate = 2.0   // halve the resolution for the quad-detection pass
detector.threadCount = 4      // parallelize on multi-core devices
detector.refineEdges = true   // reclaim some of the accuracy lost to decimation
```

Decimation gives the biggest speedup. With `quadDecimate = 2.0`, detection runs roughly 4× faster with marginal accuracy loss for tags that are reasonably large in the frame.
