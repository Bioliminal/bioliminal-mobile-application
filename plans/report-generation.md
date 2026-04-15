# Report Generation
Story: story-1297
Agent: architect

## Context
Build the personalized triage report that transforms raw compensation data into actionable, layered findings with body-path language, confidence annotations, inline evidence citations, practitioner discussion points, and PDF export with native sharing. The report is the primary user-facing output of the entire screening pipeline -- it must translate clinical chain reasoning into language anyone can understand while maintaining evidence credibility through inline citations.

This story receives a completed `Assessment` (with `compensations` populated) from story-1295 (Screening) and produces `Report` objects consumed by story-1298 (Data Persistence) for storage.

Files:
- lib/features/report/views/report_view.dart
- lib/features/report/widgets/finding_card.dart
- lib/features/report/widgets/citation_expandable.dart
- lib/features/report/services/pdf_generator.dart

## What changes
| File | Change |
|---|---|
| lib/features/report/views/report_view.dart | New. Layered report screen: summary dashboard (2-3 sentence overview, finding count, overall confidence) scrolling into a list of FindingCards. Receives Assessment via route parameter, builds Report from its compensations. Includes "Export PDF" and "Share" action buttons in app bar. |
| lib/features/report/widgets/finding_card.dart | New. Expandable card displaying a single Finding: body-path description, confidence color badge, upstream driver identification, recommendation text. Collapsed state shows description + confidence. Expanded state reveals full detail, CitationExpandable widgets, and practitioner discussion point. |
| lib/features/report/widgets/citation_expandable.dart | New. Inline expandable widget for a single Citation: collapsed shows source name + year, expanded shows full finding text, URL (tappable), citation type, and how the app uses this evidence. |
| lib/features/report/services/pdf_generator.dart | New. Declarative PDF generation using `pdf: ^3.10.0`. Takes a Report + Assessment metadata, produces a searchable-text PDF (~100KB target). Sections: header, summary, findings with confidence colors, citations, practitioner discussion points, recommendations, footer disclaimer. Returns `Uint8List` for share_plus and local save. |

## Architecture (Claude)

### Data flow
```
Assessment (from screening)
  │
  ├─ compensations: List<Compensation>  (populated by ChainMapper mock/real)
  │
  ▼
ReportView receives Assessment via GoRouter param
  │
  ├─ Groups compensations by chain → builds Finding objects
  │   ├─ Maps chain → body-path description (SBL → "ankle, knee, hip along your back body")
  │   ├─ Identifies upstream driver via CC/CP logic (first joint in chain sequence)
  │   ├─ Selects relevant citations from embedded citation map
  │   ├─ Generates recommendation (mobility vs stability based on pattern context)
  │   └─ Assigns overall finding confidence (worst-case of constituent compensations)
  │
  ├─ Builds practitioner discussion points per finding
  │
  ▼
Report { findings, practitionerPoints, pdfUrl? }
  │
  ├─ UI: summary → FindingCard list → each card expands → CitationExpandable
  │
  ├─ PDF: PdfGenerator.generate(report, assessment) → Uint8List
  │   └─ Writes to temp dir via path_provider
  │
  └─ Share: share_plus shares PDF file from temp path
```

### Report assembly logic (in ReportView controller/builder)
Compensations arrive pre-classified with `chain` and `confidence` from the ChainMapper. The report layer:
1. Groups compensations by `ChainType` (null-chain compensations become standalone findings)
2. For each group, looks up body-path language from a static map (never exposes chain names)
3. Identifies the upstream driver: the compensation closest to the anatomical origin of the chain (ankle for SBL/FFL, shoulder for BFL)
4. Selects citations relevant to the compensations in the group (from embedded citation data keyed by CompensationType)
5. Generates a recommendation: if upstream driver is a restriction → mobility focus; if hypermobility markers present → stability focus
6. Worst-case confidence across the group becomes the finding confidence (a single red joint drags the whole finding to red)

### Body-path language map (static, never user-editable)
- SBL → "your ankle, knee, and hip compensate together along your back body"
- BFL → "your shoulder and opposite hip are connected through your back"
- FFL → "your front body -- ankle, knee, hip -- compensates as a unit"
- null (standalone) → "an isolated finding at [joint]"

