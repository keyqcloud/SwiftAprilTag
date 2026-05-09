//
//  Detection+CGPath.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

#if canImport(CoreGraphics)
import CoreGraphics

extension Detection {

    /// Closed `CGPath` of the detected tag's outer black-border polygon.
    ///
    /// Useful for drawing detection overlays on a `CALayer` (`CAShapeLayer.path`)
    /// or in SwiftUI (`Path(cgPath)`). Coordinates are in the same image-pixel
    /// space as the input you passed to `Detector.detect(...)`. If you're
    /// drawing on top of an `AVCaptureVideoPreviewLayer`, run the corner
    /// points through `layerPointConverted(fromCaptureDevicePoint:)` first to
    /// account for orientation, mirroring, and aspect-fill cropping.
    public var cgPath: CGPath {
        let path = CGMutablePath()
        path.addLines(between: corners)
        path.closeSubpath()
        return path
    }
}
#endif
