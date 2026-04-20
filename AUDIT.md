# Bioliminal Mobile — Code Audit

**Status:** Draft
**Created:** 2026-04-19
**Owner:** kelsi.andrews
**Audited by:** Claude Sonnet 4.6

---

## Executive Summary

The codebase is in genuinely good shape for a capstone project. Architecture is clean: sealed-class state machines in Notifier controllers, proper lifecycle separation in services, sensible feature slicing. The platform channel implementation (both Android Kotlin and iOS Swift) is correct and production-quality. Riverpod 3 usage is largely well-applied.

Four issues stand out as worthy of fix before a real demo: a 30fps full-tree rebuild in `BicepCurlView` that will burn battery and cause jank on older devices, a history view that goes stale after completing a set, a crash path when `CompensationDetector.buildReference` is called with zero frames, and the release build still signing with debug keys. Everything else is medium-to-low severity.

**Overall score: 7/10**

---

## Widget Tree & Performance

### [HIGH] BicepCurlView rebuilds its full widget tree at ~30fps

**File:** `lib/features/bicep_curl/views/bicep_curl_view.dart`, line 183

`BicepCurlView.build` watches `appCameraControllerProvider`. `AppCameraController.updateLandmarks` creates a new `AsyncData(CameraStreaming(...))` on every processed frame (lines 219–222 of `camera_controller.dart`). Because equality is reference-based, every frame triggers a rebuild of the entire `Scaffold` — top bar, HUD center, HUD bottom, all of it — at ~30fps during a live session.

The only part of `build` that actually *needs* frame-rate updates is the `SkeletonOverlay` (already a separate `ConsumerWidget` watching `currentLandmarksProvider`). The `_CoverCameraPreview` widget just holds a stable `CameraController` ref. Nothing else in the tree changes at 30fps.

**Fix:** Remove the `appCameraControllerProvider` watch from `BicepCurlView.build`. Replace with a selector that only fires on streaming-state changes:

```dart
// In build():
// REMOVE: final cameraAsync = ref.watch(appCameraControllerProvider);

// Replaces it — fires only when the bool changes, not every frame:
final isStreaming = ref.watch(
  appCameraControllerProvider.select(
    (v) => v.value is CameraStreaming,
  ),
);
```

The stable `CameraController` reference can be captured once in `_bootstrapCamera` and stored in state, so `_cameraStack` no longer needs to pull it from the provider.

---

### [MEDIUM] `SkeletonOverlay` lacks a `RepaintBoundary`

**File:** `lib/features/camera/widgets/skeleton_overlay.dart`

`SkeletonOverlay` runs `CustomPaint` + `SkeletonPainter` on every landmark update (~30fps). Nothing isolates it from triggering ancestor repaints. Wrapping it in `RepaintBoundary` confines raster work to the overlay layer.

```dart
return RepaintBoundary(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return CustomPaint(
        size: size,
        painter: SkeletonPainter(
          landmarks: landmarks,
          previewSize: size,
          isFrontCamera: isFrontCamera,
          isPremium: isPremium,
        ),
      );
    },
  ),
);
```

---

### [MEDIUM] `Paint` object allocated inside `SkeletonPainter.paint` on every repaint

**File:** `lib/features/camera/widgets/skeleton_overlay.dart`, lines 80–85

A new `Paint` is created for every segment inside `paint()`. At 30fps with 35 connections that is ~1050 `Paint` allocations per second — steady GC pressure on mobile. Since `color` varies per segment, keep one `Paint` instance and mutate its `color` field:

```dart
// Promote to field on SkeletonPainter:
final _segmentPaint = Paint()
  ..strokeWidth = _segmentStrokeWidth
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

// In paint():
_segmentPaint.color = segmentColor;
canvas.drawLine(startPt, endPt, _segmentPaint);
```

---

### [LOW] History list does not refresh after a new session is saved

**File:** `lib/features/history/views/history_view.dart`, line 12–14

```dart
final _sessionRecordsProvider = FutureProvider.autoDispose<List<SessionRecord>>(
  (ref) {
    return ref.read(localStorageServiceProvider).listSessionRecords();
  },
);
```

