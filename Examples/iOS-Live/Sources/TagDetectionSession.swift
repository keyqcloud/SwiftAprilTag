//
//  TagDetectionSession.swift
//  AprilTagLive
//
//  AVCaptureSession wrapper that streams frames from the rear camera through
//  SwiftAprilTag's detector and publishes the latest detection + pose.
//

import AVFoundation
import Combine
import CoreVideo
import Foundation
import SwiftAprilTag
import UIKit

@MainActor
final class TagDetectionSession: NSObject, ObservableObject {

    /// Snapshot of the most recently detected tag, lifted to MainActor for UI.
    struct DetectionSnapshot {
        let id: Int
        let decisionMargin: Float
        let corners: [CGPoint]
        let colorFrameSize: CGSize
        let pose: TagPose?
    }

    /// Most recent successful detection. `nil` when no tag is currently visible.
    @Published private(set) var latestDetection: DetectionSnapshot?

    /// The capture session, exposed so `CameraPreviewView` can show its preview.
    let captureSession = AVCaptureSession()

    /// Physical edge length of the printed tag's outer black border, in meters.
    /// Adjust to match your printed tag.
    var tagSize: Double = 0.1

    private let sessionQueue = DispatchQueue(label: "tag-detection.session")
    private let dataQueue = DispatchQueue(label: "tag-detection.data")
    private let videoOutput = AVCaptureVideoDataOutput()

    private nonisolated(unsafe) let detector: Detector? = {
        guard let d = try? Detector(families: [.tag36h11]) else { return nil }
        d.quadDecimate = 2.0
        d.refineEdges = true
        return d
    }()

    /// Camera intrinsics derived from `videoOutput.sampleBufferCallbackQueue`'s
    /// connection. We populate this lazily from the first sample buffer that
    /// reports calibration data; if your AVCaptureDevice doesn't provide it,
    /// `estimatePose(...)` is skipped.
    private nonisolated(unsafe) var cachedIntrinsics: CameraIntrinsics?

    override init() {
        super.init()
        configure()
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func configure() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        // Use the rear wide-angle camera.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        videoOutput.setSampleBufferDelegate(self, queue: dataQueue)

        // Ask AVFoundation to deliver per-frame intrinsics if the camera
        // supports it. iPhone wide-angle cameras typically do.
        if let connection = videoOutput.connection(with: .video),
           connection.isCameraIntrinsicMatrixDeliverySupported {
            connection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }

        captureSession.commitConfiguration()
    }
}

extension TagDetectionSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let detector = detector,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let frameW = CVPixelBufferGetWidth(pixelBuffer)
        let frameH = CVPixelBufferGetHeight(pixelBuffer)

        // Run detection on the luminance plane.
        guard let detection = (try? detector.detect(pixelBuffer: pixelBuffer, plane: 0))?
                .max(by: { $0.decisionMargin < $1.decisionMargin }) else {
            DispatchQueue.main.async { [weak self] in self?.latestDetection = nil }
            return
        }

        // Extract per-frame intrinsics if AVFoundation provides them.
        var pose: TagPose?
        if let attachment = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
            attachmentModeOut: nil
        ) as? Data, attachment.count == MemoryLayout<simd_float3x3>.size {
            let K = attachment.withUnsafeBytes { $0.load(as: simd_float3x3.self) }
            let intrinsics = CameraIntrinsics(
                fx: Double(K.columns.0.x),
                fy: Double(K.columns.1.y),
                cx: Double(K.columns.2.x),
                cy: Double(K.columns.2.y)
            )
            cachedIntrinsics = intrinsics
            pose = detection.estimatePose(intrinsics: intrinsics, tagSize: tagSize)
        } else if let cached = cachedIntrinsics {
            pose = detection.estimatePose(intrinsics: cached, tagSize: tagSize)
        }

        let snapshot = DetectionSnapshot(
            id: detection.id,
            decisionMargin: detection.decisionMargin,
            corners: detection.corners,
            colorFrameSize: CGSize(width: frameW, height: frameH),
            pose: pose
        )

        DispatchQueue.main.async { [weak self] in
            self?.latestDetection = snapshot
        }
    }
}
