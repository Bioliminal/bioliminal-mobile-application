# Task T13 — Jitter Rejection Integration Tests

## What
Created 4 integration tests in `test/features/bicep_curl/jitter_rejection_test.dart` exercising the full smoother → detector loop + provider graph.

## Files
- `test/features/bicep_curl/jitter_rejection_test.dart` (created)

## Tests
4 / 4 passing.

## Deviations
- Import for `ArmSide` adjusted from `domain/models.dart` (not present) to `features/bicep_curl/models/compensation_reference.dart` (actual location). Plan's `models.dart` import was incorrect; auto-fixed inline per task instructions.