`_sessionRecordsProvider` is `autoDispose`, which means it disposes when no widget watches it. Because `HistoryView` lives inside a `StatefulShellRoute` and stays mounted while the user is on `/bicep-curl/debrief/:id`, the provider never disposes and never re-runs. The history list goes stale after completing a set — the new session doesn't appear until the app is relaunched.

**Fix:** Invalidate `_sessionRecordsProvider` from `_persistAndExit` after saving the record. Since the provider is file-private, either move it to `providers.dart` or pass a `Ref` to the invalidation call:

```dart
// In BicepCurlView._persistAndExit:
await ref.read(localStorageServiceProvider).saveSessionRecord(record);
ref.invalidate(_sessionRecordsProvider);  // triggers re-fetch next time list is shown
if (!mounted) return;
context.go('/bicep-curl/debrief/$sessionId');
```

Alternatively, change `ref.read` to `ref.watch` inside the provider body to create a reactive dependency, then call `ref.invalidate` from the mutation site.

---

### [LOW] `ListView` without `.builder` in `SetPickerView` and `BleDebugView`

**Files:** `lib/features/sets/views/set_picker_view.dart:22`, `lib/features/dev/views/ble_debug_view.dart:443`

Both use `ListView(children: [...])`. The lists are short and static so this is not a runtime problem, but `.builder` should be the default pattern for any list that could grow.

---

## State Management (Riverpod 3)

### [HIGH] Core infrastructure providers missing `keepAlive: true`

**File:** `lib/core/providers.dart`

In Riverpod 3, all providers are `autoDispose` by default. Several providers in `providers.dart` hold long-lived resources or application-level state that must not dispose when temporarily unwatched:

| Provider | Risk |
|---|---|
| `poseDetectorProvider` | `MediaPipePoseDetector` holds a native `PoseLandmarker` instance. Disposing tears down the native object; re-creation triggers model re-initialization (slow). |
| `bioliminalClientProvider` | Holds an `http.Client`. Disposing closes the client, cancelling in-flight requests. |
| `hardwareControllerProvider` | Holds BLE subscriptions, stream controllers, and a connected device. Disposing mid-connection silently drops the BLE link. |
| `cloudSyncEnabledProvider` | User preference — should persist for app lifetime. |
| `isPremiumProvider` | Same. |
| `cameraDescriptionProvider` | Should survive navigation between features. |

`hardwareControllerProvider` and `poseDetectorProvider` are especially risky because they are not watched by a shell-level widget. Between screens, Riverpod 3 may dispose them.

**Fix:** Add `keepAlive: true` to providers that hold resources or app-level state:

```dart
final poseDetectorProvider = Provider<PoseDetector>(
  (ref) {
    final detector = MediaPipePoseDetector();
    ref.onDispose(() => detector.dispose());
    return detector;
  },
  keepAlive: true,
);

final hardwareControllerProvider =
    NotifierProvider<HardwareController, HardwareConnectionState>(
      HardwareController.new,
      keepAlive: true,
    );

final cloudSyncEnabledProvider = NotifierProvider<CloudSyncNotifier, bool>(
  CloudSyncNotifier.new,
  keepAlive: true,
);

final isPremiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
  keepAlive: true,
);
```

`bicepCurlControllerProvider` correctly needs autoDispose behavior (resets between sessions). The `ref.onDispose(_teardown)` call in its `build()` handles cleanup correctly.

---

### [MEDIUM] `ref.listen` registered in `build` runs at 30fps (consequence of issue 1)

**File:** `lib/features/bicep_curl/views/bicep_curl_view.dart`, lines 186–195

Riverpod de-duplicates `ref.listen` registrations on rebuild so there is no resource leak, but the listener registrations execute 30x/sec once `appCameraControllerProvider` is watched at that rate. This resolves automatically once the 30fps rebuild is fixed with the `select` approach above.

---

### [LOW] `lastCompletedSessionLogProvider` is defined but never watched

**File:** `lib/features/bicep_curl/controllers/bicep_curl_controller.dart`, line 572

```dart
final lastCompletedSessionLogProvider = Provider<SessionLog?>((ref) {
  final s = ref.watch(bicepCurlControllerProvider);
  return s is BicepCurlComplete ? s.log : null;
});
```

No view references this provider (confirmed by grep). The debrief view correctly loads from disk via `_debriefSessionProvider`. This appears to be dead code — remove it.

