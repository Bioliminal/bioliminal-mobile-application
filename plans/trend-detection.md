# Longitudinal trend detection service
Story: story-1328
Agent: architect

## Context
Users with multiple assessments need to see whether each compensation pattern is improving, worsening, or stable over time. The app currently supports pairwise comparison (ComparisonService.compare) between two adjacent assessments, but has no longitudinal analysis across a full assessment history. This story adds the domain models and a pure-logic service to classify compensation trends across an arbitrary number of assessments.

DATA_FLOW_TRACE segment:
[LocalStorageService.listAssessments()] -> List<Assessment> (sorted by createdAt desc)
-> [TrendDetectionService.analyzeTrends(assessments)] -> TrendReport
   - Groups compensations by (CompensationType, joint) across all assessments
   - Computes slope per group: (newest - oldest) / (count - 1)
   - Classifies: negative slope = improving, positive = worsening, abs < 1.0 = stable, only-in-newest = newPattern
-> [TrendReport.trendFor(type, joint)] -> CompensationTrend? (lookup helper)

## What changes
| File | Change |
|---|---|
| `lib/domain/models.dart` | Add `TrendClassification` enum (improving, worsening, stable, newPattern). Add `MobilityArchetype` enum (ankleDominant, hipDominant, trunkDominant, hypermobile, balanced). Add `CompensationTrend` data class (compensationType, joint, trend, values, slope). Add `TrendReport` data class (trends list + trendFor lookup helper). Add optional `TrendClassification? trendStatus` field to existing `Finding` class constructor (defaults to null, backward compatible). |
| `lib/features/history/services/trend_detection_service.dart` | New. TrendDetectionService with private constructor and static `analyzeTrends(List<Assessment>)` method. Groups compensations by (type, joint) across assessments (oldest-first), computes slope per group, classifies each trend, returns TrendReport. |

## Architecture
TrendDetectionService follows the same pattern as ComparisonService: private constructor, only static methods, pure functions, no Flutter imports. The service receives the full assessment list (newest-first from listAssessments), reverses it internally to process oldest-first for chronological slope calculation.

Slope calculation: `(newest_value - oldest_value) / (count - 1)` where count is the number of data points for that (type, joint) pair. For pairs with only one data point that appears only in the most recent assessment, classify as `newPattern`. Otherwise: `abs(slope) < 1.0` = stable, `slope < 0` = improving, `slope > 0` = worsening.

MobilityArchetype enum is defined here but classification logic belongs to story-1330 (ArchetypeClassifier). This story only adds the enum.

<!-- CODER_ONLY -->
## Read-only context
- lib/features/history/services/comparison_service.dart (follow conventions: private ctor, static methods, pure functions)
- lib/core/services/local_storage_service.dart (listAssessments returns sorted newest-first — service must handle this ordering)
- lib/domain/models.dart (existing types — append new types, do not modify existing)

## Tasks
1. In `lib/domain/models.dart`, append the following after the existing `Assessment` class:
   - `TrendClassification` enum with values: `improving`, `worsening`, `stable`, `newPattern`
   - `MobilityArchetype` enum with values: `ankleDominant`, `hipDominant`, `trunkDominant`, `hypermobile`, `balanced`
   - `CompensationTrend` class with const constructor and required final fields: `CompensationType compensationType`, `String joint`, `TrendClassification trend`, `List<double> values`, `double slope`
   - `TrendReport` class with const constructor, required final field `List<CompensationTrend> trends`, and method `CompensationTrend? trendFor(CompensationType type, String joint)` that returns the first matching trend or null
   - Add optional `TrendClassification? trendStatus` field to existing `Finding` class: add `this.trendStatus` as an optional named parameter (defaults to null). This is backward compatible — all existing Finding constructors continue to work.