### PDF generation strategy
- `pdf: ^3.10.0` declarative document builder
- All text is searchable (no rasterized text)
- Confidence colors rendered as colored rectangles/badges (vector, not images)
- Body-path diagrams: simple vector line drawings connecting involved joints (pw.CustomPaint or pw.Container with borders) -- keeps file under 100KB
- Sections mirror the UI: header → summary → findings → citations → practitioner points → recommendations → footer disclaimer
- Returns `Uint8List` -- caller decides whether to save locally, upload to Firestore Storage, or share immediately

### Share integration
- `share_plus: ^9.0.0` for native share sheet
- PDF written to temp directory via `path_provider` (`getTemporaryDirectory()`)
- `Share.shareXFiles([XFile(path)])` with subject line "Bioliminal Movement Screen"
- No Firestore upload in this story (story-1298 handles persistence)

### Confidence annotation rules
- Green badge: all constituent compensations have `ConfidenceLevel.high`
- Yellow badge: worst compensation is `ConfidenceLevel.medium`
- Red badge: any compensation has `ConfidenceLevel.low` -- card includes explicit text: "Tracking was unclear for this finding -- verify with a practitioner"
- Ankle-dependent findings: always reduced to at most yellow, regardless of raw confidence (MediaPipe ankle r=0.45)

<!-- CODER_ONLY -->
## Read-only context
- presearch/bioliminal-product.md
- lib/domain/models.dart (from story-1293 -- Assessment, Report, Finding, Compensation, Citation, ConfidenceLevel, ChainType, CompensationType enums)
- lib/features/screening/ (from story-1295 -- provides completed Assessment with compensations populated)
- presearch/.scout-bioliminal-product.json (citations array, chain_mappings, cc_cp_logic, body-path language patterns)
- lib/core/theme.dart (BioliminalTheme.confidenceHigh/Medium/Low colors, confidenceColor() helper)
- lib/core/providers.dart (provider registration pattern)
- lib/core/router.dart (GoRouter /report/:id route already declared)

## Tasks
1. Create `lib/features/report/services/pdf_generator.dart`:
   - Class `PdfGenerator` with static method `Future<Uint8List> generate(Report report, {required String assessmentId, required DateTime date})`
   - Build a `pw.Document` with:
     - **Header**: "Bioliminal Movement Screen" + formatted date
     - **Summary section**: finding count, overall confidence level (worst-case across findings), 2-3 sentence overview built from findings
     - **Findings section**: for each Finding, render body-path description in bold, confidence color as a colored pw.Container badge, upstream driver, recommendation text
     - **Citations section** per finding: source, finding text, URL as clickable pw.UrlLink
     - **Practitioner discussion points**: bulleted list
     - **Footer** on every page: "This is an educational triage tool, not a diagnostic assessment"
   - Use `pw.ThemeData` with base font (Helvetica built-in, no custom font loading needed)
   - Confidence colors: map ConfidenceLevel to PdfColors (green/amber/red) matching BioliminalTheme values
   - Return `document.save()` (Uint8List)
   - No file I/O in this class -- caller handles writing to disk

2. Create `lib/features/report/widgets/citation_expandable.dart`:
   - Stateful widget `CitationExpandable` taking a `Citation` parameter
   - Collapsed state: Row with book icon + source name (e.g., "Hewett et al. (2005)") + chevron
   - Expanded state (on tap): Column showing:
     - Full finding text from citation
     - Tappable URL (display as SelectableText -- no url_launcher dependency needed)
     - Citation type badge (research/clinical/guideline)
     - "How this applies" text from `citation.appUsage`
   - Animate expand/collapse with `ExpansionTile`
   - Use theme colors, no hardcoded values

