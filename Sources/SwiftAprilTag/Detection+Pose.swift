//
//  Detection+Pose.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import CAprilTag
import Foundation

extension Detection {

    /// Estimate the 6-DOF pose of this tag in the camera's coordinate frame.
    ///
    /// Uses the upstream AprilTag library's homography + orthogonal-iteration
    /// solver. Internally reconstructs an `apriltag_detection_t` from the
    /// corner positions and homography matrix this `Detection` already holds,
    /// so it does not require keeping the original C detection alive after
    /// `Detector.detect(...)` returns.
    ///
    /// - Parameters:
    ///   - intrinsics: Camera intrinsic parameters (focal length, principal
    ///     point) in the same pixel coordinate space as the image you fed
    ///     to the detector.
    ///   - tagSize: Physical edge length of the tag's outer black border, in
    ///     the units you want the resulting translation in (typically meters).
    ///     This is the same dimension AprilTag's library uses for its corner
    ///     positions — NOT the full tag image including any white margin
    ///     around the black square.
    /// - Returns: A `TagPose` with rotation, translation, and reprojection
    ///   error, or `nil` if the upstream solver failed (very rare; usually
    ///   indicates a degenerate input).
    public func estimatePose(intrinsics: CameraIntrinsics, tagSize: Double) -> TagPose? {
        guard homography.count == 9, corners.count == 4 else { return nil }

        // Allocate a matd_t for our homography. The C library owns it; we
        // free it after the pose call.
        guard let H = matd_create(3, 3) else { return nil }
        defer { matd_destroy(H) }
        for r in 0..<3 {
            for c in 0..<3 {
                matd_put(H, UInt32(r), UInt32(c), homography[r * 3 + c])
            }
        }

        // Reconstruct a minimal apriltag_detection_t with the fields the
        // pose solver actually reads (id, corners, homography). family is
        // not dereferenced by the pose code path.
        var det = apriltag_detection_t()
        det.family = nil
        det.id = Int32(id)
        det.hamming = Int32(hamming)
        det.decision_margin = decisionMargin
        det.H = H
        det.c.0 = Double(center.x)
        det.c.1 = Double(center.y)
        det.p.0.0 = Double(corners[0].x); det.p.0.1 = Double(corners[0].y)
        det.p.1.0 = Double(corners[1].x); det.p.1.1 = Double(corners[1].y)
        det.p.2.0 = Double(corners[2].x); det.p.2.1 = Double(corners[2].y)
        det.p.3.0 = Double(corners[3].x); det.p.3.1 = Double(corners[3].y)

        // Run pose estimation inside a withUnsafeMutablePointer so the
        // temporary `det` lives across the C call.
        return withUnsafeMutablePointer(to: &det) { detPtr -> TagPose? in
            var info = apriltag_detection_info_t()
            info.det = detPtr
            info.tagsize = tagSize
            info.fx = intrinsics.fx
            info.fy = intrinsics.fy
            info.cx = intrinsics.cx
            info.cy = intrinsics.cy

            var pose = apriltag_pose_t()
            let err = estimate_tag_pose(&info, &pose)

            defer {
                if let R = pose.R { matd_destroy(R) }
                if let t = pose.t { matd_destroy(t) }
            }

            guard let R = pose.R, let t = pose.t else { return nil }

            var rotation = [Float](repeating: 0, count: 9)
            for r in 0..<3 {
                for c in 0..<3 {
                    rotation[r * 3 + c] = Float(matd_get(R, UInt32(r), UInt32(c)))
                }
            }
            var translation = [Float](repeating: 0, count: 3)
            for r in 0..<3 {
                translation[r] = Float(matd_get(t, UInt32(r), 0))
            }

            return TagPose(
                rotation: rotation,
                translation: translation,
                reprojectionError: Float(err)
            )
        }
    }
}
