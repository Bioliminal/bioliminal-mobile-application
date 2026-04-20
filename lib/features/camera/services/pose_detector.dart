import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../../../domain/models.dart' as domain;
import 'pose_channel.dart';

/// Abstract pose detection interface for the Bioliminal Flutter app.
///
/// Implementations MUST return exactly 33 BlazePose landmarks per frame.
/// See `bioliminal-ops/operations/handover/mobile/model/blazepose_landmark_order.md`
/// for the canonical index → joint mapping.
abstract class PoseDetector {
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  });

  Future<void> dispose();
}

/// Real pose detector — BlazePose Full via direct MediaPipe Tasks.
///
/// Bridges to native MediaPipe Tasks via [PoseChannel]. Asset
/// `assets/models/pose_landmarker_full.task` (SHA-256 in
/// `assets/models/CHECKSUMS.md`) is loaded lazily on first frame.
///
/// Google ML Kit is excluded from ship (beta, no SLA) per the
/// model-commercial-viability matrix §9 — do not re-introduce
/// `google_mlkit_pose_detection` as the binding.
class MediaPipePoseDetector implements PoseDetector {
  MediaPipePoseDetector({
    this.assetPath = 'assets/models/pose_landmarker_full.task',
    PoseChannel? channel,
  }) : _channel = channel ?? PoseChannel();

  final String assetPath;
  final PoseChannel _channel;
  bool _initialized = false;
  int _consecutiveInitFailures = 0;

  /// Cap on init attempts — prevents a failing native init from looping at
  /// ~30fps when the camera stream is live.
  static const int _maxInitAttempts = 3;

  @override
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  }) async {
    if (!_initialized) {
      if (_consecutiveInitFailures >= _maxInitAttempts) return const [];
      try {
        _initialized = await _channel.initialize(assetPath: assetPath);
        if (_initialized) {
          _consecutiveInitFailures = 0;
        } else {
          _consecutiveInitFailures++;
        }
      } on PlatformException catch (e, stack) {
        _consecutiveInitFailures++;
        developer.log(
          'PoseChannel init failed',
          error: e,
          stackTrace: stack,
          name: 'MediaPipePoseDetector',
        );
        return const [];
      }
      if (!_initialized) return const [];
    }

    final plane = image.planes.first;
    final List<Map<String, double>> raw;
    try {
      raw = await _channel.processFrame(
        bytes: plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
        rotationDegrees: rotationDegrees,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
    } on PlatformException catch (e, stack) {
      developer.log(
        'PoseChannel processFrame failed',
        error: e,
        stackTrace: stack,
        name: 'MediaPipePoseDetector',
      );
      return const [];
    }

    // Drop partial detections — server 422s anything that isn't exactly 33.
    if (raw.length != 33) return const [];

    return raw
        .map(
          (m) => domain.PoseLandmark(
            x: m['x'] ?? 0,
            y: m['y'] ?? 0,
            z: m['z'] ?? 0,
            visibility: m['visibility'] ?? 0,
            presence: m['presence'] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      try {
        await _channel.dispose();
      } on PlatformException catch (e, stack) {
        developer.log(
          'PoseChannel dispose failed',
          error: e,
          stackTrace: stack,
          name: 'MediaPipePoseDetector',
        );
      }
      _initialized = false;
    }
  }
}

/// Mock implementation for unit tests. Returns static landmarks and avoids
/// native plugin calls.
class MockPoseDetector implements PoseDetector {
  @override
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  }) async {
    return List.generate(
      33,
      (idx) => const domain.PoseLandmark(
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.9,
        presence: 0.9,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    // No-op for mock
  }
}
