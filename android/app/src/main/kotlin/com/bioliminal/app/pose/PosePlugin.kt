package com.bioliminal.app.pose

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Flutter plugin bridging Dart → native MediaPipe Tasks PoseLandmarker.
 *
 * Channel: `bioliminal.app/pose`. Inference runs on a single-threaded
 * background executor; concurrent calls drop the new frame (defense in
 * depth — Dart side also drops while busy).
 */
class PosePlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "bioliminal.app/pose"
    }

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var flutterAssets: FlutterPlugin.FlutterAssets? = null
    private var helper: PoseLandmarkerHelper? = null
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val isProcessing = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterAssets = binding.flutterAssets
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).apply {
            setMethodCallHandler(this@PosePlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        executor.shutdown()
        helper?.close()
        helper = null
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
        flutterAssets = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "processFrame" -> handleProcessFrame(call, result)
            "dispose" -> handleDispose(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val ctx = context
        val assets = flutterAssets
        val assetPath = call.argument<String>("assetPath")
        if (ctx == null || assets == null || assetPath == null) {
            result.success(false)
            return
        }
        // Resolve Flutter asset to the path MediaPipe can read via AssetManager.
        val resolved = assets.getAssetFilePathByName(assetPath)
        executor.submit {
            try {
                val newHelper = PoseLandmarkerHelper(ctx).apply { setup(resolved) }
                helper?.close()
                helper = newHelper
                replyOnMain(result, true)
            } catch (e: Exception) {
                replyOnMain(result, false)
            }
        }
    }

    private fun handleProcessFrame(call: MethodCall, result: Result) {
        val helper = this.helper
        if (helper == null) {
            result.success(emptyList<Map<String, Double>>())
            return
        }
        if (!isProcessing.compareAndSet(false, true)) {
            result.success(emptyList<Map<String, Double>>())
            return
        }

        val bytes = call.argument<ByteArray>("bytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val rotationDegrees = call.argument<Int>("rotationDegrees")
        val timestampMs = (call.argument<Number>("timestampMs"))?.toLong()

        if (bytes == null || width == null || height == null ||
            rotationDegrees == null || timestampMs == null
        ) {
            isProcessing.set(false)
            result.success(emptyList<Map<String, Double>>())
            return
        }

        executor.submit {
            try {
                val landmarks = helper.detectForVideo(
                    bytes, width, height, rotationDegrees, timestampMs,
                )
                replyOnMain(result, landmarks)
            } catch (_: Exception) {
                replyOnMain(result, emptyList<Map<String, Double>>())
            } finally {
                isProcessing.set(false)
            }
        }
    }

    private fun handleDispose(result: Result) {
        executor.submit {
            helper?.close()
            helper = null
            replyOnMain(result, null)
        }
    }

    private fun replyOnMain(result: Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }
}
