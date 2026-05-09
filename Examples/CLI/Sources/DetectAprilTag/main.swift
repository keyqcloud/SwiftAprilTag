//
//  main.swift
//  DetectAprilTag (SwiftAprilTag CLI example)
//
//  Loads an image, runs AprilTag detection, prints results.
//
//  Usage:
//      swift run DetectAprilTag path/to/image.png
//
//  Optional flags:
//      --tag-size <meters>   Run pose estimation against synthetic intrinsics
//                            (fx = fy = imageWidth, principal point at center)
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftAprilTag

// MARK: - CLI parsing

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("""
        usage: \(args[0]) <image-path> [--tag-size <meters>]

        Detects AprilTags (tag36h11 family) in the given image and prints results.
        Supports PNG, JPEG, HEIC, BMP, GIF — anything ImageIO can read.

        --tag-size <meters>    Also run pose estimation. The synthetic intrinsics
                               used assume fx = fy = imageWidth and a principal
                               point at the geometric center; this is a rough
                               default. For real metric pose, supply the actual
                               camera intrinsics in your own program.
        """.appending("\n").utf8))
    exit(64)
}

let imagePath = args[1]
var tagSize: Double? = nil
var i = 2
while i < args.count {
    if args[i] == "--tag-size", i + 1 < args.count, let v = Double(args[i + 1]) {
        tagSize = v
        i += 2
    } else {
        FileHandle.standardError.write(Data("Unrecognized arg: \(args[i])\n".utf8))
        exit(64)
    }
}

// MARK: - Image load

let url = URL(fileURLWithPath: imagePath)
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    FileHandle.standardError.write(Data("Could not read image at \(imagePath)\n".utf8))
    exit(1)
}

print("Image: \(image.width)×\(image.height) pixels")

// MARK: - Detect

let detector = try Detector(families: [.tag36h11])
let detections = try detector.detect(cgImage: image)

if detections.isEmpty {
    print("No tags detected.")
    exit(0)
}

print("Detected \(detections.count) tag(s):")
for (idx, det) in detections.enumerated() {
    print("""

      [\(idx)] tag36h11 id=\(det.id)
          decisionMargin: \(String(format: "%.2f", det.decisionMargin))
          hamming corrections: \(det.hamming)
          center: (\(String(format: "%.2f", det.center.x)), \(String(format: "%.2f", det.center.y)))
          corners (CCW around outer black border):
              \(formatCorner(det.corners[0]))
              \(formatCorner(det.corners[1]))
              \(formatCorner(det.corners[2]))
              \(formatCorner(det.corners[3]))
    """)

    if let tagSize = tagSize {
        // Synthetic intrinsics: fx = fy = imageWidth (~ 60° HFOV), principal
        // point centered. Good enough to demonstrate pose estimation; replace
        // with real calibration for metric work.
        let imageWidth = Double(image.width)
        let imageHeight = Double(image.height)
        let intrinsics = CameraIntrinsics(
            fx: imageWidth, fy: imageWidth,
            cx: imageWidth / 2, cy: imageHeight / 2
        )
        if let pose = det.estimatePose(intrinsics: intrinsics, tagSize: tagSize) {
            print("""
                  pose:
                      translation (m): (\(formatFloat(pose.translation[0])), \(formatFloat(pose.translation[1])), \(formatFloat(pose.translation[2])))
                      reprojection error: \(formatFloat(pose.reprojectionError))
            """)
        }
    }
}

// MARK: - Helpers

func formatCorner(_ p: CGPoint) -> String {
    return "(\(String(format: "%.2f", p.x)), \(String(format: "%.2f", p.y)))"
}

func formatFloat(_ v: Float) -> String {
    return String(format: "%.4f", v)
}
