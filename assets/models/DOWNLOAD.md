# Pose Landmarker Model Downloads

**Status:** current
**Created:** 2026-04-19
**Updated:** 2026-04-19
**Owner:** AaronCarney

MediaPipe Pose Landmarker `.task` asset files are not committed to the repo
(they're gitignored; size + churn). Fetch them into `assets/models/` on your
dev machine before running a device build.

## pose_landmarker_full.task (mid tier — Android default, iOS mid)

- Size: ~9 MB
- Source: https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task
- SHA-256: `4eaa5eb7a98365221087693fcc286334cf0858e2eb6e15b506aa4a7ecdcec4ad`

## pose_landmarker_heavy.task (high tier — iPhone 17 Pro demo target)

- Size: ~29 MB
- Source: https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task
- SHA-256: `<pending fetch>`

## pose_landmarker_lite.task (low tier)

- Size: ~3 MB
- Source: https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task
- SHA-256: `<pending fetch>`

## Manual fetch (sandboxed agents cannot reach the network)

Run these from your dev machine shell:

```bash
cd assets/models
curl -L -o pose_landmarker_heavy.task \
  https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task
curl -L -o pose_landmarker_lite.task \
  https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task
sha256sum pose_landmarker_full.task pose_landmarker_heavy.task pose_landmarker_lite.task
```

Update `CHECKSUMS.md` with the resulting hashes.

## Version pinning

Mobile#50 tracks pinning to a versioned URL instead of `/latest/` post-demo.
