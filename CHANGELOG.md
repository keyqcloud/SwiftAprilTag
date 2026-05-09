# Changelog

All notable changes to SwiftAprilTag are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/keyqcloud/SwiftAprilTag/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/keyqcloud/SwiftAprilTag/releases/tag/v1.0.0
