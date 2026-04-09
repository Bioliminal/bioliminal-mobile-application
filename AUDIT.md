# AuraLink Audit Report

**Date:** 2026-04-08
**Scope:** Full project — /Users/kelsiandrews/capstone
**Engine:** Dual (Gemini + Claude)
**Sections:** Security, Bugs, Completeness, Quality

## Executive Summary

AuraLink is a Flutter movement screening app with a well-designed domain model and comprehensive rule-based clinical logic. The Gemini pass found 12 issues; Claude confirmed 7, downgraded 1, and rejected 3 (false positives). Claude independently found 24 additional issues. The merged report contains 31 confirmed findings: 0 critical, 7 high, 13 medium, 11 low. The most significant issues are: (1) the entire ML pipeline is stubbed — no real pose estimation exists, (2) the privacy disclaimer contradicts the Firebase sync infrastructure, (3) authentication is never triggered so Firestore will throw on access, (4) report deep-linking is broken, and (5) there is effectively no test coverage. Score: **0/100** — high finding volume across all sections, weighted heavily by security and bugs.

## Score Breakdown

| Section | Finding Count | Weight | Weighted Deduction | Raw Deduction |
|---|---|---|---|---|
| Security | 4 | 4x | 28 | 7 |
| Bugs | 10 | 3x | 57 | 19 |
| Completeness | 9 | 2x | 42 | 21 |
| Quality | 8 | 1x | 11 | 11 |
| **Total** | **31** | | **138** | **58** |

**Score: 0/100** (100 - 138, floored at 0)

---

## Security

### F-001 — **LOW** — Web Firebase API key unrestricted
**File:** `lib/firebase_options.dart:49-56`
**Source:** [claude]

Mobile API keys are bound to app signing and are safe to ship. The web API key, however, can be used from any origin without APK/bundle signing enforcement. Without App Check or HTTP referrer restrictions, it's exploitable.

```dart
apiKey: 'AIzaSyB8q1jQLraMrG8_FJDQ-_aUtD1EJqGQ8_E', // web — no referrer lock
```

> Given the Firebase project, When the web API key is used from an unauthorized origin, Then the request should be rejected by App Check or HTTP referrer restrictions configured in the Google Cloud console.

---

### F-002 — **MEDIUM** — Firestore rules allow arbitrary document shape
**File:** `firestore.rules:4-9`
**Source:** [claude]

Rules authenticate users but perform no schema validation. A compromised client can write arbitrary fields or oversized documents.

```
allow read, write: if request.auth != null && request.auth.uid == uid;
```

> Given an authenticated user, When they write a document with unexpected fields or oversized data, Then Firestore rules should reject the write with a permission-denied error.

---

### F-003 — **MEDIUM** — Storage rules allow any file type and size
**File:** `storage.rules:3-7`
**Source:** [claude]

No `request.resource.size` or `request.resource.contentType` constraints. A malicious client could upload multi-GB non-PDF files.

```
allow read, write: if request.auth != null && request.auth.uid == uid;
```

> Given an authenticated user, When they upload a file larger than 10MB or with a non-PDF content type, Then Storage rules should reject the upload.

---

### F-004 — **MEDIUM** — Anonymous auth with no account upgrade path
**File:** `lib/core/services/auth_service.dart:8-13`
**Source:** [claude]

Anonymous auth means each install gets a throwaway uid. On reinstall or device wipe, all Firestore data is permanently lost. No linkWithCredential or upgrade flow exists.

```dart
final credential = await _auth.signInAnonymously();
```

> Given an anonymous user with stored assessments, When they reinstall the app, Then they should be able to link their anonymous account to a permanent identity to preserve data.

---

## Bugs

### F-005 — **HIGH** — processFrame called with null as dynamic
**File:** `lib/features/screening/controllers/screening_controller.dart:103`
**Source:** [claude]

The screening controller passes `null as dynamic` as a CameraImage to the mock. The mock ignores it, but the abstract interface declares a non-nullable parameter. Swapping to a real implementation will crash immediately.

```dart
_mockLandmarkSub = mock.processFrame(null as dynamic).listen((landmarks) {
```

> Given the screening controller starts a mock landmark feed, When processFrame is called, Then it should receive a valid CameraImage or the mock interface should accept a nullable parameter.

---

### F-006 — **HIGH** — Report deep-link broken — GoRouter extra is ephemeral
**File:** `lib/features/report/views/report_view.dart:333`
**Source:** [claude]

