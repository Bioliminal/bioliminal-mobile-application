# Camera Lifecycle Fixes
Story: story-1303
Agent: architect
Audit findings: F-007, F-008

## Context
Three bugs in the camera permission and lifecycle layer, all identified in AUDIT.md:

1. **Dispose-before-reinit (F-007)**: `didChangeAppLifecycleState(resumed)` calls `requestPermission()` which creates a new `CameraController` without disposing the old one. Leaks the previous controller.
2. **Open Settings (F-008)**: When camera permission is permanently denied, the "Open Settings" button calls `requestPermission()` (which silently fails again) instead of opening the OS app settings page.
3. **ref.read() in dispose() (F-007)**: `_CameraViewState.dispose()` calls `ref.read(appCameraControllerProvider.notifier).disposeCamera()`. If ProviderScope is already torn down, this throws.

Depends: story-1306 adds `app_settings` to pubspec.yaml (this story uses it, does not add it).
Does NOT depend on story-1301 — the ChainMapper/AngleCalculator renames don't touch camera files.

Files:
- lib/features/camera/controllers/camera_controller.dart
- lib/features/camera/views/camera_view.dart

## What changes
| File | Change |
|---|---|
| `camera_controller.dart` | Add `disposeCamera()` call at the top of `requestPermission()` before creating a new controller. This makes re-init safe from any call site. |
| `camera_view.dart` | (1) Capture notifier reference in `initState` and use it in `dispose()` instead of calling `ref.read()`. (2) Import `app_settings` and pass `AppSettings.openAppSettings` as the `onRetry` callback for `_PermissionDeniedView` when `permanent == true`. (3) In `didChangeAppLifecycleState(resumed)`, no change needed since `requestPermission()` now self-disposes. |

## Architecture

**Dispose-before-reinit**: The fix goes in `AppCameraController.requestPermission()` itself rather than in every call site. At the top of the method, dispose the existing `_cameraController` if non-null. This makes the method idempotent — calling it from `initState`, `resumed`, or retry buttons all behave correctly without caller coordination.

**ref.read() in dispose()**: Store the notifier in a local field (`late final _notifier`) assigned in `initState` (after the microtask fires). Use that field in `dispose()`. The notifier object itself outlives the widget (it's owned by the provider), so this is safe even after ProviderScope teardown.

**Open Settings**: `_PermissionDeniedView` already receives an `onRetry` callback. The fix is at the call site in `CameraView.build()`: when `permanent == true`, pass a callback that calls `AppSettings.openAppSettings()` instead of `requestPermission()`. No changes to `_PermissionDeniedView` itself.

<!-- CODER_ONLY -->
## Read-only context
- AUDIT.md (F-007, F-008 — the bugs being fixed)
- lib/core/providers.dart (imports, no changes needed)
- pubspec.yaml (story-1306 adds app_settings before this story runs)

## Tasks
1. **Dispose old controller in requestPermission()** — At the top of `AppCameraController.requestPermission()`, before `state = AsyncValue.loading()`, call: stop image stream if active, cancel landmark subscription, dispose `_cameraController`, null it out. Extract this into a private `_releaseCamera()` method that both `requestPermission()` and `disposeCamera()` call to avoid duplication.

2. **Fix ref.read() in dispose()** — In `_CameraViewState`, add a `late final AppCameraController _notifier` field. Assign it in `initState` via `ref.read(appCameraControllerProvider.notifier)`. In `dispose()`, call `_notifier.disposeCamera()` instead of `ref.read(...)`.

3. **Wire openAppSettings for permanent denial** — In `camera_view.dart`, add `import 'package:app_settings/app_settings.dart';`. In the `CameraPermissionDenied` branch of `build()`, when `permanent == true`, pass `onRetry: () => AppSettings.openAppSettings()` instead of `requestPermission()`.
<!-- END_CODER_ONLY -->

## Contract

### AppCameraController (changed methods)
```dart
class AppCameraController extends AsyncNotifier<CameraState> {
  // NEW — shared teardown, called by requestPermission() and disposeCamera()
  Future<void> _releaseCamera();

  // CHANGED — now calls _releaseCamera() before re-init
  Future<void> requestPermission();

  // CHANGED — delegates to _releaseCamera()
  void disposeCamera();
}
```

### _CameraViewState (changed fields)
```dart
class _CameraViewState extends ConsumerState<CameraView>
    with WidgetsBindingObserver {
  // NEW — captured in initState, used in dispose()
  late final AppCameraController _notifier;
}
```

### _PermissionDeniedView — no signature changes
Callback behavior changes at the call site only.

## Acceptance criteria
- Given the app resumes from background while camera is active, when the lifecycle triggers `resumed`, then the old CameraController is disposed before the new one initializes (no leaked controllers)
- Given camera permission is permanently denied, when the user taps "Open Settings", then the OS app settings page opens (not a silent re-request)
- Given the user navigates away from CameraView causing widget disposal, when `dispose()` runs after ProviderScope teardown, then no exception is thrown
- Given the user denies permission non-permanently, when the user taps "Grant Access", then `requestPermission()` is called (existing behavior preserved)
- Given `requestPermission()` is called when no camera was previously initialized, then it proceeds normally without errors from the dispose-first logic

## Verification
- Confirm `_releaseCamera()` stops image stream, cancels subscription, disposes controller, and nulls the field
- Confirm `requestPermission()` calls `_releaseCamera()` before `state = AsyncValue.loading()`
- Confirm `disposeCamera()` delegates to `_releaseCamera()` (no duplicated teardown logic)
- Confirm `_notifier` field is assigned exactly once in `initState`
- Confirm `dispose()` uses `_notifier` not `ref.read()`
- Confirm `app_settings` import is present and `AppSettings.openAppSettings()` is wired to the permanent denial branch
- No changes outside the two write files
