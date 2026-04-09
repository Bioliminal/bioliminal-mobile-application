# Add Unit Tests -- Chain Mapping, Screening State Machine, Report Assembly, Serialization, Routing, Privacy
Story: story-1309
Agent: unit-tester

## Context
All production logic services now have stable interfaces but zero test coverage. This story adds targeted unit tests for the six areas most likely to break silently: chain mapping rules, screening state machine transitions, report assembly output, model serialization, routing configuration, and the privacy/offline-first guard pattern. Every test file maps to a service or module that was created or stabilized by the preceding stories in this epic.

## Dependencies (all must complete before this story)
| Dependency | What it provides | Needed by |
|---|---|---|
| story-1301 | `RuleBasedChainMapper`, `RuleBasedAngleCalculator`, `CompensationProfile` in `domain/services/` | chain_mapping_test |
| story-1302 | `ReportAssemblyService` in `features/report/services/report_assembly_service.dart` | report_assembly_test |
| story-1299 | `cloudSyncEnabledProvider`, FirestoreService guard, offline-first providers | privacy_test |
| story-1300 | ReportView deep-link via LocalStorageService, ConsumerStatefulWidget conversion | routing_test |
| story-1304 | Screening controller disposal fix, movement type advancement, 60s timer | screening_controller_test |

## Files
| File | Purpose |
|---|---|
| test/unit/chain_mapping_test.dart | 5 compensation profiles, threshold boundaries, confidence propagation, _neverHighForAnkle |
| test/unit/screening_controller_test.dart | State machine transitions, skipMovement, startScreening guard, timer cleanup, disposal |
| test/unit/report_assembly_test.dart | ReportAssemblyService.buildReport output, chain grouping, upstream drivers, citations, practitioner points |
| test/unit/serialization_test.dart | assessmentToJson/assessmentFromJson round-trip, reportToJson/reportFromJson, edge cases |
| test/unit/routing_test.dart | GoRouter initialLocation, route path definitions, /report/:id parameter extraction |
| test/unit/privacy_test.dart | FirestoreService guards, LocalStorageService independence, cloudSyncEnabled default, provider graph |

<!-- CODER_ONLY -->
## Read-only context
- lib/domain/models.dart (all domain types)
- lib/domain/services/chain_mapper.dart (ChainMapper interface)
- lib/domain/services/angle_calculator.dart (AngleCalculator interface)
- lib/domain/mocks/mock_chain_mapper.dart (current source -- will be rule_based_chain_mapper.dart after story-1301)
- lib/domain/mocks/mock_angle_calculator.dart (current source -- will be rule_based_angle_calculator.dart after story-1301)
- lib/features/screening/controllers/screening_controller.dart (ScreeningState sealed class, ScreeningController)
- lib/features/screening/models/movement.dart (MovementConfig, screeningMovements)
- lib/features/report/views/report_view.dart (current _buildReport logic -- moves to ReportAssemblyService via story-1302)
- lib/core/services/local_storage_service.dart (serialization functions: assessmentToJson, assessmentFromJson, reportToJson, reportFromJson)
- lib/core/services/firestore_service.dart (FirestoreService with cloudSyncEnabled guard after story-1299)
- lib/core/services/auth_service.dart (AuthService)
- lib/core/providers.dart (provider graph -- cloudSyncEnabledProvider after story-1299)
- lib/core/router.dart (GoRouter configuration)
- plans/report-assembly.md (ReportAssemblyService contract)
- plans/rename-services.md (RuleBasedChainMapper/RuleBasedAngleCalculator contract, frame-skip guard)
- plans/offline-first-auth.md (cloudSyncEnabledProvider, FirestoreService guard pattern)
- plans/screening-fixes.md (disposal leak fix, movement type advancement)

## Tasks

### 1. chain_mapping_test.dart
Create `test/unit/chain_mapping_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/domain/services/rule_based_chain_mapper.dart` (post story-1301)
- `package:auralink/domain/services/rule_based_angle_calculator.dart` (post story-1301)
- `package:auralink/domain/models.dart`

Setup: instantiate `RuleBasedChainMapper` once, reuse across groups. Build landmark lists (33 landmarks) with varying visibility.

