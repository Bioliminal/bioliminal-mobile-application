# Camera Pipeline + Setup
Story: story-1294
Agent: architect

## Context
Camera access, skeleton overlay via CustomPainter, progressive setup checklist, and per-joint confidence coloring. This is the visual foundation — everything the user sees during movement capture flows through these components. The camera controller owns the permission lifecycle and frame stream; the skeleton overlay renders landmarks in real time; the setup checklist gates the user into good capture conditions before screening begins.

Depends: story-1293 (Bootstrap — theme, providers, router, domain models)
Blocks: story-1295 (Screening flow consumes CameraView and setup state)

Files:
- lib/features/camera/views/camera_view.dart
- lib/features/camera/controllers/camera_controller.dart
- lib/features/camera/widgets/skeleton_overlay.dart
- lib/features/camera/widgets/setup_checklist.dart

## What changes
| File | Change |
|---|---|
| `lib/features/camera/controllers/camera_controller.dart` | New. Riverpod `AsyncNotifier` managing camera permission requests, `CameraController` lifecycle (initialize/dispose), frame streaming to `PoseEstimationService`, and exposure of current landmarks + camera state. |
| `lib/features/camera/views/camera_view.dart` | New. Full-screen camera preview with `CameraPreview` widget, `SkeletonOverlay` stacked on top, `SetupChecklist` overlay that dismisses when all checks pass, and permission-denied fallback UI. |
| `lib/features/camera/widgets/skeleton_overlay.dart` | New. `CustomPainter` that draws 33 BlazePose landmarks as circles and connects them with line segments per BlazePose topology. Each landmark/segment colored by visibility confidence using theme colors. |
| `lib/features/camera/widgets/setup_checklist.dart` | New. Progressive checklist widget — shows one requirement at a time (camera angle, distance, lighting, clothing). Each item shows instruction text, validates, and displays a green checkmark on pass. Exposes an `onAllPassed` callback. |

## Architecture (Claude)

**State management**: `AppCameraController` is a Riverpod `AsyncNotifier` that holds a `CameraState` (sealed class: `uninitialized | permissionDenied | ready | streaming | error`). The camera view watches this provider and renders accordingly.

**Data flow**:
```
CameraImage frame
  -> PoseEstimationService.processFrame(frame)  [via StreamProvider]
  -> Stream<List<Landmark>>
  -> SkeletonOverlay.paint(landmarks)
  -> Per-landmark confidence -> theme color lookup
```

The `AppCameraController` subscribes to the pose estimation stream and exposes `List<Landmark>` as a separate provider that `SkeletonOverlay` watches. This keeps the overlay reactive without coupling it to camera internals.

**Setup checklist** is independent state — a simple `StateNotifier<SetupChecklistState>` tracking which requirements have been validated. It sits above the camera preview as a semi-transparent overlay and dismisses itself when all four checks pass. The screening flow (story-1295) reads checklist completion state before allowing movement capture to begin.

**Coordinate mapping**: `SkeletonOverlay`'s `CustomPainter` receives the preview size and landmark list. Landmarks arrive in normalized [0,1] coordinates from MediaPipe; the painter scales them to the canvas size. Mirror-flip for front camera.

<!-- CODER_ONLY -->
## Read-only context
- presearch/bioliminal-product.md
- lib/domain/models.dart (from story-1293 — specifically `Landmark` with x, y, z, visibility fields)
- lib/core/theme.dart (from story-1293 — `confidenceHigh`, `confidenceMedium`, `confidenceLow` color definitions)
- lib/core/providers.dart (from story-1293 — `poseEstimationServiceProvider` registered here)

## Tasks
1. **CameraController state model** — Define `CameraState` as a sealed class with variants: `uninitialized`, `permissionDenied`, `ready(CameraController controller)`, `streaming(CameraController controller, List<Landmark> landmarks)`, `error(String message)`. Place in `camera_controller.dart`.

