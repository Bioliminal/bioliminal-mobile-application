# Assessment history dashboard enhancements
Story: story-1327
Agent: quick-fixer

## Context
Enhance the existing HistoryView and AssessmentTimeline to display longitudinal trend summaries and mobility archetype badges. Currently the history view shows a basic timeline with date, finding count, confidence badge, and pairwise delta indicators. This story adds a trend summary header (improving/worsening/stable counts), an archetype badge, and richer delta chips.

Files:
- lib/features/history/views/history_view.dart
- lib/features/history/widgets/assessment_timeline.dart

## Frontend Design (Gemini)

### Layout Structure
```text
HistoryView (Scaffold)
+-- AppBar ("Progress Journey")
+-- SingleChildScrollView (Padding: 16)
    +-- Column
        +-- SummaryHeader (Card)
        |   +-- Column
        |       +-- Row [ArchetypeBadge, Spacer, ConfidenceIndicator]
        |       +-- TrendMetricsRow [ImprovingCount, StableCount, WorseningCount]
        +-- SectionDivider ("Recent History")
        +-- AssessmentTimeline
            +-- TimelineNode (Repeat)
                +-- AssessmentCard
                    +-- Header [Date, DetailsArrow]
                    +-- SummaryText ("X findings detected")
                    +-- DeltaVisualizer (Wrap)
                        +-- DeltaChip [BodyPathIcon, TrendArrow, DeltaLabel]
```

### Trend Badge Colors
| State | Color | Icon |
|---|---|---|
| Improving | BioliminalTheme.confidenceHigh | Icons.trending_down (value decreasing = improving) |
| Stable | BioliminalTheme.confidenceMedium | Icons.trending_flat |
| Worsening | BioliminalTheme.confidenceLow | Icons.trending_up (value increasing = worsening) |

### Body-Path Language for Delta Chips
- ankleRestriction -> "Ankle flexibility"
- kneeValgus -> "Knee alignment"
- hipDrop -> "Pelvic level"
- trunkLean -> "Torso balance"

## Architecture (Claude)

### State management
HistoryView becomes a ConsumerStatefulWidget (or stays ConsumerWidget if async data can be watched cleanly). It watches three providers:
1. `_assessmentsProvider` (existing) — `FutureProvider<List<Assessment>>`
2. Import `TrendDetectionService` directly — call `TrendDetectionService.analyzeTrends(assessments)` to get `TrendReport`
3. Import `ArchetypeClassifier` directly — call `ArchetypeClassifier.classify(assessments)` to get `MobilityArchetype`

Both are static utility classes (no providers needed). The trend report and archetype are computed from the same assessment list, so load assessments first, then compute both.

### Data flow
```
_assessmentsProvider → List<Assessment>
  → TrendDetectionService.analyzeTrends(assessments) → TrendReport
  → ArchetypeClassifier.classify(assessments) → MobilityArchetype
  → SummaryHeader renders counts + badge
  → AssessmentTimeline receives TrendReport for richer deltas
```

## Integration contracts
### Imports (this story depends on these)
| Symbol | From file | Expected interface | Producer story |
|---|---|---|---|
| TrendDetectionService | lib/features/history/services/trend_detection_service.dart | static TrendReport analyzeTrends(List<Assessment>) | story-1328 |
| TrendReport, TrendClassification, CompensationTrend | lib/domain/models.dart | data classes with compensationType, trend, slope fields | story-1328 |
| ArchetypeClassifier | lib/features/history/services/archetype_classifier.dart | static MobilityArchetype classify(List<Assessment>) | story-1330 |
| MobilityArchetype | lib/domain/models.dart | enum with values: ankleDominant, hipDominant, trunkDominant, hypermobile, balanced | story-1328 |

<!-- CODER_ONLY -->
## Read-only context
- lib/features/history/services/comparison_service.dart (existing pairwise comparison — still used by timeline for per-node deltas)
- lib/core/providers.dart (provider registration pattern)
- lib/core/theme.dart (BioliminalTheme confidence colors)
- lib/domain/models.dart (Assessment, Report, Finding, Compensation, TrendReport, MobilityArchetype)

## Tasks
1. Update `lib/features/history/views/history_view.dart`:
   - Change `_assessmentsProvider` to compute trend report and archetype from assessment list: create two derived FutureProviders (or compute inline) that call `TrendDetectionService.analyzeTrends(assessments)` and `ArchetypeClassifier.classify(assessments)`
   - Add a `_SummaryHeader` widget above the timeline: Card containing:
     - Row with `_ArchetypeBadge` (displays MobilityArchetype as human-readable label: ankleDominant -> "Ankle-Dominant", etc.) and overall confidence
     - `_TrendMetricsRow`: three columns showing improving/stable/worsening counts from TrendReport with trend icons and confidence colors
   - Pass TrendReport to AssessmentTimeline as a new parameter
   - Keep existing empty state and loading/error handling unchanged

2. Update `lib/features/history/widgets/assessment_timeline.dart`:
   - Add optional `TrendReport? trendReport` parameter to AssessmentTimeline
   - In `_TimelineNode`, replace `_DeltaIndicator` with `_DeltaChip`: a rounded chip widget showing body-path label (not compensation type name), trend arrow icon, and delta value, with 10% alpha background tint of the trend color
   - Add static body-path label map: ankleRestriction -> "Ankle flexibility", kneeValgus -> "Knee alignment", hipDrop -> "Pelvic level", trunkLean -> "Torso balance"
   - Keep existing timeline painting and node structure
<!-- END_CODER_ONLY -->

## Acceptance criteria
- When a user with 3+ past assessments opens /history, the summary header shows the archetype badge (e.g., "Ankle-Dominant") and trend counts (e.g., "2 improving, 1 stable")
- When a user has no past assessments, the existing empty state ("Complete your first screening...") renders unchanged
- When a user taps a timeline node, navigation to /report/:id occurs
- Delta chips on timeline nodes display body-path language ("Ankle flexibility") not compensation type names ("ankleRestriction")
- Delta chips are color-coded: green for improving, amber for stable, red for worsening
- Integration: TrendDetectionService from story-1328 is imported and connected — not stubbed, not TODO
- Integration: ArchetypeClassifier from story-1330 is imported and connected — not stubbed, not TODO
- TrendDetectionService and ArchetypeClassifier are imported directly (static method calls, no providers)

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- Body-path language map uses only human-readable descriptions
- No chain names (SBL, BFL, FFL) appear in any user-facing text
<!-- TESTER_ONLY -->
test_files: test/features/history/views/history_view_test.dart, test/features/history/widgets/assessment_timeline_test.dart
<!-- END_TESTER_ONLY -->
