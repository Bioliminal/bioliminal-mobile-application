# tflite_flutter Platform Notes

Research findings from custom model integration spike (April 2026). Reference when building the tflite pose estimation service.

## Package Status

- **Latest version**: 0.12.1 (October 2024, published by tensorflow.org)
- **Status**: "work-in-progress" / "TensorFlow managed fork"
- **Repo**: github.com/tensorflow/flutter-tflite (102 open issues as of April 2026)
- **Release pace**: Slow — 0.12.0 and 0.12.1 both landed Oct 2024, nothing since

## iOS Delegates

**Metal GPU delegate** — Use this. Generally reliable on physical devices.
- Requires `TensorFlowLiteCMetal.framework` in iOS project
- Can fail on certain model/device combos (issue #286) — wrap in try/catch, fall back to CPU

**CoreML delegate** — Do NOT use. Crashes with SIGABRT during `TfLiteInterpreterCreate()`.
- Root cause: protobuf version incompatibility (TFLite bundles 3.21.9, CoreML needs 3.19.x)
- Workaround requires rebuilding native binaries — not practical for pub.dev consumers
- Source: github.com/tensorflow/tensorflow/issues/73167

**iOS Simulator** — Not supported. Tests must run on physical devices.

**iOS Release Builds** — Change Xcode "Strip Style" from "All Symbols" to "Non-Global Symbols" or you get symbol lookup errors at runtime.

## Known Bugs

**interpreter.close() memory leak** (issue #110): `close()` does not reliably free native heap memory. Mitigation: create the interpreter once per session, reuse across all frames, only close on app dispose. Never recreate per-frame.

**GPU delegate invoke leak** (tensorflow/tensorflow#70316): `TfLiteInterpreterInvoke()` has a confirmed heap leak when using GPU delegate across repeated calls. Memory grows over time. Same mitigation — minimize interpreter recreation.

**Interpreter is not isolate-safe**: Cannot share across Dart isolates. If using isolates for inference, create a new interpreter inside each isolate.

## Android Delegates

**GPU delegate (GpuDelegateV2)** — Works reliably. Primary recommendation for Android.

**NNAPI delegate** — Available but device-dependent. GPU delegate is more predictable.

## BlazePose Landmark Lite Model Specs

- Input: `[1, 256, 256, 3]` float32, RGB, normalized [0, 1] (pixel / 255.0)
- Output 0: `[1, 195]` — 33 landmarks x 5 values: x, y, z, visibility, presence
  - x, y already normalized [0,1] within the 256x256 crop
  - z is relative depth (similar scale to x)
  - visibility/presence are likely logits — apply sigmoid, verify at runtime
- Output 1: `[1, 1]` — pose presence score
- Outputs 2-4: segmentation mask, heatmaps, world landmarks (not needed)
- Detection model normalization differs: [-1, 1] (pixel / 127.5 - 1.0)

## Sources

- pub.dev/packages/tflite_flutter
- github.com/tensorflow/flutter-tflite
- github.com/tensorflow/tensorflow/issues/73167 (CoreML crash)
- github.com/tensorflow/flutter-tflite/issues/110 (memory leak)
- github.com/tensorflow/tensorflow/issues/70316 (invoke leak)
- github.com/geaxgx/depthai_blazepose (model specs)
- github.com/google-ai-edge/mediapipe/issues/5622 (output shapes)
- github.com/google-ai-edge/mediapipe/issues/6114 (normalization)
