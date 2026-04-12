// Reference implementation of PoseDetector using MediaPipe Tasks.
//
// NOT A COMPLETE IMPLEMENTATION — this is a skeleton that shows the
// contract the real Flutter code needs to satisfy. The teammate fills in
// the platform channels / plugin calls for whichever MediaPipe Tasks
// Flutter binding they pick.
//
// Recommended plugin options (pick one, benchmark, stick with it):
//   1. `flutter_mediapipe_pose` (if maintained)
//   2. `google_mlkit_pose_detection` — ML Kit wraps BlazePose for both
//      Android and iOS. Easiest path, slightly behind MediaPipe Tasks for
//      feature parity.
//   3. Direct MediaPipe Tasks API via platform channel — most flexibility,
//      most work, but you can drop in new .task files without changing app
//      code.
//
// Landmark order: MediaPipe Tasks and ML Kit both return the 33 canonical
// BlazePose landmarks in the standard order documented at
// https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker
// The mapping lines up 1:1 with this package's
// blazepose_landmark_order.md — no remapping required for those plugins.

import 'models.dart';
import 'pose_detector.dart';

class MediaPipePoseDetector implements PoseDetector {
  MediaPipePoseDetector({
    this.assetPath = 'assets/models/pose_landmarker_full.task',
    this.minPoseDetectionConfidence = 0.5,
    this.minPosePresenceConfidence = 0.5,
    this.minTrackingConfidence = 0.5,
  });

  /// Path to the .task file bundled with the app. See model/DOWNLOAD.md for
  /// where to fetch it and how to register it in pubspec.yaml.
  final String assetPath;

  final double minPoseDetectionConfidence;
  final double minPosePresenceConfidence;
  final double minTrackingConfidence;

  @override
  String get modelId => 'mediapipe_blazepose_full';

  @override
  Future<void> initialize() async {
    // TODO(phone-teammate): load the .task file via the chosen plugin.
    //
    // Example sketch with the MediaPipe Tasks Flutter binding (pseudo-code):
    //
    //   final options = PoseLandmarkerOptions(
    //     baseOptions: BaseOptions(modelAssetPath: assetPath),
    //     runningMode: RunningMode.liveStream,
    //     minPoseDetectionConfidence: minPoseDetectionConfidence,
    //     minPosePresenceConfidence: minPosePresenceConfidence,
    //     minTrackingConfidence: minTrackingConfidence,
    //     outputSegmentationMasks: false,
    //   );
    //   _landmarker = await PoseLandmarker.create(options);
    throw UnimplementedError('wire up the MediaPipe Tasks binding');
  }

  @override
  Future<PoseFrame?> detect({
    required List<int> imageBytes,
    required int width,
    required int height,
    required int rotationDegrees,
    required int timestampMs,
  }) async {
    // TODO(phone-teammate): run inference, convert output to PoseFrame.
    //
    // Every implementation MUST:
    //   1. Produce exactly 33 landmarks or return null (no partial frames).
    //   2. Clamp visibility and presence into [0, 1]. MediaPipe already
    //      returns sigmoid outputs, but ML Kit returns [0, 1] presence and
    //      visibility separately — both need to match the server schema.
    //   3. Use image-normalized coordinates for x, y (BlazePose default).
    //   4. Use hip-midpoint-relative z (BlazePose default).
    throw UnimplementedError('wire up inference + conversion');
  }

  @override
  Future<void> dispose() async {
    // TODO(phone-teammate): release native resources.
  }
}
