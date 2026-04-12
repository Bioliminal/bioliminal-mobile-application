# AuraLink Mobile Hand-off Package

Everything the Flutter teammate needs to ship the launch-candidate phone client.
Matches the server contract at `software/server/src/auralink/api/schemas.py`.

**Contents of this directory**

```
software/mobile-handover/
├── README.md                          ← you are here
├── interface/
│   ├── models.dart                    ← data classes mirroring the server schema
│   ├── pose_detector.dart             ← abstract pose-model interface
│   └── mediapipe_pose_detector.dart   ← reference implementation skeleton
├── schemas/
│   └── session.schema.json            ← JSON Schema exported from pydantic
├── fixtures/
│   └── sample_valid_session.json      ← known-valid payload (5 frames, overhead squat)
├── model/
│   ├── DOWNLOAD.md                    ← where to get pose_landmarker_full.task
│   └── blazepose_landmark_order.md    ← canonical 33-landmark index table
└── tools/
    ├── export_schemas.py              ← regenerate session.schema.json
    └── post_sample.sh                 ← smoke-test upload against a running server
```

---

## The contract in one paragraph

Capture overhead-squat / single-leg-squat / push-up / rollup video at ≥ 25 fps.
Run MediaPipe BlazePose Full on-device. Convert every frame to a `PoseFrame`
(33 landmarks, canonical BlazePose order, visibility + presence in [0,1]).
Bundle the frames into a `SessionPayload` with metadata (movement, device,
`"mediapipe_blazepose_full"`, measured fps, UTC timestamp) and POST it as JSON
to `http://<server>/sessions`. The server responds with
`{session_id, frames_received}`. Fetch the analysis later via
`GET /sessions/{id}/report` (shape TBD — ship a "pending" view first).

That's the whole protocol. Everything else in this package exists to make
that paragraph easy to implement.

---

## Step-by-step integration

### 1. Download the model (once)

```
cd model
open DOWNLOAD.md        # contains the Google CDN URL + expected SHA-256
```

Drop `pose_landmarker_full.task` into your Flutter project's
`assets/models/` directory and register it in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/pose_landmarker_full.task
```

### 2. Copy the Dart contract files

Copy all three files from `interface/` into your Flutter project:

- `lib/models/auralink_session.dart`  ← from `models.dart`
- `lib/pose/pose_detector.dart`       ← from `pose_detector.dart`
- `lib/pose/mediapipe_pose_detector.dart` ← from `mediapipe_pose_detector.dart`

Rename the imports to match your project layout. The classes are plain
Dart — no freezed, no codegen step. If you want freezed/json_serializable
later, swap them in behind the same interface without changing callers.

### 3. Pick a MediaPipe binding and wire `initialize()` / `detect()`

Three options, listed in order of expected effort (lowest first):

1. **`google_mlkit_pose_detection`** (ML Kit). Easiest. Returns the 33
   BlazePose landmarks in canonical order. Ship this unless you hit a blocker.
2. **Direct MediaPipe Tasks plugin** (if a maintained Flutter binding exists
   when you start). More flexible — lets you swap `.task` files without
   changing app code. Worth the effort if you want to A/B test model
   variants.
3. **Platform channels straight to the native MediaPipe Tasks API**
   (Android + iOS). Maximum control, maximum work. Don't do this unless
   option 2 turns out to be a dead end.

Whichever you pick, the reference skeleton in
`interface/mediapipe_pose_detector.dart` marks the two methods that need
real bodies: `initialize()` and `detect()`. Every other class in the
package already works as-is.

### 4. Capture + upload

Rough flow in Dart (not copy-paste; structure only):

```dart
final detector = MediaPipePoseDetector();
await detector.initialize();

final frames = <PoseFrame>[];
await for (final image in cameraController.imageStream) {
  final frame = await detector.detect(
    imageBytes: image.bytes,
    width: image.width,
    height: image.height,
    rotationDegrees: image.rotation,
    timestampMs: image.timestampMs,
  );
  if (frame != null) frames.add(frame);
}
await detector.dispose();

final payload = SessionPayload(
  metadata: SessionMetadata(
    movement: MovementType.overheadSquat,
    device: await _deviceModel(), // e.g. "Pixel 8 Pro"
    model: detector.modelId,
    frameRate: measuredFps,
  ),
  frames: frames,
);

final response = await http.post(
  Uri.parse('$serverBase/sessions'),
  headers: {'content-type': 'application/json'},
  body: jsonEncode(payload.toJson()),
);
```

The `SessionPayload.toJson()` output is exactly what `sample_valid_session.json`
looks like. If the server accepts that fixture, it'll accept your payload.

### 5. Smoke-test before touching UI

With the server running locally (or anywhere reachable):

```
cd tools
./post_sample.sh http://localhost:8000
```

You should see a `201 Created` response with a `session_id`. If you don't,
the fixture or your server is broken — fix before writing Flutter code.

---

## What NOT to build on the phone

Clear scope boundary so we don't duplicate server work:

- ❌ **No chain reasoning, no risk flagging, no MSI classification.** Server
  only. Joyce 2023 and Van Dillen 2016 make clear this has to be centralized
  and auditable.
- ❌ **No onboarding questionnaire.** Team decision 2026-04-10. Body type gets
  auto-derived from the SKEL shape vector server-side.
- ❌ **No account wall** on the free flow. Low-friction onboarding is the
  whole pitch.
- ❌ **No 3D lifting, no WHAM, no OpenCap Monocular, no HSMR.** Those are
  all server-side — even on capable phones, we don't ship them in the app.
- ❌ **No sEMG pairing UI** yet. That unlocks in the hardware epoch.

What the phone DOES own:
- ✅ Camera capture with framing guidance (real-time skeleton overlay with
  visibility-coloured landmarks — this is the single biggest accuracy lever
  per research-integration-report §1.2).
- ✅ Setup validation (progressive requirement checks: lighting, distance,
  full-body-in-frame).
- ✅ MediaPipe on-device inference.
- ✅ Rep counting and live cue text for user feedback during capture.
- ✅ Upload + retry + error UX.
- ✅ Report fetch + render.

---

## Regenerating the JSON schema

If the server-side pydantic models change, refresh the schema:

```
cd tools
./export_schemas.py
```

This writes `schemas/session.schema.json` from the live pydantic models.
Commit the refreshed file. The Dart classes are hand-written — update
`interface/models.dart` to match.

---

## Validation checklist before you consider this done

- [ ] `post_sample.sh` returns 201 against a local server.
- [ ] `SessionPayload.toJson()` round-trips through
      `SessionPayload.fromJson(jsonDecode(payload.toJson()))` byte-for-byte
      (the Dart classes include `fromJson` for this test).
- [ ] Every rejected frame (no person detected, < 33 landmarks, bad
      confidence) is dropped silently — the server enforces "exactly 33
      landmarks per frame," partial frames will 422.
- [ ] `metadata.model` is always `"mediapipe_blazepose_full"` for this
      ship; no hardcoded values anywhere else.
- [ ] A 10-second overhead squat capture produces ~250–300 frames (at
      ~25–30 fps). Fewer than ~100 means something's wrong with capture
      throughput.

---

*Maintained alongside `software/server/src/auralink/api/schemas.py`. If you
see drift, the server schema wins — regenerate `session.schema.json` and
update `models.dart` to match.*
