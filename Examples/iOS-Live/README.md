# AprilTagLive — iOS live-camera example

Minimal SwiftUI iOS app that streams the rear camera, detects AprilTags in real time, draws a green outline around each detection, and shows the tag's 6-DOF pose.

## Source layout

```
Sources/
├── AprilTagLiveApp.swift      # @main app entry point
├── ContentView.swift          # status banner + detection info card
├── CameraPreviewView.swift    # AVCaptureVideoPreviewLayer + corner overlay
└── TagDetectionSession.swift  # AVCaptureSession + per-frame detection + pose
```

The example deliberately ships as **source files only**, not a pre-built `.xcodeproj`. Xcode-project files are fragile to maintain, and most users will paste the source into an existing app anyway.

## How to run it

1. In Xcode: **File → New Project → iOS App** (SwiftUI lifecycle)
2. Delete the generated `ContentView.swift` and the auto-generated app entry file
3. Drag the four `.swift` files from this directory into your new project's source group
4. **Add SwiftAprilTag as a Swift Package dependency:** **File → Add Package Dependencies…** and paste `https://github.com/keyqcloud/SwiftAprilTag.git`
5. **Add camera permission:** in your project's `Info.plist` (or the target's "Info" tab), add the key `NSCameraUsageDescription` with a value like *"AprilTagLive needs the camera to detect AprilTag fiducial markers."*
6. Build and run on a real iPhone (the simulator has no camera)
7. Print an AprilTag (tag36h11 family — see the [bundled fixture](../../Tests/SwiftAprilTagTests/Fixtures/tag36h11_id0.png) or [`rgov/apriltag-pdfs`](https://github.com/rgov/apriltag-pdfs)) and point the rear camera at it
8. The status banner turns green when a tag is detected, the outline tracks the tag, and the pose readout shows in real time

## What it demonstrates

- **`Detector(families: [.tag36h11])`** — set up
- **`detect(pixelBuffer:plane:)`** — direct `CVPixelBuffer` luminance-plane detection with no color-space conversion
- **`Detection.corners`** — sub-pixel corner positions
- **`AVCaptureVideoPreviewLayer.layerPointConverted(fromCaptureDevicePoint:)`** — correct pixel→view mapping handling orientation, mirroring, and aspect-fill cropping
- **`CameraIntrinsics`** — built directly from the per-frame `kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix` attachment
- **`Detection.estimatePose(intrinsics:tagSize:)`** — recover the tag's 6-DOF pose for AR placement

## Tweaking

- **Tag size** — adjust `TagDetectionSession.tagSize` to match your printed tag's outer black border in meters.
- **Detector throughput** — `quad_decimate` is set to 2.0 for live-camera throughput. If you need finer corner accuracy and have GPU/CPU headroom, set it to 1.0.
- **Camera position** — change `.builtInWideAngleCamera, position: .back` to `.builtInTrueDepthCamera, position: .front` to use the front-facing TrueDepth camera (e.g., for face-side scanning workflows).
