---
Status: Active
Created: 2026-04-19
Updated: 2026-04-19
Owner: kelsi.andrews
---

# Bioliminal Flutter App — Code Audit

**Date:** 2026-04-19
**Branch:** fix/audit-high-findings-2026-04-19
**Auditor:** Claude Sonnet 4.6 (automated)
**Scope:** Full project — all `.dart` files under `lib/`, plus `pubspec.yaml`, `analysis_options.yaml`, `android/app/build.gradle.kts`, and `ios/Runner/Info.plist`.

---

## Executive Summary

The codebase is in solid shape for a capstone demo. Architecture decisions are sound: Riverpod 3 is used consistently with properly-scoped providers, the BLE/EMG pipeline is well-isolated with correct teardown, and the camera/pose detection stack has good error-surface coverage. The prior HIGH-finding audit (commit `fea1b75`) resolved the most critical items.

What remains is a concentrated set of real issues, none of which blocks a demo, but two of which can crash or corrupt data in specific runtime scenarios:

1. **Missing `try/catch` on `PoseChannel` method calls** — an uninitialised native PoseLandmarker silently throws `PlatformException`, creating a hot retry loop that saturates the UI thread.
2. **`firstWhere` without `orElse` on enum deserialisation** — stale on-disk data with an unknown wire value throws `StateError` at load time, crashing the history view.

Everything else is medium/low: a Riverpod `ref.read` anti-pattern in a `FutureProvider` body, a missing `const` constructor, `debugPrint` calls in the waitlist service, indefinite polling in `ReportView`, and pubspec dependency pinning.

**Overall Score: 7.5 / 10**

The pipeline logic and state model are production-calibre. The gaps are in defensive error handling at the platform-channel boundary and a few Riverpod patterns that can manifest as stale UI data.

---

## Widget Tree & Performance

### M1 — `BicepCurlHeatmapSection` autoplay fires `setState` at ~71 fps (MEDIUM)

**File:** `lib/features/bicep_curl/views/widgets/body_heatmap.dart:117,150–153`

`_frameInterval = Duration(milliseconds: 14)` drives a `Timer.periodic` that calls `setState` unconditionally, rebuilding the entire `_BicepCurlHeatmapSectionState` subtree — including both `BodyHeatmapPanel` `CustomPaint` calls and the scrub row — at ~71 fps. The widget lives inside a `SingleChildScrollView` on the debrief screen, so it does not participate in viewport clipping.

`_BodyHeatmapPainter.shouldRepaint` correctly gates on field equality, so the actual repaint is bounded. The issue is the `setState` triggering widget tree reconciliation at 71 Hz for the entire section.

**Fix:** Replace `setState` with a `ValueNotifier<int>` and drive only the animated subtree through `ValueListenableBuilder`:

```dart
final _sampleNotifier = ValueNotifier<int>(0);

// Timer callback:
_autoPlay = Timer.periodic(_frameInterval, (_) {
  if (!mounted) return;
  _sampleNotifier.value = (_sampleNotifier.value + 1) % _totalSamples;
});

// In build():
ValueListenableBuilder<int>(
  valueListenable: _sampleNotifier,
  builder: (_, sample, __) {
    final activations = MuscleActivations.fromLog(..., absoluteSample: sample, ...);
    return Column(children: [BodyHeatmapPanel(...), ScrubRow(...)]);
  },
)
```

Also consider wrapping `BicepCurlHeatmapSection` in a `RepaintBoundary` to isolate its raster layer from the rest of the debrief scroll.

---

### M2 — `IntrinsicHeight` in debrief stats wall (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_debrief_view.dart:313`

`_StatsWall` wraps its three-column row in `IntrinsicHeight`, which forces a two-pass layout for every child. Fine for a static one-time render, but blocks future placement inside an animated or list context. No urgent action.

---

### M3 — `_CtaBar` in debrief missing `const` constructor (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_debrief_view.dart:645,165`

`_CtaBar` has no fields, extends `StatelessWidget`, and is instantiated without `const`. Add `const _CtaBar();` and call it as `const _CtaBar()`.

