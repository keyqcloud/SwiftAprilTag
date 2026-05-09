//
//  IntegrationTests.swift
//  SwiftAprilTagTests
//
//  End-to-end tests that exercise the detector against a real AprilTag
//  image. These tests prove the wrapper actually decodes a tag — beyond
//  the unit tests in DetectorTests.swift which only exercise configuration
//  and error paths.
//
//  The fixture `tag36h11_id0.png` is a 200×200 nearest-neighbor upscale of
//  upstream AprilRobotics/apriltag-imgs/tag36h11/tag36_11_00000.png.
//
//  Apple-only — uses CoreGraphics + ImageIO to decode the PNG fixture.
//  Linux CI runs the unit tests only.
//

#if canImport(CoreGraphics) && canImport(ImageIO)

import CoreGraphics
import ImageIO
import XCTest
@testable import SwiftAprilTag

final class IntegrationTests: XCTestCase {

    func testDetectsKnownTag36h11Id0() throws {
        let image = try loadFixturePNG(named: "tag36h11_id0", ofType: "png")
        let (luminance, width, height, stride) = try grayscalePixels(from: image)

        let detector = try Detector(families: [.tag36h11])
        let detections = try detector.detect(
            luminance: luminance,
            width: width,
            height: height,
            stride: stride
        )

        XCTAssertEqual(detections.count, 1, "Expected exactly one detection in the fixture image")
        guard let detection = detections.first else { return }

        XCTAssertEqual(detection.id, 0, "Fixture is tag36h11 id 0")
        XCTAssertEqual(detection.hamming, 0, "A clean rendered tag should decode with zero error correction")
        XCTAssertGreaterThan(detection.decisionMargin, 50,
                             "A clean rendered tag should produce a high decision margin")

        // The fixture is a 200×200 nearest-neighbor 20× upscale of the
        // upstream 10×10 native PNG. tag36h11's standard rendering surrounds
        // the 8-unit black border with a 1-unit white margin, giving a 10-unit
        // total. After 20× scale, the OUTER BLACK BORDER corners — which is
        // what AprilTag's library returns — sit at:
        //
        //     (20, 20)   (180, 20)
        //     (20, 180)  (180, 180)
        //
        // Documenting the corner convention here directly: corners are at the
        // outer black-border edges, NOT the outer extent of the white-margin
        // rendering. Distributors who label tags by overall image size
        // (e.g. rgov/apriltag-pdfs "100mm") are reporting margin-inclusive
        // dimensions that don't match what `detection.corners` returns.
        XCTAssertEqual(detection.corners.count, 4)
        let expectedCornerInset: CGFloat = 20  // 1-unit white margin × 20× upscale
        let tolerance: CGFloat = 1.0
        let expectedCornerXs: Set<Int> = [
            Int(expectedCornerInset),
            width - Int(expectedCornerInset)
        ]
        let expectedCornerYs: Set<Int> = [
            Int(expectedCornerInset),
            height - Int(expectedCornerInset)
        ]
        for corner in detection.corners {
            let nearestX = expectedCornerXs.min { abs(CGFloat($0) - corner.x) < abs(CGFloat($1) - corner.x) }!
            let nearestY = expectedCornerYs.min { abs(CGFloat($0) - corner.y) < abs(CGFloat($1) - corner.y) }!
            XCTAssertLessThan(abs(corner.x - CGFloat(nearestX)), tolerance,
                              "Corner \(corner) x is not within \(tolerance) of expected (\(nearestX), \(nearestY))")
            XCTAssertLessThan(abs(corner.y - CGFloat(nearestY)), tolerance,
                              "Corner \(corner) y is not within \(tolerance) of expected (\(nearestX), \(nearestY))")
        }
    }

