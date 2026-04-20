## Task T5 — delegate param threading (native Android plugin)

**What:** Extended `PoseLandmarkerHelper.setup` and `PosePlugin.handleInitialize` to accept and forward a `delegate` string parameter, enabling GPU/CPU selection from Dart.

**Files modified:**
- `android/app/src/main/kotlin/com/bioliminal/app/pose/PoseLandmarkerHelper.kt` — `setup(modelAssetPath, delegate)` signature + `when` dispatch to `Delegate.GPU`/`Delegate.CPU`
- `android/app/src/main/kotlin/com/bioliminal/app/pose/PosePlugin.kt` — `handleInitialize` reads `delegate` arg (defaults `"cpu"`), passes to `setup`

**Build verify:** DEFERRED — `No Android SDK found` in WSL2 env. Verify on Kelsi's macOS dev env.

**Deviations:** None. Edits matched plan exactly; existing `Delegate` import already present.

**Commit:** `2d2eb03` on `feat/adaptive-pose-smoothing-2026-04-19`