**group('SBL pattern')**:
- Create `RuleBasedAngleCalculator(profile: CompensationProfile.sblPattern)`
- Generate angles from 33 high-visibility landmarks (all visibility 0.95)
- Feed angles to `RuleBasedChainMapper().mapCompensations(angles)`
- `expect(result, isNotEmpty)`
- `expect(result.where((c) => c.chain == ChainType.sbl), isNotEmpty)` -- at least one SBL compensation
- `expect(result.any((c) => c.type == CompensationType.ankleRestriction), true)` -- ankle restriction present
- `expect(result.any((c) => c.type == CompensationType.kneeValgus), true)` -- knee valgus present
- `expect(result.any((c) => c.type == CompensationType.hipDrop), true)` -- hip drop present
- Verify all 3 compensations have `chain == ChainType.sbl`

**group('BFL pattern')**:
- Create `RuleBasedAngleCalculator(profile: CompensationProfile.bflPattern)`
- Generate angles from 33 high-visibility landmarks
- Feed to mapper
- `expect(result.where((c) => c.chain == ChainType.bfl), isNotEmpty)`
- `expect(result.any((c) => c.type == CompensationType.trunkLean && c.joint == 'shoulder'), true)`
- `expect(result.any((c) => c.type == CompensationType.hipDrop && c.joint == 'contralateral_hip'), true)`

**group('FFL pattern')**:
- Create `RuleBasedAngleCalculator(profile: CompensationProfile.fflPattern)`
- Generate angles from 33 high-visibility landmarks
- Feed to mapper
- `expect(result.where((c) => c.chain == ChainType.ffl), isNotEmpty)`
- `expect(result.any((c) => c.type == CompensationType.ankleRestriction), true)` -- ankle in FFL
- `expect(result.any((c) => c.joint == 'hip_flexors'), true)` -- hip flexors joint for FFL

**group('healthy pattern')**:
- Create `RuleBasedAngleCalculator(profile: CompensationProfile.healthy)`
- Generate angles from 33 high-visibility landmarks
- Feed to mapper
- `expect(result, isEmpty)` -- no compensations

**group('hypermobile pattern')**:
- Create `RuleBasedAngleCalculator(profile: CompensationProfile.hypermobile)`
- Generate angles from 33 high-visibility landmarks
- Feed to mapper
- `expect(result.length, 1)` -- single compensation
- `expect(result.first.type, CompensationType.kneeValgus)`
- `expect(result.first.chain, isNull)` -- no chain mapping
- `expect(result.first.citation.url, contains('PMC8558993'))` -- hypermobility citation

**group('threshold boundaries')**:
- Test knee valgus at exactly 10.0 (threshold value): create angle list with `left_knee_valgus: 10.0`, rest normal. Since the condition is `> threshold`, exactly 10.0 should NOT trigger. Verify empty result.
- Test knee valgus at 10.1: SHOULD trigger (as isolated, no chain). Verify kneeValgus present.
- Test ankle dorsiflexion at exactly 10.0: condition is `< _ankleDorsiflexionMin`, so exactly 10.0 should NOT trigger restriction. Verify no ankleRestriction.
- Test ankle dorsiflexion at 9.9: SHOULD trigger. Verify ankleRestriction present.

**group('confidence propagation')**:
- Create 33 landmarks with low visibility on ankle landmarks (indices 27, 28 at visibility 0.5), rest at 0.95
- Use sblPattern profile
- Feed through calculator then mapper
- Verify ankle compensation has `confidence != ConfidenceLevel.high` (low visibility -> low confidence)
- Verify the chain-level confidence is at worst the ankle's level (worst-of propagation)

**group('_neverHighForAnkle')**:
- Create 33 landmarks all at visibility 0.99 (would normally produce high confidence)
- Use sblPattern profile
- Feed through calculator then mapper
- Find ankleRestriction compensation
- `expect(ankleComp.confidence, isNot(ConfidenceLevel.high))` -- capped to medium
- Other SBL compensations (knee, hip) CAN be high

**group('citation completeness')**:
- For each of the 5 profiles, run through mapper
- For every compensation in the result, verify `c.citation.source.isNotEmpty` and `c.citation.url.isNotEmpty`