    func testEstimatePoseFromKnownFixture() throws {
        let image = try loadFixturePNG(named: "tag36h11_id0", ofType: "png")
        let (luminance, width, height, stride) = try grayscalePixels(from: image)

        let detector = try Detector(families: [.tag36h11])
        let detections = try detector.detect(
            luminance: luminance,
            width: width,
            height: height,
            stride: stride
        )
        guard let detection = detections.first else {
            XCTFail("No detection in fixture image")
            return
        }

        // Synthesize plausible camera intrinsics for this synthetic image:
        // - 200x200 image
        // - principal point at the geometric center (100, 100)
        // - focal length such that a 0.1m tag with 160px pixel-edge length
        //   would correspond to a tag 0.5m from the camera:
        //     pixel_edge = tagSize * fx / Z  ⇒  160 = 0.1 * fx / 0.5  ⇒  fx = 800
        let intrinsics = CameraIntrinsics(fx: 800, fy: 800, cx: 100, cy: 100)
        let tagSize = 0.1 // meters

        guard let pose = detection.estimatePose(intrinsics: intrinsics, tagSize: tagSize) else {
            XCTFail("estimatePose returned nil")
            return
        }

        // Translation should land near (0, 0, 0.5) — tag is centered in
        // image, principal point matches, and we constructed fx so that the
        // observed pixel edge corresponds to 0.5m depth.
        let tolerance: Float = 0.005 // 5mm
        XCTAssertEqual(pose.translation[0], 0, accuracy: tolerance, "Tag should be centered horizontally")
        XCTAssertEqual(pose.translation[1], 0, accuracy: tolerance, "Tag should be centered vertically")
        XCTAssertEqual(pose.translation[2], 0.5, accuracy: tolerance, "Tag depth should match constructed intrinsics")

        // Rotation should be ~ identity (with the camera convention's sign
        // pattern). The tag is fronto-parallel; the diagonal entries should
        // be ±1 and off-diagonals near zero.
        let rotationTolerance: Float = 0.01
        for i in [0, 4, 8] {
            XCTAssertEqual(abs(pose.rotation[i]), 1.0, accuracy: rotationTolerance,
                           "Rotation diagonal entry \(i) should have magnitude 1")
        }
        for i in [1, 2, 3, 5, 6, 7] {
            XCTAssertEqual(pose.rotation[i], 0, accuracy: rotationTolerance,
                           "Rotation off-diagonal entry \(i) should be ~0")
        }

        // Reprojection error should be small for this clean synthetic image.
        XCTAssertLessThan(pose.reprojectionError, 1.0,
                          "Reprojection error \(pose.reprojectionError) larger than expected")
    }

    func testDoesNotDetectInBlankImage() throws {
        // Sanity counter-test: a flat-gray image must produce zero detections.
        // This guards against false positives that would render the integration
        // test above misleading.
        let width = 200, height = 200
        let pixels = Data(repeating: 128, count: width * height)
        let detector = try Detector(families: [.tag36h11])
        let detections = try detector.detect(
            luminance: pixels,
            width: width,
            height: height,
            stride: width
        )
        XCTAssertEqual(detections.count, 0)
    }

    // MARK: - Fixture loading helpers

    private func loadFixturePNG(named name: String, ofType ext: String) throws -> CGImage {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")
              ?? bundle.url(forResource: name, withExtension: ext) else {
            throw FixtureError.notFound("\(name).\(ext)")
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw FixtureError.decodeFailed(url.path)
        }
        return image
    }

    /// Renders an arbitrary CGImage into a tightly-packed 8-bit grayscale
    /// luminance buffer. Stride equals width.
    private func grayscalePixels(from image: CGImage) throws -> (Data, Int, Int, Int) {
        let width = image.width
        let height = image.height
        let stride = width
        var pixels = Data(count: height * stride)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let success: Bool = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: stride,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        if !success { throw FixtureError.contextFailed }
        return (pixels, width, height, stride)
    }

    enum FixtureError: Error {
        case notFound(String)
        case decodeFailed(String)
        case contextFailed
    }
}

#endif
