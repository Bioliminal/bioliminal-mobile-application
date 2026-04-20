# Task T3 — RepDecisionPolicy + ExtremaAmplitudeGate

## What
Streaming state-machine rep counter for bicep curl. Ports 30° amplitude gate from server `rep_segmentation.py`. Three-phase FSM: armed → descending → ascending → emit RepCompleteEvent.

## Files
- `lib/features/bicep_curl/services/rep_decision_policy.dart` (created)
- `test/features/bicep_curl/services/rep_decision_policy_test.dart` (created)

## Test Count
5 behaviors, all passing.

## Deviations
- Plan test imports `ArmSide` from `package:bioliminal/domain/models.dart` — `ArmSide` is not there; it lives in `lib/features/bicep_curl/models/compensation_reference.dart`. Fixed import in test file. Impl imports from same location.
- All 5 behaviors implemented in single green pass (impl written verbatim from plan after first red run).
