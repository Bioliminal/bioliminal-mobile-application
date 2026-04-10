# Mobility Drill Data & Recommendation Engine
Story: story-1321
Agent: architect

## Context
Current recommendations are generic ("Prioritize ankle and hip mobility work", "Discuss this pattern with a movement professional"). The audit calls for 1-2 specific educational mobility drills per finding based on the upstream driver. This story adds the MobilityDrill data model, a drill content database keyed by CompensationType and driver joint, and wires drill selection into ReportAssemblyService.

DATA_FLOW_TRACE segment:
[ChainMapper.mapCompensations()] → List<Compensation> (with type, joint, chain)
→ [ReportAssemblyService.buildReport()] → finds upstream driver per chain
→ [MobilityDrillSelector.drillsForFinding(finding)] → List<MobilityDrill> (1-2 per finding)
→ [Finding now contains List<MobilityDrill> drills field]
→ [LocalStorageService serializes/deserializes MobilityDrill in Finding JSON]

## What changes
| File | Change |
|---|---|
| `lib/domain/models.dart` | Add MobilityDrill class (name, targetArea, durationSeconds, steps: List<String>, compensationType, difficulty). Add `drills` field to Finding (List<MobilityDrill>, defaults to empty). |
| `lib/features/report/data/mobility_drills.dart` | New. Static drill content database: Map<CompensationType, List<MobilityDrill>>. Drills per type: ankleRestriction → ankle circles + wall ankle mobilization; kneeValgus → clamshells + single-leg glute bridge; hipDrop → side-lying hip abduction + standing hip hike; trunkLean → pallof press hold + dead bug. Each drill has 3-5 clear instruction steps. |
| `lib/features/report/services/report_assembly_service.dart` | Import mobility_drills.dart. In buildReport(), after determining upstream driver, call drill selection: pick top 2 drills matching the finding's primary CompensationType. If upstream driver is ankle, prioritize ankle-specific drills. Attach drills to each Finding. |
| `lib/core/services/local_storage_service.dart` | Add _mobilityDrillToJson/_mobilityDrillFromJson helpers. Update _findingToJson/_findingFromJson to serialize/deserialize the drills list. Handle missing drills key for backward compatibility with existing saved assessments (default to empty list). |

## Acceptance criteria
- MobilityDrill model has: name, targetArea, durationSeconds, steps (List<String>), compensationType
- Each CompensationType has at least 2 defined drills with 3-5 instruction steps each
- ReportAssemblyService.buildReport() attaches 1-2 drills to each Finding based on compensation type
- Ankle restriction findings prioritize ankle-specific drills
- Hypermobility findings get stability-focused drills (not mobility drills)
- Serialization round-trip: save assessment with drills → load → drills are preserved
- Loading old assessments (no drills key in JSON) returns findings with empty drill list (no crash)

## Architecture notes
- Drill content is static data, not user-generated — const maps in mobility_drills.dart
- Drill selection is deterministic: same compensations always produce same drills
- The Finding.drills field is populated during report assembly, not stored on Compensation
- Keep drill descriptions action-oriented and jargon-free (matching the app's body-path language)
