# Custom Model Integration Contract

When shipping a custom `.tflite` model for on-device pose estimation, fill out this spec. The Flutter app's `TflitePoseEstimationService` (to be built) will consume these values.

## Model Spec

| # | Question | BlazePose Lite (reference) | Your Model |
|---|----------|---------------------------|------------|
| 1 | Input tensor shape `[1, H, W, 3]` — what are H and W? | 256 x 256 | |
| 2 | Input normalization: `pixel/255` ([0,1]) or `pixel/127.5 - 1` ([-1,1])? | [0, 1] | |
| 3 | Which output tensor index has landmarks, and what shape? | Index 0, `[1, 195]` | |
| 4 | Per-landmark value order (e.g., `[x, y, z, visibility, presence]`)? | x, y, z, visibility, presence | |
| 5 | Are x/y normalized [0,1] or pixel coords relative to input? | Normalized [0,1] | |
| 6 | Are visibility values raw logits (need sigmoid) or probabilities? | Logits | |
| 7 | Landmark ordering — same as BlazePose 33-point? | Yes (MediaPipe standard) | |
| 8 | "No person detected" confidence output — which tensor index? | Index 1, `[1, 1]` | |

## BlazePose 33-Point Landmark Ordering (MediaPipe standard)

```
 0: nose               11: left_shoulder     23: left_hip
 1: left_eye_inner     12: right_shoulder    24: right_hip
 2: left_eye           13: left_elbow        25: left_knee
 3: left_eye_outer     14: right_elbow       26: right_knee
 4: right_eye_inner    15: left_wrist        27: left_ankle
 5: right_eye          16: right_wrist       28: right_ankle
 6: right_eye_outer    17: left_pinky        29: left_heel
 7: left_ear           18: right_pinky       30: right_heel
 8: right_ear          19: left_index        31: left_foot_index
 9: mouth_left         20: right_index       32: right_foot_index
10: mouth_right        21: left_thumb
                       22: right_thumb
```

Matching this ordering avoids a mapping layer in the angle calculator and chain mapper. If your model uses a different ordering, provide the mapping table.

## Fixture Format (shared with server pipeline)

Golden landmark fixtures use this schema (same JSON tests Flutter capture and server pipeline):

```json
{
  "metadata": {
    "movement": "overhead_squat",
    "source_image": "assets/reference_images/overhead_squat.jpg",
    "image_width": 640,
    "image_height": 480,
    "model": "mlkit_pose_detection",
    "captured_at": "2026-04-10T14:32:00Z"
  },
  "frames": [
    {
      "timestamp_ms": 0,
      "landmarks": [
        {"x": 0.52, "y": 0.31, "z": -0.08, "visibility": 0.98, "presence": 1.0}
      ]
    }
  ]
}
```

MLKit captures set `presence: 1.0` (MLKit doesn't distinguish visibility from presence). Custom tflite models should output real presence values if available.

## Integration Path

When the model is ready:

1. Drop the `.tflite` file in `assets/models/`
2. Add `tflite_flutter: ^0.12.0` to `pubspec.yaml`
3. Write a concrete subclass of `TflitePoseEstimationService` implementing the 6 abstract members
4. Wire it into `poseEstimationServiceProvider` in `lib/core/providers.dart`
5. Run golden comparison integration test against MLKit baseline fixtures
