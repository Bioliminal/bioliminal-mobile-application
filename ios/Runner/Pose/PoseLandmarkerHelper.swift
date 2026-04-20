import CoreVideo
import Foundation
import MediaPipeTasksVision
import UIKit

/// Wraps MediaPipe Tasks PoseLandmarker for the bicep-curl screening flow.
///
/// VIDEO mode, single pose, CPU delegate. BGRA8888 frames from the Flutter
/// `camera` plugin become CVPixelBuffers, then MPImage with the right
/// orientation derived from the camera rotation.
final class PoseLandmarkerHelper {

    private var landmarker: PoseLandmarker?

    func setup(modelAssetPath: String, delegate: String) throws {
        close()
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelAssetPath
        switch delegate.lowercased() {
        case "coreml":
            options.baseOptions.delegate = .CoreML
        case "gpu":
            options.baseOptions.delegate = .GPU
        default:
            options.baseOptions.delegate = .CPU
        }
        options.runningMode = .video
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        landmarker = try PoseLandmarker(options: options)
    }

    /// Run inference on a single frame. Returns 33 landmark dicts when a
    /// pose is found, an empty list otherwise.
    func detectForVideo(
        bgra: Data,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        rotationDegrees: Int,
        timestampMs: Int
    ) -> [[String: Double]] {
        guard let landmarker = self.landmarker else { return [] }
        guard let pixelBuffer = makePixelBuffer(
            bgra: bgra,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        ) else { return [] }

        let orientation = uiOrientation(for: rotationDegrees)

        do {
            let mpImage = try MPImage(pixelBuffer: pixelBuffer, orientation: orientation)
            let result = try landmarker.detect(
                videoFrame: mpImage,
                timestampInMilliseconds: timestampMs
            )
            return mapResult(result)
        } catch {
            return []
        }
    }

    func close() {
        landmarker = nil
    }

    // MARK: - Helpers

    private func makePixelBuffer(
        bgra: Data,
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: CFDictionary = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ] as CFDictionary
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pb = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        let dest = CVPixelBufferGetBaseAddress(pb)
        let destStride = CVPixelBufferGetBytesPerRow(pb)

        bgra.withUnsafeBytes { (rawBuf: UnsafeRawBufferPointer) in
            guard let src = rawBuf.baseAddress else { return }
            if destStride == bytesPerRow {
                memcpy(dest, src, height * bytesPerRow)
            } else {
                // Source and destination strides differ — copy row by row.
                let copyBytes = min(destStride, bytesPerRow)
                for row in 0..<height {
                    memcpy(
                        dest!.advanced(by: row * destStride),
                        src.advanced(by: row * bytesPerRow),
                        copyBytes
                    )
                }
            }
        }
        return pb
    }

    /// Maps a 0/90/180/270° clockwise rotation to the UIImage orientation
    /// MediaPipe uses to know how to rotate the input to upright.
    private func uiOrientation(for rotationDegrees: Int) -> UIImage.Orientation {
        switch ((rotationDegrees % 360) + 360) % 360 {
        case 90: return .right
        case 180: return .down
        case 270: return .left
        default: return .up
        }
    }

    private func mapResult(_ result: PoseLandmarkerResult) -> [[String: Double]] {
        guard let firstPose = result.landmarks.first else { return [] }
        return firstPose.map { l in
            [
                "x": Double(l.x),
                "y": Double(l.y),
                "z": Double(l.z),
                "visibility": Double(truncating: l.visibility ?? 0),
                "presence": Double(truncating: l.presence ?? 0),
            ]
        }
    }
}