Helper function: `List<Landmark> _buildLandmarks({double visibility = 0.95})` -- generates 33 landmarks with the given visibility, using the same layout as MockPoseEstimationService._buildLandmarks with default neutral positions.

### 2. screening_controller_test.dart
Create `test/unit/screening_controller_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/features/screening/controllers/screening_controller.dart`
- `package:auralink/domain/services/rule_based_angle_calculator.dart`
- `package:auralink/domain/services/rule_based_chain_mapper.dart`
- `package:auralink/domain/models.dart`
- `package:auralink/features/screening/models/movement.dart`

Note: ScreeningController takes AngleCalculator and ChainMapper via constructor injection. Use RuleBasedAngleCalculator(profile: healthy) and RuleBasedChainMapper() directly -- no mocking framework needed.

Note: ScreeningController._startMockLandmarkFeed() calls MockPoseEstimationService which depends on `package:camera`. For unit tests that only test state transitions, do NOT call startScreening() (which triggers the mock feed). Instead, test the public API that doesn't depend on the mock pose service: skipMovement(), continueToNextMovement(), onLandmarkFrame(), and the initial state. For startScreening() tests, use a narrow scope: just verify the guard condition (only works from ScreeningSetup).

**group('initial state')**:
- Create controller
- `expect(controller.state, isA<ScreeningSetup>())`

**group('startScreening guard')**:
- Create controller, manually set state to ActiveMovement (via test seam -- not possible without calling startScreening). Alternative: verify that after construction, state is ScreeningSetup. Call startScreening guard check: since we can't easily mock the pose service in unit tests, instead document that this specific test requires the camera package to be available. For pure state-machine testing, skip startScreening and drive the controller via onLandmarkFrame after manually setting up state.
- Actually, since startScreening() calls _startMockLandmarkFeed which needs MockPoseEstimationService (depends on camera package), and this is a unit test: verify the guard by checking that calling startScreening from a non-ScreeningSetup state (by overriding state) is a no-op. BUT StateNotifier.state is settable. So: create controller, set state to ShowingFindings, call startScreening(), verify state is still ShowingFindings (guard blocked it).

**group('state machine transitions via onLandmarkFrame')**:
- Create controller with RuleBasedAngleCalculator(profile: healthy) and RuleBasedChainMapper()
- Manually set state to ActiveMovement for movement index 0 (overheadSquat config) with remaining: Duration(seconds: 60)
- Feed 33-landmark frames via onLandmarkFrame -- build enough frames to trigger peak detection (at least _derivativeWindow + 1 frames with a sign change in derivative)
- Verify that after targetReps peaks are detected, state transitions to ShowingFindings (for non-final movement) or ScreeningComplete (for final movement)

**group('skipMovement')**:
- Create controller
- Manually set state to ActiveMovement for movement index 0
- Call skipMovement()
- Verify state transitions (should be ShowingFindings for non-final movement since skipMovement calls _completeMovement)

**group('skipMovement from non-ActiveMovement')**:
- Set state to ScreeningSetup
- Call skipMovement()
- Verify state unchanged (guard)

**group('continueToNextMovement')**:
- Set state to ShowingFindings with completedMovementIndex: 0
- Call continueToNextMovement()
- Verify state is ActiveMovement with movementIndex: 1

**group('continueToNextMovement from non-ShowingFindings')**:
- Set state to ScreeningSetup
- Call continueToNextMovement()
- Verify state unchanged (guard)

**group('dispose cancels timer and subscription')**:
- Create controller
- Call dispose()
- Verify no errors thrown (smoke test -- actual timer/sub cancellation is internal)

### 3. report_assembly_test.dart
Create `test/unit/report_assembly_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/features/report/services/report_assembly_service.dart` (created by story-1302)
- `package:auralink/domain/models.dart`

Note: ReportAssemblyService has static methods (per story-1302 plan). All tests call `ReportAssemblyService.buildReport(assessment)` and `ReportAssemblyService.overallConfidence(findings)`.

Helper: build test Assessment objects with known compensations. Use factory functions to create Assessment with specific Compensation lists.

**group('empty compensations')**:
- Build Assessment with compensations: []
- Call buildReport
- `expect(report.findings, isEmpty)`
- `expect(report.practitionerPoints, isEmpty)`

