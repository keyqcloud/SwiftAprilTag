//
//  DetectorTests.swift
//  SwiftAprilTagTests
//

import XCTest
@testable import SwiftAprilTag

final class DetectorTests: XCTestCase {

    func testDetectorAllocates() throws {
        let detector = try Detector(families: [.tag36h11])
        XCTAssertEqual(detector.threadCount, 1)
    }

    func testConfigurableProperties() throws {
        let detector = try Detector(families: [.tag36h11])
        detector.threadCount = 4
        detector.quadDecimate = 2.0
        detector.quadSigma = 0.8
        detector.refineEdges = true
        detector.decodeSharpening = 0.5

        XCTAssertEqual(detector.threadCount, 4)
        XCTAssertEqual(detector.quadDecimate, 2.0)
        XCTAssertEqual(detector.quadSigma, 0.8, accuracy: 0.0001)
        XCTAssertTrue(detector.refineEdges)
        XCTAssertEqual(detector.decodeSharpening, 0.5, accuracy: 0.0001)
    }

    func testEmptyImageReturnsNoDetections() throws {
        let detector = try Detector(families: [.tag36h11])
        let width = 64, height = 64
        // Solid mid-gray image — no tags expected
        let pixels = Data(repeating: 128, count: width * height)
        let detections = try detector.detect(luminance: pixels, width: width, height: height)
        XCTAssertEqual(detections.count, 0)
    }

    func testInvalidDimensionsThrow() throws {
        let detector = try Detector(families: [.tag36h11])
        let pixels = Data(repeating: 0, count: 100)
        XCTAssertThrowsError(try detector.detect(luminance: pixels, width: 0, height: 10))
        XCTAssertThrowsError(try detector.detect(luminance: pixels, width: 10, height: 0))
        XCTAssertThrowsError(try detector.detect(luminance: pixels, width: 10, height: 10, stride: 5))
    }

    func testInsufficientDataThrows() throws {
        let detector = try Detector(families: [.tag36h11])
        // Claim 100x100 but only provide 100 bytes
        let pixels = Data(repeating: 0, count: 100)
        XCTAssertThrowsError(try detector.detect(luminance: pixels, width: 100, height: 100))
    }

    func testMultipleFamilies() throws {
        // Just make sure multi-family construction doesn't crash and tears down cleanly
        let detector = try Detector(families: [.tag36h11, .tag25h9, .tagStandard41h12])
        XCTAssertNotNil(detector)
    }
}
