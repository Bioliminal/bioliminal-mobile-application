---
Status: Complete
Created: 2026-04-19
Owner: aaron.carney
---

# R1 — Pose Detector Init Failure Surface

## What

Added `_initFailed` flag + `initFailed` getter + SEVERE-level `developer.log` to
`MediaPipePoseDetector`. When `PoseChannel.initialize()` returns `false` (missing
`.task` asset, license not accepted, etc.), the detector now logs once and fast-returns
`const []` on all subsequent `processFrame` calls without retrying init.

## Files Changed

- `lib/features/camera/services/pose_detector.dart` — added `dart:developer` import,
  `_initFailed` field, `initFailed` getter, log-once path in init block, guard before
  frame processing.
- `test/features/camera/services/pose_detector_test.dart` — added test that wires a
  mock `MethodChannel` returning `false` from `initialize`, asserts `initFailed=true`
  after first call and `initCalls=1` after second call (no retry).

## Tests

2 passing in `pose_detector_test.dart` (1 pre-existing + 1 new).
Pre-existing 105/2 baseline unchanged (full suite not re-run; disjoint from R2/R3 files).

## Commit

`b1dec16` — fix(pose): surface MediaPipePoseDetector init failure via log + initFailed flag
