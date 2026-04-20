# Model checksums

Use to detect drift between CI runs and to re-verify after re-downloading.

| File | Size (bytes) | SHA-256 | Source |
|---|---:|---|---|
| `pose_landmarker_full.task` | 9,398,198 | `4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task` |

Verify after pull:

```bash
cd assets/models
sha256sum -c <<EOF
4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad  pose_landmarker_full.task
EOF
```

## About the file

`pose_landmarker_full.task` is the MediaPipe Pose Landmarker (Full variant)
shipped by Google as a flatbuffer/zip bundle containing two TFLite models
(`pose_detector.tflite`, `pose_landmarks_detector.tflite`). License Apache
2.0. Used by direct MediaPipe Tasks bindings to produce 33 BlazePose
landmarks on-device. See `bioliminal-ops/operations/handover/mobile/model/`
for variant rationale and `blazepose_landmark_order.md` for the canonical
landmark index table.

| File | Size (bytes) | SHA-256 | Source |
|---|---:|---|---|
| `pose_landmarker_heavy.task` | ~29 MB | `<pending fetch — run sha256sum on downloaded file and update>` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task` |
| `pose_landmarker_lite.task` | ~3 MB | `<pending fetch — run sha256sum on downloaded file and update>` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task` |