**group('SBL chain grouping')**:
- Build Assessment with 3 SBL compensations: ankleRestriction (joint: 'ankle', chain: sbl), kneeValgus (joint: 'knee', chain: sbl), hipDrop (joint: 'hip', chain: sbl)
- Call buildReport
- `expect(report.findings.length, 1)` -- all 3 grouped into one finding
- `expect(report.findings.first.compensations.length, 3)`
- `expect(report.findings.first.bodyPathDescription, contains('ankle'))` -- body path mentions ankle
- `expect(report.findings.first.bodyPathDescription, contains('knee'))` -- body path mentions knee
- Body path description should NOT contain 'SBL', 'sbl', 'Superficial Back Line'

**group('upstream driver identification')**:
- Build Assessment with SBL compensations (ankle is origin for SBL per _chainOriginJoint)
- Call buildReport
- `expect(report.findings.first.upstreamDriver, isNotNull)` -- upstream driver identified
- `expect(report.findings.first.upstreamDriver, contains('ankle'))` -- ankle is the upstream driver for SBL

**group('FFL upstream driver is ankle')**:
- Build Assessment with FFL compensations (ankle is origin for FFL too)
- Call buildReport
- `expect(report.findings.first.upstreamDriver, contains('ankle'))`

**group('BFL upstream driver is shoulder')**:
- Build Assessment with BFL compensations (shoulder is origin for BFL)
- Call buildReport
- `expect(report.findings.first.upstreamDriver, contains('shoulder'))`

**group('standalone compensations')**:
- Build Assessment with one kneeValgus compensation with chain: null
- Call buildReport
- `expect(report.findings.length, 1)`
- `expect(report.findings.first.bodyPathDescription, contains('knee'))` -- standalone description mentions joint
- `expect(report.findings.first.upstreamDriver, isNull)` -- no chain, no upstream driver

**group('citation assembly')**:
- Build Assessment with SBL compensations
- Call buildReport
- Finding should have citations from: type-specific (Hewett for kneeValgus, Ferber for hipDrop, Wilke for ankleRestriction), chain-level (_chainCitation from Gnat 2022), and universal (_bahrCitation from Bahr 2016)
- `expect(finding.citations.any((c) => c.source.contains('Bahr')), true)` -- universal citation present
- `expect(finding.citations.any((c) => c.source.contains('Gnat')), true)` -- chain citation present for SBL

**group('practitioner points')**:
- Build Assessment with SBL compensations that have an upstream driver
- Call buildReport
- `expect(report.practitionerPoints, isNotEmpty)`
- `expect(report.practitionerPoints.first, contains('ankle'))` -- references the upstream driver

**group('practitioner points empty when no upstream driver')**:
- Build Assessment with standalone (null chain) compensations
- Call buildReport
- `expect(report.practitionerPoints, isEmpty)` -- no upstream driver, no practitioner points

**group('ankle confidence capping')**:
- Build Assessment with ankleRestriction compensation at ConfidenceLevel.high
- Call buildReport
- Find the ankle compensation in the finding
- `expect(ankleComp.confidence, ConfidenceLevel.medium)` -- capped from high to medium

**group('overallConfidence')**:
- Build findings with all high-confidence compensations: `expect(overallConfidence, ConfidenceLevel.high)`
- Build findings with one low-confidence compensation among highs: `expect(overallConfidence, ConfidenceLevel.low)`
- Build findings with medium and high: `expect(overallConfidence, ConfidenceLevel.medium)`

### 4. serialization_test.dart
Create `test/unit/serialization_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/core/services/local_storage_service.dart` (exports assessmentToJson, assessmentFromJson, reportToJson, reportFromJson)
- `package:auralink/domain/models.dart`

**group('Assessment round-trip')**:
- Build a full Assessment with: id, createdAt (DateTime.utc(2026, 4, 8, 12, 0)), 1 movement with 2 landmark frames and 3 keyframe angles, 2 compensations (one with chain, one without), report: null
- `assessmentToJson(assessment)` -> json -> `assessmentFromJson(json)`
- Verify all fields match: id, createdAt (compare toIso8601String), movements.length, movements.first.type, movements.first.landmarks.length, movements.first.keyframeAngles.length, movements.first.duration, compensations.length, compensations[0].type, compensations[0].chain, compensations[1].chain (null), report == null

