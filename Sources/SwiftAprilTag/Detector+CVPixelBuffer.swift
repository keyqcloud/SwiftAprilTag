//
//  Detector+CVPixelBuffer.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

#if canImport(CoreVideo)
import CoreVideo
import Foundation

extension Detector {

    /// Detect AprilTags in a `CVPixelBuffer`'s luminance plane.
    ///
    /// For `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` and friends (the
    /// default format produced by AVFoundation video capture), pass `plane: 0`
    /// to use the Y plane directly — no color-space conversion needed.
    ///
    /// For single-plane grayscale buffers, pass `plane: 0`.
    ///
    /// The pixel buffer is locked for read for the duration of the detection.
    ///
    /// - Parameters:
    ///   - pixelBuffer: A planar or grayscale `CVPixelBuffer`.
    ///   - plane: Plane index to use as luminance source. Defaults to `0`.
    /// - Returns: Detections in the plane's pixel coordinates.
    public func detect(pixelBuffer: CVPixelBuffer, plane: Int = 0) throws -> [Detection] {
        let lockResult = CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        guard lockResult == kCVReturnSuccess else {
            throw AprilTagError.insufficientImageData
        }
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        let isPlanar = CVPixelBufferIsPlanar(pixelBuffer)
        let width: Int
        let height: Int
        let stride: Int
        let baseAddress: UnsafeMutableRawPointer?

        if isPlanar {
            guard plane < CVPixelBufferGetPlaneCount(pixelBuffer) else {
                throw AprilTagError.invalidImageDimensions
            }
            width = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane)
            height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane)
        } else {
            width = CVPixelBufferGetWidth(pixelBuffer)
            height = CVPixelBufferGetHeight(pixelBuffer)
            stride = CVPixelBufferGetBytesPerRow(pixelBuffer)
            baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        }

        guard let base = baseAddress else {
            throw AprilTagError.insufficientImageData
        }

        return try detect(
            luminanceBaseAddress: base.assumingMemoryBound(to: UInt8.self),
            width: width,
            height: height,
            stride: stride
        )
    }
}
#endif
