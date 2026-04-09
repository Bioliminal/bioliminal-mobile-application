# Fix Report Deep-Linking
Story: story-1300
Agent: architect

## Context
ReportView currently crashes or shows a dead-end "Assessment not found" when the user navigates to `/report/:id` without a GoRouter `extra` (e.g. browser refresh, saved link, back-navigation after process death). The `:id` path parameter is already available but unused. This story makes ReportView load the Assessment from LocalStorageService when `extra` is null, delegates report assembly to ReportAssemblyService (from story-1302), and uses the ConfidenceLevel extension (from story-1307) for severity styling.

Files:
- lib/features/report/views/report_view.dart

## Cross-story dependencies
| Dependency | What it provides | Status |
|---|---|---|
| story-1302 | `ReportAssemblyService` in `lib/features/report/services/report_assembly_service.dart` | Must land first |
| story-1307 | `ConfidenceLevel` extension with `.severity` / `.color` on `lib/domain/models.dart` | Must land first |
| story-1301 | Renames `MockChainMapper` -> `RuleBasedChainMapper`, `MockAngleCalculator` -> `RuleBasedAngleCalculator` in `domain/services/` | Must land first (transitive via 1302, 1307) |

## What changes
| File | Change |
|---|---|
| lib/features/report/views/report_view.dart | Convert from `StatefulWidget` to `ConsumerStatefulWidget`. Add `initState` that checks GoRouter `extra` for an Assessment; if null, load from `LocalStorageService` via `localStorageServiceProvider` using `widget.id`. Replace inline `_buildReport` with `ReportAssemblyService.buildReport`. Replace manual confidence color/text helpers with ConfidenceLevel extension. Add loading and error states. Remove all report-assembly constants/logic (moved to story-1302). |

## Architecture

### State machine
```
initState
  ├─ extra != null → _assessment = extra, _loading = false
  └─ extra == null → _loading = true
                        │
                        ▼
                  LocalStorageService.loadAssessment(id)
                        │
                        ├─ Assessment found → _assessment = result, _loading = false
                        └─ null → _error = "Assessment not found", _loading = false
```

### Data flow (after load)
```
Assessment
  │
  ▼
ReportAssemblyService.buildReport(assessment)   ← from story-1302
  │
  ▼
Report { findings, practitionerPoints }
  │
  ├─ UI renders summary, FindingCards, practitioner points
  ├─ ConfidenceLevel.color / .label from extension  ← from story-1307
  └─ PDF / Share unchanged (already working)
```

### Key decisions
- **ConsumerStatefulWidget** over `StatefulWidget`: need `ref.read(localStorageServiceProvider)` for async load. Matches ScreeningView and CameraView patterns.
- **Load in didChangeDependencies, not build**: async load fires once (guarded by `_didLoad` flag), stores result in state. No `FutureBuilder` -- keeps PDF caching and share state management straightforward in the same `State` object.
- **Removed assembly logic**: `_buildReport`, `_bodyPathDescriptions`, `_citationsByType`, `_chainOriginJoint`, `_chainCitation`, `_bahrCitation`, `_standaloneDescription`, `_readableCompType`, `_hasHypermobilityIndicators`, `_overallConfidence` all move to `ReportAssemblyService` (story-1302). This file becomes a pure view.
- **Removed manual confidence helpers**: `_confidenceFlutterColor` and `_confidenceText` replaced by ConfidenceLevel extension from story-1307.

## Contract

```dart
// ReportView -- updated signature (unchanged public API)
class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key, required this.id});
  final String id;
}

// State fields
class _ReportViewState extends ConsumerState<ReportView> {
  Assessment? _assessment;
  bool _loading = true;
  bool _didLoad = false;
  String? _error;
  String? _cachedPdfPath;
  bool _generating = false;

  /// Called in didChangeDependencies (once). Checks GoRouter extra first,
  /// falls back to LocalStorageService.loadAssessment(widget.id).
  Future<void> _loadAssessment();
}

// Consumed from story-1302 (not created here):
class ReportAssemblyService {
  Report buildReport(Assessment assessment);
}

// Consumed from story-1307 (not created here):
extension ConfidenceLevelX on ConfidenceLevel {
  Color get color;   // returns AuraLinkTheme.confidenceHigh/Medium/Low
  String get label;  // returns 'High' / 'Medium' / 'Low'
  int get severity;  // high=0, medium=1, low=2 (for comparison)
}
```

