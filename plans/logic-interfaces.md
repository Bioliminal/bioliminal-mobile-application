# Logic Engine Interfaces + Mocks
Story: story-1296
Agent: architect

## Context
Defines the three abstract service interfaces that form the logic engine contract between the Flutter app and the ML developer's implementation. Each interface gets a mock implementation that returns realistic, deterministic data so the rest of the app (screening flow, report generation, confidence visualization) can develop without waiting for real ML code.

These are the most critical contracts in the project. Once shipped, interface signatures are frozen — downstream features (camera pipeline, screening flow, report) all bind to them.

Files:
- lib/domain/services/pose_estimation_service.dart
- lib/domain/services/angle_calculator.dart
- lib/domain/services/chain_mapper.dart
- lib/domain/mocks/mock_pose_estimation.dart
- lib/domain/mocks/mock_angle_calculator.dart
- lib/domain/mocks/mock_chain_mapper.dart

## What changes
| File | Change |
|---|---|
| lib/domain/services/pose_estimation_service.dart | New abstract class `PoseEstimationService` with `Stream<List<Landmark>> processFrame(CameraImage frame)` and `void dispose()` |
| lib/domain/services/angle_calculator.dart | New abstract class `AngleCalculator` with `List<JointAngle> calculateAngles(List<Landmark> landmarks)` |
| lib/domain/services/chain_mapper.dart | New abstract class `ChainMapper` with `List<Compensation> mapCompensations(List<JointAngle> angles)` |
| lib/domain/mocks/mock_pose_estimation.dart | `MockPoseEstimationService` — streams pre-built landmark sequences for each of 4 movements with realistic visibility scores (ankle often degraded) |
| lib/domain/mocks/mock_angle_calculator.dart | `MockAngleCalculator` — returns deterministic joint angles that trigger known compensation patterns per movement type |
| lib/domain/mocks/mock_chain_mapper.dart | `MockChainMapper` — rule-based implementation applying published thresholds, mapping co-occurring flags to SBL/BFL/FFL chains with CC/CP logic, confidence levels, and citations |

<!-- CODER_ONLY -->
## Read-only context
- presearch/auralink-product.md
- lib/domain/models.dart (from story-1293)
- presearch/.scout-auralink-product.json (thresholds, chain mappings, CC/CP logic)

## Tasks

### 1. Define PoseEstimationService interface
Create `lib/domain/services/pose_estimation_service.dart`:
- Import `Landmark` model from story-1293's domain models
- Abstract class with:
  - `Stream<List<Landmark>> processFrame(CameraImage frame)` — takes a camera frame, returns a stream of landmark lists (33 landmarks per frame, each with x, y, z, visibility)
  - `void dispose()` — cleanup for stream controllers and ML resources
- Document that `CameraImage` comes from the `camera` package
- No implementation logic — this is the contract only

### 2. Define AngleCalculator interface
Create `lib/domain/services/angle_calculator.dart`:
- Import `Landmark` and `JointAngle` models
- Abstract class with:
  - `List<JointAngle> calculateAngles(List<Landmark> landmarks)` — takes a list of 33 landmarks, returns joint angles for hip, knee, ankle, and shoulder (both sides)
- Document that angle calculation uses 2D screen-space trigonometry (3D upgrade path exists via this same interface)
- No implementation logic

### 3. Define ChainMapper interface
Create `lib/domain/services/chain_mapper.dart`:
- Import `JointAngle` and `Compensation` models
- Abstract class with:
  - `List<Compensation> mapCompensations(List<JointAngle> angles)` — takes joint angles, applies thresholds, detects co-occurring patterns, maps to fascial chains, identifies upstream drivers (CC), returns compensation objects with chain assignment, confidence, and citation
- Document that this is where CC/CP logic lives: detect compensation at CP → trace upstream along chain → identify CC → recommend at CC

### 4. Implement MockPoseEstimationService
Create `lib/domain/mocks/mock_pose_estimation.dart`:
- Implements `PoseEstimationService`
- Constructor takes optional `MovementType` parameter to select which pre-built landmark sequence to stream
- Pre-built landmark data for each of the 4 movements:
  - **Overhead squat**: 33 landmarks across ~30 frames simulating descent to parallel. Knee landmarks drift medially (valgus). Ankle visibility degrades mid-squat (0.6-0.7). Hip/knee visibility stays high (0.9+).
  - **Single-leg balance**: Standing leg landmarks stable. Non-stance leg elevated. Hip drop visible via pelvis landmark asymmetry. Trunk lean ~7° lateral. Ankle visibility medium (0.75).
  - **Overhead reach**: Arms overhead. Shoulder landmarks show slight asymmetry (left depression). Thoracic landmarks show limited rotation. All upper body visibility high (0.9+).
  - **Forward fold**: Forward bend. Hamstring landmarks stretched. Ankle landmarks often occluded (visibility 0.4-0.5 — this is the known MediaPipe weakness). Hip/spine visibility medium (0.8).
