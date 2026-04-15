# MediaPipe Pose Landmarker model

## What to download

**Model:** MediaPipe Pose Landmarker, `full` variant.
**File name:** `pose_landmarker_full.task`
**Size:** ~10 MB (varies by version).
**License:** Apache 2.0 (see Google MediaPipe model card).
**Keypoint count:** 33 (BlazePose canonical order — see
`blazepose_landmark_order.md`).

## Source

Google publishes the `.task` files on their CDN under
`https://storage.googleapis.com/mediapipe-models/pose_landmarker/`. The
`full` variant path at time of writing is:

```
https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task
```

**Verify before committing to this URL.** Google occasionally reorganizes
the bucket. The authoritative index is the model card page linked from
https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker —
go there, copy the current "Pose landmarker (Full)" download link, and
drop it into `fetch_mediapipe_model.sh` below if different.

## Why `full`, not `lite` or `heavy`

| Variant | Size | Latency (mid-range Android) | Accuracy |
|---|---|---|---|
| lite   | ~3 MB  | ~15 ms | Lower — not recommended for biomechanics |
| full   | ~10 MB | ~30–50 ms | Our target — accuracy/speed balance |
| heavy  | ~30 MB | ~80+ ms | Diminishing returns for our use case |

The research-integration-report §1 accuracy envelope (hip r=0.94, knee
r=0.95) was measured on a variant equivalent to `full`. Shipping `lite`
puts our rule thresholds into a regime we haven't validated.

## Fetch script

Create `fetch_mediapipe_model.sh` next to this file, paste the verified URL,
and run it from the Flutter project's `assets/models/` directory:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODEL_URL="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task"
DEST="pose_landmarker_full.task"

echo "Downloading MediaPipe Pose Landmarker (full) ..."
curl -L -o "$DEST" "$MODEL_URL"

echo "Computing SHA-256..."
sha256sum "$DEST"

echo "Done. Commit the file (or .gitignore + CI-download it) and add to pubspec.yaml:"
echo "  flutter:"
echo "    assets:"
echo "      - assets/models/pose_landmarker_full.task"
```

After downloading, record the SHA-256 in your Flutter project's
`CHECKSUMS.md` so you can detect model drift between CI runs.

## Where the file lives in the Flutter project

```
your_flutter_app/
└── assets/
    └── models/
        └── pose_landmarker_full.task
```

Registered in `pubspec.yaml` under `flutter.assets`. Accessed at runtime
via `rootBundle.load('assets/models/pose_landmarker_full.task')` or
passed directly as a path to the MediaPipe plugin.

## Size / git considerations

The `.task` file is ~10 MB. Options:

1. **Commit it.** Simple, works offline, no CI flakes. Git LFS optional
   for cleanliness. Recommended for a capstone.
2. **Gitignore + CI download.** Keeps the repo small but adds a network
   dependency to every clean build. Only worth it if you end up shipping
   multiple variants.

Either way — never download it at app startup. The model ships in the
APK/IPA.
