# App-Dev Handoff Kit

Everything the app-side developer (and her Claude session) needs to start on Phase 2 — the prompt to seed the Claude session, and the acceptance criteria that define "done" for v0.

**Reads alongside:** `haptic-cueing-handshake.md` (the technical spec itself) and the four supporting docs it references.

---

## Suggested first-message prompt

Paste this verbatim as the first message in the app-dev's Claude session (Claude Code recommended so it can read files directly).

```
You're the mobile-app-side Claude for the Bioliminal bicep curl project —
a closed-loop biofeedback garment that senses EMG, tracks form via the
phone's camera, and fires haptic + visual + verbal cues to coach the user
through a set.

Architecture at a glance:
- ESP32 firmware: owned by another Claude session. Don't touch its repo.
  It streams 3-channel raw EMG over BLE (FF02) at 40 Hz, and accepts
  haptic commands from the phone over BLE (FF04). Contract is fixed.
- Mobile app (your scope): Flutter + Riverpod + google_mlkit_pose_detection.
  Owns the session state machine, rep detection (BlazePose), fatigue
  algorithm, cue decisions, and the user-facing UI.

Start by reading these five docs in this order — all at
/Users/rajatarora/Gauntlet/CapStone/notes/ :

  1. project-status-2026-04-16.md   — overall state and phase roadmap
  2. haptic-cueing-handshake.md     — YOUR primary spec. Phase 2. What to build.
  3. data-capture-handshake.md      — Phase 1 foundation. How to PARSE the
                                       308-byte FF02 stream. Still valid, carries
                                       forward unchanged.
  4. practitioner-notes-lawson.md   — user-level × channel matrix, design
                                       rationale for the CueDispatcher pattern
  5. emg-fatigue-explainer.md       — why the algorithm has the thresholds
                                       it has

Your deliverable for v0:

- New `lib/features/bicep_curl/` feature module per the handshake tree
- Extend `lib/core/services/hardware_controller.dart` with `sendCommand()`
  targeting the FF04 BLE characteristic plus semantic cue wrappers
- Build `BicepCurlController` as a Riverpod sealed-state machine mirroring
  the existing `ScreeningController` pattern
  (lib/features/screening/controllers/screening_controller.dart:14-68)
- Implement the fatigue algorithm: calibration window reps 1-5 (no cues),
  then rolling max over last 5 peaks as the baseline, with 15% / 25% / 50%
  drop thresholds and a 2-rep cooldown
- Software envelope on the RAW channel: rectify + 4th-order IIR LP with
  effective ~70 Hz -3 dB cutoff (filter coefficients in the handshake —
  earlier drafts described these as "5 Hz Butterworth", that's wrong;
  see haptic-cueing-handshake §Envelope derivation)
- Pose-based compensation gate (shoulder drift > 7°, torso pitch > 10°);
  silently suppress fatigue cues when compensation detected (v0 behavior)
- Three-channel cue dispatch (haptic via BLE, visual via UI, verbal via
  flutter_tts); always append every CueDecision to the session log
  regardless of which channels fire in real time
- Post-set debrief dashboard — THIS IS THE DEMO-DAY ANCHOR. Per-rep peak
  chart with baseline overlay, compensation events annotated, cue
  timeline, rep count, form score.

Default to intermediate user profile for v0. Architect the cue dispatch
and algorithm so beginner / intermediate / advanced profiles can be
swapped via a `CueProfile` object — the handshake explains why and how.

Reuse what's already in the codebase before writing anything new:
- Rep detection on elbow angle: adapt screening_controller.dart:228-276
- Pose math: domain/services/pose_math.dart + rule_based_angle_calculator.dart
- BLE wiring: hardwareControllerProvider already scans and connects
- BLE write pattern: proven at lib/features/dev/views/ble_debug_view.dart:238

Validation / verification:

- There is a real captured session at
  /Users/rajatarora/Gauntlet/CapStone/captures/session_Rajiv47_20260417_211321.csv
  with 27 reps including a failure endpoint — feed it through your
  algorithm offline and verify cues fire at the coach-intuitive moments
  (FADE around rep 18, URGENT around rep 22-24, STOP around rep 25).
- The firmware exposes a FF04 command characteristic that accepts
  pre-computed hex payloads — you can test your BLE write code by
  sending payloads directly via the app's existing BleDebugView before
  wiring the full controller.

Coordination rules:

- The BLE protocol (FF02 packet format, FF04 opcodes) is THE contract
  between firmware and app. If you want to propose a protocol change,
  tell the user — they'll relay to firmware-side Claude. Don't
  unilaterally extend the protocol.
- Firmware is a dumb dispatcher. ALL algorithm logic, cue decisions,
  session state, user profiles, UI — everything — lives on your side.
- Open questions the handshake flags (set-end behavior, connection-drop
  handling, UI nav placement) are YOURS to propose and decide; surface
  them to the user when you hit them.

Start by reading all five docs, then lay out an implementation plan
before writing code. Ask the user for clarification on anything unclear
before committing to an approach.
```

