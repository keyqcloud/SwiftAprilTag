//
//  CameraIntrinsics+AVFoundation.swift
//  SwiftAprilTag
//
//  Copyright (c) KeyQ, Inc. (https://www.keyq.cloud)
//  Licensed under the MIT License. See LICENSE for details.
//

#if canImport(AVFoundation) && canImport(CoreGraphics)
import AVFoundation
import CoreGraphics

extension CameraIntrinsics {

    /// Construct camera intrinsics from AVFoundation's `AVCameraCalibrationData`,
    /// optionally rescaling to a target image size.
    ///
    /// `AVCameraCalibrationData.intrinsicMatrix` is reported in the pixel
    /// coordinate space of `intrinsicMatrixReferenceDimensions`. If you ran
    /// detection on a downsampled or differently-sized buffer (e.g. captured
    /// at the sensor's native resolution but processed at 1280×720), pass
    /// the actual image size you used as `imageSize` and this initializer
    /// rescales `fx`, `fy`, `cx`, `cy` proportionally.
    ///
    /// - Parameters:
    ///   - calibration: An `AVCameraCalibrationData` from
    ///     `AVDepthData.cameraCalibrationData` or
    ///     `AVCapturePhoto.cameraCalibrationData`.
    ///   - imageSize: The size of the image the detector ran on. If `nil`,
    ///     uses the calibration's reference dimensions and applies no scaling.
    public init(avCalibrationData calibration: AVCameraCalibrationData,
                imageSize: CGSize? = nil) {
        let K = calibration.intrinsicMatrix
        let refSize = calibration.intrinsicMatrixReferenceDimensions
        let target = imageSize ?? refSize
        let scaleX = Double(target.width) / Double(refSize.width)
        let scaleY = Double(target.height) / Double(refSize.height)
        self.init(
            fx: Double(K.columns.0.x) * scaleX,
            fy: Double(K.columns.1.y) * scaleY,
            cx: Double(K.columns.2.x) * scaleX,
            cy: Double(K.columns.2.y) * scaleY
        )
    }
}
#endif
