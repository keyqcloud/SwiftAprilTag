//
//  CameraPreviewView.swift
//  AprilTagLive
//
//  AVCaptureVideoPreviewLayer wrapped for SwiftUI, with a CAShapeLayer overlay
//  that draws the detected tag's outer black-border polygon as the camera
//  streams. Uses AVCaptureVideoPreviewLayer.layerPointConverted to map sensor
//  pixel coordinates into view coordinates correctly across orientations,
//  mirroring, and aspect-fill cropping.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var session: TagDetectionSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session.captureSession
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.applyDetection(session.latestDetection)
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        private let overlayLayer = CAShapeLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            overlayLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.18).cgColor
            overlayLayer.strokeColor = UIColor.systemGreen.cgColor
            overlayLayer.lineWidth = 3
            overlayLayer.lineJoin = .round
            layer.addSublayer(overlayLayer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            overlayLayer.frame = bounds
        }

        func applyDetection(_ snapshot: TagDetectionSession.DetectionSnapshot?) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            defer { CATransaction.commit() }

            guard let snapshot = snapshot,
                  snapshot.colorFrameSize.width > 0,
                  snapshot.colorFrameSize.height > 0 else {
                overlayLayer.path = nil
                return
            }

            let path = UIBezierPath()
            for (i, corner) in snapshot.corners.enumerated() {
                let normalized = CGPoint(
                    x: corner.x / snapshot.colorFrameSize.width,
                    y: corner.y / snapshot.colorFrameSize.height
                )
                let viewPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalized)
                if i == 0 {
                    path.move(to: viewPoint)
                } else {
                    path.addLine(to: viewPoint)
                }
            }
            path.close()
            overlayLayer.path = path.cgPath
        }
    }
}
