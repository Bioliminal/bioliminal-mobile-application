# Extract ConfidenceLevel Extension
Story: story-1307
Agent: architect

## Context
The `ConfidenceLevel` enum (`high`, `medium`, `low`) is compared by `.index` in 4+ locations to determine "worst" confidence. This relies on enum declaration order (high=0, medium=1, low=2) -- fragile and duplicated. This story extracts a `ConfidenceLevel` extension with explicit severity mapping, a `worstOf` aggregator, and an `isWorseThan` comparison, then replaces the duplicated logic in `finding_card.dart` and `pdf_generator.dart`. Two other consumers (`mock_chain_mapper.dart` and `report_view.dart`) are owned by story-1301 and story-1300 respectively and will adopt the extension there.

Files:
- lib/domain/models.dart
- lib/features/report/widgets/finding_card.dart
- lib/features/report/services/pdf_generator.dart

## What changes
| File | Change |
|---|---|
| lib/domain/models.dart | Add `ConfidenceLevelX` extension on `ConfidenceLevel` with `severity` getter (explicit switch), `isWorseThan` method, and static `worstOf` aggregator. Placed after the `ConfidenceLevel` enum declaration, before `CitationType`. |
| lib/features/report/widgets/finding_card.dart | Replace `_confidenceColor` and `_confidenceLabel` worst-finding loops (lines 17-45) with `ConfidenceLevelX.worstOf`. Remove duplicated index-based comparison. Update import if needed (already imports models.dart). |
| lib/features/report/services/pdf_generator.dart | Replace `_worstConfidence` and `_overallConfidence` private methods (lines 36-51) with `ConfidenceLevelX.worstOf`. Remove duplicated index-based comparison loops. |

## Architecture (Claude)

### Extension design
The extension goes on `ConfidenceLevel` in `models.dart` so every file that imports models gets it automatically -- no new import needed for existing consumers.

`severity` is an explicit switch returning `int` (0 = best, 2 = worst). This decouples comparison semantics from enum declaration order. `isWorseThan` and `worstOf` build on `severity`.

`worstOf` takes `Iterable<ConfidenceLevel>` and returns the worst. It defaults to `ConfidenceLevel.high` for empty iterables (matches current behavior in all call sites).

### Migration in this story
- `finding_card.dart`: The two private methods `_confidenceColor` and `_confidenceLabel` both compute worst confidence with a manual loop. Replace both loops with a single `ConfidenceLevelX.worstOf(compensations.map((c) => c.confidence))` call at the top, then switch on the result for color/label.
- `pdf_generator.dart`: `_worstConfidence` and `_overallConfidence` are private helpers that do the same index-based loop. Replace both with `ConfidenceLevelX.worstOf`. The `_confidencePdfColor` and `_confidenceLabel` switches on a single `ConfidenceLevel` stay as-is (they map to PDF-specific types, not comparison logic).

### What this story does NOT touch
- `mock_chain_mapper.dart` (line 280, `_worstConfidence` and `_buildConfidenceMap`): story-1301 owns this file and will rename it to `rule_based_chain_mapper.dart`. Story-1301 adopts the extension there.
- `report_view.dart` (line 260): story-1300 owns this file and will adopt the extension there.
- No changes to `BioliminalTheme` confidence colors or thresholds.

## Contract

```dart
/// Extension on ConfidenceLevel providing explicit severity comparison.
/// Exported from lib/domain/models.dart -- available to all model importers.
extension ConfidenceLevelX on ConfidenceLevel {
  /// Explicit severity score. Higher = worse.
  /// Does NOT rely on enum index order.
  int get severity => switch (this) {
    ConfidenceLevel.high   => 0,
    ConfidenceLevel.medium => 1,
    ConfidenceLevel.low    => 2,
  };

  /// True if this confidence is worse (lower quality) than [other].
  bool isWorseThan(ConfidenceLevel other) => severity > other.severity;

  /// Returns the worst confidence in [levels].
  /// Returns ConfidenceLevel.high for empty iterables.
  static ConfidenceLevel worstOf(Iterable<ConfidenceLevel> levels) {
    var worst = ConfidenceLevel.high;
    for (final l in levels) {
      if (l.severity > worst.severity) worst = l;
    }
    return worst;
  }
}
```