ReportView reads the Assessment from `GoRouterState.extra`, which is in-memory only. Deep-linking to `/report/:id` (or browser refresh on web) yields "Assessment not found". The `:id` path parameter is never used to load from storage.

```dart
final assessment = GoRouterState.of(context).extra as Assessment?;
```

> Given a user navigates to /report/:id without an in-memory Assessment, When the view loads, Then it should fetch the assessment by id from LocalStorageService and display the report.

---

### F-007 — **MEDIUM** — Camera controller dispose/reinit lifecycle issues
**File:** `lib/features/camera/views/camera_view.dart:30-43`
**Source:** [claude]

`dispose()` calls `ref.read()` which may throw if the ProviderScope is already torn down. On `AppLifecycleState.resumed`, `requestPermission()` re-initializes without disposing the old controller first, leaking the previous CameraController.

> Given the app resumes from background, When requestPermission is called, Then the old CameraController should be disposed before creating a new one.

---

### F-008 — **MEDIUM** — "Open Settings" button doesn't open settings
**File:** `lib/features/camera/views/camera_view.dart:222-226`
**Source:** [claude]

When camera permission is permanently denied, the button calls `requestPermission()` — which will silently fail again. It should call `openAppSettings()` (from `app_settings` or similar package).

```dart
onPressed: onRetry, // onRetry = requestPermission(), not openAppSettings()
```

> Given camera permission is permanently denied, When the user taps "Open Settings", Then the OS app settings page should open.

---

### F-009 — **MEDIUM** — Frame averaging assumes uniform landmark counts
**File:** `lib/features/screening/controllers/screening_controller.dart:267-298`
**Source:** [claude]

`_averageFrameBuffer` uses the first frame's landmark count as canonical. Frames with fewer landmarks get partially averaged, producing misleading positions for some joints.

```dart
final landmarkCount = _frameBuffer.first.length;
```

> Given frames with varying landmark counts, When _averageFrameBuffer runs, Then it should skip incomplete frames or average only over landmarks present in all frames.

---

### F-010 — **LOW** — _topFindings selects by tracking quality, not clinical significance
**File:** `lib/features/screening/controllers/screening_controller.dart:351-358`
**Source:** [claude]

Sorts by confidence index ascending (high first), surfacing the best-tracked findings rather than the most clinically concerning ones. In a triage tool, severity should probably take priority.

> Given multiple compensations detected, When _topFindings selects the top 2, Then the selection criteria should be documented and should consider clinical significance.

---

### F-011 — **LOW** — Enum index comparison for confidence is fragile
**File:** `lib/domain/mocks/mock_chain_mapper.dart:280`, `lib/features/report/views/report_view.dart:260`, `lib/features/report/widgets/finding_card.dart:19`, `lib/features/report/services/pdf_generator.dart:37`
**Source:** [both]

`ConfidenceLevel` ordering (high=0, medium=1, low=2) is relied upon via `.index` comparison in 4+ locations. Reordering the enum silently breaks all of them.

> Given the ConfidenceLevel enum, When worst-confidence logic runs, Then it should use an explicit comparison rather than relying on declaration order.

---

### F-012 — **MEDIUM** — Mock pose service never disposed, leaks timer/stream
**File:** `lib/features/screening/controllers/screening_controller.dart:97-103`
**Source:** [both]

`_startMockLandmarkFeed` creates a new `MockPoseEstimationService` each call but never disposes the previous one. The old mock's Timer and StreamController keep running.

> Given the screening starts, When a mock landmark feed is created, Then the previous mock service should be disposed first.

---

### F-013 — **MEDIUM** — Skipped movement records Duration.zero
**File:** `lib/features/screening/controllers/screening_controller.dart:316-317`
**Source:** [claude]

`duration: current.config.duration - current.remaining` — if the user skips immediately, remaining equals config.duration, producing Duration.zero. Downstream code must handle this.

> Given a movement is skipped immediately, When the Movement record is created, Then the duration should reflect that the movement was skipped, and downstream code should handle zero-duration safely.

---

### F-014 — **LOW** — credential.user! forced unwrap
**File:** `lib/core/services/auth_service.dart:13`
**Source:** [gemini] *(downgraded from high to low — Firebase guarantees non-null user on successful anonymous auth)*

```dart
return credential.user!.uid;
```

> Given signInAnonymously succeeds, When the user credential is accessed, Then user is guaranteed non-null. This is safe in practice but the `!` could be replaced with a null-aware pattern for defensive clarity.

---

## Completeness

### F-015 — **HIGH** — ML pipeline entirely stubbed
**File:** `pubspec.yaml:15`
**Source:** [both]

