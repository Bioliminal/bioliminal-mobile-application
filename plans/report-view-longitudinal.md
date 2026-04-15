# Evolving recommendations engine — ReportView integration
Story: story-1331
Agent: quick-fixer

## Context
Update ReportView to render longitudinal context: trend badges per finding, priority-ordered finding cards, a "Your Movement Profile" archetype section in the summary card, and archetype-specific drill highlighting. The enriched Report data (trend annotations, priority ordering, archetype-targeted drills) comes from the updated ReportAssemblyService (story-1329). This story is purely UI — it renders what the assembly service produces.

Files:
- lib/features/report/views/report_view.dart

## Frontend Design (Gemini)

### Component Hierarchy
```text
ReportView (ConsumerStatefulWidget)
+-- Scaffold
    +-- AppBar (PDF Export, Share, Cloud Sync)
    +-- SingleChildScrollView
        +-- Column
            +-- BodyMap
            +-- Legend
            +-- SummaryCard (enhanced)
            |   +-- Column
            |       +-- "Summary" headline
            |       +-- Finding count text
            |       +-- Overall confidence row
            |       +-- Confidence quality text
            |       +-- MovementProfileSection [NEW]
            |           +-- Archetype name (titleMedium)
            |           +-- Archetype description (bodyMedium)
            +-- "Your Findings" header
            +-- FindingCard list [NEW: priority-sorted, with trend badges]
            +-- PractitionerPointsSection
```

### Trend Badge Colors
| Status | Color | Label |
|---|---|---|
| Improving | Colors.green | "Improving" |
| Worsening | BioliminalTheme.confidenceLow | "Worsening" |
| Stable | Colors.grey | "Stable" |
| New Pattern | Colors.blue | "New Pattern" |

### Movement Profile Section
- Background: colorScheme.surfaceContainerHighest with rounded corners
- Archetype name in titleMedium
- 1-2 sentence tailored description based on archetype

### Archetype-Specific Drill Badge
- "Recommended for your profile" chip on matching drills
- Color: colorScheme.secondaryContainer

## Architecture (Claude)

### State management
ReportView already loads Assessment (via GoRouter extra or LocalStorageService). To get longitudinal context:
1. Load all assessments via `ref.read(localStorageServiceProvider).listAssessments()`
2. Import and call `TrendDetectionService.analyzeTrends(allAssessments)` → TrendReport (static method, no provider)
3. Import and call `ArchetypeClassifier.classify(allAssessments)` → MobilityArchetype (static method, no provider)
4. Pass TrendReport + MobilityArchetype to `ReportAssemblyService.buildReport(assessment, trendReport: tr, archetype: arch)`

The enriched Report comes back with findings already priority-sorted and drills already archetype-targeted. ReportView just renders.

### Data flow
```
Assessment (from router extra or local storage)
  + List<Assessment> (from localStorageService.listAssessments())
  → TrendDetectionService.analyzeTrends() → TrendReport
  → ArchetypeClassifier.classify() → MobilityArchetype
  → ReportAssemblyService.buildReport(assessment, trendReport, archetype) → Report
  → ReportView renders:
     - Summary card + movement profile section
     - Finding cards in order (already sorted by assembly service)
     - Trend badges per finding (from finding.trendStatus)
     - Drill cards with archetype badge (from finding.drills with isArchetypeMatch flag)
```

## Integration contracts
### Imports (this story depends on these)
| Symbol | From file | Expected interface | Producer story |
|---|---|---|---|
| TrendDetectionService | lib/features/history/services/trend_detection_service.dart | static TrendReport analyzeTrends(List<Assessment>) | story-1328 |
| TrendReport, TrendClassification, MobilityArchetype | lib/domain/models.dart | enums and data classes | story-1328 |
| ArchetypeClassifier | lib/features/history/services/archetype_classifier.dart | static MobilityArchetype classify(List<Assessment>) | story-1330 |
| ReportAssemblyService.buildReport (updated signature) | lib/features/report/services/report_assembly_service.dart | static Report buildReport(Assessment, {TrendReport? trendReport, MobilityArchetype? archetype}) | story-1329 |

<!-- CODER_ONLY -->
## Read-only context
- lib/features/report/widgets/finding_card.dart (FindingCard widget — may need trendStatus param)
- lib/features/report/widgets/drill_card.dart (DrillCard widget — may need isArchetypeMatch param)
- lib/features/report/widgets/body_map.dart (BodyMap — unchanged)
- lib/core/theme.dart (BioliminalTheme confidence colors)
- lib/core/providers.dart (localStorageServiceProvider)
- lib/domain/models.dart (all model types)

## Tasks
1. Update `lib/features/report/views/report_view.dart`:
   - In `didChangeDependencies` (or a new `_loadLongitudinalContext` method), after loading the current assessment, also load all assessments via `localStorageServiceProvider.listAssessments()`, compute TrendReport and MobilityArchetype
   - Store as `_trendReport` and `_archetype` state fields
   - Pass `trendReport` and `archetype` to `ReportAssemblyService.buildReport()` call
   - Add `_MovementProfileSection` widget below the confidence quality text in the summary card: displays archetype name (human-readable) and a tailored description using a static map (ankleDominant -> "Your movement patterns suggest ankle mobility is a key focus area...", etc.)
   - Add `_TrendBadge` widget: small colored chip with trend label, rendered in each FindingCard's header area. TrendClassification comes from matching finding's compensations against TrendReport
   - Finding cards are already in the order returned by `buildReport` (which story-1329 sorts by priority) — no re-sorting needed in the view
   - For drill cards: if a drill's compensationType matches the archetype's dominant type, show a "Recommended for your profile" chip
   - Graceful fallback: if `_trendReport` is null (first assessment, no history), skip trend badges and movement profile section — render exactly as before
<!-- END_CODER_ONLY -->

## Acceptance criteria
- When a user with 3+ past assessments views a report, the summary card includes a "Your Movement Profile" section showing the archetype name and tailored description
- When a user views a report with longitudinal data, each finding card displays a trend badge (Improving/Worsening/Stable/New Pattern) with appropriate color coding
- When findings are rendered, they appear in priority order: recurring > worsening > new > stable
- When a drill matches the user's archetype, it shows a "Recommended for your profile" badge
- When a user has only one assessment (no history), the report renders identically to the current behavior — no trend badges, no movement profile section
- Body-path descriptions never contain chain names (SBL, BFL, FFL)
- Integration: TrendDetectionService from story-1328 is imported and connected — not stubbed, not TODO
- Integration: ArchetypeClassifier from story-1330 is imported and connected — not stubbed, not TODO
- Integration: ReportAssemblyService.buildReport updated signature from story-1329 is used — not stubbed, not TODO

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- Graceful fallback for single-assessment (no-history) case
- No chain names in user-facing text
<!-- TESTER_ONLY -->
test_files: test/features/report/views/report_view_test.dart
<!-- END_TESTER_ONLY -->