3. Create `lib/features/report/widgets/finding_card.dart`:
   - Stateful widget `FindingCard` taking a `Finding` parameter
   - Collapsed state: Card with:
     - Body-path description text (e.g., "Your ankle, knee, and hip compensate together along your back body")
     - Confidence color badge (Container with rounded corners, colored per finding confidence)
     - If confidence is low (red): italic text "Tracking was unclear for this finding -- verify with a practitioner"
     - Expand chevron
   - Expanded state: adds below the collapsed content:
     - **Upstream driver**: "Likely upstream driver: [upstreamDriver]" if present
     - **Recommendation**: styled recommendation text
     - **Practitioner point**: "Ask your practitioner about: [relevant point]"
     - **Citations**: list of `CitationExpandable` widgets for each citation on the finding
   - Confidence color derived from worst-case of finding's compensations:
     - All high → green (BioliminalTheme.confidenceHigh)
     - Any medium, none low → yellow (BioliminalTheme.confidenceMedium)
     - Any low → red (BioliminalTheme.confidenceLow)
   - Use `ExpansionTile` or manual expand -- keep it simple

4. Create `lib/features/report/views/report_view.dart`:
   - Widget `ReportView` receives assessment ID via GoRouter path parameter
   - Accept Assessment via GoRouter `extra` parameter (pre-persistence). Guard: if extra is null, show "Assessment not found" message.
   - **Report builder logic** (private method `_buildReport`):
     - Group `assessment.compensations` by `chain` (ChainType? key)
     - For each group, construct a `Finding`:
       - `bodyPathDescription`: look up from static body-path language map (SBL/BFL/FFL/null → human-readable string)
       - `compensations`: the group's compensations
       - `upstreamDriver`: identify the compensation at the anatomical origin of the chain (ankle for SBL, ankle for FFL, shoulder for BFL). Format: "[joint] [compensationType readable name]"
       - `recommendation`: if any compensation has `CompensationType.ankleRestriction` or chain is SBL/FFL with restriction pattern → "Prioritize ankle and hip mobility work"; if hypermobility indicators (low valgus + high ROM) → "Focus on neuromuscular control and stability training"; default → "Discuss this pattern with a movement professional"
       - `citations`: select from static citation map keyed by CompensationType
     - Build `practitionerPoints` from findings: "Ask about [upstreamDriver] and how it affects [symptom joint]"
     - Construct `Report(findings: findings, practitionerPoints: practitionerPoints)`
   - **Ankle confidence cap**: before building findings, iterate compensations and cap any ankleRestriction compensation's confidence to at most medium
   - **Static citation map** (embedded in file):
     - kneeValgus → Citation(finding: "Knee valgus >10 deg correlates with 2.5x ACL injury risk", source: "Hewett et al. (2005)", url: "https://pubmed.ncbi.nlm.nih.gov/15722287/", type: CitationType.research, appUsage: "Primary threshold for knee valgus detection")
     - hipDrop → Citation(finding: "Hip strengthening resolves knee pain faster than knee-only treatment (n=199)", source: "Ferber et al.", url: "https://pubmed.ncbi.nlm.nih.gov/25102167/", type: CitationType.research, appUsage: "Evidence for upstream driver logic")
     - ankleRestriction → Citation(finding: "SBL: 3/3 transitions verified across 14 cadaveric studies", source: "Wilke et al. (2016)", url: "https://pubmed.ncbi.nlm.nih.gov/26281953/", type: CitationType.research, appUsage: "Foundation for chain selection")
     - trunkLean → Citation(finding: "RESTORE trial (n=492): sustained 3-year improvement with upstream treatment", source: "Lancet via PubMed", url: "https://pubmed.ncbi.nlm.nih.gov/37060913/", type: CitationType.research, appUsage: "Long-term evidence for upstream reasoning")
     - (chain-level) sbl/bfl/ffl → Citation for Gnat 2022 CC/CP framework (url: "https://www.mdpi.com/2075-1729/12/2/222")
     - (all findings) → Citation for Bahr 2016 educational framing (url: "https://bjsm.bmj.com/content/50/13/776")
   - **Summary section** at top:
     - "We found [N] movement patterns worth discussing with a practitioner."
     - Overall confidence sentence: if all green → "Tracking quality was high throughout."; if any red → "Some findings had lower tracking confidence -- marked below."
   - **Layout**: SingleChildScrollView with Column:
     - Summary card (padded, prominent)
     - SizedBox spacer
     - "Your Findings" section header
     - FindingCard widgets for each finding (shrinkWrap ListView or Column)
     - SizedBox spacer
     - "Practitioner Discussion Points" section with bulleted list
   - **App bar actions**:
     - "Export PDF" IconButton: calls PdfGenerator.generate(), writes Uint8List to temp file via path_provider, shows SnackBar on success
     - "Share" IconButton: generates PDF if not cached, then calls Share.shareXFiles with the temp file path
   - **Empty state**: if assessment has zero compensations → show "No significant movement patterns detected. Your movement looks good!" card