2. **Permission handling** — In `AppCameraController.build()`, check camera permission status. If not granted, request it. On grant, proceed to initialization. On permanent denial, emit `permissionDenied` state. On denial (non-permanent), show re-prompt UI. iOS: ensure `NSCameraUsageDescription` is documented as a setup requirement (do not modify Info.plist — that's a manual step). Android: use `camera` package's built-in runtime permission flow.

3. **Camera lifecycle** — On permission grant, initialize `CameraController` from the `camera` package with `ResolutionPreset.medium` and the back-facing camera (user faces phone propped up). Start image stream via `controller.startImageStream()`. On dispose, stop stream and dispose controller. Expose camera controller in state for `CameraPreview` widget.

4. **Pose estimation integration** — Pipe each `CameraImage` from the image stream into `PoseEstimationService.processFrame()`. Subscribe to the returned landmark stream. Update state with latest `List<Landmark>`. Expose landmarks via a separate Riverpod provider (`currentLandmarksProvider`) so overlay can watch independently without rebuilding on every camera state change.

5. **CameraView layout** — Build `CameraView` as a `ConsumerWidget`. Stack: (1) `CameraPreview` filling the screen, (2) `SkeletonOverlay` positioned to match preview dimensions, (3) `SetupChecklist` overlay (conditionally shown until all checks pass). Handle `permissionDenied` state with a centered message + "Open Settings" button. Handle `error` state with retry button.

6. **SkeletonOverlay CustomPainter** — Implement `SkeletonPainter` extending `CustomPainter`. Input: `List<Landmark>`, `Size previewSize`, `bool isFrontCamera`. Draw each of the 33 landmarks as a filled circle (radius 6). Draw line segments between connected landmarks per BlazePose topology (define the adjacency list as a const — e.g., left shoulder to left elbow, left elbow to left wrist, etc.). Color logic per landmark: visibility > 0.9 -> `confidenceHigh`, 0.7-0.9 -> `confidenceMedium`, < 0.7 -> `confidenceLow`. Segment color = lower confidence of its two endpoints. Wrap in a `CustomPaint` widget that takes landmarks from provider.

7. **BlazePose topology constant** — Define `blazePoseConnections` as a `List<(int, int)>` mapping landmark index pairs per the 33-point BlazePose model. Reference: nose(0), left eye inner(1), left eye(2), ..., left ankle(27), right ankle(28), left heel(29), right heel(30), left foot index(31), right foot index(32). Include all standard connections (face, torso, arms, legs).

8. **SetupChecklist widget** — `ConsumerStatefulWidget` with a `SetupChecklistNotifier` (Riverpod `StateNotifier`). State: `SetupChecklistState` with four bools (angleOk, distanceOk, lightingOk, clothingOk) and `currentStep` index. Display one requirement at a time with: instruction text, illustration description area, and a "Done" / "Confirm" button. On confirm, mark current step passed (green checkmark), advance to next. When all four pass, fire `onAllPassed` callback and fade out. Requirements in order: (1) Camera angle — "Place your phone at waist height, 6-8 feet away" (2) Distance — "Step back until your full body is visible" (3) Lighting — "Make sure you're well-lit from the front" (4) Clothing — "Wear fitted clothing so joints are visible".

9. **Coordinate transform utility** — Helper function `Offset transformLandmark(Landmark lm, Size canvasSize, bool mirror)` that converts normalized [0,1] landmark coordinates to canvas pixel coordinates, with optional horizontal flip for front camera.

10. **Provider wiring** — In `camera_controller.dart`, export: `appCameraControllerProvider` (the AsyncNotifier provider), `currentLandmarksProvider` (derived provider selecting landmarks from camera state), `setupChecklistProvider` (the StateNotifier provider). These will be registered/re-exported from `lib/core/providers.dart` by the coder if needed.
<!-- END_CODER_ONLY -->

## Contract

### AppCameraController (AsyncNotifier)
```dart
// Provider
final appCameraControllerProvider = AsyncNotifierProvider<AppCameraController, CameraState>(...);

// Methods
Future<void> requestPermission();
Future<void> startStreaming();
Future<void> stopStreaming();
void dispose();
```

### CameraState (sealed)
```dart
sealed class CameraState {}
class CameraUninitialized extends CameraState {}
class CameraPermissionDenied extends CameraState { final bool permanent; }
class CameraReady extends CameraState { final CameraController controller; }
class CameraStreaming extends CameraState { final CameraController controller; final List<Landmark> landmarks; }
class CameraError extends CameraState { final String message; }
```

### currentLandmarksProvider
```dart
final currentLandmarksProvider = Provider<List<Landmark>>((ref) => ...);
```

### SkeletonOverlay
```dart
class SkeletonOverlay extends ConsumerWidget {
  // Reads currentLandmarksProvider internally
  // Requires ancestor to provide preview size via LayoutBuilder
}
```

### SkeletonPainter
```dart
class SkeletonPainter extends CustomPainter {
  final List<Landmark> landmarks;
  final Size previewSize;
  final bool isFrontCamera;
  // Colors resolved from theme
}
```

### SetupChecklist
```dart
class SetupChecklist extends ConsumerStatefulWidget {
  final VoidCallback onAllPassed;
}

// State
class SetupChecklistState {
  final bool angleOk;
  final bool distanceOk;
  final bool lightingOk;
  final bool clothingOk;
  final int currentStep;
  bool get allPassed;
}

final setupChecklistProvider = StateNotifierProvider<SetupChecklistNotifier, SetupChecklistState>(...);
```

## Acceptance criteria
- User opens camera view for the first time -> system requests camera permission -> on grant, live preview appears full-screen
- User denies camera permission -> view shows explanation text and a button to re-request (or open settings if permanently denied)
- User grants permission -> camera streams frames -> skeleton overlay draws colored landmarks on top of the live preview in real time
- Landmark with visibility > 0.9 renders as green circle; 0.7-0.9 as yellow; < 0.7 as red
- Line segments connecting landmarks use the lower confidence color of their two endpoints
- Skeleton overlay correctly scales normalized landmark coordinates to match the camera preview dimensions
- On first camera open, setup checklist appears over the preview showing the first requirement (camera angle)
- User confirms each setup requirement in sequence -> green checkmark appears -> next requirement shown
- After all four requirements confirmed, checklist fades out and full camera view with skeleton overlay is usable
- Screening flow (story-1295) can read `setupChecklistProvider.allPassed` to gate movement capture
- When app is backgrounded or view is disposed, camera stream and controller are properly released (no resource leaks)
- If camera encounters a runtime error (e.g., hardware failure), error state is shown with a retry option

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- CameraState sealed class covers all permission and lifecycle states
- SkeletonPainter draws all 33 landmarks and connects them per BlazePose topology
- Confidence color thresholds match spec (0.9 / 0.7 boundaries)
- SetupChecklist progresses through exactly 4 requirements in order
- Providers are properly scoped and disposed
<!-- TESTER_ONLY -->
test_files: test/features/camera/controllers/camera_controller_test.dart, test/features/camera/widgets/skeleton_overlay_test.dart

### camera_controller_test.dart
- Test state transitions: uninitialized -> permissionDenied (on denial)
- Test state transitions: uninitialized -> ready (on permission grant, mock camera)
- Test state transitions: ready -> streaming (when startStreaming called, mock pose service emits landmarks)
- Test that currentLandmarksProvider updates when CameraStreaming state changes
- Test that stopStreaming returns to ready state
- Test permission re-request after non-permanent denial

### skeleton_overlay_test.dart
- Test SkeletonPainter draws correct number of circles (33) given 33 landmarks
- Test confidence color selection: landmark with visibility 0.95 -> confidenceHigh color
- Test confidence color selection: landmark with visibility 0.8 -> confidenceMedium color
- Test confidence color selection: landmark with visibility 0.5 -> confidenceLow color
- Test segment color uses minimum confidence of its two endpoint landmarks
- Test coordinate transform: normalized (0.5, 0.5) maps to canvas center
- Test coordinate transform with mirror flip: x is horizontally inverted
- Test that painter handles empty landmark list without error
<!-- END_TESTER_ONLY -->
