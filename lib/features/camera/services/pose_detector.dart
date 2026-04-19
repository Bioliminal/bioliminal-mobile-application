import 'dart:async';

import 'package:camera/camera.dart';

import '../../../domain/models.dart' as domain;

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
/// PENDING INTEGRATION. The on-device asset
/// (`assets/models/pose_landmarker_full.task`, SHA-256 recorded in
/// `assets/models/CHECKSUMS.md`) is in the repo; the native binding still
/// needs to be wired. See the handover doc at
/// `bioliminal-ops/operations/handover/mobile/README.md` §3 for the
/// binding options (maintained MediaPipe Tasks Flutter binding, or
/// platform channels to the native MediaPipe Tasks API on Android + iOS).
///
/// Google ML Kit is excluded from ship (beta, no SLA) per the
/// model-commercial-viability matrix §9 — do not re-introduce
/// `google_mlkit_pose_detection` as the binding.
class MediaPipePoseDetector implements PoseDetector {
  MediaPipePoseDetector({
    this.assetPath = 'assets/models/pose_landmarker_full.task',
  });

  final String assetPath;

  @override
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  }) async {
    throw UnimplementedError(
      'MediaPipe Tasks binding not wired. Load $assetPath via the chosen '
      'MediaPipe Tasks Flutter binding or native platform channels, run '
      'inference on the CameraImage at $rotationDegrees° rotation, and '
      'map the 33 PoseLandmark outputs to domain.PoseLandmark with '
      'image-normalized x/y, hip-midpoint-relative z, and visibility + '
      'presence in [0, 1]. Drop partial detections (<33 landmarks) — '
      'the server 422s anything else.',
    );
  }

  @override
  Future<void> dispose() async {
    // No native resources held yet.
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
