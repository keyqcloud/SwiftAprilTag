//
//  Detection.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// A single AprilTag detection in image-pixel coordinates.
///
/// `CGPoint` here is the basic struct from Foundation (a pair of CGFloats),
/// available on every Swift platform including Linux. We do not import
/// CoreGraphics because that module is Apple-only.
public struct Detection: Sendable, Equatable {
    /// The decoded tag ID within its family.
    public let id: Int

    /// How many error bits were corrected during decoding. Higher values mean
    /// the decoder had to work harder; very high values raise false-positive risk.
    public let hamming: Int

    /// Quality of the binary decode — average difference between bit intensity
    /// and the decision threshold. Higher numbers indicate better decodes.
    /// Useful for filtering small or distant tags.
    public let decisionMargin: Float

    /// Tag center in image pixel coordinates (sub-pixel accuracy).
    public let center: CGPoint

    /// Tag corners in image pixel coordinates (sub-pixel accuracy).
    /// Order is counter-clockwise around the tag (matching upstream
    /// AprilTag convention).
    public let corners: [CGPoint]

    /// 3x3 homography matrix mapping ideal tag coordinates [-1, 1] at the
    /// outer black-border corners to image pixel coordinates. Stored row-major
    /// (`homography[row * 3 + col]`). Used by `estimatePose(intrinsics:tagSize:)`
    /// and exposed publicly for users who want to perform their own custom
    /// projection, perspective-warp, or homography decomposition.
    public let homography: [Double]

    public init(
        id: Int,
        hamming: Int,
        decisionMargin: Float,
        center: CGPoint,
        corners: [CGPoint],
        homography: [Double]
    ) {
        self.id = id
        self.hamming = hamming
        self.decisionMargin = decisionMargin
        self.center = center
        self.corners = corners
        self.homography = homography
    }
}