---

### M4 — `BicepCurlView` full rebuild at 100 ms during Setup phase (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_view.dart:100–126`

During `BicepCurlSetup`, `_framingTicker` calls `setState(() {})` on the parent `_BicepCurlViewState` at 100 ms to refresh `_framingHoldProgress`, rebuilding the full `Scaffold` subtree at 10 Hz. The select on `appCameraControllerProvider` prevents the 30fps camera-state rebuild, but the framing ticker still drives the parent.

**Fix:** Extract the framing progress indicator into its own `StatefulWidget` that owns the `Timer` and only calls `setState` on itself.

---

### M5 — `RepCounter` is a `ConsumerWidget` but never watches anything (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_overlays.dart:13`

`RepCounter` extends `ConsumerWidget` but only calls `ref.read` in a gesture handler, never `ref.watch`. This registers a Riverpod consumer subscription with no reactive value. Convert to `StatelessWidget` and accept an `onLongPress` callback from the parent.

---

## State Management (riverpod)

### R1 — `ref.read` inside a `FutureProvider` body (MEDIUM)

**File:** `lib/features/bicep_curl/views/widgets/session_trends.dart:14–18`

```dart
final allBicepCurlSessionsProvider =
    FutureProvider.autoDispose<List<SessionLog>>((ref) async {
  final records = await ref
      .read(localStorageServiceProvider)   // ← should be ref.watch
      .listSessionRecords();
```

`ref.read` inside a provider body does not create a reactive dependency. `allBicepCurlSessionsProvider` will never re-fire when `sessionRecordsProvider` is invalidated after a new session is saved in `BicepCurlView._persistAndExit`. The trends section on the debrief screen will show stale history data if the user completes a session and opens the debrief within the same app session.

**Fix:**
```dart
final records = await ref.watch(localStorageServiceProvider).listSessionRecords();
```

---

### R2 — `useHardwareModeProvider`, `hardwareSetupStepProvider`, `hardwareSyncOffsetProvider` missing `isAutoDispose: false` (LOW)

**File:** `lib/core/providers.dart:118–144`

These three `NotifierProvider`s are declared without `isAutoDispose: false`. Per Riverpod 3 defaults they will auto-dispose when their last listener drops. The BLE state flows through `hardwareControllerProvider` (which is `isAutoDispose: false`) so the production path is safe, but these setup-step providers will reset to defaults if the hardware setup screen is navigated away from mid-flow.

---

### R3 — `_debriefSessionProvider` uses `ref.read` inside a `FutureProvider.autoDispose.family` body (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_debrief_view.dart:17–23`

Same anti-pattern as R1. In practice benign (one-shot load), but inconsistent. Use `ref.watch` for clarity.

---

### R4 — `sessionCountProvider` pattern can be simplified (LOW)

**File:** `lib/core/providers.dart:189–192`

`FutureProvider` wrapping a watch on `sessionRecordsProvider.future` and returning `.length` is a common pattern but can be expressed more simply as a synchronous derivation:

```dart
final sessionCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(sessionRecordsProvider).whenData((r) => r.length);
});
```

No correctness issue with the current approach.

---

## Null Safety & Type Soundness

### N1 — `firstWhere` without `orElse` on enum deserialisation (HIGH)

**Files:**
- `lib/features/bicep_curl/models/compensation_reference.dart:5–6` — `ArmSide.fromName`
- `lib/features/bicep_curl/models/cue_event.dart:33–35` — `CueContent.values.firstWhere`
- `lib/domain/models.dart:20–21` — `MovementType.fromWire`
- `lib/domain/models.dart:158–159` — `ChainName.fromWire`

All four use `firstWhere` with no `orElse`. If on-disk or wire data contains an unknown enum value (e.g., a session saved on a branch with a different `CueContent` enum, or a future firmware version using a new wire movement type), `firstWhere` throws `StateError` at the deserialization callsite. This will crash `SessionRecord.fromJson`, breaking the entire history view for all sessions stored on that device.

