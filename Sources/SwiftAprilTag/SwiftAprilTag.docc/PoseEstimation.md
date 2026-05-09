# Pose Estimation

Recover the 6-DOF position and orientation of a detected tag in the camera's coordinate frame.

## Overview

Given a detected tag plus your camera's intrinsic parameters (focal length, principal point) and the tag's known physical edge length, ``Detection/estimatePose(intrinsics:tagSize:)`` returns a ``TagPose`` describing where the tag sits in 3D camera space.

Common use cases:

- **AR placement** — anchor a virtual 3D object on top of a printed marker
- **Robot manipulation** — tell a robot arm exactly where to reach
- **Multi-camera calibration** — solve relative camera positions from shared markers
- **Pose-based metrology** — measure objects by attaching markers of known size

## Get camera intrinsics

You need ``CameraIntrinsics`` — the focal length and principal point of the camera that captured the image, in pixel units.

**Manually:**
```swift
let intrinsics = CameraIntrinsics(fx: 800, fy: 800, cx: 320, cy: 240)
```

**From AVFoundation:**
```swift
let intrinsics = CameraIntrinsics(
    avCalibrationData: depthData.cameraCalibrationData!,
    imageSize: CGSize(width: 1280, height: 720)  // your processing size
)
```

The `imageSize` parameter handles the common case where AVFoundation reports intrinsics in the sensor's native reference dimensions (e.g. 4032×2268), but you ran detection on a downsampled buffer (e.g. 1280×720). The initializer rescales `fx`, `fy`, `cx`, `cy` proportionally.

## Estimate the pose

```swift
let tagSize = 0.1  // outer black-border edge length, in meters

if let pose = detection.estimatePose(intrinsics: intrinsics, tagSize: tagSize) {
    print("Position: \(pose.translation)")        // (x, y, z) in meters
    print("Reproj error: \(pose.reprojectionError)")
}
```

Pose estimation is a one-line call. Internally, SwiftAprilTag reconstructs an `apriltag_detection_t` from the corner positions and homography matrix the detection already holds, then runs the upstream homography + orthogonal-iteration solver.

## Use the pose

On Apple platforms, ``TagPose`` exposes `simd` convenience accessors that drop straight into SceneKit, RealityKit, ARKit, and Metal:

```swift
import simd

let transform: simd_float4x4 = pose.transform

// SceneKit / RealityKit
sceneNode.simdTransform = transform

// ARKit anchor
let anchor = ARAnchor(name: "AprilTag-\(detection.id)", transform: transform)
arView.session.add(anchor: anchor)
```

Cross-platform, the rotation and translation are also available as plain `[Float]`:

```swift
let r = pose.rotation     // 9-element row-major
let t = pose.translation  // (x, y, z)
```

## Quality and filtering

``TagPose/reprojectionError`` is the upstream solver's residual. Use it to filter or weight pose estimates from a stream of detections:

- **< 1.0** — typically a clean detection with a stable pose
- **1.0–5.0** — usable but worth confirming with a temporal filter
- **> 5.0** — likely spurious; consider rejecting

## Tag size convention

`tagSize` is the **outer black border** edge length — what AprilTag's library returns as ``Detection/corners``. NOT the full tag image including any white margin around the black square. See <doc:TagSizeConvention> for the full discussion.
