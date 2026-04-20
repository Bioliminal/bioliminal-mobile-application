# Task T6 — Swift Native Plugin Delegate Threading

## What
Threaded the `delegate` parameter through the iOS native pose plugin so the Flutter `initialize` call can select CPU/GPU/CoreML inference at runtime.

## Files Modified
- `ios/Runner/Pose/PoseLandmarkerHelper.swift` — Extended `setup` signature from `(modelAssetPath:)` to `(modelAssetPath:delegate:)`. Added switch on `delegate.lowercased()` mapping `"coreml"` → `.CoreML`, `"gpu"` → `.GPU`, default → `.CPU`.
- `ios/Runner/Pose/PosePlugin.swift` — Updated `handleInitialize` to extract `delegate` from args (defaults `"cpu"`), pass it to `helper.setup(modelAssetPath:delegate:)`.

## Deferred Verify
iOS compile verification deferred to Kelsi's macOS dev env — `xcodebuild` unavailable in WSL2/Linux.

## Deviations
None. Existing enum style (`.CPU`, `.GPU`, `.CoreML`) was not yet set in the file; plan cases matched MediaPipe Tasks Vision iOS convention and were applied as specified.

## Commit
`156d160` feat(pose-ios): thread delegate param through native plugin