---

## Expected result — what "done" looks like for v0

### Code deliverables

```
lib/features/bicep_curl/
├── controllers/bicep_curl_controller.dart      # Riverpod sealed-state machine
├── services/
│   ├── fatigue_algorithm.dart                   # pure function, unit-tested
│   ├── envelope_derivator.dart                  # rectify + 4th-order IIR LP on RAW channel
│   ├── compensation_detector.dart               # pose Δ-from-reference
│   └── cue_dispatcher.dart                      # fans CueDecision → haptic/visual/verbal/log
├── models/{rep_record, cue_event, cue_profile, compensation_reference}.dart
├── views/bicep_curl_view.dart                   # live session UI
└── views/bicep_curl_debrief_view.dart           # post-set dashboard

lib/core/services/hardware_controller.dart       # modified: + sendCommand, + cue wrappers
lib/core/router.dart                             # modified: + /bicep-curl route
```

Unit tests for `fatigue_algorithm.dart` (the pure function) exist and pass.

### Runtime behavior — the end-to-end flow

With the ESP32 running `bicep_realtime.ino` and the app on a real device:

1. Tap **Start Bicep Curl** → camera opens, BLE connects to `Bioliminal Garment`, skeleton overlay renders live.
2. State transitions **Idle → Calibrating**; a "Calibrating: 0/5" badge appears.
3. Do 5 reps — **no cues fire, regardless of how hard you push**. Badge counts up.
4. Rep 5 complete → state transitions **Calibrating → Active**. Calibration badge disappears; fatigue indicator bar appears.
5. Keep lifting. As reps plateau and decline:
   - First rep with ≥15% drop below rolling max → **FADE cue** — motor buzzes (2 × 200 ms pulses), visual indicator flashes.
   - Deeper drop (25%) → **URGENT cue** — stronger buzz (duty 230).
   - Past 50% drop → algorithm emits **STOP** — no more cues, flag in the log.
6. Intentionally swing your shoulder → fatigue cue **silently suppressed** (compensation detected). Visual badge optionally says "watch your form."
7. Tap **End Set** → state transitions **Active → Complete**.
8. **Debrief dashboard opens** showing:
   - Total reps + duration
   - Per-rep peak-envelope chart with rolling baseline overlay
   - Cue timeline ("FADE @ rep 18, URGENT @ rep 22, STOP @ rep 25")
   - Compensation events annotated ("rep 6: shoulder drifted 9°")
   - Form score (% reps without compensation)

### Validation her Claude should run before declaring done

- **Raw command test:** send `10 00 B4 02 C8 00 96 00` to FF04 via BleDebugView → motor fires. Proves BLE write path works end-to-end.
- **Unit tests pass:** fabricated peak sequences produce the correct cue decisions per the algorithm spec (calibration silence, rolling baseline ratchets, cooldown works, all three thresholds fire).
- **Offline replay test:** feed `captures/session_Rajiv47_20260417_211321.csv` through `fatigue_algorithm.dart` — FADE should fire around rep 18, URGENT around rep 22–24, STOP around rep 25. If it fires at rep 3 or 7, the algorithm is broken.
- **Live integration test:** wear the sleeve, run a set, verify cues fire at physically sensible moments — not every rep, not never.

### What's explicitly NOT in v0 (parked for later)

- FORM cue pattern firing — stays silent in v0 (haptic suppressed on compensation, no distinct cue type)
- User-level selector UI — just default to the "intermediate" `CueProfile` for v0 demo
- Multi-set / workout history / cloud sync — session is one-set-and-done
- Verbal prompts can be stubbed/optional — visual + haptic + debrief are the core; verbal is nice-to-have
- Advanced stabilizer meters — parked until 2nd EMG channel lands
- Connection-drop mid-set recovery logic — simple "fail + show error" is acceptable; auto-reconnect is post-v0

### The demo-day acceptance criterion

Walk on stage, plug in the hardware, tap one button, do a set of bicep curls, end the set, and have the **debrief dashboard** tell a coherent story about that set — with per-rep data, cue decisions, and form events clearly visible.

If yes → v0 is done.

The beginner profile makes that dashboard the hero moment. Haptic and verbal are supporting cast — they flip on when you demo the advanced profile mid-presentation.
