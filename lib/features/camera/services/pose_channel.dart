import 'package:flutter/services.dart';

/// Dart wrapper around the native MediaPipe Tasks pose channel.
///
/// Channel name: `bioliminal.app/pose`. Native implementations live at
/// `android/app/src/main/kotlin/com/bioliminal/app/pose/` (Kotlin) and
/// `ios/Runner/Pose/` (Swift). One MethodChannel, three methods.
class PoseChannel {
  PoseChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'bioliminal.app/pose';

  final MethodChannel _channel;

  /// Load the asset and instantiate the native PoseLandmarker.
  /// Idempotent — second call replaces the existing instance on native side.
  Future<bool> initialize({
    required String assetPath,
    required String delegate,
  }) async {
    final ok = await _channel.invokeMethod<bool>('initialize', {
      'assetPath': assetPath,
      'delegate': delegate,
    });
    return ok ?? false;
  }

  /// Run inference on a single frame. Returns 33 landmark maps when a pose
  /// is detected, or an empty list when no pose is found OR when native is
  /// already processing a previous frame (drop-while-busy on native side).
  Future<List<Map<String, double>>> processFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int rotationDegrees,
    required int timestampMs,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>('processFrame', {
      'bytes': bytes,
      'width': width,
      'height': height,
      'bytesPerRow': bytesPerRow,
      'rotationDegrees': rotationDegrees,
      'timestampMs': timestampMs,
    });
    if (raw == null) return const [];
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map(
          (m) => m.map<String, double>(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ),
        )
        .toList(growable: false);
  }

  Future<void> dispose() async {
    await _channel.invokeMethod<void>('dispose');
  }
}
