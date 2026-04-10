# Finding prioritization based on movement history
Story: story-1329
Agent: architect
Depends: story-1328 (TrendReport, TrendClassification, CompensationTrend, MobilityArchetype, Finding.trendStatus in models.dart)

## Context
Currently buildReport treats all findings equally — no ordering, no trend context, no archetype awareness. Users who have multiple assessments get the same generic recommendations whether a pattern is getting worse, improving, or appearing for the first time. This story enriches report assembly so findings are sorted by clinical priority (recurring > worsening > new > stable), recommendation text evolves based on trend data, and drill selection accounts for the user's mobility archetype.

When trendReport is null (first assessment, or legacy callers), behavior is identical to current — no sorting, no trend annotations, no archetype drill boosting.

DATA_FLOW_TRACE segment:
[buildReport(assessment, {trendReport?, archetype?})]
→ trendReport?.lookup(compensationType, joint) → TrendClassification?
→ assign Finding.trendStatus per finding's dominant compensation
→ sort findings: recurring(4) > worsening(3) > newPattern(2) > stable(1) > null(0)
→ evolve recommendation text based on trendStatus
→ _selectDrills enhanced: archetype overrides drill pool selection
→ Report with prioritized findings, trend-aware recommendations, archetype-targeted drills

## What changes
| File | Change |
|---|---|
| `lib/features/report/services/report_assembly_service.dart` | Expand `buildReport` signature to accept optional `TrendReport?` and `MobilityArchetype?`. Add `_assignTrendStatus` to look up each finding's dominant compensation in the trend report. Add `_priorityScore` mapping TrendClassification to sort weight. Sort findings by priority (stable sort). Modify recommendation text based on trendStatus. Extend `_selectDrills` to accept optional archetype and boost drills for the dominant joint region. |

## Architecture

### Priority scoring
Each finding's dominant compensation (first in list) is looked up in TrendReport. The resulting TrendClassification maps to a sort score:
- recurring (appears across all prior assessments): **4** — Note: TrendClassification doesn't have a "recurring" value. A compensation is treated as recurring when its trend is `stable` AND it appears in 3+ assessments (i.e., `CompensationTrend.values.length >= 3`). Score: 4.
- worsening: **3**
- newPattern: **2**
- stable (fewer than 3 data points): **1**
- null (no trend data): **0**

Stable sort preserves original chain-grouped order within same priority tier.

### Recommendation text evolution
Applied after base recommendation is built (existing logic unchanged):
| Trend | Text mutation |
|---|---|
| improving | Append ` — this pattern is improving, keep up your current work` |
| worsening | Prepend `Priority: `, append ` — this pattern has worsened since your last assessment` |
| newPattern | Append ` — this is a new pattern we haven't seen before` |
| stable / recurring | No change |
| null | No change |

### Archetype-targeted drill selection
_selectDrills gains an optional `MobilityArchetype?` parameter:
| Archetype | Behavior |
|---|---|
| hypermobile | Always return stabilityDrills (existing behavior, now explicit) |
| ankleDominant | Select ankle drills first from mobilityDrillsByType[ankleRestriction], fill remaining slots from compensation-matched drills |
| hipDominant | Select hip drills first from mobilityDrillsByType[hipDrop], fill remaining slots from compensation-matched drills |
| trunkDominant | Select core drills first from mobilityDrillsByType[trunkLean], fill remaining slots from compensation-matched drills |
| balanced / null | Existing _selectDrills logic unchanged |

Drill count stays at 2 per finding.

<!-- CODER_ONLY -->
## Read-only context
- lib/domain/models.dart — Finding (with trendStatus field from story-1328), TrendReport, TrendClassification, CompensationTrend, MobilityArchetype, Compensation, CompensationType, Assessment
- lib/features/report/data/mobility_drills.dart — mobilityDrillsByType, stabilityDrills
- test/features/report/services/report_assembly_service_test.dart — existing tests to extend

## Contract

### Modified signatures
```dart
// Before:
static Report buildReport(Assessment assessment)

// After:
static Report buildReport(
  Assessment assessment, {
  TrendReport? trendReport,
  MobilityArchetype? archetype,
})
```

### New private functions
```dart
/// Look up the dominant compensation's trend and return the classification.
/// Returns null when trendReport is null or no match found.
static TrendClassification? _lookupTrend(
  List<Compensation> comps,
  TrendReport? trendReport,
)

/// Map a TrendClassification + CompensationTrend to a numeric priority.
/// recurring (stable + 3+ data points) = 4, worsening = 3, newPattern = 2, stable = 1, null = 0.
static int _priorityScore(TrendClassification? trend, CompensationTrend? ct)

/// Mutate recommendation text based on trend status.
static String _evolveRecommendation(String base, TrendClassification? trend)

/// Extended drill selection with archetype awareness.
static List<MobilityDrill> _selectDrills(
  List<Compensation> comps,
  bool isHypermobile, {
  MobilityArchetype? archetype,
})
```

### Dependencies on story-1328 model additions
- `TrendClassification` enum: `improving`, `worsening`, `stable`, `newPattern`
- `MobilityArchetype` enum: `ankleDominant`, `hipDominant`, `trunkDominant`, `hypermobile`, `balanced`
- `TrendReport` with `List<CompensationTrend>` and `CompensationTrend? lookup(CompensationType type, String joint)`
- `CompensationTrend` with `compensationType`, `joint`, `trend` (TrendClassification), `values` (List<double>), `slope`
- `Finding.trendStatus` field: `TrendClassification?` (optional, added to Finding constructor by story-1328)

## Integration contracts

### Exports (this story produces)
| Symbol | File | Interface | Consumer stories |
|---|---|---|---|
| ReportAssemblyService.buildReport | lib/features/report/services/report_assembly_service.dart | static Report buildReport(Assessment, {TrendReport?, MobilityArchetype?}) | story-1331 |

