package com.bioliminal.app.pose

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.ImageProcessingOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.io.ByteArrayOutputStream

/**
 * Wraps MediaPipe Tasks PoseLandmarker for the bicep-curl screening flow.
 *
 * VIDEO mode, single pose, CPU delegate. NV21 frames from the Flutter
 * `camera` plugin are converted to a Bitmap (via YuvImage→JPEG round-trip
 * — known perf cost ~20–30ms/frame on a Pixel 6; revisit post-demo with
 * a direct YUV→RGB path if the budget needs it).
 *
 * Rotation is handled by MediaPipe via [ImageProcessingOptions], not by
 * rotating the bitmap manually.
 */
class PoseLandmarkerHelper(private val context: Context) {

    private var landmarker: PoseLandmarker? = null

    fun setup(modelAssetPath: String, delegate: String) {
        close()
        val mpDelegate = when (delegate.lowercase()) {
            "gpu" -> Delegate.GPU
            else -> Delegate.CPU  // "cpu" and any unrecognized token default to CPU
        }
        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(
                BaseOptions.builder()
                    .setModelAssetPath(modelAssetPath)
                    .setDelegate(mpDelegate)
                    .build()
            )
            .setRunningMode(RunningMode.VIDEO)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .build()
        landmarker = PoseLandmarker.createFromOptions(context, options)
    }

    /**
     * Runs inference on a single frame. Returns the first pose's 33
     * landmarks as a list of {x, y, z, visibility, presence} maps, or an
     * empty list when no pose is detected or the helper is not initialized.
     */
    fun detectForVideo(
        nv21: ByteArray,
        width: Int,
        height: Int,
        rotationDegrees: Int,
        timestampMs: Long,
    ): List<Map<String, Double>> {
        val landmarker = this.landmarker ?: return emptyList()
        val bitmap = nv21ToBitmap(nv21, width, height) ?: return emptyList()
        val mpImage = BitmapImageBuilder(bitmap).build()
        val processingOptions = ImageProcessingOptions.builder()
            .setRotationDegrees(rotationDegrees)
            .build()

        val result: PoseLandmarkerResult = landmarker.detectForVideo(
            mpImage,
            processingOptions,
            timestampMs,
        )

        return mapResult(result)
    }

    fun close() {
        landmarker?.close()
        landmarker = null
    }

    private fun nv21ToBitmap(nv21: ByteArray, width: Int, height: Int): Bitmap? {
        return try {
            val yuv = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            val out = ByteArrayOutputStream()
            yuv.compressToJpeg(Rect(0, 0, width, height), 90, out)
            val bytes = out.toByteArray()
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (_: Exception) {
            null
        }
    }

    private fun mapResult(result: PoseLandmarkerResult): List<Map<String, Double>> {
        // landmarks() returns one entry per detected pose. We configured
        // numPoses=1, so take the first if present.
        val poses = result.landmarks()
        if (poses.isEmpty()) return emptyList()
        val landmarks = poses[0]
        // The server requires exactly 33; let the Dart side drop partials.
        return landmarks.map { l ->
            mapOf(
                "x" to l.x().toDouble(),
                "y" to l.y().toDouble(),
                "z" to l.z().toDouble(),
                "visibility" to (l.visibility().orElse(0f)).toDouble(),
                "presence" to (l.presence().orElse(0f)).toDouble(),
            )
        }
    }
}
