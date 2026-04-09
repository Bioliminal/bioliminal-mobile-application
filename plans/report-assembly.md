# Extract Report Assembly into ReportAssemblyService
Story: story-1302
Agent: architect

## Context
The `_buildReport` method in `_ReportViewState` (report_view.dart, lines 120-233) is 110+ lines of clinical chain-mapping logic that has no business living in a widget. It owns compensation confidence capping, chain grouping, body-path descriptions, upstream driver identification, recommendation generation, citation assembly, and practitioner discussion points. Extracting it into a standalone service makes it unit-testable (story-1309) and callable from deep-link routes (story-1300) without constructing a widget.

Files:
- lib/features/report/services/report_assembly_service.dart (new)
- lib/features/report/views/report_view.dart (modify -- delete extracted logic, delegate to service)

## What changes
| File | Change |
|---|---|
| lib/features/report/services/report_assembly_service.dart | New. Pure-logic service encapsulating all report assembly: static data maps, confidence capping, chain grouping, finding construction, practitioner points, and hypermobility detection. Zero Flutter/widget dependencies. |
| lib/features/report/views/report_view.dart | Modify. Remove `_buildReport`, `_hasHypermobilityIndicators`, `_readableCompType`, all six static maps/constants (lines 17-99), and `_overallConfidence`. Replace with `ReportAssemblyService.buildReport(assessment)` and `ReportAssemblyService.overallConfidence(report.findings)` calls. |

## Architecture

### What moves
Everything below moves from report_view.dart into `ReportAssemblyService`:

**Static data (constants)**
- `_bodyPathDescriptions` (ChainType -> String)
- `_standaloneDescription` (String)
- `_citationsByType` (CompensationType -> List<Citation>)
- `_chainCitation` (Citation)
- `_bahrCitation` (Citation)
- `_chainOriginJoint` (ChainType -> String)

**Logic (methods)**
- `_buildReport(Assessment)` -> `Report` -- the core 110-line assembly pipeline
- `_hasHypermobilityIndicators(List<Compensation>)` -> `bool`
- `_readableCompType(CompensationType)` -> `String`
- `_overallConfidence(List<Finding>)` -> `ConfidenceLevel`

### What stays in ReportView
- PDF generation / caching / share (lines 270-327)
- All build/UI code (lines 332-538)
- Confidence color/text helpers for Flutter widgets (`_confidenceFlutterColor`, `_confidenceText`)

### Design decisions
- **Static methods, not instance.** The service holds zero mutable state -- every method is a pure function of its inputs. No reason to instantiate or inject.
- **Constants stay private to the service file.** They're implementation details of the assembly algorithm. Exposing them creates coupling with no upside.
- **`overallConfidence` is a separate public method** rather than a field on Report, because ReportView uses it for UI rendering and Report is a domain model that shouldn't know about display concerns.
- **`readableCompType` stays private.** Only used internally by upstream driver formatting. Not part of the public contract.

<!-- CODER_ONLY -->
## Read-only context
- lib/domain/models.dart (Assessment, Report, Finding, Compensation, Citation, ConfidenceLevel, ChainType, CompensationType)
- lib/features/report/views/report_view.dart (current source of truth for all logic being extracted)
- lib/features/report/services/pdf_generator.dart (sibling service -- follow its file/class conventions)

## Tasks
1. Create `lib/features/report/services/report_assembly_service.dart`:
   - Move all six static constants from report_view.dart (lines 17-99) as file-private `const` declarations:
     - `_bodyPathDescriptions` (Map<ChainType, String>)
     - `_standaloneDescription` (String)
     - `_citationsByType` (Map<CompensationType, List<Citation>>)
     - `_chainCitation` (Citation)
     - `_bahrCitation` (Citation)
     - `_chainOriginJoint` (Map<ChainType, String>)
   - Create class `ReportAssemblyService` with private constructor (`ReportAssemblyService._()`)
   - Static method `Report buildReport(Assessment assessment)` -- exact logic from `_buildReport` (lines 120-233):
     1. Cap ankle-dependent confidence to medium
     2. Group compensations by chain
     3. Build findings with body-path descriptions, upstream drivers, recommendations, citations
     4. Build practitioner discussion points keyed per finding
     5. Return `Report(findings: findings, practitionerPoints: ...)`
   - Static method `ConfidenceLevel overallConfidence(List<Finding> findings)` -- exact logic from `_overallConfidence` (lines 258-266)
   - Private static method `bool _hasHypermobilityIndicators(List<Compensation> comps)` -- exact logic from lines 236-243
   - Private static method `String _readableCompType(CompensationType type)` -- exact logic from lines 245-256
   - Only import: `'../../../domain/models.dart'`. No Flutter imports.

