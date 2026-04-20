---
Status: Complete
Created: 2026-04-19
Updated: 2026-04-19
Owner: aaron.carney
---

# T10 — Adaptive Pose Smoothing: Controller Wiring

## What

Wired `landmarkSmootherProvider` into the camera pipeline and session teardown paths.

## Files Modified

- `lib/features/camera/controllers/camera_controller.dart` — `_handleFrame` now reads `landmarkSmootherProvider`, captures `tUs` at frame arrival, and passes smoothed landmarks to `updateLandmarks`. `stopStreaming` and `disposeCamera` both call `smoother.reset()`.
- `lib/features/bicep_curl/controllers/bicep_curl_controller.dart` — `build()` caches the smoother into `_smoother` (required: `ref.read` is forbidden inside `onDispose` callbacks in Riverpod 3). `_teardown` calls `_smoother?.reset()` via the cached reference.

## Fixture Created

None — existing tests passed after the `_smoother` cache fix.

## Deviation

Plan specified `ref.read(landmarkSmootherProvider).reset()` directly in `_teardown`, which is called from `ref.onDispose`. Riverpod 3 asserts `_debugCallbackStack == 0` inside lifecycle callbacks, causing an `AssertionError` and failing 6 bicep_curl controller tests. Fix: cache the smoother in `build()` (the `_smoother` field was already declared in the plan's diff) and use `_smoother?.reset()` in `_teardown`. This matches the comment in the plan ("ref becomes invalid once the container disposes") — the ref.read call itself was the bug, not just the timing.

## Baseline Preserved

101 passing, 2 pre-existing session_log failures. No regression.