2. Create `lib/features/history/services/trend_detection_service.dart`:
   - Import only `../../../domain/models.dart`
   - `TrendDetectionService._()` private constructor
   - `static TrendReport analyzeTrends(List<Assessment> assessments)`:
     - If assessments is empty, return TrendReport with empty trends list
     - Reverse the list to get oldest-first ordering
     - Build a `Map<(CompensationType, String), List<double>>` grouping compensation values by (type, joint) across all assessments in chronological order
     - Track which (type, joint) pairs appear only in the most recent assessment (last in chronological order)
     - For each group, compute slope: `(values.last - values.first) / (values.length - 1)` (if only one value and it's only-in-newest, classify as newPattern; if one value but appears in non-newest assessment, classify as stable with slope 0.0)
     - Classify: if newPattern flag, `TrendClassification.newPattern`; else if `slope.abs() < 1.0`, `stable`; else if `slope < 0`, `improving`; else `worsening`
     - Return `TrendReport(trends: [...])` with one `CompensationTrend` per group

3. Add unit tests in `test/features/history/services/trend_detection_service_test.dart`:
   - Test empty assessment list returns empty TrendReport
   - Test single assessment: all compensations classified as stable (not newPattern, since there's no "previous" to compare against — only-in-newest requires 2+ assessments)
   - Test two assessments where a compensation value decreases: classified as improving
   - Test two assessments where a compensation value increases: classified as worsening
   - Test two assessments where a compensation value stays the same: classified as stable
   - Test two assessments where a compensation type+joint appears only in the newer assessment: classified as newPattern
   - Test three assessments with a compensation that first increases then decreases: slope is (newest-oldest)/(count-1), verify correct classification
   - Test TrendReport.trendFor returns correct CompensationTrend for a given type+joint, and null for missing
<!-- END_CODER_ONLY -->

## Contract

### New types in `lib/domain/models.dart`
```dart
enum TrendClassification { improving, worsening, stable, newPattern }

enum MobilityArchetype { ankleDominant, hipDominant, trunkDominant, hypermobile, balanced }

class CompensationTrend {
  const CompensationTrend({
    required this.compensationType,
    required this.joint,
    required this.trend,
    required this.values,
    required this.slope,
  });
  final CompensationType compensationType;
  final String joint;
  final TrendClassification trend;
  final List<double> values;
  final double slope;
}

class TrendReport {
  const TrendReport({required this.trends});
  final List<CompensationTrend> trends;
  CompensationTrend? trendFor(CompensationType type, String joint);
}

// Modified existing class — add optional trendStatus field:
class Finding {
  const Finding({
    required this.bodyPathDescription,
    required this.compensations,
    this.upstreamDriver,
    required this.recommendation,
    required this.citations,
    this.drills = const [],
    this.trendStatus,  // NEW — optional, defaults to null
  });
  // ... existing fields unchanged ...
  final TrendClassification? trendStatus;
}
```

### New service in `lib/features/history/services/trend_detection_service.dart`
```dart
class TrendDetectionService {
  TrendDetectionService._();
  static TrendReport analyzeTrends(List<Assessment> assessments);
}
```

## Integration contracts
### Exports (other stories depend on these)
| Symbol | File | Consumer stories |
|---|---|---|
| `TrendClassification` | lib/domain/models.dart | story-1329, story-1327, story-1331 |
| `MobilityArchetype` | lib/domain/models.dart | story-1329, story-1327, story-1330, story-1331 |
| `CompensationTrend` | lib/domain/models.dart | story-1329, story-1327 |
| `TrendReport` | lib/domain/models.dart | story-1329, story-1327, story-1331 |
| `TrendDetectionService` | lib/features/history/services/trend_detection_service.dart | story-1327, story-1331 |
| `Finding.trendStatus` | lib/domain/models.dart | story-1329, story-1331 |

## Acceptance criteria
- `TrendClassification` enum has exactly four values: improving, worsening, stable, newPattern
- `MobilityArchetype` enum has exactly five values: ankleDominant, hipDominant, trunkDominant, hypermobile, balanced
- `CompensationTrend` has fields: compensationType (CompensationType), joint (String), trend (TrendClassification), values (List<double>), slope (double)
- `TrendReport` has a `trends` field and a `trendFor(CompensationType, String)` method that returns null when no match exists
- `TrendDetectionService.analyzeTrends([])` returns a TrendReport with an empty trends list
- Given 2+ assessments, a compensation whose value decreases over time is classified as `improving`
- Given 2+ assessments, a compensation whose value increases over time is classified as `worsening`
- Given 2+ assessments, a compensation whose value changes by less than 1.0 per step is classified as `stable`
- Given 2+ assessments, a compensation type+joint that appears only in the most recent assessment is classified as `newPattern`
- Given a single assessment, all compensations are classified as `stable` with slope 0.0
- Slope formula is `(newest_value - oldest_value) / (count - 1)`, using 0.0 when count == 1
- Stable threshold: `slope.abs() < 1.0`
- TrendDetectionService has no Flutter imports, no state, only static methods
- Finding class gains an optional `trendStatus` field (backward compatible — defaults to null)
- No existing types in models.dart have fields removed or renamed

## Verification
- All acceptance criteria pass via unit tests
- No changes to existing types in lib/domain/models.dart (only appended)
- Service follows ComparisonService conventions (private ctor, static methods, pure functions)
- No Flutter imports in service or models
<!-- TESTER_ONLY -->
test_files: test/features/history/services/trend_detection_service_test.dart
<!-- END_TESTER_ONLY -->
