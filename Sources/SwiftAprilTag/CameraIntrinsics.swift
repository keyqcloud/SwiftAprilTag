//
//  CameraIntrinsics.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Pinhole-camera intrinsic parameters in pixel units.
///
/// Used by `Detection.estimatePose(intrinsics:tagSize:)` to recover the 6-DOF
/// pose of a detected tag in the camera's coordinate frame. The values are in
/// the same pixel coordinate space as the image you passed to the detector.
///
/// If your image was downsampled or cropped from a higher-resolution sensor
/// frame, scale the intrinsics into the image's pixel space before passing
/// them in:
///
/// ```swift
/// // Source intrinsics measured at the sensor's reference resolution
/// let scale = imageWidth / referenceWidth
/// let scaled = CameraIntrinsics(
///     fx: sourceFx * scale, fy: sourceFy * scale,
///     cx: sourceCx * scale, cy: sourceCy * scale
/// )
/// ```
public struct CameraIntrinsics: Sendable, Equatable {
    /// Horizontal focal length, in pixels.
    public var fx: Double
    /// Vertical focal length, in pixels.
    public var fy: Double
    /// Horizontal principal point (optical center), in pixels.
    public var cx: Double
    /// Vertical principal point (optical center), in pixels.
    public var cy: Double

    public init(fx: Double, fy: Double, cx: Double, cy: Double) {
        self.fx = fx
        self.fy = fy
        self.cx = cx
        self.cy = cy
    }
}