`google_mlkit_pose_detection` is commented out. All landmark data comes from deterministic mocks. The core feature of an "AI movement screening app" does not exist.

```yaml
# google_mlkit_pose_detection: ^0.11.0  # ML dev adds when implementing PoseEstimationService
```

> Given a user performs a movement, When the camera streams frames, Then real ML Kit pose detection should process frames and return actual landmark positions.

---

### F-016 — **HIGH** — Test suite is a single broken test
**File:** `test/widget_test.dart:1-13`
**Source:** [claude]

One test checks for "SplashView" text, which will never appear because `initialLocation` is `/disclaimer`. Zero tests for chain mapping, angle calculation, screening state machine, report assembly, or serialization.

```dart
expect(find.text('SplashView'), findsOneWidget); // will fail — app starts at /disclaimer
```

> Given the test suite, When tests run, Then there should be unit tests for MockChainMapper threshold logic, ScreeningController state transitions, report assembly, and serialization round-trips.

---

### F-017 — **HIGH** — No auth gating on any route
**File:** `lib/core/router.dart:9-35`
**Source:** [claude]

No `redirect` guard in GoRouter. Users can navigate to `/screening` or `/report/:id` without authentication. `AuthService.signIn()` is never called anywhere. `FirestoreService._uid` will throw `StateError` on first access.

> Given an unauthenticated user, When they navigate to /screening, Then the router should redirect to a sign-in flow or trigger anonymous auth first.

---

### F-018 — **HIGH** — syncLocalAssessments never called
**File:** `lib/core/services/firestore_service.dart:135-163`
**Source:** [claude]

The sync method exists but has no call site anywhere in the app. Assessments are saved to local storage only and never uploaded to Firestore.

> Given a user completes a screening, When the assessment is saved locally, Then syncLocalAssessments should be triggered to back up data to Firestore.

---

### F-019 — **MEDIUM** — freezed/json_serializable deps unused
**File:** `pubspec.yaml:22-30`
**Source:** [claude]

`freezed_annotation`, `json_annotation`, `freezed`, `json_serializable`, and `build_runner` are declared but no `.g.dart` or `.freezed.dart` files exist. The code generation has never been run. Dead dependencies.

> Given the project dependencies, When build_runner runs, Then generated code should be produced and used, or unused dependencies should be removed.

---

### F-020 — **LOW** — Movement duration set to 15s (TODO: restore to 60s)
**File:** `lib/features/screening/models/movement.dart:8`
**Source:** [both]

```dart
this.duration = const Duration(seconds: 15), // TODO: restore to 60 for production
```

> Given a production build, When the user performs a movement, Then the duration should be 60 seconds as clinically intended.

---

### F-021 — **LOW** — _SplashView is dead code
**File:** `lib/core/router.dart:37-46`
**Source:** [both]

The `/` route and `_SplashView` are defined but unreachable — `initialLocation` is `/disclaimer`. The widget test expects to find it, compounding the issue (F-016).

> Given the app routes, When unreachable routes exist, Then they should be removed or the initialLocation updated.

---

### F-022 — **HIGH** — Privacy disclaimer contradicts Firebase infrastructure
**File:** `lib/features/onboarding/views/disclaimer_view.dart:79-85`
**Source:** [both]

The disclaimer states: *"All movement analysis happens on your device. No video is stored or transmitted."* Meanwhile, `FirestoreService` uploads assessments, reports, and PDFs to Firebase. If sync is wired up (F-018), this claim becomes false.

```dart
'All movement analysis happens on your device. No video is stored or transmitted.'
```

> Given the privacy disclaimer, When Firestore sync is implemented, Then the disclaimer must accurately describe what data is transmitted, or sync must be opt-in with separate consent.

---

### F-023 — **MEDIUM** — Auth not triggered before assessment save
**File:** `lib/features/screening/views/screening_view.dart:24-29`
**Source:** [claude]

The screening completion handler saves to local storage (works without auth), but any future Firestore sync will fail because `_uid` throws `StateError` without authentication.

> Given a screening completes, When the assessment is saved, Then the app should ensure the user is authenticated so subsequent Firestore sync has a valid uid.

---

## Quality

### F-024 — **MEDIUM** — Serialization logic duplicated across two files
**File:** `lib/core/services/local_storage_service.dart:12-153`, `lib/core/services/firestore_service.dart:36-59`
**Source:** [claude]