**group('Assessment round-trip with Report')**:
- Build Assessment with a Report that has 1 Finding and 2 practitionerPoints and pdfUrl: 'https://example.com/report.pdf'
- Round-trip
- Verify report is not null, report.findings.length, report.findings.first.bodyPathDescription, report.practitionerPoints, report.pdfUrl

**group('Report round-trip')**:
- Build a Report with: 2 findings, 3 practitioner points, pdfUrl: null
- `reportToJson(report)` -> json -> `reportFromJson(json)`
- Verify findings.length, practitionerPoints.length, pdfUrl is null

**group('null chain in Compensation')**:
- Build Compensation with chain: null
- Serialize via assessmentToJson (in an Assessment)
- Verify json contains `'chain': null`
- Deserialize back, verify chain is null

**group('DateTime serialization')**:
- Build Assessment with specific DateTime
- Serialize
- Verify json `'createdAt'` is ISO 8601 string
- Deserialize, verify DateTime matches

**group('enum serialization')**:
- Build Compensation with each CompensationType, ChainType, ConfidenceLevel
- Serialize, verify enum is stored as `.name` string
- Deserialize, verify enum round-trips

**group('Duration serialization')**:
- Build Movement with duration: Duration(seconds: 45, milliseconds: 500)
- Serialize, verify `'durationMs'` key is 45500
- Deserialize, verify duration matches

**group('empty collections')**:
- Assessment with empty movements and empty compensations
- Round-trip, verify empty lists preserved

### 5. routing_test.dart
Create `test/unit/routing_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/core/router.dart`

Note: GoRouter configuration testing. These are unit-level checks on the GoRouter instance's configuration properties, NOT widget/navigation tests. No pumpWidget needed.

**group('initialLocation')**:
- `expect(goRouter.configuration.routes, isNotEmpty)`
- GoRouter doesn't expose initialLocation directly after construction on all versions. Alternative: verify `/disclaimer` is a defined route.

**group('route definitions')**:
- Extract route paths from `goRouter.configuration.routes` (each GoRoute has a `path` property)
- Verify `/disclaimer` route exists
- Verify `/screening` route exists
- Verify `/report/:id` route exists
- Verify `/camera` route exists

**group('/report/:id path parameter')**:
- Verify the /report/:id route definition contains `:id` in its path (confirming parameterized routing)

**group('no dead routes')**:
- Count total routes. After dead-code cleanup (story-1305 or prior), the `'/'` splash route may or may not still exist. If the route list contains `'/'`, that's acceptable pre-cleanup. Test that all defined routes have non-null builders.

### 6. privacy_test.dart
Create `test/unit/privacy_test.dart`.

Imports:
- `package:flutter_test/flutter_test.dart`
- `package:auralink/core/services/firestore_service.dart`
- `package:auralink/core/services/local_storage_service.dart`
- `package:auralink/core/providers.dart`
- `package:auralink/domain/models.dart`
- `dart:io` (for temp directory in LocalStorageService tests)

Note: After story-1299, FirestoreService constructor takes `cloudSyncEnabled` bool. When false, all public methods throw StateError. These tests verify that guard without needing Firebase SDK at all -- we test the guard in isolation.

**group('FirestoreService guard -- cloud sync disabled')**:
- This requires constructing FirestoreService, which needs FirebaseFirestore, FirebaseStorage, and AuthService instances. Since we can't instantiate real Firebase in unit tests, these tests verify the pattern described in story-1299.
- Alternative approach: since story-1299 adds `_requireCloudSync()` as the first line in every method, and the constructor accepts `cloudSyncEnabled: false`, we need mock Firebase instances. If firebase_core_platform_interface is available in test, use `setupFirebaseCoreMocks()`. Otherwise, these tests must run as integration tests.
- Pragmatic approach: test the provider graph behavior. Use `ProviderContainer` to verify that reading `firestoreServiceProvider` when `cloudSyncEnabledProvider` is false throws StateError.

```dart
test('firestoreServiceProvider throws when cloud sync disabled', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // cloudSyncEnabledProvider defaults to false
  expect(
    () => container.read(firestoreServiceProvider),
    throwsA(isA<StateError>()),
  );
});
```

