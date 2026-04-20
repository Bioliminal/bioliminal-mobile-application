# Task T9 — Provider Wiring

**What:** Extended `lib/core/providers.dart` to wire pose config + landmark smoother providers.

**Files modified:**
- `lib/core/providers.dart`

**Changes:**
1. Added imports: `capability_tier.dart`, `landmark_smoother.dart`
2. Added re-export block for `CapabilityTier`, `PoseConfig`, `PoseDelegate`, `PosePlatform`, `deviceCapabilityProvider`, `poseConfigProvider`
3. Replaced `MediaPipePoseDetector()` with `MediaPipePoseDetector(config: config)` where `config` comes from `ref.watch(poseConfigProvider)`
4. Added `landmarkSmootherProvider` using `OneEuroLandmarkSmoother` with `ref.onDispose(smoother.reset)`

**Analyze result:** No issues found (providers.dart)

**Suite baseline preserved:** 101 passing / 2 failing (pre-existing session_log failures)

**Deviations:** None