Hand-written toJson/fromJson in local_storage_service.dart, plus Timestamp conversion wrappers in firestore_service.dart. Two serialization paths that must stay in sync. This is the exact problem the unused freezed/json_serializable deps (F-019) would solve.

> Given domain model serialization, When a field is added or changed, Then there should be a single source of truth for serialization.

---

### F-025 — **MEDIUM** — MockChainMapper is misnamed — contains real business logic
**File:** `lib/domain/mocks/mock_chain_mapper.dart:1-455`
**Source:** [both]

455 lines of production clinical logic — threshold detection, chain mapping, CC/CP identification, hypermobility detection, confidence assignment, citations. Named "mock" but is the actual `ChainMapper` implementation. Risk: developers discard the "mock" when writing a "real" implementation without realizing it contains the validated rule engine.

> Given the chain mapping implementation, When it contains production business logic, Then it should be named appropriately (e.g., RuleBasedChainMapper) and placed in the services directory.

---

### F-026 — **MEDIUM** — Report assembly logic embedded in widget
**File:** `lib/features/report/views/report_view.dart:120-233`
**Source:** [claude]

`_buildReport` is a 110-line method inside `_ReportViewState` containing clinical chain grouping, upstream driver identification, recommendation generation, and citation assembly. Untestable without rendering a widget.

> Given report assembly logic, When it needs to be tested, Then it should live in a dedicated service that can be unit-tested independently.

---

### F-027 — **LOW** — MovementInstructions returns Positioned (requires Stack parent)
**File:** `lib/features/screening/widgets/movement_instructions.dart:20`
**Source:** [claude]

The widget's `build()` returns a `Positioned` widget, forcing the caller to use a Stack. Not enforced by types — using it in a Column would fail at runtime.

> Given MovementInstructions is used in a layout, When placed outside a Stack, Then it should still render correctly.

---

### F-028 — **LOW** — _handleFrame is a no-op
**File:** `lib/features/camera/controllers/camera_controller.dart:132-136`
**Source:** [claude]

After the first frame triggers the mock stream, `_handleFrame` does nothing. The camera image stream runs but every frame is discarded.

```dart
void _handleFrame(CameraImage image, PoseEstimationService poseService) {
  // poseService.addFrame(image);
}
```

> Given camera streaming is active, When frames arrive, Then each frame should be processed, or the image stream should not be started until the real ML pipeline is implemented.

---

### F-029 — **LOW** — _CompleteScreen may double-navigate on rebuild
**File:** `lib/features/screening/views/screening_view.dart:264-267`
**Source:** [claude]

`Future.delayed` in `initState` navigates after 1 second. If the widget rebuilds, a second delay is scheduled. The `mounted` check prevents crashes but not duplicate scheduling.

> Given the screening completes, When the complete screen is shown, Then navigation to the report should happen exactly once.

---

### F-030 — **LOW** — Mock always generates overhead squat landmarks
**File:** `lib/features/screening/controllers/screening_controller.dart:91-95`
**Source:** [claude]

`_startMockLandmarkFeed` hardcodes `screeningMovements.first.type` (overhead squat). As movements advance, the mock still emits squat patterns — single-leg balance, overhead reach, and forward fold all get squat landmarks.

```dart
final mock = MockPoseEstimationService(movementType: screeningMovements.first.type);
```

> Given the screening advances to single-leg balance, When landmarks are generated, Then they should match the current movement's pattern.

---

### F-031 — **LOW** — Worst-confidence logic duplicated 3x
**File:** `lib/features/report/views/report_view.dart:258`, `lib/features/report/services/pdf_generator.dart:36`, `lib/features/report/widgets/finding_card.dart:17`
**Source:** [claude]

Three identical implementations of worst-confidence-from-compensations. Should be a single extension method or utility.

> Given confidence-level comparison, When needed in multiple places, Then it should be defined once and reused.

---

## Appendix: Rejected Gemini Findings

| Gemini Finding | Severity | Description | Rejection Reason |
|---|---|---|---|
| Camera setup feedback missing | medium | "No implementation or interface for feedback system" | `SetupChecklist` widget exists in `lib/features/camera/widgets/setup_checklist.dart` with full step-by-step UI |
| PDF generation not wired | medium | "No service for generating/exporting PDFs" | `PdfGenerator` exists in `lib/features/report/services/pdf_generator.dart` and is called from `ReportView._generatePdf` |
| Dead MockPoseEstimation class | high | "If a separate MockPoseEstimation class exists, it is orphaned" | No such class exists. The class is `MockPoseEstimationService` and is correctly referenced |
