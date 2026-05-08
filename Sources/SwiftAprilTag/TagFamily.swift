//
//  TagFamily.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import CAprilTag

/// AprilTag tag family. Each family is a different bit-grid layout with its own
/// trade-off between marker density and minimum Hamming distance (false-positive
/// resistance). `tag36h11` is the most widely used family in robotics and AR.
public enum TagFamily: String, Sendable, CaseIterable {
    case tag36h11
    case tag25h9
    case tag16h5
    case tag36h10
    case tagCircle21h7
    case tagCircle49h12
    case tagCustom48h12
    case tagStandard41h12
    case tagStandard52h13

    /// Bits-corrected parameter passed to `apriltag_detector_add_family_bits`.
    /// `2` is the upstream-recommended default for tag36h11. Larger values consume
    /// significantly more memory for marginal detection-rate gains.
    static let defaultBitsCorrected: Int32 = 2

    internal func createCFamily() -> UnsafeMutablePointer<apriltag_family_t>? {
        switch self {
        case .tag36h11:           return tag36h11_create()
        case .tag25h9:            return tag25h9_create()
        case .tag16h5:            return tag16h5_create()
        case .tag36h10:           return tag36h10_create()
        case .tagCircle21h7:      return tagCircle21h7_create()
        case .tagCircle49h12:     return tagCircle49h12_create()
        case .tagCustom48h12:     return tagCustom48h12_create()
        case .tagStandard41h12:   return tagStandard41h12_create()
        case .tagStandard52h13:   return tagStandard52h13_create()
        }
    }

    internal func destroyCFamily(_ family: UnsafeMutablePointer<apriltag_family_t>) {
        switch self {
        case .tag36h11:           tag36h11_destroy(family)
        case .tag25h9:            tag25h9_destroy(family)
        case .tag16h5:            tag16h5_destroy(family)
        case .tag36h10:           tag36h10_destroy(family)
        case .tagCircle21h7:      tagCircle21h7_destroy(family)
        case .tagCircle49h12:     tagCircle49h12_destroy(family)
        case .tagCustom48h12:     tagCustom48h12_destroy(family)
        case .tagStandard41h12:   tagStandard41h12_destroy(family)
        case .tagStandard52h13:   tagStandard52h13_destroy(family)
        }
    }
}
