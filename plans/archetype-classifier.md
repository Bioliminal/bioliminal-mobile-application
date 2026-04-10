# Mobility archetype classification
Story: story-1330
Agent: architect

## Context
Users with repeated assessments develop persistent compensation patterns. A user who consistently shows ankle dorsiflexion restriction across sessions is meaningfully different from one whose compensations are evenly distributed. Archetype classification clusters users into one of five buckets (ankle-dominant, hip-dominant, trunk-dominant, hypermobile, balanced) based on compensation frequency across their assessment history. Downstream consumers (story-1327 history dashboard, story-1329 drill selection, story-1331 coaching) use the archetype to personalize UI and recommendations.

ComparisonService established the convention: private constructor, all static methods, pure functions, no Flutter imports. ArchetypeClassifier follows the same pattern.

## What changes
| File | Change |
|---|---|
| `lib/features/history/services/archetype_classifier.dart` | New. ArchetypeClassifier with private constructor and a single static method `classify(List<Assessment>)` that returns `MobilityArchetype`. Counts compensation type frequencies across all assessments, applies deterministic threshold rules, and returns the dominant archetype or `balanced` when nothing dominates. |
| `lib/core/providers.dart` | No provider registration needed — both TrendDetectionService and ArchetypeClassifier are pure static utility classes with private constructors. Consumers import and call static methods directly (e.g., `TrendDetectionService.analyzeTrends(assessments)`). This avoids the private-constructor-vs-Provider conflict and follows the same pattern as ComparisonService (no provider, imported directly). |

## Architecture

### Classification algorithm
`classify(List<Assessment>) -> MobilityArchetype`:
1. If `assessments.isEmpty` or `assessments.length == 1`, return `MobilityArchetype.balanced` (insufficient data to establish a pattern).
2. Flatten all compensations across all assessments.
3. If total compensation count is 0, return `MobilityArchetype.balanced`.
4. Check hypermobility first (special rule): count assessments where any compensation has `value < 5.0 && chain == null`. If that count is >= 50% of total assessments, return `MobilityArchetype.hypermobile`.
5. Count frequency of each `CompensationType` across the flattened list. Group hip-related types: `hipDrop` and `kneeValgus` counts are summed for the hip-dominant bucket.
6. Calculate percentage of each bucket against total compensations:
   - ankle bucket: `ankleRestriction` count / total
   - hip bucket: (`hipDrop` + `kneeValgus`) count / total
   - trunk bucket: `trunkLean` count / total
7. If the highest percentage >= 40%, return the corresponding archetype (`ankleDominant`, `hipDominant`, `trunkDominant`).
8. Otherwise return `MobilityArchetype.balanced`.

### Hypermobility detection
Mirrors `ReportAssemblyService._hasHypermobilityIndicators`: a compensation with `value < 5.0 && chain == null` signals hypermobility. The archetype classifier checks whether this pattern appears in >= 50% of assessments (not just one).

### Provider registration
Both providers are stateless `Provider<T>` entries in the core providers section. No complex init, no ref.watch dependencies. The services have private constructors and only static methods, so the provider value is purely for DI consistency with how consumers import services.

<!-- CODER_ONLY -->
## Read-only context
- `lib/features/history/services/comparison_service.dart` — convention exemplar: private constructor, static methods, only `domain/models.dart` import
- `lib/features/report/services/report_assembly_service.dart` lines 228-235 — `_hasHypermobilityIndicators` logic: `c.value < 5.0 && c.chain == null`
- `lib/core/providers.dart` — provider registration pattern: prefixed alias imports, `Provider<T>((ref) => ...)` in core section
- `lib/domain/models.dart` — Assessment, Compensation, CompensationType, MobilityArchetype (from story-1328)
- `test/features/history/services/comparison_service_test.dart` — test convention: `_testCitation` constant, `_makeAssessment` helper, group/test structure
<!-- END_CODER_ONLY -->

## Contract

### lib/features/history/services/archetype_classifier.dart
```dart
import '../../../domain/models.dart';

class ArchetypeClassifier {
  ArchetypeClassifier._();

  /// Classifies a user into a mobility archetype based on compensation
  /// patterns across multiple assessments.
  ///
  /// Returns [MobilityArchetype.balanced] for empty or single-assessment
  /// histories (insufficient data to establish a pattern).
  static MobilityArchetype classify(List<Assessment> assessments) { ... }
}
```

### No provider registration
Both services use private constructors with only static methods. No provider needed — consumers import and call static methods directly. This avoids the private-constructor-vs-Provider conflict entirely and matches ComparisonService convention.

## Integration contracts

### Exports (this story produces)
| Symbol | File | Interface | Consumed by |
|---|---|---|---|
| `ArchetypeClassifier` | `lib/features/history/services/archetype_classifier.dart` | `static MobilityArchetype classify(List<Assessment>)` | story-1327, story-1329, story-1331 |

### Imports (this story depends on)
| Symbol | File | Expected interface | Producer story |
|---|---|---|---|
| `TrendDetectionService` | `lib/features/history/services/trend_detection_service.dart` | Service class (constructor visibility TBD by story-1328) | story-1328 |
| `MobilityArchetype` | `lib/domain/models.dart` | `enum MobilityArchetype { ankleDominant, hipDominant, trunkDominant, hypermobile, balanced }` | story-1328 |

