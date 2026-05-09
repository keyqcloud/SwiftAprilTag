# Changelog

All notable changes to SwiftAprilTag are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-05-10

### Added
- **DocC catalog.** New `Sources/SwiftAprilTag/SwiftAprilTag.docc/` with a
  module landing page (topic-grouped symbol references), a Getting
  Started article, a Pose Estimation deep-dive, and a Tag Size Convention
  article that documents the outer-black-border vs. white-margin pitfall.
- **`.spi.yml`** to enable hosted DocC documentation on the Swift
  Package Index. Once the package re-indexes, the docs will be available
  at https://swiftpackageindex.com/keyqcloud/SwiftAprilTag/documentation.
- **`Examples/CLI/`** — a self-contained Swift executable that loads an
  image, runs detection, and optionally estimates pose. Demonstrates the
  full CGImage path and pose API in <100 lines.
- **`Examples/iOS-Live/`** — minimal SwiftUI iOS app with live-camera
  detection, real-time corner overlay drawn on top of an
  `AVCaptureVideoPreviewLayer`, and per-frame 6-DOF pose readout. Ships
  as source files only with instructions for dropping into a new Xcode
  project (avoiding fragile xcodeproj scripting).

## [1.2.0] - 2026-05-10

### Added
- `Detector.detect(cgImage:)` — Apple-platform convenience that takes
  any `CGImage`, renders it to 8-bit grayscale internally, and runs
  detection. Saves callers from doing the conversion themselves.
- `Detector.detect(uiImage:)` — UIKit convenience (iOS, tvOS, Mac
  Catalyst) that unwraps the underlying `CGImage` and forwards.
- `Detection.cgPath` — closed `CGPath` of the detected corner polygon,
  ready to assign to `CAShapeLayer.path` or wrap with `Path(cgPath)`
  for SwiftUI overlays.
- `CameraIntrinsics(avCalibrationData:imageSize:)` — convenience
  initializer from AVFoundation's `AVCameraCalibrationData`, with
  automatic rescaling between the calibration's reference dimensions
  and the actual image size you used for detection.
- New integration test exercising `detect(cgImage:)` and verifying
  `cgPath` produces the expected bounding box.

## [1.1.0] - 2026-05-10

### Added
- **Pose estimation.** New `CameraIntrinsics` and `TagPose` public types,
  plus `Detection.estimatePose(intrinsics:tagSize:) -> TagPose?` which
  recovers the 6-DOF pose of a detected tag in the camera's coordinate
  frame using the upstream homography + orthogonal-iteration solver.
  `TagPose` exposes the rotation matrix, translation vector, and
  reprojection error, with Apple-only convenience accessors for
  `simd_float3x3`, `simd_float3`, and a combined `simd_float4x4`
  transform suitable for SceneKit/RealityKit/Metal.
- `Detection.homography` field exposing the 3x3 homography matrix that
  maps ideal tag corners `[-1, 1]` to image pixel coordinates. Required
  by pose estimation, also useful for users who want to do their own
  perspective warps or homography decomposition.
- README now includes a pose-estimation usage example with a note about
  the outer-black-border convention.
- New integration test that recovers the pose of the bundled fixture
  against synthetic intrinsics and asserts translation within 5mm of
  the expected value, rotation matrix near identity, and small
  reprojection error.

## [1.0.2] - 2026-05-10

### Added
- Integration test that loads a real `tag36h11_id0` fixture image, runs
  detection end-to-end, and asserts ID, hamming distance, decision
  margin, and sub-pixel corner positions. Apple-only (gated behind
  `#if canImport(CoreGraphics) && canImport(ImageIO)`) — Linux CI
  continues to run the unit tests only.
- Counter-test verifying a flat gray image produces zero detections,
  guarding against false-positive regressions.
- Bundled `Tests/SwiftAprilTagTests/Fixtures/tag36h11_id0.png` (200×200,
  516 bytes) as a known-good detection target. Derived from the upstream
  `AprilRobotics/apriltag-imgs` 10×10 native rendering by 20× nearest-
  neighbor upscale, so the corner positions are exactly predictable.

## [1.0.1] - 2026-05-09

### Fixed
- Removed `import CoreGraphics` from public source files. CoreGraphics is
  Apple-only; `CGPoint` and `CGSize` are available on Linux directly via
  Foundation. SwiftAprilTag now builds cleanly on Linux too.
- Dropped synthesized `Hashable` conformance from `Detection` (it was not
  reliably available across platforms). `Equatable` and `Sendable` are
  retained.

### Added
- GitHub Actions CI running `swift build` + `swift test` on macOS 14 and
  Ubuntu (Swift 5.10) for every push, pull request, and tag.
- README badges for CI status, Swift version, supported platforms, SPM
  compatibility, and MIT license.
- GitHub repository topics for discoverability.

## [1.0.0] - 2026-05-08

### Added
- Initial release.
- Swift wrapper around the [AprilTag](https://github.com/AprilRobotics/apriltag)
  fiducial-marker detection library.
- Support for all standard AprilTag families (`tag36h11`, `tag25h9`,
  `tag16h5`, `tag36h10`, `tagCircle21h7`, `tagCircle49h12`, `tagCustom48h12`,
  `tagStandard41h12`, `tagStandard52h13`).
- `Detector` API with configurable thread count, decimation, blur, edge
  refinement, and decode sharpening.
- `Detector.detect(luminance:width:height:stride:)` for raw 8-bit image data.
- `Detector.detect(pixelBuffer:plane:)` for direct AVFoundation
  `CVPixelBuffer` support (Apple platforms only).
- Sub-pixel corner localization in `Detection.corners`.
- Vendored upstream AprilTag C99 source (BSD-2-Clause).
- MIT-licensed Swift wrapper code.
- iOS 15+, macOS 12+, Mac Catalyst 15+, and tvOS 15+ support.

[Unreleased]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/keyqcloud/SwiftAprilTag/releases/tag/v1.0.0
