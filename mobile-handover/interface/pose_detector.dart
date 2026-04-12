// Abstract pose detection interface for the AuraLink Flutter app.
//
// Why this file exists:
// The app should not bind directly to MediaPipe at the UI layer. We ship
// BlazePose at launch, but the pipeline plan (see
// docs/research/model-framework-recommendations-2026-04-10.md §2.1) keeps
// MoveNet Thunder and HRPose-small as alternates. Hiding the backend behind
// this interface means swapping models is a constructor change, not an app
// release.
//
// Every PoseDetector implementation MUST produce `PoseFrame` objects matching
// the server pydantic schema (33 BlazePose-ordered landmarks, normalized
// coordinates, visibility/presence in [0,1]).

import 'models.dart';

abstract class PoseDetector {
  /// Identifier written into SessionMetadata.model.
  /// Must match a string the server side recognizes. Current valid values:
  ///   "mediapipe_blazepose_full"
  ///   "movenet_thunder"       (reserved, not yet supported)
  ///   "hrpose_small"          (reserved, not yet supported)
  String get modelId;

  /// Initialize the underlying runtime (load .task / .tflite / .onnx,
  /// warm up the GPU delegate, etc.). Call once at app startup.
  Future<void> initialize();

  /// Process a single image frame and return 33 landmarks in canonical
  /// BlazePose order, or null if no person was detected with sufficient
  /// confidence.
  ///
  /// Implementations must remap their native output order to the
  /// BlazePose canonical order if it differs. See
  /// blazepose_landmark_order.md for the expected index layout.
  ///
  /// `imageBytes`, `width`, `height`, and `rotationDegrees` are passed
  /// through to the native runtime — use whatever your chosen camera
  /// plugin produces.
  Future<PoseFrame?> detect({
    required List<int> imageBytes,
    required int width,
    required int height,
    required int rotationDegrees,
    required int timestampMs,
  });

  /// Release native resources. Call on app shutdown and also when the user
  /// tears down a capture session to free the GPU delegate.
  Future<void> dispose();
}