**Fix (priority action):**
```dart
// ArmSide.fromName
static ArmSide fromName(String name) =>
    ArmSide.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ArmSide.right,
    );

// CueContent in CueEvent.fromJson
content: CueContent.values.firstWhere(
  (c) => c.name == json['content'] as String,
  orElse: () => CueContent.fatigueFade,
),

// MovementType.fromWire
static MovementType fromWire(String value) =>
    MovementType.values.firstWhere(
      (m) => m.wire == value,
      orElse: () => MovementType.bicepCurl,
    );

// ChainName.fromWire
static ChainName fromWire(String value) =>
    ChainName.values.firstWhere(
      (c) => c.wire == value,
      orElse: () => ChainName.upperLimbLocal,
    );
```

---

### N2 — Bang operator on `credential.user!` in `AuthService` without guard (MEDIUM)

**File:** `lib/core/services/auth_service.dart:33–35, 44–45, 48`

```dart
await credential.user!.updateDisplayName(displayName.trim());
return _auth.currentUser!;
```

`UserCredential.user` is nullable in the Firebase SDK contract. In practice it is non-null after a successful call, but the bang operators bypass the type system. If Firebase changes this (documented as unlikely but not contractually guaranteed), the call throws `Null check operator used on a null value` instead of a recoverable error.

**Fix:**
```dart
final user = credential.user ??
    (throw FirebaseAuthException(code: 'user-null', message: 'user is null after credential'));
await user.updateDisplayName(displayName.trim());
```

---

### N3 — `dispose()` calls `stopStreaming()` without `unawaited` marker (LOW)

**File:** `lib/features/bicep_curl/views/bicep_curl_view.dart:67`

`_cameraNotifier.stopStreaming()` is `async` and is called without `await` or `unawaited` in `dispose`. This is a fire-and-forget in a lifecycle method (correct behaviour), but it should be marked explicitly to match project style and suppress implicit-cast warnings:

```dart
unawaited(_cameraNotifier.stopStreaming());
```

---

## Platform & Build Configuration

### P1 — `PoseChannel` method calls have no `PlatformException` handling (HIGH)

**File:** `lib/features/camera/services/pose_channel.dart:18–56`

All three `_channel.invokeMethod` calls (`initialize`, `processFrame`, `dispose`) are bare awaits with no `try/catch`. When the native PoseLandmarker fails to initialise (missing asset, unsupported OS version, or native exception), `initialize` throws `PlatformException`. This propagates through `MediaPipePoseDetector.processFrame` and is caught by the `onError` handler in `_handleFrame` in the camera controller:

```dart
onError: (e) {
  developer.log('Pose detection error', error: e, name: 'CameraController');
  _isProcessing = false;
},
```

The error is logged and swallowed, but `_initialized` remains `false`. On the next camera frame, `processFrame` tries to call `_channel.initialize` again — and fails again. This creates a hot loop that fires a failing platform channel call on every camera frame (~30fps), saturating the method channel and degrading UI responsiveness.

**Fix:** Add a retry ceiling in `MediaPipePoseDetector`:

```dart
int _consecutiveInitFailures = 0;
static const int _maxInitAttempts = 3;

Future<List<domain.PoseLandmark>> processFrame(
  CameraImage image, {required int rotationDegrees}) async {
  if (!_initialized) {
    if (_consecutiveInitFailures >= _maxInitAttempts) return const [];
    try {
      _initialized = await _channel.initialize(assetPath: assetPath);
      if (_initialized) _consecutiveInitFailures = 0;
      else _consecutiveInitFailures++;
    } on PlatformException catch (e) {
      _consecutiveInitFailures++;
      developer.log('PoseChannel init failed', error: e, name: 'MediaPipePoseDetector');
      return const [];
    }
    if (!_initialized) return const [];
  }
  try {
    final raw = await _channel.processFrame(
      bytes: image.planes.first.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: image.planes.first.bytesPerRow,
      rotationDegrees: rotationDegrees,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (raw == null || raw.length != 33) return const [];
    return raw.map((m) => domain.PoseLandmark(
      x: m['x'] ?? 0, y: m['y'] ?? 0, z: m['z'] ?? 0,
      visibility: m['visibility'] ?? 0, presence: m['presence'] ?? 0,
    )).toList(growable: false);
  } on PlatformException catch (e) {
    developer.log('PoseChannel processFrame failed', error: e, name: 'MediaPipePoseDetector');
    return const [];
  }
}
```

