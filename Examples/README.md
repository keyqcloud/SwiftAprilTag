# SwiftAprilTag examples

Two end-to-end demonstrations of using SwiftAprilTag in real applications.

| Example | Platform | What it shows |
|---|---|---|
| [`CLI/`](CLI/) | macOS | Command-line tool that loads an image, runs detection, optionally estimates pose, and prints the result |
| [`iOS-Live/`](iOS-Live/) | iOS | SwiftUI app with live-camera detection, real-time corner overlay, and per-frame 6-DOF pose readout |

Each example has its own README with run instructions.

## Trying the CLI quickly

```bash
cd CLI
swift run DetectAprilTag ../../Tests/SwiftAprilTagTests/Fixtures/tag36h11_id0.png --tag-size 0.1
```

## Trying the iOS demo

The iOS example ships as source files only, not a pre-built Xcode project. Open Xcode, create a new iOS SwiftUI app, drop the source from `iOS-Live/Sources/` into your target, add SwiftAprilTag as an SPM dependency, add an `NSCameraUsageDescription` key to your Info.plist, and run on a real device. Full instructions in [`iOS-Live/README.md`](iOS-Live/README.md).
