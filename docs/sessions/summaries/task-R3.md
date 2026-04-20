---
Status: Complete
Created: 2026-04-19
Updated: 2026-04-19
Owner: aaron.carney
---

# R3 Summary — Policy Start Angle + Rep-Start Wiring

## What

Fixed two bugs in the bicep curl pipeline (N1 + W1) via TDD.

## Files Modified

- `lib/features/bicep_curl/services/rep_decision_policy.dart` — N1: track peak armed angle; use it as `startAngle` at armed→descending transition
- `lib/features/bicep_curl/services/rep_detector.dart` — W1: add `_startController` + `onRepStart` stream; emit on `RepStartedEvent`
- `lib/features/bicep_curl/controllers/bicep_curl_controller.dart` — W1: wire `_repStartSub`; clear `_currentRepFrames` in `_onRepStart`
- `test/features/bicep_curl/services/rep_decision_policy_test.dart` — N1 behavioral test
- `test/features/bicep_curl/services/rep_detector_test.dart` — W1 behavioral test

## Test Counts

- Baseline: 105 passing / 2 pre-existing failures
- After R3: 108 passing / 2 failures (pre-existing session_log failures unchanged)
- New tests added: 2 (one per fix)

## Key Decisions

- N1: `_lastObservedAngle` tracks the peak angle seen while armed (max-update, not last-update). This captures the arm's resting/top position before descent begins, not an intermediate descent value. Initialized to 0.0 so any observed angle updates it.
- W1: `RepDetector` now holds two broadcast stream controllers — `_controller` (RepBoundary on complete) and `_startController` (int tUs on start). Controller wires `_repStartSub` alongside `_repSub`; both cancelled in `_teardown`.

## Commits

1. `fix(bicep_curl): capture actual start angle in policy instead of armedAngleDeg constant`
2. `feat(bicep_curl): expose onRepStart stream from RepDetector`
3. `fix(bicep_curl): clear currentRepFrames on rep-start boundary (not only rep-end)`
