//
//  Detector.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

import CAprilTag
import Foundation

/// Errors thrown by `Detector`.
public enum AprilTagError: Error, Sendable {
    /// The underlying C detector or family allocation failed.
    case allocationFailed
    /// The provided image data is shorter than `height * stride` bytes.
    case insufficientImageData
    /// The provided dimensions are non-positive or stride is less than width.
    case invalidImageDimensions
}

/// Detects AprilTag fiducial markers in single-channel 8-bit luminance images.
///
/// `Detector` is **not** thread-safe — create one instance per thread, or use
/// external synchronization. The underlying C detector internally parallelizes
/// work across `threadCount` worker threads.
///
/// The detector retains its tag families until it is deinitialized, so a single
/// `Detector` can be reused across many frames without re-allocating per call.
public final class Detector {

    // MARK: - Configuration

    /// Number of worker threads the detector uses internally. Defaults to 1.
    /// Increase to roughly the number of performance cores for best throughput.
    public var threadCount: Int {
        get { Int(td.pointee.nthreads) }
        set { td.pointee.nthreads = Int32(max(1, newValue)) }
    }

    /// Image decimation applied during quad detection. Values > 1 trade detection
    /// accuracy for speed (e.g. `2.0` halves the image dimensions for the quad
    /// detection pass). Decoding still runs at full resolution.
    public var quadDecimate: Float {
        get { td.pointee.quad_decimate }
        set { td.pointee.quad_decimate = newValue }
    }

    /// Standard deviation (in pixels) of the Gaussian blur applied before quad
    /// detection. Helpful for noisy images. `0` disables blurring.
    public var quadSigma: Float {
        get { td.pointee.quad_sigma }
        set { td.pointee.quad_sigma = newValue }
    }

    /// When true, quad edges are snapped to nearby strong gradients after
    /// detection. Recommended; only meaningful when `quadDecimate > 1`.
    public var refineEdges: Bool {
        get { td.pointee.refine_edges }
        set { td.pointee.refine_edges = newValue }
    }

    /// Sharpening applied to the decoded image. Defaults to `0.25`. Helps decode
    /// small tags but may hurt in unusual lighting.
    public var decodeSharpening: Double {
        get { td.pointee.decode_sharpening }
        set { td.pointee.decode_sharpening = newValue }
    }

    // MARK: - Lifecycle

    private let td: UnsafeMutablePointer<apriltag_detector_t>
    private var registeredFamilies: [(family: TagFamily, pointer: UnsafeMutablePointer<apriltag_family_t>)] = []

    /// Creates a detector configured for the given tag families. Most callers
    /// pass `[.tag36h11]`.
    ///
    /// - Throws: `AprilTagError.allocationFailed` if the underlying C
    ///   detector or any family fails to allocate.
    public init(families: [TagFamily] = [.tag36h11]) throws {
        guard let detector = apriltag_detector_create() else {
            throw AprilTagError.allocationFailed
        }
        self.td = detector

        for family in families {
            guard let cFamily = family.createCFamily() else {
                cleanup()
                throw AprilTagError.allocationFailed
            }
            apriltag_detector_add_family_bits(td, cFamily, TagFamily.defaultBitsCorrected)
            registeredFamilies.append((family, cFamily))
        }
    }

    deinit {
        cleanup()
    }

    private func cleanup() {
        apriltag_detector_clear_families(td)
        for (family, pointer) in registeredFamilies {
            family.destroyCFamily(pointer)
        }
        registeredFamilies.removeAll()
        apriltag_detector_destroy(td)
    }

    // MARK: - Detection

    /// Runs the detector against an 8-bit grayscale image.
    ///
    /// - Parameters:
    ///   - luminance: Raw 8-bit grayscale pixel data, row-major, `height * stride`
    ///     bytes long. Pass the Y-plane of a `kCVPixelFormatType_420YpCbCr8*`
    ///     CVPixelBuffer for AVFoundation captures.
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - stride: Row stride in bytes. For a tightly packed grayscale image,
    ///     this equals `width`. CVPixelBuffer planes often have larger strides.
    /// - Returns: Detections in image pixel coordinates. Empty if no tags found.
    /// - Throws: `AprilTagError.invalidImageDimensions` or
    ///   `AprilTagError.insufficientImageData` for malformed inputs.
    public func detect(
        luminance: Data,
        width: Int,
        height: Int,
        stride: Int? = nil
    ) throws -> [Detection] {
        let actualStride = stride ?? width
        guard width > 0, height > 0, actualStride >= width else {
            throw AprilTagError.invalidImageDimensions
        }
        guard luminance.count >= height * actualStride else {
            throw AprilTagError.insufficientImageData
        }

        return try luminance.withUnsafeBytes { rawBuffer -> [Detection] in
            guard let baseAddress = rawBuffer.baseAddress else {
                throw AprilTagError.insufficientImageData
            }
            return detectFromPointer(
                baseAddress: baseAddress.assumingMemoryBound(to: UInt8.self),
                width: width,
                height: height,
                stride: actualStride
            )
        }
    }

    /// Lower-level detect entry point taking a raw pointer. Useful when you
    /// already have a locked CVPixelBuffer plane and want to avoid copying.
    /// The pointer must remain valid for the duration of this call.
    public func detect(
        luminanceBaseAddress baseAddress: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        stride: Int
    ) throws -> [Detection] {
        guard width > 0, height > 0, stride >= width else {
            throw AprilTagError.invalidImageDimensions
        }
        return detectFromPointer(
            baseAddress: baseAddress,
            width: width,
            height: height,
            stride: stride
        )
    }

    private func detectFromPointer(
        baseAddress: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        stride: Int
    ) -> [Detection] {
        // image_u8_t has const fields, so we allocate via the C helper and copy
        // row data in. We use the default 96-byte aligned allocator to keep the
        // detector's internal SIMD paths happy; the destination stride may differ
        // from the source stride and we account for that in the row copy below.
        guard let image = image_u8_create(UInt32(width), UInt32(height)) else {
            return []
        }
        defer { image_u8_destroy(image) }

        // Copy row-by-row to honor the destination's stride.
        let dstStride = Int(image.pointee.stride)
        if let dstBuf = image.pointee.buf {
            for row in 0..<height {
                memcpy(
                    dstBuf.advanced(by: row * dstStride),
                    baseAddress.advanced(by: row * stride),
                    width
                )
            }
        }

        guard let zarray = apriltag_detector_detect(td, image) else {
            return []
        }
        defer { apriltag_detections_destroy(zarray) }

        let count = Int(zarray_size(zarray))
        var results: [Detection] = []
        results.reserveCapacity(count)

        for i in 0..<count {
            var detPtr: UnsafeMutablePointer<apriltag_detection_t>? = nil
            withUnsafeMutablePointer(to: &detPtr) { ptr in
                zarray_get(zarray, Int32(i), UnsafeMutableRawPointer(ptr))
            }
            guard let det = detPtr else { continue }
            let d = det.pointee

            let corners: [CGPoint] = [
                CGPoint(x: d.p.0.0, y: d.p.0.1),
                CGPoint(x: d.p.1.0, y: d.p.1.1),
                CGPoint(x: d.p.2.0, y: d.p.2.1),
                CGPoint(x: d.p.3.0, y: d.p.3.1)
            ]

            results.append(Detection(
                id: Int(d.id),
                hamming: Int(d.hamming),
                decisionMargin: d.decision_margin,
                center: CGPoint(x: d.c.0, y: d.c.1),
                corners: corners
            ))
        }

        return results
    }
}
