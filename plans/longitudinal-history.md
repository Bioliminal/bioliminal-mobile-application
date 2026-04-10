# Longitudinal History Screen
Story: story-1322
Agent: architect
Depends: story-1321 (Mobility Drill Data — uses updated Finding model)

## Context
Premium users want to track progress over time. The app currently has no way to view past screenings. LocalStorageService.listAssessments() already returns all saved assessments sorted by date. This story adds a History screen with a timeline of past screenings and comparison metrics showing improvement between sessions.

DATA_FLOW_TRACE segment:
[LocalStorageService.listAssessments()] → List<Assessment> (sorted by createdAt desc)
→ [ComparisonService.compare(older, newer)] → List<ComparisonMetric> (joint, oldValue, newValue, delta, improved)
→ [HistoryView renders timeline + comparison cards]
→ [Tap assessment → GoRouter.go('/report/{id}')]

## What changes
| File | Change |
|---|---|
| `lib/features/history/views/history_view.dart` | New. ConsumerWidget that reads localStorageServiceProvider.listAssessments(). Empty state: centered illustration + "Complete your first screening to start tracking progress" text + button to /screening. Populated state: scrollable timeline of assessment cards showing date, finding count, and top compensation. Tap navigates to /report/:id. |
| `lib/features/history/widgets/assessment_timeline.dart` | New. Timeline widget: vertical line with date markers. Each node shows an AssessmentSummaryCard with: date, number of findings, confidence level badge, and delta indicators if a previous assessment exists (e.g., "Knee valgus improved by 4°"). |
| `lib/features/history/services/comparison_service.dart` | New. ComparisonService with static compare(Assessment older, Assessment newer) method. Matches compensations by type+joint across assessments. Returns ComparisonMetric list: { joint, compensationType, oldValue, newValue, delta, improved }. |
| `lib/core/router.dart` | Add '/history' route pointing to HistoryView. Add bottom navigation or entry point from report view ("View History" button). |

## Acceptance criteria
- Navigating to /history with no saved assessments shows empty state with "Complete your first screening" message and a button to /screening
- With 1+ assessments, shows a chronological timeline with date, finding count, and confidence badge per entry
- With 2+ assessments, shows delta indicators (e.g., "Knee valgus: 14° → 10° (improved)") comparing most recent to previous
- Tapping an assessment in the timeline navigates to /report/:id
- History loads from local storage only (no cloud dependency)
- Router has /history route that resolves correctly

## Architecture notes
- ComparisonService is pure logic — no state, no providers, just static methods
- Comparison matches by CompensationType + joint string (exact match)
- Delta display uses body-path language, not clinical terms
- The history route should be accessible from the report view (after screening) and potentially from a future home/dashboard screen
- Timeline widget uses a simple Column with custom paint for the vertical line — no heavy timeline packages