---

### P2 — `updateLandmarks` can be called after `stopStreaming` due to in-flight inference (MEDIUM)

**File:** `lib/features/camera/controllers/camera_controller.dart:165–196, 218–224`

`_handleFrame` dispatches inference asynchronously via `.then(...)`. The `_isProcessing` flag prevents new inference from starting after `stopStreaming`, but an in-flight inference started just before `stopStreaming` can complete and call `updateLandmarks` after the state has moved to `CameraReady`. `updateLandmarks` guards on `current is CameraStreaming` before updating, so it does not corrupt state. However, `_isProcessing` remains `true` until the in-flight callback resolves, silently dropping frames if streaming is restarted immediately. This can cause a ~100ms delay before the skeleton overlay reappears after a camera toggle.

**Fix:** Add a generation counter to invalidate in-flight callbacks:

```dart
int _generation = 0;

Future<void> stopStreaming() async {
  _generation++;
  ...
}

void _handleFrame(CameraImage image) {
  if (_isProcessing) return;
  _isProcessing = true;
  final gen = _generation;
  poseDetector.processFrame(...).then((landmarks) {
    if (gen != _generation) { _isProcessing = false; return; }
    updateLandmarks(landmarks);
    _isProcessing = false;
  }, onError: (e) {
    developer.log('Pose detection error', error: e, name: 'CameraController');
    _isProcessing = false;
  });
}
```

---

### P3 — Release build falls back to debug signing key when `key.properties` is absent (MEDIUM)

**File:** `android/app/build.gradle.kts:55–69`

The comment explicitly states "Not acceptable for Play Store uploads." There is no build-time guard that fails `flutter build appbundle --release` when `key.properties` is absent. A developer without the key file will produce a debug-signed AAB that Google Play rejects — but only at upload time, not at build time.

**Fix:** Add a Gradle `doFirst` block that asserts the release keystore is configured:

```kotlin
tasks.whenTaskAdded { task ->
    if (task.name == "packageRelease" || task.name == "bundleRelease") {
        task.doFirst {
            require(hasReleaseKeystore) {
                "Release build requires android/key.properties. See key.properties.example."
            }
        }
    }
}
```

---

### P4 — No documented `--obfuscate` / `--split-debug-info` release build command (MEDIUM)

No release build script was found in the repository. The Dart symbol table is not obfuscated in any observed build configuration. For a clinical biometric app, this exposes internal class names (`BicepCurlController`, `FatigueAlgorithm`, `CompensationDetector`, etc.) in the binary.

**Fix:** Add a `build_release.sh`:

```sh
#!/usr/bin/env bash
set -e
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android
flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/ios
```

Commit the `build/debug-info` artifacts alongside each release for crash symbolication.

---

### P5 — iOS deployment target is iOS 16.0 (LOW)

`IPHONEOS_DEPLOYMENT_TARGET = 16.0` in the Release configuration matches the current App Store minimum as of early 2026. No action required, but worth reviewing after WWDC when Apple typically raises the floor.

---

## pubspec & Dependency Health

### D1 — All dependencies use broad `^` constraints with no pinned `pubspec.lock` policy (LOW)

**File:** `pubspec.yaml`

Every dependency uses `^` (minor-compatible). `pubspec.lock` is committed, which is correct. The risk is that `flutter pub upgrade` on CI can silently advance `flutter_blue_plus`, `camera`, or `firebase_*` packages between runs, both of which have historically had breaking behavioural changes in BLE or AVFoundation wiring. Ensure CI runs `flutter pub get` (not `upgrade`) against the committed lock file.

---

### D2 — `flutter_web_plugins` as a direct dependency (LOW)

