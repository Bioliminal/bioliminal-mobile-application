# Rename Mock Services to RuleBased
Story: story-1301
Agent: architect

## Context
MockChainMapper and MockAngleCalculator contain real production business logic (455 lines of threshold detection, chain mapping, CC/CP identification, hypermobility detection, and confidence assignment). They implement the `ChainMapper` and `AngleCalculator` interfaces and are the only implementations that exist. The "Mock" prefix is a lie — these are rule-based production services. This story renames them, moves them from `domain/mocks/` to `domain/services/`, and deletes the old files.

MockPoseEstimationService stays in `domain/mocks/` — it is a true mock (streams pre-built landmark sequences) that will be replaced by another developer's ML implementation.

This is the root dependency for 5 downstream stories. File paths must be exact.

Files (write):
- lib/domain/services/rule_based_chain_mapper.dart
- lib/domain/services/rule_based_angle_calculator.dart

Files (delete):
- lib/domain/mocks/mock_chain_mapper.dart
- lib/domain/mocks/mock_angle_calculator.dart

Files (read-only, do not modify):
- lib/domain/services/chain_mapper.dart
- lib/domain/services/angle_calculator.dart
- lib/domain/models.dart
- lib/core/providers.dart (story-1299 owns import updates)

## What changes
| File | Change |
|---|---|
| lib/domain/services/rule_based_chain_mapper.dart | New file. Class `RuleBasedChainMapper implements ChainMapper`. Exact logic from MockChainMapper with class rename. Import path changes from `../models.dart` to `../models.dart` (same — already relative within services/), interface import from `chain_mapper.dart` (same directory, no prefix needed). |
| lib/domain/services/rule_based_angle_calculator.dart | New file. Class `RuleBasedAngleCalculator implements AngleCalculator` + `CompensationProfile` enum. Exact logic from MockAngleCalculator with class rename. Import path: `../models.dart` and `angle_calculator.dart`. |
| lib/domain/mocks/mock_chain_mapper.dart | Delete. |
| lib/domain/mocks/mock_angle_calculator.dart | Delete. |

<!-- CODER_ONLY -->
## Read-only context
- lib/domain/models.dart — domain model classes (Landmark, JointAngle, ConfidenceLevel, Compensation, ChainType, Citation, etc.)
- lib/domain/services/chain_mapper.dart — abstract `ChainMapper` interface
- lib/domain/services/angle_calculator.dart — abstract `AngleCalculator` interface
- lib/core/providers.dart — currently imports from `domain/mocks/`. Story-1299 will update these imports to point at the new locations. Do NOT modify this file.
- plans/logic-interfaces.md — original plan that created the mock files

## Tasks

### 1. Create RuleBasedChainMapper
Create `lib/domain/services/rule_based_chain_mapper.dart`:
- Copy all content from `lib/domain/mocks/mock_chain_mapper.dart`
- Rename class `MockChainMapper` to `RuleBasedChainMapper`
- Update imports: `import '../models.dart';` stays the same. Change `import '../services/chain_mapper.dart';` to `import 'chain_mapper.dart';` (now in the same directory)
- Update doc comment: remove "Mock" references, describe as "Rule-based chain mapper using published thresholds"
- All threshold constants, citations, detection methods, chain mapping logic, CC/CP logic, and confidence helpers remain identical — zero logic changes