- Stream emits landmarks at ~30fps pace (one List<Landmark> per ~33ms) using a periodic timer
- `dispose()` cancels the timer and closes the stream controller
- Landmarks use normalized coordinates (0.0-1.0 range for x, y) matching MediaPipe output format

### 5. Implement MockAngleCalculator
Create `lib/domain/mocks/mock_angle_calculator.dart`:
- Implements `AngleCalculator`
- Constructor takes optional `CompensationProfile` enum (`sblPattern`, `bflPattern`, `fflPattern`, `healthy`, `hypermobile`) to control which angle set is returned
- Returns deterministic angles that trigger specific patterns:
  - **sblPattern**: knee valgus 15° (above 10° threshold), ankle dorsiflexion 7° (below 10° threshold), hip drop present (gluteus medius angle asymmetry >10°)
  - **bflPattern**: shoulder depression detected (asymmetry >8°), thoracic rotation limited (below normal range), contralateral hip abduction weakness (asymmetry >10°)
  - **fflPattern**: ankle plantarflexion dominant (>20°), knee extension bias, hip flexion angle elevated (>30° in standing)
  - **healthy**: all angles within normal thresholds, no compensations triggered
  - **hypermobile**: knee external rotation 50° (>45° threshold), knee valgus 3° (<5° threshold — triggers reverse interpretation)
- Each JointAngle includes confidence derived from corresponding landmark visibility (high for hip/knee, reduced for ankle)

### 6. Implement MockChainMapper
Create `lib/domain/mocks/mock_chain_mapper.dart`:
- Implements `ChainMapper`
- Rule-based logic using published thresholds from scout data:

**Threshold detection:**
- Knee valgus: angle > 10° → flag (Hewett 2005, PubMed 15722287)
- Knee asymmetry: left-right difference > 10° → flag
- Hip drop: pelvis angle asymmetry during single-leg → flag (Ferber, PubMed 25102167)
- Ankle restriction: dorsiflexion < 10° OR plantarflexion asymmetry > 15° → flag (reduced confidence always)
- Trunk lean: > 5° lateral during single-leg balance → flag
- Hypermobility check: knee ER > 45° AND valgus < 5° → reverse threshold interpretation (PMC8558993)

**Chain mapping rules:**
- SBL candidate: ankle restriction + knee valgus + hip drop → assign `ChainType.sbl`. CC: ankle (dorsiflexion restriction). CP: knee (valgus). Citation: Wilke 2016, Hewett 2005, Ferber.
- BFL candidate: shoulder depression + thoracic rotation limitation + contralateral hip weakness → assign `ChainType.bfl`. CC: shoulder or thoracic spine. CP: contralateral knee. Citation: Wilke 2016.
- FFL candidate: ankle plantarflexion + knee extension + hip flexion dominance → assign `ChainType.ffl`. CC: ankle (plantarflexion dominance) or hip flexors. CP: knee. Citation: Wilke 2016.
- If flags don't cluster into a chain: return individual `Compensation` objects with `chain: null`

**CC/CP logic:**
- For each chain candidate: set `Compensation.upstreamDriver` to the CC joint (farthest upstream in the chain from the symptom)
- SBL trace: ankle → knee → hip → lower back
- BFL trace: shoulder → thoracic → lumbar → contralateral hip → knee
- FFL trace: ankle → knee → hip flexors → lumbar → shoulder

**Confidence assignment:**
- High: all contributing joints have landmark visibility > 0.9
- Medium: any contributing joint has visibility 0.7-0.9
- Low: any contributing joint has visibility < 0.7 (e.g., ankle in forward fold) — always the case for ankle-dependent findings

**Citations:**
- Each Compensation object includes a `Citation` with source name, finding summary, and PubMed URL from the scout data

### 7. Write tests
Create test files that verify mock implementations return valid domain objects:

