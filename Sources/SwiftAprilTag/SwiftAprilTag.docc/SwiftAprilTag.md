# ``SwiftAprilTag``

A Swift wrapper around the AprilTag fiducial-marker detection library.

## Overview

[AprilTag](https://april.eecs.umich.edu/software/apriltag) is a robust 2D fiducial-marker system from the APRIL Robotics Lab at the University of Michigan, widely used in robotics, AR/VR, and computer-vision research for tracking, pose estimation, and camera calibration.

SwiftAprilTag wraps the upstream C99 reference implementation in a clean Swift API, packaged for Swift Package Manager. It supports iOS 15+, macOS 12+, Mac Catalyst 15+, tvOS 15+, and Linux (Swift 5.9+).

### Quick start

```swift
import SwiftAprilTag

let detector = try Detector(families: [.tag36h11])
let detections = try detector.detect(uiImage: photo)

for detection in detections {
    print("Tag \(detection.id) at \(detection.center)")
}
```

### When to use this package

Reach for SwiftAprilTag when you specifically need:

- **Sub-pixel corner accuracy** (typical ~0.1–0.3 px) — the property that makes AprilTag useful for measurement, not just recognition
- **ID-verified detection** that rejects coincidentally-rectangular objects in the scene
- **A standardized fiducial format** documented across the robotics and AR/VR ecosystems
- **Cross-platform Swift** with no third-party dependencies

If you only need rough rectangle or QR detection, Apple's `VNDetectRectanglesRequest` and `VNDetectBarcodesRequest` may already be enough.

## Topics

### Essentials

- ``Detector``
- ``Detection``
- ``TagFamily``
- ``AprilTagError``

### Pose estimation

- ``CameraIntrinsics``
- ``TagPose``
- <doc:PoseEstimation>

### Apple-platform conveniences

- ``Detector/detect(cgImage:)``
- ``Detector/detect(uiImage:)``
- ``Detector/detect(pixelBuffer:plane:)``
- ``Detection/cgPath``
- ``CameraIntrinsics/init(avCalibrationData:imageSize:)``
- ``TagPose/transform``
- ``TagPose/rotationMatrix``
- ``TagPose/translationVector``

### Articles

- <doc:GettingStarted>
- <doc:PoseEstimation>
- <doc:TagSizeConvention>