<!-- CODER_ONLY -->
## Tasks

### Task 1: Implement ArchetypeClassifier
File: `lib/features/history/services/archetype_classifier.dart` (new)

Create the classifier following ComparisonService conventions:
- Import only `'../../../domain/models.dart'`
- Private constructor `ArchetypeClassifier._()`
- Single static method `classify(List<Assessment> assessments) -> MobilityArchetype`
- Implementation per the Architecture section above:
  1. Guard: empty list or single assessment -> `balanced`
  2. Flatten all compensations from all assessments
  3. Guard: zero compensations -> `balanced`
  4. Hypermobility check: count assessments containing any comp where `value < 5.0 && chain == null`. If count >= `assessments.length / 2` -> `hypermobile`
  5. Count by type: `ankleRestriction`, `hipDrop`, `kneeValgus`, `trunkLean`
  6. Compute bucket percentages: ankle = ankleCount/total, hip = (hipDropCount + kneeValgusCount)/total, trunk = trunkCount/total
  7. Find max bucket. If max >= 0.4, return corresponding archetype
  8. Otherwise return `balanced`

### Task 2: Remove providers.dart from write scope
No changes needed in `lib/core/providers.dart`. Both TrendDetectionService and ArchetypeClassifier are pure static utility classes with private constructors — no provider registration is appropriate. Consumers import the service files directly and call static methods (e.g., `TrendDetectionService.analyzeTrends(assessments)`, `ArchetypeClassifier.classify(assessments)`). This follows the same pattern as ComparisonService, which has no provider.

### Task 3: Unit tests
File: `test/features/history/services/archetype_classifier_test.dart` (new)

Follow comparison_service_test.dart conventions:
- Shared `_testCitation` constant and `_makeAssessment` helper (same as comparison test)
- Helper `_makeCompensation(CompensationType type, {double value = 10.0, ChainType? chain})` for concise test data

Test cases:
1. `'returns balanced for empty assessment list'` — `classify([])` -> `balanced`
2. `'returns balanced for single assessment'` — `classify([oneAssessment])` -> `balanced`
3. `'returns ankleDominant when ankleRestriction >= 40%'` — 3 assessments: first has 2 ankleRestriction + 1 hipDrop, second has 2 ankleRestriction, third has 1 ankleRestriction + 1 trunkLean. Ankle = 5/7 > 40%. Expect `ankleDominant`.
4. `'returns hipDominant when hipDrop + kneeValgus >= 40%'` — 2 assessments: first has 1 hipDrop + 1 kneeValgus, second has 1 hipDrop + 1 ankleRestriction. Hip bucket = 3/4 = 75%. Expect `hipDominant`.
5. `'returns trunkDominant when trunkLean >= 40%'` — 2 assessments where trunkLean dominates. Expect `trunkDominant`.
6. `'returns hypermobile when low-value chain-null compensations in >= 50% of assessments'` — 4 assessments: 3 have a compensation with `value: 3.0, chain: null`. 3/4 >= 50%. Expect `hypermobile`.
7. `'returns balanced when no type reaches 40%'` — 3 assessments with evenly distributed types (1 ankle, 1 hip, 1 trunk each). No bucket reaches 40%. Expect `balanced`.
8. `'hypermobility check takes priority over frequency'` — assessments where both hypermobility threshold and ankle threshold are met. Expect `hypermobile` (checked first).
9. `'returns balanced for assessments with no compensations'` — 3 assessments, all with empty compensation lists. Expect `balanced`.
<!-- END_CODER_ONLY -->

## Acceptance criteria
- `ArchetypeClassifier.classify([])` returns `MobilityArchetype.balanced`
- `ArchetypeClassifier.classify([singleAssessment])` returns `MobilityArchetype.balanced`
- Given 3+ assessments where `ankleRestriction` compensations constitute >= 40% of all compensations, `classify` returns `MobilityArchetype.ankleDominant`
- Given assessments where `hipDrop` + `kneeValgus` compensations constitute >= 40%, `classify` returns `MobilityArchetype.hipDominant`
- Given assessments where `trunkLean` compensations constitute >= 40%, `classify` returns `MobilityArchetype.trunkDominant`
- Given assessments where >= 50% contain a compensation with `value < 5.0` and `chain == null`, `classify` returns `MobilityArchetype.hypermobile` (takes priority over frequency rules)
- Given assessments where no compensation type reaches 40%, `classify` returns `MobilityArchetype.balanced`
- No providers registered — consumers call `TrendDetectionService.analyzeTrends()` and `ArchetypeClassifier.classify()` as static methods directly
- `archetype_classifier.dart` imports only `domain/models.dart` (no Flutter imports)
- All 9 unit tests in `test/features/history/services/archetype_classifier_test.dart` pass

## Verification
- ArchetypeClassifier follows ComparisonService convention: private constructor, static methods only, single domain/models import
- No provider registrations — static-only services don't need DI
- Hypermobility check runs before frequency check (priority order)
- Hip bucket correctly sums hipDrop and kneeValgus counts
- 40% threshold uses `>=` (not `>`)
- No Flutter/Riverpod imports in archetype_classifier.dart

<!-- TESTER_ONLY -->
test_files: test/features/history/services/archetype_classifier_test.dart
<!-- END_TESTER_ONLY -->