5. Wire the report route:
   - Update GoRouter `/report/:id` route in `lib/core/router.dart` to point to ReportView (replace placeholder scaffold with actual import)
   - No new Riverpod providers needed -- ReportView builds Report locally from Assessment data, PdfGenerator is a static utility
   - Verify share_plus and path_provider imports resolve (already in pubspec from story-1293)
<!-- END_CODER_ONLY -->

## Contract

### ReportView input
```dart
// Receives Assessment via GoRouter extra parameter
// Example navigation from screening:
// context.go('/report/${assessment.id}', extra: assessment);

// ReportView extracts:
final assessment = GoRouterState.of(context).extra as Assessment?;
```

### PdfGenerator API
```dart
class PdfGenerator {
  /// Generates a clinical-grade PDF triage report.
  /// Returns raw bytes -- caller handles file I/O and sharing.
  static Future<Uint8List> generate(
    Report report, {
    required String assessmentId,
    required DateTime date,
  });
}
```

### Report assembly (internal, not exported)
```dart
// Groups compensations → Findings with body-path language
Report _buildReport(Assessment assessment);

// Static body-path language map
const _bodyPathDescriptions = {
  ChainType.sbl: "your ankle, knee, and hip compensate together along your back body",
  ChainType.bfl: "your shoulder and opposite hip are connected through your back",
  ChainType.ffl: "your front body -- ankle, knee, hip -- compensates as a unit",
};

// Static citation map keyed by CompensationType
const _citationMap = { CompensationType.kneeValgus: [...], ... };
```

### Downstream consumers
- story-1298 (Data Persistence): stores the generated Report on the Assessment, uploads PDF bytes to Firestore Storage, sets `report.pdfUrl`
- story-1299 (Confidence Visualization): may modify FindingCard to add richer confidence detail

## Acceptance criteria
- When a completed Assessment with 3+ compensations across 2 chains arrives at ReportView, the summary displays finding count and overall confidence, followed by one FindingCard per chain grouping
- When a FindingCard is tapped, it expands to show upstream driver, recommendation, practitioner discussion point, and a CitationExpandable for each citation on that finding
- When a CitationExpandable is tapped, it expands to show the full citation text, source URL (selectable), and "how this applies" explanation
- When a finding includes any compensation with ConfidenceLevel.low, the FindingCard shows a red confidence badge and the text "Tracking was unclear for this finding -- verify with a practitioner"
- When any compensation is ankle-dependent (ankleRestriction type), its finding confidence is capped at medium regardless of raw tracking confidence
- When two users have knee valgus but different upstream patterns (Person A: ankle restriction → mobility recommendation; Person B: hypermobility indicators → stability recommendation), ReportView produces different recommendation text for each
- When "Export PDF" is tapped, PdfGenerator produces a Uint8List PDF containing: header with date, summary, all findings with confidence colors, citations, practitioner points, recommendations, and footer disclaimer -- written to temp directory with success feedback
- When "Share" is tapped, the native share sheet opens with the generated PDF file attached
- When an Assessment has zero compensations, ReportView shows a "no significant patterns" empty state instead of findings
- Body-path descriptions never contain chain names (SBL, BFL, FFL) -- only anatomical body-part language appears in any user-facing text or PDF output
- PDF footer on every page reads: "This is an educational triage tool, not a diagnostic assessment"

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- Body-path language map uses only human-readable anatomical descriptions, never chain abbreviations
- Citation URLs match the presearch/.scout-bioliminal-product.json citation sources
- Confidence color logic matches BioliminalTheme thresholds (high >0.9, medium 0.7-0.9, low <0.7)
- Ankle-dependent confidence cap enforced in report assembly
- PDF contains searchable text (no rasterized content)
- Empty state handles zero-compensation Assessment gracefully
<!-- TESTER_ONLY -->
test_files: test/features/report/services/pdf_generator_test.dart
<!-- END_TESTER_ONLY -->