## Acceptance criteria
1. Given a user navigates to `/report/abc123` with an Assessment passed as GoRouter `extra`, when ReportView loads, then the report renders immediately with no loading spinner.
2. Given a user navigates to `/report/abc123` without GoRouter `extra` (null), when ReportView loads, then a loading indicator appears, LocalStorageService is called with id `abc123`, and the report renders after the Assessment loads.
3. Given a user navigates to `/report/abc123` without `extra` and no Assessment exists in LocalStorageService for that id, when the load completes, then ReportView displays "Assessment not found" error text.
4. Given an Assessment with zero compensations loads (via either path), when the report renders, then the "no significant patterns" empty state is shown.
5. Given the ConfidenceLevel extension is available (story-1307), when the summary card renders overall confidence, then it uses `ConfidenceLevel.color` and `ConfidenceLevel.label` instead of local switch statements.
6. Given ReportAssemblyService is available (story-1302), when ReportView needs a Report, then it calls `ReportAssemblyService().buildReport(assessment)` instead of the former inline `_buildReport`.
7. Given the user taps "Export PDF" or "Share" after the assessment loads from LocalStorageService, when the action completes, then PDF generation and sharing work identically to the GoRouter-extra path.

<!-- CODER_ONLY -->
## Read-only context
- lib/core/services/local_storage_service.dart — `loadAssessment(String id) → Future<Assessment?>` API
- lib/core/providers.dart — `localStorageServiceProvider` (already registered)
- lib/features/report/services/report_assembly_service.dart — from story-1302: `ReportAssemblyService` with `Report buildReport(Assessment assessment)`
- lib/domain/models.dart — ConfidenceLevel extension added by story-1307
- lib/features/report/widgets/finding_card.dart — FindingCard widget (unchanged, consumed here)
- lib/features/report/services/pdf_generator.dart — PdfGenerator (unchanged, consumed here)
- lib/core/theme.dart — AuraLinkTheme confidence colors
- lib/core/router.dart — GoRouter route `/report/:id` passes `id` to ReportView

## Tasks
1. **Convert to ConsumerStatefulWidget + add loading state**
   - Change `ReportView extends StatefulWidget` to `extends ConsumerStatefulWidget`
   - Change `_ReportViewState extends State<ReportView>` to `extends ConsumerState<ReportView>`
   - Add fields: `Assessment? _assessment`, `bool _loading = true`, `bool _didLoad = false`, `String? _error`

2. **Implement `_loadAssessment` in `didChangeDependencies`**
   - Override `didChangeDependencies`. Guard with `if (_didLoad) return; _didLoad = true;`.
   - Read `GoRouterState.of(context).extra as Assessment?` (context is safe here, unlike initState).
   - If extra is non-null: set `_assessment = extra`, `_loading = false` (synchronous, no setState needed before first build).
   - If extra is null: keep `_loading = true`, call `ref.read(localStorageServiceProvider).loadAssessment(widget.id)`.
     - On result non-null: `setState(() { _assessment = result; _loading = false; })`
     - On result null: `setState(() { _error = 'Assessment not found'; _loading = false; })`

3. **Replace `_buildReport` with ReportAssemblyService**
   - Import `../services/report_assembly_service.dart`
   - In `build`, where `_buildReport(assessment)` was called, use `ReportAssemblyService().buildReport(assessment)`
   - Delete all assembly constants and methods: `_buildReport`, `_bodyPathDescriptions`, `_citationsByType`, `_chainCitation`, `_bahrCitation`, `_standaloneDescription`, `_chainOriginJoint`, `_readableCompType`, `_hasHypermobilityIndicators`, `_overallConfidence`

4. **Replace confidence color/text helpers with ConfidenceLevel extension**
   - Delete `_confidenceFlutterColor` and `_confidenceText`
   - In summary card, replace `_confidenceFlutterColor(overall)` with `overall.color`
   - Replace `_confidenceText(overall)` with `overall.label`
   - For overall confidence computation: use `ReportAssemblyService` if it exposes this, or compute via the extension's `.severity` for worst-case comparison across findings

5. **Update imports**
   - Add: `import 'package:flutter_riverpod/flutter_riverpod.dart';`
   - Add: `import '../../../core/providers.dart';` (for `localStorageServiceProvider`)
   - Add: `import '../services/report_assembly_service.dart';`
   - Keep: `import 'package:go_router/go_router.dart';` (still needed for `GoRouterState.of(context)`)
   - Remove: `import '../../../core/theme.dart';` only if ConfidenceLevel extension fully replaces direct theme references (check if AuraLinkTheme is used elsewhere in this file — it is not after helpers are removed)

6. **Update build method for three states**
   - Loading: `if (_loading) return Scaffold(appBar: AppBar(title: const Text('Report')), body: const Center(child: CircularProgressIndicator()))`
   - Error: `if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Report')), body: Center(child: Text(_error!)))`
   - Loaded: existing report UI using `_assessment!`, now with ReportAssemblyService and ConfidenceLevel extension
<!-- END_CODER_ONLY -->

## Verification
- Confirm ReportView handles both navigation paths: extra-present (instant) and extra-null (async load)
- Confirm null assessment from LocalStorageService shows error, not crash
- Confirm all report-assembly logic is delegated to ReportAssemblyService (no leftover `_buildReport`)
- Confirm confidence styling uses extension, not local switch helpers
- Confirm no changes outside `lib/features/report/views/report_view.dart`
- Confirm PDF export and share still work after refactor
<!-- TESTER_ONLY -->
test_files: test/features/report/views/report_view_test.dart
<!-- END_TESTER_ONLY -->
