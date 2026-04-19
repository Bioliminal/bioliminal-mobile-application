# Native MediaPipe Tasks Pose Integration

Story: (pending)
Agent: architect (multi-platform native + Dart channel)

## Context

`lib/features/camera/services/pose_detector.dart:46` throws `UnimplementedError` — the camera pipeline produces no landmarks today. The previous working `google_mlkit_pose_detection` integration was stripped during the auralink→bioliminal rebrand and not replaced.

Per `bioliminal-ops/strategy/model-commercial-viability-matrix-2026-04-16.md` §9, ML Kit is excluded from ship (beta SDK, no SLA). The documented commercial pick (matrix §4.4) is **MediaPipe BlazePose Full via direct MediaPipe Tasks** — `com.google.mediapipe:tasks-vision` on Android, `MediaPipeTasksVision` on iOS — wired through Flutter platform channels.

This plan is the Monday-critical Tier-C work. The Tier-B adaptive layer (capability probe, swappable detectors, `client_inference` upload) is mobile#45/46/47 — explicitly post-demo per Aaron's labels.

## Out of scope (post-demo)

- Variant switching (Lite/Heavy) — Full only for Monday. Aaron's `what-runs-where.md` confirms Full is tested for the bicep curl demo.
- GPU/NNAPI/CoreML delegate selection — CPU only for Monday (matches existing ML Kit baseline).
- Capability probe (mobile#45).
- `RepSegmenter` / `CompensationDetector` interface refactor (mobile#46).
- `client_inference` payload + `suggested_next_split` consumption (mobile#47).
- Multi-pose detection — `numPoses = 1`.
- Probe clip asset.

## Preconditions (must verify before starting)

- `android/app/src/main/kotlin/com/auralink/auralink/MainActivity.kt` has `package com.bioliminal.bioliminal` but `build.gradle.kts` namespace is `com.bioliminal.app`. The Android build is in an inconsistent state — verify `flutter run` on Android currently succeeds before adding plugin code, or fix the package/path alignment first as a prereq commit. Do not bundle that fix into this plan.
- `flutter pub get` succeeds.
- `assets/models/pose_landmarker_full.task` is present and matches checksum in `assets/models/CHECKSUMS.md`.
- A real Android device (API ≥24) and a real iOS device (iOS ≥16) are available for verification. Simulator/emulator is not sufficient — camera pipeline + native ML must be exercised on device.

## Architecture

```
Dart                                        Native (Android / iOS)
─────────────────────────────────────       ──────────────────────────────────────
CameraImage stream                          MediaPipe Tasks PoseLandmarker
  │                                           (VIDEO mode, single-pose, CPU)
  ▼                                                ▲
MediaPipePoseDetector.processFrame  ─────► MethodChannel ─────► PoseLandmarkerHelper
  (lib/features/camera/services/             "bioliminal.app/pose"     │
   pose_detector.dart)                       call: processFrame        │
                                                                        ▼
List<domain.PoseLandmark>  ◄──────────  channel response  ◄──── 33 NormalizedLandmark
```

**One channel, three methods.** No EventChannel — Dart drives frame submission synchronously per frame, native returns the landmark list. This pattern matches what `google_mlkit_pose_detection` did (and what works at 30fps in production). Keeps lifecycle simple, keeps backpressure on the Dart side where the existing `_handleFrame` already implements drop-while-busy.

**MediaPipe runs in VIDEO mode**, not LIVE_STREAM. VIDEO is synchronous + uses timestamp for inter-frame ROI tracking (the optimization that gives MediaPipe its frame rate). LIVE_STREAM would require an async callback bridge, which adds complexity for no benefit at our scale.

## Channel surface

```
MethodChannel: "bioliminal.app/pose"

  initialize({assetPath: String}) → bool
    Copies asset bytes from Flutter bundle to native filesystem,
    instantiates PoseLandmarker (Full, VIDEO, numPoses=1, CPU).
    Idempotent — second call replaces the existing instance.

  processFrame({
    bytes: Uint8List,         // raw plane bytes (NV21 on Android, BGRA on iOS)
    width: int,
    height: int,
    rotationDegrees: int,     // 0/90/180/270 — already lens-direction-corrected by Dart
    timestampMs: int,         // monotonic; required for VIDEO mode tracking
  }) → List<Map<String, double>>
    Returns 33 landmark maps: {x, y, z, visibility, presence}.
    Returns empty list if no pose detected (Dart drops the frame).

  dispose() → void
    Releases native resources.
```

Failure modes (initialize fails, asset copy fails, native exception during inference) surface as `PlatformException`, caught in Dart and mapped to a domain error. The camera pipeline drops the frame and continues.

## What changes

### Dart

| File | Change |
|---|---|
| `lib/features/camera/services/pose_detector.dart` | Replace `MediaPipePoseDetector.processFrame` body with channel call. Add lazy initialize on first frame. Implement `dispose()` to call channel `dispose`. Map channel response (`List<Map>`) to `List<domain.PoseLandmark>`. Drop frames where landmarks count != 33. |
| `lib/features/camera/services/pose_channel.dart` | New. Thin wrapper around `MethodChannel("bioliminal.app/pose")` exposing `initialize`, `processFrame`, `dispose`. Centralizes the channel name + payload shape so Android + iOS implementations have one Dart contract to satisfy. |
| `lib/features/camera/controllers/camera_controller.dart` | Verify `_handleFrame` (`:153–184`) passes `image.planes[0].bytes` (NV21 single-plane on Android) and `format`-appropriate bytes on iOS. The existing rotation logic stays. Add `imageFormatGroup: ImageFormatGroup.nv21` to the `CameraController` constructor on Android — see `camera_android_camerax` NV21 quirk in flutter/flutter#145961. |
| `test/features/camera/services/pose_detector_test.dart` | New. Mock the platform channel, assert serialization of payload + parsing of response. Existing `MockPoseDetector` covers higher-level tests. |

### Android

| File | Change |
|---|---|
| `android/app/build.gradle.kts` | Add `implementation("com.google.mediapipe:tasks-vision:0.10.14")` (or latest stable as of integration). Bump `minSdk = 24` if Flutter default is lower (MediaPipe Tasks requires API 24+). |
| `android/app/src/main/kotlin/com/bioliminal/app/pose/PoseLandmarkerHelper.kt` | New. Wraps `com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker`. Methods: `setup(assetPath: String)`, `detectForVideo(bytes, width, height, rotationDegrees, timestampMs): PoseLandmarkerResult?`, `close()`. Single-pose, VIDEO mode, CPU delegate. Handles asset copy from APK to filesystem on setup. |
| `android/app/src/main/kotlin/com/bioliminal/app/pose/NV21Converter.kt` | New. Converts NV21 `ByteArray` + dimensions + rotation → `MPImage` via `ByteBufferImageBuilder` (MediaPipe Tasks accepts NV21 directly). Encapsulates the rotation handling — MediaPipe expects the rotation as part of the image, not as a separate inference param. |
| `android/app/src/main/kotlin/com/bioliminal/app/pose/PosePlugin.kt` | New. Implements `FlutterPlugin` + `MethodCallHandler`. Registers channel `"bioliminal.app/pose"`. Routes `initialize` / `processFrame` / `dispose` to `PoseLandmarkerHelper`. Holds a single instance; serializes calls with a mutex (drop frame if previous still running — return empty list immediately). Maps `PoseLandmarkerResult` to `List<Map<String, Double>>`. |
| `android/app/src/main/kotlin/com/bioliminal/app/MainActivity.kt` | New (or rename existing). After the precondition fix, register `PosePlugin` via `flutterEngine.plugins.add(PosePlugin())` in `configureFlutterEngine`. |

### iOS

| File | Change |
|---|---|
| `ios/Podfile` | Add `pod 'MediaPipeTasksVision', '~> 0.10.14'` to the `Runner` target. Run `pod install`. |
| `ios/Runner/Pose/PoseLandmarkerHelper.swift` | New. Wraps `MPPPoseLandmarker`. Methods: `setup(assetPath: String)`, `detectForVideo(pixelBuffer, orientation, timestampMs) -> PoseLandmarkerResult?`, `close()`. VIDEO mode, single-pose, CPU delegate. |
| `ios/Runner/Pose/PixelBufferConverter.swift` | New. Converts BGRA8888 byte buffer + dimensions → `CVPixelBuffer` → `MPImage`. Encodes `rotationDegrees` as `UIImage.Orientation` (`.up`/`.right`/`.down`/`.left` — MediaPipe iOS uses orientation, not rotation degrees, and the mapping is non-obvious: 90° clockwise = `.right`, etc.). |
| `ios/Runner/Pose/PosePlugin.swift` | New. Implements `FlutterPlugin`. Registers channel `"bioliminal.app/pose"`. Routes `initialize` / `processFrame` / `dispose`. Single instance, serial dispatch queue (drop frame if busy). Maps `PoseLandmarkerResult.landmarks[0]` to `[[String: Double]]`. |
| `ios/Runner/AppDelegate.swift` | Register `PosePlugin` in the existing `didInitializeImplicitFlutterEngine` callback alongside `GeneratedPluginRegistrant.register`. |

## YUV / rotation / mirror handling — the non-obvious parts

**Android NV21 quirk.** `camera_android_camerax` (default since `camera 0.11`) returns `ImageFormatGroup.yuv420` even when you request `nv21` — but the bytes are NV21-laid-out (flutter/flutter#145961). Set `imageFormatGroup: ImageFormatGroup.nv21` explicitly in the `CameraController` constructor. On the Dart side this gives you a single-plane image (`image.planes[0].bytes`), passed straight through. On the Kotlin side, treat the bytes as NV21, build `MPImage` via `ByteBufferImageBuilder` with `MPImage.IMAGE_FORMAT_NV21`. Do not convert YUV→RGB in Dart — MediaPipe Tasks handles it natively.

**iOS BGRA.** `camera` plugin returns `ImageFormatGroup.bgra8888` by default on iOS, single plane. The bytes go straight into a `CVPixelBuffer` of `kCVPixelFormatType_32BGRA`, then `MPImage(pixelBuffer:orientation:)`.

**Rotation.** Existing `_handleFrame` (`camera_controller.dart:153–184`) computes `rotationDegrees` from `sensorOrientation` and `lensDirection` (front camera flips: `(360 - sensorOrientation) % 360`). The Dart side passes this integer to native. Android uses it directly via `MPImage` rotation; iOS encodes it as `UIImage.Orientation` per the table above.

**Mirror.** Front-camera horizontal flip is already handled in `skeleton_overlay.dart:transformLandmark` for the rendered overlay. MediaPipe's landmark output is in the **input image's** coordinate space (after rotation), so no mirror is needed before passing to the model — only at render time. Confirm this matches the existing skeleton overlay's expectations on a real device with the front camera.

## Lifecycle

- **Initialize** lazily on first `processFrame` call. The Dart-side `MediaPipePoseDetector` checks an `_initialized` flag, calls channel `initialize` if needed, then proceeds.
- **Dispose** explicitly when the Riverpod `poseDetectorProvider` is torn down (`providers.dart:78–82` already wires `ref.onDispose`). Dart calls channel `dispose`; native releases the `PoseLandmarker` instance.
- **Reentrancy.** If `processFrame` is called while a previous call is in flight, drop the new frame on the native side (return empty list immediately). The Dart `_handleFrame` already throttles by waiting for the previous future, so this is a defense-in-depth.
- **Hot reload.** Native plugin instances survive hot reload; the Dart-side `_initialized` flag may not. The first post-reload frame will re-call `initialize`, which is idempotent (replaces the existing instance).

## Asset access

MediaPipe Tasks loads the model from a filesystem path, not bundled bytes. Flutter assets are inside the APK / IPA. Both platforms need to copy on first `initialize`:

- **Android:** Read from `flutterAssets.getAssetFilePathByName("assets/models/pose_landmarker_full.task")` (via `FlutterPlugin.getFlutterAssets()`) → returns a path inside the APK. Copy to `context.filesDir / pose_landmarker_full.task` if not present, then pass that path to `BaseOptions.builder().setModelAssetPath(...)`.
- **iOS:** `Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task", inDirectory: "flutter_assets/assets/models")` returns a usable path directly (iOS bundle assets are filesystem-accessible). Pass straight to `MPPPoseLandmarkerOptions.modelAssetPath`.

Cache the resolved path on the native side to avoid repeating the lookup.

## Tasks

1. **Precondition:** verify Android build, fix `MainActivity` package/path/namespace alignment if needed (separate commit, not in this plan).
2. **Dart channel scaffold:** create `pose_channel.dart`, `pose_detector_test.dart` with mocked channel returning canned 33-landmark response. Wire `MediaPipePoseDetector` to call the channel. Tests pass against the mock.
3. **Android plugin scaffold:** add MediaPipe dep, bump minSdk if needed, create empty `PosePlugin` that returns `[]` for `processFrame` and `true` for `initialize`. Register in MainActivity. Verify `flutter run` on Android device boots without crashing.
4. **Android: real inference.** Implement `PoseLandmarkerHelper`, `NV21Converter`, asset copy. Wire `processFrame` to actually run inference. Verify on device: skeleton overlay renders, landmarks animate.
5. **iOS plugin scaffold:** add Pod, run `pod install`, create empty `PosePlugin` returning `[]`. Register in AppDelegate. Verify `flutter run` on iOS device boots.
6. **iOS: real inference.** Implement `PoseLandmarkerHelper`, `PixelBufferConverter`, asset path resolution. Wire `processFrame`. Verify on device.
7. **Cross-cutting:** front camera (mirror sanity check on both platforms), portrait + landscape (rotation correctness), backgrounding/foregrounding (lifecycle no-leak), session end-to-end (record set → upload → report renders).
8. **Verification pass:** see acceptance criteria below.

## Acceptance criteria

- `flutter pub get` succeeds. `flutter analyze` passes with no new errors.
- `flutter run` builds and launches on a real Android device (API ≥24) and a real iOS device (iOS ≥16).
- Camera screen renders a live skeleton overlay derived from real MediaPipe landmarks. Joints follow the user's body in real time on both front and back camera, in both portrait and landscape orientations.
- Sustained inference rate ≥20 fps on a Pixel 6 / iPhone 12 or equivalent. (Aaron's doc cites 30–50 ms/frame for ML Kit baseline; native should match or beat.)
- Recording a bicep curl set produces a `SessionPayload` with 33-landmark frames that the server accepts (returns `session_id`, `frames_received` matches Dart's frame count). The polled `Report` renders without crashing.
- The current `MockPoseDetector` test path still works (verify by running existing widget tests).
- No native resource leaks on repeated camera open/close cycles (manual verification: 10 cycles, watch memory in profiler).
- `pose_landmarker_full.task` is the only model loaded; no ML Kit dependency present in `pubspec.yaml` or in transitive dep tree.

## Verification

```bash
flutter pub get
flutter analyze
flutter test test/features/camera/services/pose_detector_test.dart
# manual:
flutter run --release -d <android-device>
# - exercise camera screen, verify skeleton renders, record a set, verify report
flutter run --release -d <ios-device>
# - same as above
```

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| MediaPipe Tasks Android version mismatch (the API has shifted across 0.10.x releases) | Pin to a known-good version (`0.10.14` as a starting point); follow the [Android pose landmarker guide](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker/android) verbatim for the helper class. |
| iOS Pod install bloats build (~50 MB) | One-time cost, accepted. CI cache the Pods directory. |
| MainActivity package inconsistency breaks the build before we touch it | Caught in preconditions step; fix as a separate commit before starting plugin work. |
| Front-camera rotation/mirror produces inverted skeleton | Test on device early (step 4 / step 6); compare to existing `skeleton_overlay.dart` expectations. The recent `hotfix/front-camera` commit suggests this area is fragile — read that commit before testing. |
| Channel serialization too slow at 30 fps (frame copy across boundary) | Profile early. Fallback: `BasicMessageChannel` with `BinaryCodec` if MethodChannel JSON encoding is the bottleneck. ML Kit's pattern works at 30 fps with this exact approach, so unlikely to be a problem. |
| Asset copy fails silently on Android (file path returned but APK extract didn't happen) | Verify file exists + matches checksum after copy; throw `PlatformException` if not. |
| MediaPipe min Android SDK > current minSdk | Bump `minSdk = 24` in `build.gradle.kts`. Verify no other Flutter deps require higher. |

## Honest timeline

Sequential focused work for one developer:

- Day 1: Dart scaffold + Android plugin scaffold (steps 2–3).
- Day 2: Android real inference + on-device verification (step 4).
- Day 3: iOS scaffold + Pod setup (step 5).
- Day 4: iOS real inference + on-device verification (step 6).
- Day 5: Cross-cutting + edge cases + acceptance pass (steps 7–8).

**5 focused days minimum** with debugging buffer. Today is 2026-04-19; demo is 2026-04-20. Native-by-Monday is not achievable for one developer at clinical-grade quality. The realistic Monday options are:

1. **Slip the demo by one week**, ship native correctly. Best architectural outcome.
2. **Ship Monday on a one-time exception** (community wrapper `flutter_pose_detection` or restored ML Kit) with the explicit commitment to land native within 5 working days post-demo. Acceptable iff tracked as a Tier-1 followup.
3. **Show the Monday demo without a live skeleton** — record a session with the existing stub returning zeros, demo the server pipeline + report rendering against a fixture. Honest about state, doesn't compromise architecture.

Decide which Monday path you're on before starting day 1.
