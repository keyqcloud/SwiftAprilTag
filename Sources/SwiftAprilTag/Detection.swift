//
//  Detection.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import CoreGraphics
import Foundation

/// A single AprilTag detection in image-pixel coordinates.
public struct Detection: Sendable, Equatable, Hashable {
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
    /// Order is counter-clockwise around the tag, starting from the bottom-left
    /// corner of an upright tag (matching the upstream AprilTag convention).
    public let corners: [CGPoint]

    public init(
        id: Int,
        hamming: Int,
        decisionMargin: Float,
        center: CGPoint,
        corners: [CGPoint]
    ) {
        self.id = id
        self.hamming = hamming
        self.decisionMargin = decisionMargin
        self.center = center
        self.corners = corners
    }
}