### 2. Create RuleBasedAngleCalculator
Create `lib/domain/services/rule_based_angle_calculator.dart`:
- Copy all content from `lib/domain/mocks/mock_angle_calculator.dart`
- Rename class `MockAngleCalculator` to `RuleBasedAngleCalculator`
- Keep `CompensationProfile` enum in this file (it's co-located with its only consumer)
- Update imports: `import '../models.dart';` stays the same. Change `import '../services/angle_calculator.dart';` to `import 'angle_calculator.dart';`
- Update doc comment: remove "Mock" references, describe as "Rule-based angle calculator returning deterministic joint angles for known compensation profiles"
- All profile methods (_sblAngles, _bflAngles, _fflAngles, _healthyAngles, _hypermobileAngles), visibility helpers, and confidence mapping remain identical

### 3. Add frame-skip guard to RuleBasedAngleCalculator
In `RuleBasedAngleCalculator.calculateAngles`:
- Before the switch statement, add: `if (landmarks.length != 33) return [];`
- This prevents downstream chain mapping from receiving garbage angles when MediaPipe drops landmarks (known issue during fast movement)
- The interface contract says "Takes 33 landmarks" — returning empty for non-33 input enforces it

### 4. Prepare RuleBasedChainMapper for ConfidenceLevel extension (story-1307)
In `RuleBasedChainMapper._worstConfidence`:
- Add a `// TODO(story-1307): Replace with ConfidenceLevel.worst(levels) extension method` comment above the method
- Do NOT implement the extension — story-1307 owns that. This just marks the seam so the coder knows where to integrate.
- Same for `_neverHighForAnkle` — add `// TODO(story-1307): Replace with conf.capped(ConfidenceLevel.medium) extension method`

### 5. Delete old mock files
- Delete `lib/domain/mocks/mock_chain_mapper.dart`
- Delete `lib/domain/mocks/mock_angle_calculator.dart`
- Do NOT delete `lib/domain/mocks/mock_pose_estimation.dart` — it's a true mock for the ML developer's work

### 6. Write tests
Create `test/domain/services/rule_based_chain_mapper_test.dart`:
- SBL: angles from sblPattern profile -> at least one Compensation with `chain == ChainType.sbl`
- BFL: angles from bflPattern -> `chain == ChainType.bfl`
- FFL: angles from fflPattern -> `chain == ChainType.ffl`
- Healthy: angles from healthy profile -> empty list
- Hypermobility: angles from hypermobile profile -> Compensation with citation referencing PMC8558993, chain is null
- Ankle confidence cap: SBL ankle compensation never has `ConfidenceLevel.high`
- Every Compensation has a non-null citation with non-empty source and url
- Person differentiation: same mapper, sblPattern angles vs hypermobile angles -> different chain assignments

Create `test/domain/services/rule_based_angle_calculator_test.dart`:
- Frame skip: `calculateAngles([])` returns empty list
- Frame skip: 32 landmarks returns empty list
- Frame skip: 34 landmarks returns empty list
- sblPattern: returns angles including knee valgus > 10 degrees
- healthy: no angle exceeds any compensation threshold
- hypermobile: knee ER > 45 degrees and knee valgus < 5 degrees
- All profiles return exactly 16-18 JointAngle objects (each profile has that many)
- Confidence derived from landmark visibility: landmarks with visibility 0.5 -> ConfidenceLevel.low on their angles
<!-- END_CODER_ONLY -->

## Contract

```dart
// lib/domain/services/rule_based_chain_mapper.dart

/// Rule-based chain mapper using published thresholds from scout data.
/// Applies threshold detection, chain mapping, CC/CP logic, confidence
/// assignment, and citations.
class RuleBasedChainMapper implements ChainMapper {
  @override
  List<Compensation> mapCompensations(List<JointAngle> angles);

  // Internal (private) — not part of interface, listed for completeness:
  // _buildAngleMap, _buildConfidenceMap, _jointToRegion
  // _detectKneeValgus, _detectAnkleRestriction, _detectHipDrop,
  //   _detectShoulderDepression, _detectThoracicLimitation,
  //   _detectContralateralHipWeakness, _detectPlantarflexionDominance,
  //   _detectKneeExtensionBias, _detectHipFlexionDominance,
  //   _detectTrunkLean, _detectHypermobility
  // _worstConfidence, _neverHighForAnkle, _ankleConfidence
}
```

```dart
// lib/domain/services/rule_based_angle_calculator.dart

enum CompensationProfile {
  sblPattern,
  bflPattern,
  fflPattern,
  healthy,
  hypermobile,
}

/// Returns deterministic joint angles that trigger specific compensation
/// patterns. Each profile produces angles matching published thresholds.
class RuleBasedAngleCalculator implements AngleCalculator {
  RuleBasedAngleCalculator({CompensationProfile profile = CompensationProfile.healthy});

  final CompensationProfile profile;

  @override
  List<JointAngle> calculateAngles(List<Landmark> landmarks);
  // Returns [] if landmarks.length != 33 (frame-skip guard)
}
```

## Acceptance criteria
1. `RuleBasedChainMapper` compiles, implements `ChainMapper`, and lives at `lib/domain/services/rule_based_chain_mapper.dart`
2. `RuleBasedAngleCalculator` compiles, implements `AngleCalculator`, and lives at `lib/domain/services/rule_based_angle_calculator.dart`
3. `CompensationProfile` enum is exported from `rule_based_angle_calculator.dart`
4. SBL pattern angles -> at least one `Compensation` with `chain == ChainType.sbl` and ankle as the restriction finding
5. BFL pattern angles -> at least one `Compensation` with `chain == ChainType.bfl`
6. FFL pattern angles -> at least one `Compensation` with `chain == ChainType.ffl`
7. Healthy profile -> empty compensation list
8. Hypermobile profile -> reversed threshold interpretation (knee ER flagged, not knee valgus), chain is null
9. Ankle-dependent findings never carry `ConfidenceLevel.high`
10. Every `Compensation` includes a `Citation` with non-empty `source` and `url`
11. `calculateAngles` returns `[]` when `landmarks.length != 33`
12. `lib/domain/mocks/mock_chain_mapper.dart` and `lib/domain/mocks/mock_angle_calculator.dart` are deleted
13. `lib/domain/mocks/mock_pose_estimation.dart` is NOT deleted
14. `lib/core/providers.dart` is NOT modified (story-1299's responsibility)
15. All logic is identical to the original mock implementations except: class renames, import path updates, doc comment updates, frame-skip guard (task 3), and TODO comments (task 4)

## Verification
- `dart analyze lib/domain/services/rule_based_chain_mapper.dart` — no errors
- `dart analyze lib/domain/services/rule_based_angle_calculator.dart` — no errors
- `flutter test test/domain/services/rule_based_chain_mapper_test.dart` — all pass
- `flutter test test/domain/services/rule_based_angle_calculator_test.dart` — all pass
- `ls lib/domain/mocks/` contains only `mock_pose_estimation.dart`
- No changes to any file outside write scope
<!-- TESTER_ONLY -->
test_files: test/domain/services/rule_based_chain_mapper_test.dart, test/domain/services/rule_based_angle_calculator_test.dart
<!-- END_TESTER_ONLY -->
