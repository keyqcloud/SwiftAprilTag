//
//  Detector+UIImage.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

#if canImport(UIKit)
import UIKit

extension Detector {

    /// Detect AprilTags in a `UIImage`.
    ///
    /// Convenience wrapper that unwraps the `UIImage`'s underlying `CGImage`
    /// and forwards to `detect(cgImage:)`. If the `UIImage` was created from
    /// a `CIImage` source, you may need to bake it to a `CGImage` first via
    /// `CIContext.createCGImage(_:from:)` before calling this method.
    ///
    /// Available on iOS, tvOS, and Mac Catalyst. macOS callers should use
    /// `detect(cgImage:)` directly with `NSImage.cgImage(forProposedRect:...)`.
    ///
    /// - Parameter uiImage: A `UIImage` backed by a `CGImage`.
    /// - Returns: Detections in the image's pixel coordinate space.
    /// - Throws: `AprilTagError.invalidImageDimensions` if the image has no
    ///   underlying CGImage or rendering fails.
    public func detect(uiImage: UIImage) throws -> [Detection] {
        guard let cgImage = uiImage.cgImage else {
            throw AprilTagError.invalidImageDimensions
        }
        return try detect(cgImage: cgImage)
    }
}
#endif
