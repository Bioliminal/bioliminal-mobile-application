# Model checksums

Use to detect drift between CI runs and to re-verify after re-downloading.

| File | Size (bytes) | SHA-256 | Source |
|---|---:|---|---|
| `pose_landmarker_full.task` | 9,398,198 | `4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task` |
| `pose_landmarker_heavy.task` | 30,664,242 | `64437af838a65d18e5ba7a0d39b465540069bc8aae8308de3e318aad31fcbc7b` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task` |
| `pose_landmarker_lite.task` | 5,777,746 | `59929e1d1ee95287735ddd833b19cf4ac46d29bc7afddbbf6753c459690d574a` | `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task` |

Verify after pull:

```bash
cd assets/models
shasum -a 256 -c <<EOF
4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad  pose_landmarker_full.task
64437af838a65d18e5ba7a0d39b465540069bc8aae8308de3e318aad31fcbc7b  pose_landmarker_heavy.task
59929e1d1ee95287735ddd833b19cf4ac46d29bc7afddbbf6753c459690d574a  pose_landmarker_lite.task
EOF
```

## About the files

These are the MediaPipe Pose Landmarker variants shipped by Google as
flatbuffer/zip bundles containing two TFLite models
(`pose_detector.tflite`, `pose_landmarks_detector.tflite`). License Apache
2.0. Used by direct MediaPipe Tasks bindings to produce 33 BlazePose
landmarks on-device.

All three tiers are committed to the repo and bundled into the app binary
at build time — no runtime download, no manual fetch step. The capability
tier selection in `lib/core/services/capability_tier.dart` decides which
variant to load per device.

See `bioliminal-ops/operations/handover/mobile/model/` for variant rationale
and `blazepose_landmark_order.md` for the canonical landmark index table.