---

## Null Safety & Type Soundness

### [HIGH] Crash path: `CompensationDetector.buildReference` throws when pose frames are empty

**File:** `lib/features/bicep_curl/services/compensation_detector.dart`, line 25
**Called from:** `lib/features/bicep_curl/controllers/bicep_curl_controller.dart`, line 364

```dart
if (calibrationFrames.isEmpty) {
  throw StateError('Cannot build compensation reference from zero frames');
}
```

In `_handleCalibrationRep`, `_calibrationFramesForRef` is populated via `_currentRepFrames` only when `repNum <= 3`. `_currentRepFrames` accumulates frames via `_onLandmarks` — but only when pose detection returns non-empty results. If pose never fires results for the first three reps (degraded lighting, model init delay, very fast first rep before the channel initializes), `_calibrationFramesForRef` is empty when `repNum >= calibrationReps`.

Since `RepDetector` is pose-driven, a rep boundary only fires if landmarks arrived. However, there is a window: `_currentRepFrames` is cleared at line 337 (top of `_onRepBoundary`) before `addAll` runs at line 360 — so frames from *that* rep are included. But if pose worked for rep detection but returned too few frames per rep, the reference could be sparse enough that a subset scenario produces empty frames.

The simplest guard is a null-fallback instead of throw:

```dart
static CompensationReference buildReference(
  List<List<PoseLandmark>> calibrationFrames,
  ArmSide side,
) {
  if (calibrationFrames.isEmpty) {
    // Zero reference: drift deltas start near zero.
    // Compensation thresholds won't fire falsely from day 1.
    return CompensationReference(
      shoulderYRef: 0.5,
      torsoPitchDegRef: 0.0,
      armSide: side,
    );
  }
  // ... existing logic
}
```

Alternatively, wrap the call in `_handleCalibrationRep` with a try/catch and transition to `BicepCurlError`.

---

### [MEDIUM] `base!.path` force-unwrap in `_sessionDir` — correctness smell on web

**File:** `lib/core/services/local_storage_service.dart`, line 30

```dart
Future<Directory> _sessionDir() async {
  final base = await _baseDir;
  final dir = Directory('${base!.path}/session_records');
```

`_baseDir` returns `null` on web. `_sessionDir()` is only called from methods that already guard on `kIsWeb`, so the bang is safe today. But if any future code path calls `_sessionDir()` without the guard, it throws `Null check operator used on a null value`. Tighten:

```dart
Future<Directory> _sessionDir() async {
  assert(!kIsWeb, '_sessionDir should never be called on web');
  final base = await _baseDir;
  if (base == null) throw StateError('No application documents directory');
  final dir = Directory('${base.path}/session_records');
  // ...
}
```

---

### [MEDIUM] `credential.user!` force-unwrap in `AuthService` after Firebase Auth calls

**File:** `lib/core/services/auth_service.dart`, lines 22, 34, 35, 42

Firebase Auth's `createUserWithEmailAndPassword` and `signInAnonymously` can return a `UserCredential` with null `user` in edge cases (auth emulator, partial network failure). The `!` throws an unhandled NPE in the sign-in flow.

```dart
// Replace:
return credential.user!.uid;

// With:
final user = credential.user;
if (user == null) throw StateError('Firebase returned null user after sign-in');
return user.uid;
```

---

### [LOW] `washTint!` / `tint!` repeated force-unwraps in landing widgets

**Files:** `lib/features/landing/views/landing_page_view.dart`, lines 1266–1288; `lib/features/landing/widgets/premium_atmosphere.dart`, lines 58–80

These are non-null after a null guard a few lines above in each case. Assign to a non-nullable local to eliminate the bangs and let the analyzer enforce the invariant statically.

---

## Platform & Build Configuration

### [HIGH] Release build signed with debug keys

