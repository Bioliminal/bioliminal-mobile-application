---
Status: Complete
Created: 2026-04-19
Updated: 2026-04-19
Owner: aaron.carney
---

# Task T2 — LandmarkSmoother

## What
Wrapper around `OneEuroFilter` applied per-coordinate across 33 pose landmarks.

## Files
- `lib/features/camera/services/landmark_smoother.dart` (created)
- `test/features/camera/services/landmark_smoother_test.dart` (created)

## Test Count
4 / 4 passing

## Behaviors
1. First frame passes through unchanged (filter seeds on tUs=0)
2. Visibility and presence forwarded unchanged (not position signals)
3. Variance reduction >75% on stationary-jittery input after warmup
4. `reset()` clears all 99 per-landmark filter states

## Deviations
None. Implementation matched plan verbatim. All tests green on first run.