**File:** `pubspec.yaml:12`

`flutter_web_plugins` is listed explicitly (`sdk: flutter`) alongside the standard `flutter` SDK dependency. This is needed for `usePathUrlStrategy()` on web. Correct and intentional; no action needed.

---

## Identified Bugs and Fixes

### B1 — `_summarizeWindow` relies on sorted `_envelopeBuffer` but breaks on BLE clock wrap (MEDIUM)

**File:** `lib/features/bicep_curl/controllers/bicep_curl_controller.dart:466–481`

```dart
for (final s in _envelopeBuffer) {
  if (s.tUs < tStartUs) continue;
  if (s.tUs >= tEndUs) break;   // assumes sorted ascending
```

The break is correct only if `_envelopeBuffer` is strictly time-ordered. The wall-clock conversion `_wallEpochUs! + (batch.tUsAt(i) - _bleEpochUs!)` is monotonic under normal conditions, but if the ESP32 firmware restarts mid-session (timer reset), `tUsAt(i)` decreases below `_bleEpochUs`, producing a `wallTUs` that is earlier than prior samples. The break would then silently skip all samples beyond that point, producing a zero peak for the affected rep with no error surface.

**Fix:** Replace the break with a continue (safe, slightly slower over long buffers), or add a monotonicity check in `_onSample` that resets the epoch variables on detected wrap:

```dart
// Safer scan — no assumption on ordering:
for (final s in _envelopeBuffer) {
  if (s.tUs < tStartUs || s.tUs >= tEndUs) continue;
  if (s.value > peak) peak = s.value;
  final bin = ((s.tUs - tStartUs) / binSize).floor().clamp(0, _envelopeBucketsPerRep - 1);
  if (s.value > samples[bin]) samples[bin] = s.value;
}
```

---

### B2 — `_maybeStartSession` boolean guard cannot distinguish "session running" from "session complete" (MEDIUM)

**File:** `lib/features/bicep_curl/views/bicep_curl_view.dart:45, 171–179`

`_attemptedSessionStart` is set to `true` on first call and never reset. The `ref.listen` on `hardwareControllerProvider` calls `_maybeStartSession` on every state change, including reconnect events. The guard correctly prevents double-start during a session, but if the controller reaches `BicepCurlComplete` and the widget stays mounted (e.g., the `_persistAndExit` future is awaited), a BLE reconnect event during that window would call `_maybeStartSession`, which would be silently no-op'd by `_attemptedSessionStart`, preventing the expected session start if the user quickly starts a second session without navigating away.

**Fix:** Replace the boolean flag with a controller-state guard:

```dart
void _maybeStartSession() {
  final cam = ref.read(appCameraControllerProvider).value;
  if (cam is! CameraStreaming) return;
  final s = ref.read(bicepCurlControllerProvider);
  if (s is! BicepCurlIdle) return;
  ref.read(bicepCurlControllerProvider.notifier).startSession(side: widget.armSide);
}
```

This is idempotent, self-documenting, and handles all state transitions correctly.

---

### B3 — `LocalStorageService._webMemory` is static — not hermetic in tests (LOW)

**File:** `lib/core/services/local_storage_service.dart:19`

```dart
static final Map<String, Map<String, dynamic>> _webMemory = {};
```

The in-memory web store is shared across all instances. In production there is one singleton instance, so this is harmless. In tests, creating a fresh `LocalStorageService()` shares (and pollutes) the map from prior test runs.

**Fix:** Make `_webMemory` an instance field, or accept an override map via the constructor for tests:

```dart
final Map<String, Map<String, dynamic>> _webMemory;
LocalStorageService({Directory? directory, Map<String, Map<String, dynamic>>? webMemory})
    : _overrideDir = directory, _webMemory = webMemory ?? {};
```

---

### B4 — `WaitlistService` uses `debugPrint` in production (MEDIUM)

**File:** `lib/features/waitlist/services/waitlist_service.dart:65,70`

```dart
debugPrint('waitlist firestore error: ${e.code} ${e.message}');
debugPrint('waitlist unexpected error: $e');
```

