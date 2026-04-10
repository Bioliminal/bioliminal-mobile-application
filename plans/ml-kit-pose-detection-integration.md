# ML Kit Pose Detection Integration

Story: (pending)
Agent: quick-fixer

## Context

The app's core AI promise — real-time pose detection — currently runs on MockPoseEstimationService with synthetic data. This integrates the real google_mlkit_pose_detection package to process live camera frames and produce actual landmark data.

## What changes

| File | Change |
|---|---|
| `pubspec.yaml` | Uncomment `google_mlkit_pose_detection: ^0.11.0` |
| `lib/domain/services/mlkit_pose_estimation_service.dart` | New. Implements PoseEstimationService. Creates a PoseDetector instance. Converts CameraImage to InputImage (handles platform-specific format/rotation). Runs pose detection, maps 33 PoseLandmark to domain Landmark (normalizing x/y to 0-1 range using image dimensions, mapping visibility/inFrameLikelihood). Disposes PoseDetector on dispose(). |
| `lib/core/providers.dart` | Change poseEstimationServiceProvider to return MlKitPoseEstimationService by default. Add a `useMockPoseService` bool provider (defaults to false, can be overridden in tests via ProviderScope overrides) so mock remains available for testing. |
| `lib/features/camera/controllers/camera_controller.dart` | Update `_handleFrame` to call the pose service for each frame. Currently it's a no-op stub with a comment. Wire it to feed frames continuously — but throttle to avoid backpressure (skip frame if previous detection is still running). |

## Tasks

1. Uncomment ML Kit dependency in pubspec.yaml
2. Create MlKitPoseEstimationService with CameraImage → InputImage conversion and landmark mapping
3. Wire into providers.dart with mock fallback flag
4. Update AppCameraController._handleFrame for real frame processing with backpressure throttling

## Acceptance criteria

- google_mlkit_pose_detection is an active dependency (flutter pub get succeeds)
- MlKitPoseEstimationService.processFrame() accepts a CameraImage, runs ML Kit pose detection, and emits List<Landmark> with 33 entries
- Landmarks have x/y normalized to 0.0-1.0 range and visibility from ML Kit's inFrameLikelihood
- providers.dart defaults to MlKitPoseEstimationService; tests can override to mock via useMockPoseService
- _handleFrame processes frames with backpressure — skips if previous detection hasn't completed
- App compiles and runs on both iOS and Android

## Verification

- `flutter pub get` succeeds with ML Kit dependency
- `flutter analyze` passes with no new errors
- Existing tests pass (they use mock via provider override)