### Downstream consumers (cross-story)
- story-1301 (`RuleBasedChainMapper`): will replace `_worstConfidence` and `_buildConfidenceMap` index comparisons with `ConfidenceLevelX.worstOf` and `isWorseThan`.
- story-1300 (`ReportView`): will replace worst-confidence loop with `ConfidenceLevelX.worstOf`.

<!-- CODER_ONLY -->
## Read-only context
- lib/domain/mocks/mock_chain_mapper.dart (lines 275-454 -- `_buildConfidenceMap` uses `.index >` on line 280, `_worstConfidence` on lines 448-454. DO NOT MODIFY -- story-1301 owns this file.)
- lib/features/report/views/report_view.dart (DO NOT MODIFY -- story-1300 owns this file.)
- lib/core/theme.dart (BioliminalTheme.confidenceHigh/Medium/Low color constants, confidenceColor() helper -- read-only reference for finding_card.dart color mapping.)

## Tasks
1. In `lib/domain/models.dart`, add `extension ConfidenceLevelX on ConfidenceLevel` immediately after the `ConfidenceLevel` enum (line 25) and before `CitationType` (line 27). Include `severity` getter (explicit switch), `isWorseThan` method, and `static worstOf` method per the Contract section.

2. In `lib/features/report/widgets/finding_card.dart`:
   - Replace `_confidenceColor` method body: compute `final worst = ConfidenceLevelX.worstOf(compensations.map((c) => c.confidence));` once, then switch on `worst` for color.
   - Replace `_confidenceLabel` method body: same pattern, switch on `worst` for label string.
   - No signature changes to these methods (they're called from `build`).

3. In `lib/features/report/services/pdf_generator.dart`:
   - Delete the `_worstConfidence` method (lines 36-42).
   - Delete the `_overallConfidence` method (lines 44-51).
   - Replace call sites:
     - Line 67 (`_overallConfidence`): `final overall = ConfidenceLevelX.worstOf(report.findings.expand((f) => f.compensations).map((c) => c.confidence));`
     - Line 231 (`_worstConfidence`): `final confidence = ConfidenceLevelX.worstOf(finding.compensations.map((c) => c.confidence));`
   - Keep `_confidencePdfColor` and `_confidenceLabel` as-is (they map ConfidenceLevel to PDF-specific types, not comparison).

4. Update imports: verify `finding_card.dart` and `pdf_generator.dart` already import `models.dart`. No new imports needed since the extension is in the same file as the enum.
<!-- END_CODER_ONLY -->

## Acceptance criteria
- `ConfidenceLevelX.severity` returns 0 for high, 1 for medium, 2 for low via explicit switch (no `.index` reference).
- `ConfidenceLevelX.worstOf([high, medium, low])` returns `ConfidenceLevel.low`.
- `ConfidenceLevelX.worstOf([high, high])` returns `ConfidenceLevel.high`.
- `ConfidenceLevelX.worstOf([])` returns `ConfidenceLevel.high` (empty default).
- `ConfidenceLevel.low.isWorseThan(ConfidenceLevel.medium)` returns `true`.
- `ConfidenceLevel.high.isWorseThan(ConfidenceLevel.medium)` returns `false`.
- `FindingCard._confidenceColor` and `_confidenceLabel` no longer contain `.index` comparisons.
- `PdfGenerator` no longer contains `_worstConfidence` or `_overallConfidence` private methods.
- No `.index`-based confidence comparison remains in any of the three write-target files.
- Visual behavior of FindingCard confidence badges and PdfGenerator confidence colors is unchanged (green/amber/red mapping preserved).
- `models.dart` exports the extension (no separate export needed -- it's in the same file as the enum).

## Verification
- Confirm `ConfidenceLevelX` is positioned between `ConfidenceLevel` enum and `CitationType` enum in models.dart.
- Grep all three write-target files for `.index` -- zero matches expected.
- Confirm `_confidencePdfColor` and `_confidenceLabel` in pdf_generator.dart are untouched (they switch on a single ConfidenceLevel, not comparison logic).
- Confirm no changes to files outside write scope (especially mock_chain_mapper.dart and report_view.dart).
<!-- TESTER_ONLY -->
test_files: test/domain/confidence_level_extension_test.dart
<!-- END_TESTER_ONLY -->