**test/domain/services/angle_calculator_test.dart:**
- Given landmarks from MockPoseEstimation, MockAngleCalculator returns non-empty list of JointAngle objects
- Given `sblPattern` profile, returned angles include knee valgus > 10°
- Given `healthy` profile, no angles exceed compensation thresholds
- Given `hypermobile` profile, knee ER > 45° and valgus < 5°

**test/domain/services/chain_mapper_test.dart:**
- Given angles from `sblPattern`, ChainMapper returns at least one Compensation with `chain == ChainType.sbl`
- Given angles from `bflPattern`, returns Compensation with `chain == ChainType.bfl`
- Given angles from `fflPattern`, returns Compensation with `chain == ChainType.ffl`
- Given angles from `healthy`, returns empty list
- Every returned Compensation has a non-null citation

**test/domain/mocks/mock_chain_mapper_test.dart:**
- SBL chain: ankle restriction + knee valgus + hip drop → SBL assignment with ankle as CC and knee as CP
- BFL chain: shoulder + thoracic + hip → BFL assignment
- FFL chain: plantarflexion + extension + flexion → FFL assignment
- Hypermobility: reversed thresholds applied when knee ER > 45° and valgus < 5°
- Confidence: ankle-dependent findings always get reduced confidence (medium or low, never high)
- CC/CP: upstream driver is correctly identified (e.g., ankle for SBL, not knee)
- Person A vs Person B: same knee valgus + different context (ankle restriction vs hypermobility) → different chain assignment and different recommendation
<!-- END_CODER_ONLY -->

## Contract

```dart
/// Takes a camera frame, returns a stream of 33 landmarks with
/// x, y, z coordinates and visibility confidence scores.
/// CameraImage comes from the `camera` package.
abstract class PoseEstimationService {
  Stream<List<Landmark>> processFrame(CameraImage frame);
  void dispose();
}

/// Takes 33 landmarks, returns joint angles for hip, knee, ankle,
/// and shoulder (both sides) using 2D screen-space trigonometry.
/// 3D upgrade path: same interface, swap implementation.
abstract class AngleCalculator {
  List<JointAngle> calculateAngles(List<Landmark> landmarks);
}

/// Takes joint angles, applies published thresholds, detects
/// co-occurring compensation patterns, maps to SBL/BFL/FFL chains,
/// identifies upstream driver (CC) vs symptom site (CP).
/// Returns Compensation objects with chain, confidence, and citation.
abstract class ChainMapper {
  List<Compensation> mapCompensations(List<JointAngle> angles);
}
```

## Acceptance criteria
- All three abstract interfaces compile and import correctly from `lib/domain/services/`
- MockPoseEstimationService streams landmark data for all 4 movement types with varying visibility scores (ankle degraded in forward fold)
- MockAngleCalculator returns angles that trigger each of the 5 profiles (sblPattern, bflPattern, fflPattern, healthy, hypermobile)
- MockChainMapper correctly maps SBL pattern (ankle restriction + knee valgus + hip drop) to ChainType.sbl with ankle as upstream driver
- MockChainMapper correctly maps BFL pattern (shoulder + thoracic + contralateral hip) to ChainType.bfl
- MockChainMapper correctly maps FFL pattern (plantarflexion + extension + hip flexion) to ChainType.ffl
- MockChainMapper returns empty list for healthy profile (no compensations)
- Hypermobility case: knee ER >45° + valgus <5° triggers reversed threshold interpretation, not standard SBL mapping
- Ankle-dependent findings always carry reduced confidence (never high)
- Every Compensation includes a non-null Citation with source and URL
- Person A (knee valgus + ankle restriction) and Person B (knee valgus + hypermobility) produce different chain assignments
- All tests in test_files pass

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- Interfaces match signatures documented in presearch/auralink-product.md (processFrame, calculateAngles, mapCompensations)
- Mock data shapes match domain models from story-1293
- Threshold values match scout data (knee valgus >10°, dorsiflexion <10°, trunk lean >5°, knee ER >45°, etc.)
- Chain mapping rules match scout data (SBL = ankle+knee+hip, BFL = shoulder+thoracic+hip, FFL = plantarflexion+extension+flexion)
<!-- TESTER_ONLY -->
test_files: test/domain/services/angle_calculator_test.dart, test/domain/services/chain_mapper_test.dart, test/domain/mocks/mock_chain_mapper_test.dart
<!-- END_TESTER_ONLY -->