**File:** `android/app/build.gradle.kts`, lines 38–41

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```

Debug-signed APKs cannot be submitted to the Play Store and will be rejected by enterprise MDM. This is a hard blocker for any external distribution.

**Fix:** Create a `keystore.properties` file (gitignored), define a release signing config:

```kotlin
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    load(FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

### [HIGH] No obfuscation configured for release builds

The fatigue algorithm and compensation detection logic are embedded in plaintext Dart — no obfuscation is configured.

Add to release build command or CI:
```sh
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols
```

Store the `build/symbols` directory for crash symbolication.

---

### [MEDIUM] `PoseChannel` has no `PlatformException` handling

**File:** `lib/features/camera/services/pose_channel.dart`

All three `invokeMethod` calls can throw `PlatformException`. `processFrame` errors are caught by the `onError` callback in `AppCameraController._handleFrame`, so that path is safe. `initialize` and `dispose` are unguarded — if native setup fails, `_initialized` stays false and every subsequent `processFrame` call silently re-attempts (acceptable) but the `dispose` call will throw unhandled on teardown.

**Fix:**
```dart
Future<bool> initialize({required String assetPath}) async {
  try {
    final ok = await _channel.invokeMethod<bool>('initialize', {'assetPath': assetPath});
    return ok ?? false;
  } on PlatformException catch (e) {
    debugPrint('PoseChannel.initialize failed: ${e.code}');
    return false;
  }
}

Future<void> dispose() async {
  try {
    await _channel.invokeMethod<void>('dispose');
  } on PlatformException catch (_) {}
}
```

---

### [MEDIUM] Android `PosePlugin.replyOnMain` may post to a dead `Result` after engine detach

**File:** `android/app/src/main/kotlin/com/bioliminal/app/pose/PosePlugin.kt`, line 41

`executor.shutdown()` in `onDetachedFromEngine` stops accepting new tasks but waits for the running one. If inference is in progress, `replyOnMain` will post to the Flutter result object after the engine has detached — undefined behavior on the platform channel.

**Fix:**
```kotlin
@Volatile private var engineDetached = false

override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    engineDetached = true
    executor.shutdownNow()
    helper?.close()
    helper = null
    channel?.setMethodCallHandler(null)
    channel = null
}

private fun replyOnMain(result: Result, value: Any?) {
    if (engineDetached) return
    mainHandler.post { result.success(value) }
}
```

---

### [LOW] Android `targetSdk` deferred to Flutter plugin default

**File:** `android/app/build.gradle.kts`, line 31

`flutter.targetSdkVersion` tracks the Flutter tool's embedded default, which may be behind Google Play requirements. Pin explicitly:

```kotlin
targetSdk = 35
```

---

## pubspec & Dependency Health

### [MEDIUM] Critical packages use broad `^` version pins with no lock floor

**File:** `pubspec.yaml`

| Package | Risk if wrong version lands |
|---|---|
| `camera: ^0.12.0+1` | `nv21`/`bgra8888` image format API is version-specific. Wrong format silently breaks native inference. |
| `flutter_blue_plus: ^1.34.5` | BLE UUID handling and scan API changed between 1.x minors. |
| `flutter_riverpod: ^3.3.1` | Riverpod 3 autoDispose semantics differ from 2.x. Wrong version would silently break provider state. |
| `firebase_core: ^4.6.0` | Firebase major versions have breaking initialization changes. |

Tighten to `>=X.Y.Z <(X+1).0.0` for these four packages. Also commit `pubspec.lock` to the repository so CI builds are reproducible.

---

### [LOW] `debugPrint` in `WaitlistService` emits error codes visible to debugger in release

**File:** `lib/features/waitlist/services/waitlist_service.dart`, lines 65, 70

`debugPrint` is not stripped in release builds — it calls through to `print` with rate limiting. Firestore error codes (`e.code`) are visible to anyone with a device debugger attached. Use `developer.log` or gate on `kDebugMode`:

```dart
if (kDebugMode) {
  developer.log('waitlist error: ${e.code} ${e.message}', name: 'WaitlistService');
}
```

---

## Identified Bugs and Fixes

### Bug 1 (HIGH): `fatigueStop` fires on every rep past the stop threshold — UI never acts on it

**Files:** `lib/features/bicep_curl/services/fatigue_algorithm.dart:44`; `lib/features/bicep_curl/controllers/bicep_curl_controller.dart:431–436`

`fatigueStop` bypasses the cooldown check (by design) but does not bump `_lastCueRep`. After the stop threshold is crossed, `evaluate()` returns `fatigueStop` on every subsequent rep. `CueDispatcher` logs a `CueEvent` for each one, so the debrief cue timeline shows N stop events instead of one. The algorithm comment says "UI may auto-end" but `BicepCurlView` has no `fatigueStop` handler — auto-end never triggers.

**Fix (recommended):** Auto-end the set on `fatigueStop`, which is what the algorithm intends:

```dart
// In BicepCurlController._handleActiveRep, after dispatch:
if (decision?.content == CueContent.fatigueStop) {
  unawaited(endSession());
  return;
}
```

**Alternative fix:** Add `fatigueStop` to the cooldown-bump list so it fires once per threshold crossing, leaving the user in control of when to end:

```dart
if (decision.content == CueContent.fatigueFade ||
    decision.content == CueContent.fatigueUrgent ||
    decision.content == CueContent.fatigueStop) {
  _lastCueRep = repNum;
}
```

---

### Bug 2 (HIGH): History list stale after completing a session

Already described in Widget Tree section. Root cause: `_sessionRecordsProvider` stays alive inside the `StatefulShellRoute` shell, never re-runs, and shows the pre-session list after the user returns from debrief. Fix is provider invalidation from `_persistAndExit`.

---

### Bug 3 (MEDIUM): Router `redirect` swallows storage errors silently — possible navigation deadlock

**File:** `lib/core/router.dart`, lines 64–74

If `storage.listSessionRecords()` throws (corrupted session file, unexpected I/O error), the redirect exception propagates to `go_router`'s redirect handler. Depending on the `go_router` version, this may either crash with an unhandled exception or produce a stuck loading state on the splash screen.

**Fix:** Wrap with try/catch (stay on disclaimer on any error):

```dart
redirect: (context, state) async {
  if (!kIsWeb && state.uri.path == '/disclaimer') {
    try {
      final container = ProviderScope.containerOf(context);
      final storage = container.read(localStorageServiceProvider);
      final records = await storage.listSessionRecords();
      if (records.isNotEmpty) return '/history';
    } catch (_) {
      // Storage error → stay on disclaimer
    }
  }
  return null;
},
```

---

### Bug 4 (LOW): `_MetaDivider` in debrief view missing `const` constructor

**File:** `lib/features/bicep_curl/views/bicep_curl_debrief_view.dart`

```dart
class _MetaDivider extends StatelessWidget {
  @override  // no const constructor
  Widget build(BuildContext context) { ... }
```

This is a minor efficiency miss — `_MetaDivider()` can be `const`. Not impactful but easy:

```dart
class _MetaDivider extends StatelessWidget {
  const _MetaDivider();
  // ...
}
```

---

## Recommendations

Priority order for pre-demo work:

1. **Fix the 30fps rebuild** (`BicepCurlView` + `select` on `appCameraControllerProvider`). 10–15 minutes, measurable frame time reduction.
2. **Fix history staleness** (invalidate `_sessionRecordsProvider` from `_persistAndExit`). 5 minutes, immediately visible UX fix.
3. **Add `keepAlive: true`** to `poseDetectorProvider`, `hardwareControllerProvider`, `cloudSyncEnabledProvider`, `isPremiumProvider`, `cameraDescriptionProvider`. 10 minutes, prevents unpredictable state loss.
4. **Handle `fatigueStop`** — add auto-end in `_handleActiveRep`. 5 minutes, algorithm behavior is currently broken past the stop threshold.
5. **Guard `CompensationDetector.buildReference`** — replace throw with fallback reference. 5 minutes, eliminates a crash path.
6. **Release signing** — blocker before any external distribution.
7. **Add `RepaintBoundary`** around `SkeletonOverlay`. One line.
8. **Wrap `PoseChannel` methods** in `PlatformException` try/catch. 10 minutes.

---

## Overall Score: 7/10

The architecture is clean and intentional. Sealed state machines, proper teardown lifecycle, correct Riverpod patterns in controllers, production-quality platform channel code on both Android and iOS. The BLE protocol implementation is solid.

Points off: the 30fps rebuild is a real performance bug that will be felt on older demo devices; history staleness is a visible UX regression in the core demo flow; the Riverpod 3 keepAlive gap is a correctness time-bomb; `fatigueStop` behavior is broken; release signing and obfuscation are not configured. None of these are architectural — they are all fixable in under a day.