```dart
test('cloudSyncEnabledProvider defaults to false', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  expect(container.read(cloudSyncEnabledProvider), false);
});
```

```dart
test('authServiceProvider throws when cloud sync disabled', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  expect(
    () => container.read(authServiceProvider),
    throwsA(isA<StateError>()),
  );
});
```

**group('LocalStorageService works without auth')**:
- Create LocalStorageService with a temp directory (using Directory.systemTemp.createTempSync)
- Build a minimal Assessment
- Call saveAssessment, then loadAssessment
- Verify round-trip works with zero auth, zero Firebase
- This proves offline-first persistence requires no cloud services

**group('provider graph -- no auth in default graph')**:
- Create ProviderContainer with no overrides
- `localStorageServiceProvider` should resolve without error (though it uses path_provider which won't work in test without override). Alternative: test that the provider is defined and doesn't depend on authServiceProvider or firestoreServiceProvider by verifying that a container with `localStorageServiceProvider` overridden can be used without touching auth providers.

```dart
test('localStorageService does not depend on auth', () {
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(
        LocalStorageService(directory: Directory.systemTemp.createTempSync()),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Should not throw -- no auth dependency
  final service = container.read(localStorageServiceProvider);
  expect(service, isA<LocalStorageService>());
});
```

**group('no cloud sync during screening flow')**:
- Verify that ScreeningController's dependencies (AngleCalculator, ChainMapper) do not transitively require auth or Firestore
- Create ProviderContainer with overrides for localStorageServiceProvider only
- Read angleCalculatorProvider and chainMapperProvider -- should resolve without error
- Reading firestoreServiceProvider should throw StateError
- This proves the screening flow is fully local

<!-- END_CODER_ONLY -->

## Acceptance criteria
1. `test/unit/chain_mapping_test.dart` verifies all 5 CompensationProfile outputs with correct chain/type/confidence assertions
2. `test/unit/chain_mapping_test.dart` verifies threshold boundary behavior at exactly 10.0 for knee valgus and ankle dorsiflexion
3. `test/unit/chain_mapping_test.dart` verifies ankle findings never carry ConfidenceLevel.high
4. `test/unit/chain_mapping_test.dart` verifies low-visibility landmarks produce low-confidence compensations
5. `test/unit/screening_controller_test.dart` verifies startScreening guard (no-op from non-ScreeningSetup state)
6. `test/unit/screening_controller_test.dart` verifies skipMovement transitions state correctly and guards from non-ActiveMovement
7. `test/unit/screening_controller_test.dart` verifies continueToNextMovement transitions and guards
8. `test/unit/report_assembly_test.dart` verifies buildReport produces correct Finding objects with chain grouping
9. `test/unit/report_assembly_test.dart` verifies upstream driver identification (ankle for SBL/FFL, shoulder for BFL)
10. `test/unit/report_assembly_test.dart` verifies citation assembly includes type-specific, chain-level, and universal citations
11. `test/unit/report_assembly_test.dart` verifies empty compensations produce empty findings
12. `test/unit/serialization_test.dart` verifies assessmentToJson/assessmentFromJson round-trip preserves all fields
13. `test/unit/serialization_test.dart` verifies null chain, null report, null pdfUrl survive round-trip
14. `test/unit/serialization_test.dart` verifies DateTime as ISO 8601 and enums by name
15. `test/unit/routing_test.dart` verifies /disclaimer, /screening, /report/:id, and /camera routes exist
16. `test/unit/privacy_test.dart` verifies firestoreServiceProvider and authServiceProvider throw StateError when cloud sync disabled
17. `test/unit/privacy_test.dart` verifies LocalStorageService works without auth/Firebase

## Verification
- `flutter test test/unit/chain_mapping_test.dart` -- all pass
- `flutter test test/unit/screening_controller_test.dart` -- all pass
- `flutter test test/unit/report_assembly_test.dart` -- all pass
- `flutter test test/unit/serialization_test.dart` -- all pass
- `flutter test test/unit/routing_test.dart` -- all pass
- `flutter test test/unit/privacy_test.dart` -- all pass
- No production code modified
- All test files import only from `package:auralink/` and `package:flutter_test/`
