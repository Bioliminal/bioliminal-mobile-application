# InputImage rotation from camera sensor orientation

Story: (pending)
Agent: quick-fixer

## Context

MlKitPoseEstimationService hardcodes InputImageRotation.rotation0deg. ML Kit needs the correct rotation derived from the camera's sensorOrientation and lensDirection to produce accurate landmark coordinates, especially on Android where sensor orientation varies by device and front cameras mirror.

## What changes

| File | Change |
|---|---|
| `lib/domain/services/mlkit_pose_estimation_service.dart` | Add sensorOrientation (int) and lensDirection (CameraLensDirection) constructor params. Add static `_rotationFromSensor(int sensorOrientation, CameraLensDirection lens)` that maps degrees (0/90/180/270) to InputImageRotation, accounting for front camera compensation on Android. Use the computed rotation in `_convertCameraImage` instead of hardcoded rotation0deg. |
| `lib/core/providers.dart` | Add a `cameraDescriptionProvider` StateProvider<CameraDescription?> (initially null). Update poseEstimationServiceProvider to read cameraDescriptionProvider and pass sensorOrientation + lensDirection to MlKitPoseEstimationService constructor. If cameraDescription is null, default to 0/back. |
| `lib/features/camera/controllers/camera_controller.dart` | In requestPermission(), after selecting the camera, set cameraDescriptionProvider to the selected CameraDescription so the pose service picks up the correct orientation. |

## Tasks

1. Add constructor params and _rotationFromSensor to MlKitPoseEstimationService
2. Add cameraDescriptionProvider and wire into poseEstimationServiceProvider
3. Set cameraDescriptionProvider in AppCameraController.requestPermission()

## Acceptance criteria

- MlKitPoseEstimationService uses the actual camera sensor orientation, not hardcoded rotation0deg
- Front camera on Android gets compensated rotation (360 - sensorOrientation)
- Back camera uses sensorOrientation directly mapped to InputImageRotation
- Provider chain: camera selected → cameraDescriptionProvider set → poseEstimationServiceProvider rebuilds with correct rotation
- Existing mock path (useMockPoseService=true) unaffected

## Verification

- flutter analyze passes
- Existing tests pass (mock path doesn't use rotation)