### Imports (this story depends on)
| Symbol | From file | Expected interface | Producer story |
|---|---|---|---|
| TrendReport | lib/domain/models.dart | class with trendFor(CompensationType, String) → CompensationTrend? | story-1328 |
| TrendClassification | lib/domain/models.dart | enum: improving, worsening, stable, newPattern | story-1328 |
| CompensationTrend | lib/domain/models.dart | class with compensationType, joint, trend, values, slope | story-1328 |
| MobilityArchetype | lib/domain/models.dart | enum: ankleDominant, hipDominant, trunkDominant, hypermobile, balanced | story-1328 |
| Finding.trendStatus | lib/domain/models.dart | TrendClassification? optional field on Finding | story-1328 |

## Tasks
1. **Extend buildReport signature** — Add optional named parameters `{TrendReport? trendReport, MobilityArchetype? archetype}`. Pass archetype to `_selectDrills`. All existing callers continue to work (both params optional).

2. **Add `_lookupTrend` helper** — Takes the finding's compensation list and TrendReport. Looks up the first compensation's (dominant) type+joint via `trendReport.trendFor(comp.type, comp.joint)`. Returns the `TrendClassification` from the matched `CompensationTrend`, or null.

3. **Add `_priorityScore` helper** — Takes `TrendClassification?` and `CompensationTrend?`. If trend is `stable` and `ct != null && ct.values.length >= 3`, return 4 (recurring). Otherwise: worsening → 3, newPattern → 2, stable → 1, null → 0.

4. **Assign trendStatus to findings** — After the existing findings-building loop, if `trendReport != null`: iterate findings, call `_lookupTrend`, set `trendStatus` on each Finding via reconstruction (Finding is immutable, so create a new Finding with all same fields plus trendStatus).

5. **Sort findings by priority** — After assigning trendStatus: look up each finding's CompensationTrend (for recurring detection) and sort the findings list using `_priorityScore`. Use a stable sort (Dart's List.sort is stable as of Dart 2.18+, but to be safe, use indexed sort: assign indices, sort by (score, index)).

6. **Add `_evolveRecommendation` helper** — Takes base recommendation string and TrendClassification?. Applies text mutations per the architecture table. Return the mutated string.

7. **Integrate recommendation evolution** — In the findings-building loop, after computing base recommendation, call `_evolveRecommendation(recommendation, trendStatus)`. This means trend lookup needs to happen inside the loop (before Finding construction), not after. Restructure: move trend lookup to inside the loop so both trendStatus and evolved recommendation are set during Finding construction.

8. **Extend `_selectDrills` with archetype** — Add optional `MobilityArchetype? archetype` parameter. When archetype is `hypermobile`, return stabilityDrills (existing path). When archetype is `ankleDominant`, try ankle drills first; `hipDominant`, try hip drills first; `trunkDominant`, try trunk drills first. "Try first" means: get the archetype's preferred drill list, take 1 from it, then fill remaining slot from compensation-matched drills. If preferred list is empty, fall through to existing logic. When `balanced` or `null`, existing logic applies.

9. **Add unit tests** in `test/features/report/services/report_assembly_service_test.dart`:
   - Test: `buildReport with trendReport sorts findings by priority: worsening before stable`
   - Test: `buildReport with trendReport assigns trendStatus to findings`
   - Test: `buildReport without trendReport preserves original finding order`
   - Test: `worsening finding recommendation starts with "Priority:" and mentions worsened`
   - Test: `improving finding recommendation mentions improving`
   - Test: `newPattern finding recommendation mentions new pattern`
   - Test: `stable finding recommendation is unchanged`
   - Test: `archetype hipDominant boosts hip drills for non-hip compensation`
   - Test: `archetype ankleDominant boosts ankle drills for non-ankle compensation`
   - Test: `archetype hypermobile returns stability drills regardless of compensation type`
   - Test: `archetype null uses default drill selection logic`
   - Test: `recurring detection: stable trend with 3+ data points scores higher than worsening`
<!-- END_CODER_ONLY -->

## Acceptance criteria
- Calling `buildReport(assessment)` with no optional params produces identical output to current behavior (backward compatible)
- Calling `buildReport(assessment, trendReport: report)` assigns `trendStatus` to each finding based on the dominant compensation's trend lookup
- Findings are sorted by priority: recurring (stable + 3+ values) > worsening > newPattern > stable > null, with original order preserved within same tier
- A worsening finding's recommendation starts with `Priority: ` and ends with ` — this pattern has worsened since your last assessment`
- An improving finding's recommendation ends with ` — this pattern is improving, keep up your current work`
- A newPattern finding's recommendation ends with ` — this is a new pattern we haven't seen before`
- Stable and null-trend findings have unmodified recommendation text
- When archetype is `hypermobile`, all findings get stability drills
- When archetype is `ankleDominant`, findings preferentially receive ankle drills
- When archetype is `hipDominant`, findings preferentially receive hip drills
- When archetype is `balanced` or null, existing drill selection logic applies unchanged
- No changes to models.dart (owned by story-1328)
- No chain names (SBL, BFL, FFL) appear in any user-facing text

## Verification
- All existing tests in report_assembly_service_test.dart continue to pass (backward compat)
- New tests cover priority ordering, recommendation text evolution, and archetype drill selection
- No changes outside lib/features/report/services/report_assembly_service.dart and test file
- buildReport called with no optional params returns findings in original order with null trendStatus

<!-- TESTER_ONLY -->
test_files: test/features/report/services/report_assembly_service_test.dart
test_helpers_needed: Mock TrendReport with configurable lookup results, mock CompensationTrend with configurable values list length
<!-- END_TESTER_ONLY -->