`debugPrint` is not stripped in release builds. The `avoid_print` lint in `analysis_options.yaml` does not cover `debugPrint` (which is in `package:flutter/foundation.dart`, not `dart:core`). This writes structured error output — including Firebase exception codes and raw error messages — to the platform console in production.

**Fix:**
```dart
import 'dart:developer' as developer;
// Replace both debugPrint calls:
developer.log(
  'waitlist firestore error: ${e.code}',
  error: e,
  name: 'WaitlistService',
);
developer.log('waitlist unexpected error', error: e, name: 'WaitlistService');
```

---

### B5 — GoRouter redirect performs disk I/O on main isolate at cold start (LOW)

**File:** `lib/core/router.dart:64–76`

The `redirect` callback is `async` and calls `storage.listSessionRecords()` (filesystem read) before the first frame renders on mobile cold launch. On devices with slow flash this creates a visible blank frame. The redirect fires only once (initial `/disclaimer` path), so impact is one-time and brief, but it blocks the navigation system during the async gap.

**Fix:** Pre-fetch the session count in `main()` before `runApp` and pass it to the router via a `ProviderScope` override, making the redirect synchronous.

---

### B6 — `ReportView` polling has no maximum retry count (LOW)

**File:** `lib/features/report/views/report_view.dart:56–62`

`Timer.periodic` fires every 3 seconds indefinitely until the widget is disposed. If the server is down or the session ID is invalid, this burns battery and network with no user-visible indication that the poll has given up.

**Fix:** Add a poll ceiling (e.g. 40 attempts = 2 minutes) and surface a user-visible "report unavailable" state:

```dart
int _pollCount = 0;
static const int _maxPolls = 40;

_pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
  if (++_pollCount >= _maxPolls) {
    _pollingTimer?.cancel();
    if (mounted) setState(() => _fetchError = 'Report unavailable after 2 minutes. Tap retry.');
    return;
  }
  _fetchOnce();
});
```

---

## Recommendations

Priority order for a targeted fix pass (est. 2–4 hours):

1. **Add `orElse` to all `firstWhere` enum deserialisations** (N1) — one `StateError` here crashes the entire history view from on-disk data. This is the only change that can affect all existing users with saved sessions.

2. **Wrap `PoseChannel` calls in `try/catch PlatformException`** (P1) — prevents the hot retry loop on uninitialised native stack.

3. **Switch `allBicepCurlSessionsProvider` to `ref.watch`** (R1) — fixes stale trends data within the same app session.

4. **Replace `_attemptedSessionStart` boolean with controller-state check** (B2) — cleaner, covers edge cases the boolean cannot.

5. **Replace `debugPrint` with `developer.log` in `WaitlistService`** (B4) — consistent logging, no production console exposure.

6. **Add a release build script with `--obfuscate --split-debug-info`** (P4) — important before any public distribution.

7. **Add polling ceiling to `ReportView`** (B6) — prevents indefinite battery drain.

8. **Heatmap: switch to `ValueNotifier` + `ValueListenableBuilder`** (M1) — isolates the 71fps rebuild scope to the animated leaf widgets.

---

## Overall Score: 7.5 / 10

**Rationale:** Architecture is production-calibre — sealed state classes, a clean BLE pipeline with correct teardown semantics, Riverpod 3 used consistently for the majority of providers, and a thoughtful separation of concerns between `FatigueAlgorithm`, `CueDispatcher`, and `BicepCurlController`. The prior HIGH-finding audit (commit `fea1b75`) addressed the most severe items.

The remaining deductions are:

- **−1.0** for two HIGH findings that can crash the app from runtime conditions: unguarded `firstWhere` on enum deserialization (N1) and missing `PlatformException` handling on the pose channel (P1)
- **−0.5** for four MEDIUM items that manifest as stale UI data, missed error recovery, or missing release hardening (R1, N2, P2, P3, B4)
- **−0.5** for several low-friction but real issues across performance, const constructors, and test isolation

None of the above block the demo. All can be resolved in one focused session.
