# DetectAprilTag CLI

Minimal command-line example for SwiftAprilTag. Reads an image, prints detected tags + optional pose estimation.

## Run it

From this directory:

```bash
swift run DetectAprilTag path/to/image.png
```

With pose estimation:

```bash
swift run DetectAprilTag path/to/image.png --tag-size 0.1
```

`--tag-size` is the **outer black border** edge length in meters. The example uses synthetic intrinsics (`fx = fy = imageWidth`, principal point at center) — fine for demonstrating the API, replace with real calibration for metric work.

## Try it with the bundled fixture

```bash
swift run DetectAprilTag ../../Tests/SwiftAprilTagTests/Fixtures/tag36h11_id0.png --tag-size 0.1
```

Should print one tag36h11 detection with id 0 and a recovered pose.

## What it demonstrates

- `Detector(families: [.tag36h11])` — set up
- `Detector.detect(cgImage:)` — run detection on any CoreGraphics image
- `Detection` properties — id, corners, center, decisionMargin
- `Detection.estimatePose(intrinsics:tagSize:)` — recover 6-DOF pose
- `CameraIntrinsics` — manual intrinsics construction

## Platform

macOS 12+. Uses `CoreGraphics` and `ImageIO` for image decoding. Linux usage of SwiftAprilTag is supported by the library proper, but this example needs Apple's image-loading frameworks.
