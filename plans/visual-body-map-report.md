# Visual-First Body Map Report
Story: story-1320
Agent: architect
Depends: story-1321 (Mobility Drill Data — provides MobilityDrill model and drill data on Finding)

## Context
The current report uses FindingCard with ExpansionTile — text-first, reads like a checklist. A premium experience needs an interactive body map where the user can see their compensations spatially. The upstream driver should be highlighted in one color and symptoms in another. Chain paths should be visually traced on a body silhouette.

Also verifies deep-link robustness: /report/:id should work on browser refresh (ReportView already falls back to LocalStorageService — confirm this path works end-to-end).

DATA_FLOW_TRACE segment:
[ReportAssemblyService.buildReport(assessment)] → Report (findings with MobilityDrill[], practitionerPoints)
→ [BodyMap widget: renders SVG body silhouette, maps Compensation.joint to body regions, colors by driver vs symptom]
→ [FindingCard: tap a body region → finding detail expands below with drill cards]
→ [DrillCard: renders MobilityDrill name, description, duration, instruction steps]

## What changes
| File | Change |
|---|---|
| `lib/features/report/widgets/body_map.dart` | New. CustomPainter-based body silhouette (front view). Define body regions as Path objects (ankles, knees, hips, shoulders, trunk). Accept a List<Finding> and highlight: upstream driver joint in teal/accent, symptom joints in orange/warning. Draw chain connection lines between related joints. Tappable regions via GestureDetector + hitTest on regions. |
| `lib/features/report/views/report_view.dart` | Replace the linear findings list with: (1) BodyMap at top showing all findings spatially, (2) selected finding detail below (driven by tap on body region or list item). Keep summary card and practitioner points. Add DrillCard rendering for each finding's drills. Verify deep-link path: when loaded via LocalStorageService (no router extra), the full report renders correctly. |
| `lib/features/report/widgets/finding_card.dart` | Adapt to work alongside body map: add a `selected` state (highlighted when corresponding body region is tapped). Remove standalone confidence badge from title (body map shows this spatially). Keep expansion behavior for citations and practitioner points. |
| `lib/features/report/widgets/drill_card.dart` | New. Renders a MobilityDrill: name, target area, duration badge, step-by-step instructions in a numbered list. Compact card design that fits inside a finding's expanded content. |

## Acceptance criteria
- Report view shows a body silhouette at top with highlighted regions for each finding
- Upstream driver joint is visually distinct (different color) from symptom joints
- Chain connections are drawn as lines between related joints on the body map
- Tapping a body region scrolls to and expands the corresponding finding card below
- Each finding shows 1-2 mobility drill cards with step-by-step instructions (data from story-1321)
- Deep-link: navigating directly to /report/:id (no router extra) loads the assessment from local storage and renders the full report with body map
- Empty state: assessment with no compensations still shows "No significant patterns detected"

## Architecture notes
- Body map uses CustomPainter, not SVG files — keeps it self-contained with no asset dependencies
- Body regions are defined as normalized coordinate paths (0-1 range) scaled to canvas size
- Joint-to-region mapping: use the same joint names from Compensation.joint (e.g., "left_ankle", "left_knee")
- The body map is a controlled widget: parent passes selectedFinding, body map calls onRegionTap
- Chain visualization: SBL draws a line from ankle → knee → hip along the back; BFL draws shoulder → opposite hip; FFL draws ankle → knee → hip along the front
