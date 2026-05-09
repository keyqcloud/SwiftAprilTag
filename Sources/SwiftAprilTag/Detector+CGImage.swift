//
//  Detector+CGImage.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

extension Detector {

    /// Detect AprilTags in a `CGImage`.
    ///
    /// Renders the image into an 8-bit grayscale buffer (any color image is
    /// luminance-converted via the device-gray color space) and runs the
    /// detector on that buffer. Stride matches the image width — no padding.
    ///
    /// For best performance on a streaming source, prefer
    /// `detect(pixelBuffer:plane:)` which avoids the conversion when the
    /// pixel buffer already has a luminance plane.
    ///
    /// - Parameter cgImage: Any `CGImage`. Color space, alpha, and bit depth
    ///   don't matter — they're normalized during the grayscale render.
    /// - Returns: Detections in the image's pixel coordinate space.
    /// - Throws: `AprilTagError.invalidImageDimensions` if the image is empty
    ///   or the grayscale render fails.
    public func detect(cgImage: CGImage) throws -> [Detection] {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            throw AprilTagError.invalidImageDimensions
        }

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
                  ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard success else {
            throw AprilTagError.invalidImageDimensions
        }

        return try detect(
            luminance: pixels,
            width: width,
            height: height,
            stride: stride
        )
    }
}
#endif
