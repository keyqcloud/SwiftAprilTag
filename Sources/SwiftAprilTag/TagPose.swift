//
//  TagPose.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// 6-DOF pose of a detected tag in the camera's coordinate frame.
///
/// The transformation is: any point `p_tag` in the tag's local coordinate
/// frame (origin at the tag center, +X right, +Y up, +Z out of the tag) maps
/// to a point `p_camera = R * p_tag + t` in the camera's coordinate frame.
///
/// Distances are in the same units as the `tagSize` you passed to
/// `Detection.estimatePose` — typically meters.
///
/// Stored as plain `[Float]` for cross-platform portability (Linux Swift has
/// no `simd` module). On Apple platforms, the `simd_float3x3`,
/// `simd_float3`, and `simd_float4x4` accessors below give you the standard
/// math types directly.
public struct TagPose: Sendable, Equatable {
    /// 3x3 rotation matrix, row-major (`rotation[row * 3 + col]`).
    public let rotation: [Float]

    /// 3-element translation vector `(tx, ty, tz)` in the units of `tagSize`.
    public let translation: [Float]

    /// Reprojection error reported by the upstream pose solver. Lower is
    /// better; values much above ~1.0 typically mean the corner detection
    /// was poor or the tag was viewed at an extreme angle. Use this to
    /// filter or weight pose estimates from a stream of detections.
    public let reprojectionError: Float

    public init(rotation: [Float], translation: [Float], reprojectionError: Float) {
        precondition(rotation.count == 9, "rotation must have exactly 9 elements (row-major 3x3)")
        precondition(translation.count == 3, "translation must have exactly 3 elements (x, y, z)")
        self.rotation = rotation
        self.translation = translation
        self.reprojectionError = reprojectionError
    }
}

#if canImport(simd)
import simd

extension TagPose {

    /// Rotation as a `simd_float3x3`. Columns of the simd matrix correspond
    /// to columns of the underlying row-major storage (i.e. simd's
    /// column-major convention is preserved).
    public var rotationMatrix: simd_float3x3 {
        // simd_float3x3 is column-major: each column is a simd_float3.
        // Our rotation is row-major; transpose during conversion.
        let r = rotation
        return simd_float3x3(
            simd_float3(r[0], r[3], r[6]),
            simd_float3(r[1], r[4], r[7]),
            simd_float3(r[2], r[5], r[8])
        )
    }

    /// Translation as a `simd_float3`.
    public var translationVector: simd_float3 {
        simd_float3(translation[0], translation[1], translation[2])
    }

    /// Combined 4x4 homogeneous transform suitable for use with SceneKit,
    /// RealityKit, ARKit, or Metal. Multiplies a `simd_float4` `(x, y, z, 1)`
    /// in the tag's coordinate frame to produce the same point in the
    /// camera's coordinate frame.
    public var transform: simd_float4x4 {
        let r = rotation
        let t = translation
        return simd_float4x4(
            simd_float4(r[0], r[3], r[6], 0),
            simd_float4(r[1], r[4], r[7], 0),
            simd_float4(r[2], r[5], r[8], 0),
            simd_float4(t[0], t[1], t[2], 1)
        )
    }
}
#endif