2. Update `lib/features/report/views/report_view.dart`:
   - Add import: `import '../services/report_assembly_service.dart';`
   - Delete lines 14-99 (all six static constants and their comment headers)
   - Delete `_buildReport` method (lines 120-234)
   - Delete `_hasHypermobilityIndicators` method (lines 236-243)
   - Delete `_readableCompType` method (lines 245-256)
   - Delete `_overallConfidence` method (lines 258-266)
   - Replace `final report = _buildReport(assessment);` (line 365) with `final report = ReportAssemblyService.buildReport(assessment);`
   - Replace `final overall = _overallConfidence(report.findings);` (line 366) with `final overall = ReportAssemblyService.overallConfidence(report.findings);`
   - Keep all remaining UI code, PDF/share logic, and `_confidenceFlutterColor`/`_confidenceText` helpers unchanged
<!-- END_CODER_ONLY -->

## Contract

### ReportAssemblyService API
```dart
/// Pure-logic service for assembling Report objects from Assessment data.
/// No Flutter dependencies. All methods are static pure functions.
class ReportAssemblyService {
  ReportAssemblyService._();

  /// Builds a complete Report from an Assessment's compensations.
  ///
  /// Pipeline: cap ankle confidence -> group by chain -> build findings
  /// (body-path descriptions, upstream drivers, recommendations, citations)
  /// -> build practitioner discussion points.
  ///
  /// Returns a Report with empty findings if assessment.compensations is empty.
  static Report buildReport(Assessment assessment);

  /// Worst-case confidence across all compensations in all findings.
  /// Used by ReportView for the summary confidence badge.
  static ConfidenceLevel overallConfidence(List<Finding> findings);
}
```

### Downstream consumers
- **story-1300 (report deep-linking)**: calls `ReportAssemblyService.buildReport(assessment)` to assemble a Report from a persisted Assessment loaded by ID, without needing a widget tree.
- **story-1309 (unit tests)**: tests `buildReport` and `overallConfidence` directly with synthetic Assessment/Compensation data.

### ReportView migration (call site)
```dart
// Before (in _ReportViewState):
final report = _buildReport(assessment);
final overall = _overallConfidence(report.findings);

// After:
final report = ReportAssemblyService.buildReport(assessment);
final overall = ReportAssemblyService.overallConfidence(report.findings);
```

## Acceptance criteria
- `ReportAssemblyService.buildReport(assessment)` returns an identical `Report` to what `_buildReport` produced for the same Assessment input -- no behavioral change
- `ReportAssemblyService.buildReport` caps ankleRestriction confidence to medium when raw confidence is high
- `ReportAssemblyService.buildReport` groups compensations by chain and produces one Finding per chain (plus one per standalone null-chain compensation)
- `ReportAssemblyService.buildReport` on an Assessment with empty compensations returns a Report with empty findings and empty practitionerPoints
- `ReportAssemblyService.overallConfidence` returns the worst confidence level across all compensations in all findings
- `report_assembly_service.dart` has zero Flutter imports -- only `domain/models.dart`
- `report_view.dart` no longer contains `_buildReport`, `_hasHypermobilityIndicators`, `_readableCompType`, `_overallConfidence`, or any of the six static citation/description constants
- ReportView renders identically before and after this change (pure refactor, no UI diff)
- Body-path descriptions in the service never contain chain names (SBL, BFL, FFL)

## Verification
- Confirm report_assembly_service.dart compiles with `dart analyze`
- Confirm report_view.dart compiles with `dart analyze`
- Confirm no logic duplication between the two files
- Confirm the service file has no `import 'package:flutter/` lines
- Confirm all six static constant maps/values appear in the service and are absent from report_view.dart
- Spot-check: `_chainOriginJoint[ChainType.sbl]` returns `'ankle'`, `_bodyPathDescriptions[ChainType.bfl]` returns the shoulder-hip description
