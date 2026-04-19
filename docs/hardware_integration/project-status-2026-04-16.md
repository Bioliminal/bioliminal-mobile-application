# Project Status — Bioliminal Bicep Curl v0

Snapshot as of 2026-04-16. Reference this to get back up to speed after time away.

---

## The product
Bioliminal closed-loop biofeedback garment. **First demo: bicep curl.** User puts on a sleeve, taps "Start Bicep Curl" in the app, does a set. Garment senses muscle effort (EMG), phone senses movement (camera + BlazePose), vibration cue fires at the coach-intuitive "you're fading" moment.

## The hardware (locked for v0)
- **MCU:** ESP32-WROOM-32UE, 2.4 GHz BLE, 115 200-baud serial
- **EMG sensor:** 1× MyoWare 2.0 on biceps brachii. **All three analog outputs wired** (as of 2026-04-16):
  - **ENV** → GPIO34 (ADC1_CH6) — hardware envelope, rectified + 3.6 Hz LP
  - **RAW** → GPIO35 (ADC1_CH7) — amplified bipolar EMG, 20–500 Hz passband, centered at VCC/2
  - **RECT** → GPIO32 (ADC1_CH4) — full-wave rectified, no smoothing
- **Haptic actuator:** 1× DFRobot FIT0774 coin ERM (10 × 2.7 mm, 3 V / 90 mA, ~200 Hz mechanical resonance — Pacinian-optimal). Driven via 2N7000 N-MOSFET on GPIO25 with LEDC PWM (2 kHz, 8-bit duty 0–255). DigiKey PN 1738-FIT0774-ND. 7 in stock.
- **Power:** 800 mAh LiPo + TP4056 charger
- **BLE link:** proven live at 10-byte notify / 20 Hz (current synthetic-sine sketch); about to be replaced with 308-byte / 40 Hz raw-triplet stream for Phase 1 data capture

## The software (two codebases, two Claude sessions)
- **Firmware repo:** `/Users/rajatarora/Gauntlet/CapStone/esp32-firmware/` — existing Arduino sketches `emg_read`, `emg_fatigue`, `motor_test`, `esp32_ble_test` used as building blocks. Firmware Claude works here.
- **Mobile app repo:** `/Users/rajatarora/Gauntlet/CapStone/bioliminal-mobile-application/` — Flutter, Riverpod, flutter_blue_plus, google_mlkit_pose_detection (BlazePose already running on-device). App-side Claude works here.

## Architecture (committed)
- **Phone owns the session.** Camera + BlazePose counts reps. Phone reads EMG from BLE, computes fatigue, writes haptic commands back.
- **ESP32 stays dumb.** Streams EMG envelope at 20 Hz on `FF02`. Executes haptic commands from new `FF04` write characteristic. Zero rep detection, zero fatigue logic onboard.
- **Reason:** CV rep detection is unambiguous; EMG thresholds are noisy. Haptic roundtrip latency (~50 ms) doesn't matter because cues fire at the bottom-dead-center pause, not mid-lift.

## Algorithm (research-grounded — see `emg-fatigue-explainer.md`)
- **Signal:** per-rep peak of the rectified-and-smoothed EMG envelope (100 ms window; 4th-order IIR LP, effective ~70 Hz -3 dB cutoff — earlier docs mis-labeled this as 5 Hz, see haptic-cueing-handshake §Envelope derivation)
- **Baseline:** max of first ≥3 reps; ratchets up while rising; freezes when peak starts declining — **adaptive, not rep-number-gated.** Works for heavy weights that fatigue at rep 3 *and* light weights that fatigue at rep 12.
- **Thresholds:** 15% drop → primary cue, 25% drop → urgent cue, > 50% drop → stop (past useful intervention)
- **Haptic shape:** 2-pulse burst, 200 ms on / 150 ms off, fired at BDC (never mid-concentric)
- **Pose gate:** BlazePose-monitored; if shoulder drift > 5–7° or torso pitch > 8–10°, suppress cue (don't reward cheating)
- **Cooldown:** 2 reps minimum between cues (prevents Pacinian habituation)

## BLE protocol
| Char | Props | Use |
|---|---|---|
| `FF02` | NOTIFY | 10 B @ 20 Hz, ESP32 → phone (EMG envelope in byte 0) |
| `FF04` | WRITE | variable length, phone → ESP32. Opcodes: `0x10 SET_HAPTIC`, `0x11 STOP_HAPTIC`, `0x12 SET_MODE`, `0x13 RESET_SESSION`, `0x14 PULSE_BURST` |

## What's decided
- Architecture split (phone = brain, ESP32 = dumb actuator/sensor)
- BLE protocol
- Algorithm parameters (adaptive fatigue onset, 15/25/50% thresholds, 2-pulse burst, pose gate, 2-rep cooldown)
- No 3-2-1 countdown
- Single preset ("Start Bicep Curl") for v0
- Haptic fires pre-rep at BDC, never during the lift

## What's still open
- **Set-end behavior** — timeout, explicit button, or hybrid
- **Bicep curl screen UI scope** — minimal (skeleton + rep count) or instrumented (fatigue chart, compensation indicator)
- **Connection-drop mid-set** — pause / fail / auto-reconnect
- **Latency verification** — measure end-to-end BDC → motor-start during integration

## Known tradeoffs
1. **Motor on biceps belly = internal-focus cue.** Wulf/Vance/Iwata research says tactile-on-agonist hurts strength output slightly. Mitigated by short pre-rep pulses. V2 hardware should relocate motor to forearm or lateral upper arm.
2. **One EMG channel = blind spot for synergist recruitment.** Pose gate catches gross compensation; a second EMG (brachioradialis or anterior deltoid) would be the real fix.
3. **CV rep detection requires user in frame.** No EMG-only fallback currently.
4. **Session = one set.** No multi-set workout model yet.

## Current phase of work — updated 2026-04-18

**Phase 1 (DONE):** Raw EMG data capture. Button-triggered sketch (`emg_button_capture.ino`) + Python pyserial dashboard (`live_dashboard.py`). Two sessions captured and analyzed:
- Rajat 30 reps no failure (baseline / recruitment-rise)
- Rajiv 27 reps to failure (gold-standard fatigue signature)
Key learnings: 9.4% noise CV matches literature; software envelope (rectify + 4th-order IIR LP on RAW, effective ~70 Hz cutoff — handshake's "5 Hz" label was wrong) correlates 0.885 with hardware ENV; `max(peak_1..3)` + freeze-at-rep-5 baseline is **broken** on real data (Rajiv's peaks climbed to rep 16, far past the freeze point); MDF not useful for dynamic reps.

**Phase 2 (ACTIVE):** Realtime cueing with revised algorithm, CV compensation gate, and **three-channel cue fan-out** (haptic + visual + verbal + post-set debrief). See `haptic-cueing-handshake.md`.
- Firmware sketches: **two, paired** — `bicep_realtime.ino` is the BLE production sketch (raw stream + FF04 command char + pulse scheduler); `bicep_hardware_test.ino` is the no-BLE bench-test twin (BOOT button + Serial commands → identical pulse scheduler) so the hardware can be validated before the app lands.
- App: new `features/bicep_curl/` module — `BicepCurlController` with calibration window (reps 1–5, no cues) + rolling-max baseline (last 5 peaks) + 15%/25%/50% drop thresholds + pose-based compensation gate + `CueDispatcher` that fans out each decision to enabled channels per user profile.
- **Post-set debrief is the demo-day anchor** — silent set with rich dashboard at end. Reliable on stage, visually impressive, doesn't depend on haptic landing audibly. Advanced-profile flip demonstrates the full channel suite.
- Extensible to multi-sensor / multi-motor (BLE protocol accommodates without changes).

**Phase 3 (post-Phase-2 validation):** Fitness expert consults to scope synergist sensor placements (brachialis, brachioradialis, upper trap, etc.) and multi-motor cue semantics. Light up the FORM cue. Multi-subject / multi-load validation.

**Phase 4 (adaptive cueing, newly scoped 2026-04-18):** Per Lawson Harris (pilates instructor, practitioner-notes), cue timing is **user-skill-dependent** — beginners benefit from fewer, later, simpler cues (even post-set only); advanced users tolerate mid-rep cues and get high value from graduated pressure reinforcement. Adds a user-level dimension to the cueing strategy and drives the v2 TSA (graduated pressure) hardware roadmap. See `practitioner-notes-lawson.md`.

## Where to look next
- `~/Gauntlet/CapStone/notes/haptic-cueing-handshake.md` — **active handshake** for Phase 2 realtime cueing
- `~/Gauntlet/CapStone/notes/app-dev-handoff.md` — **onboarding kit** for the app-side developer (prompt + v0 acceptance criteria)
- `~/Gauntlet/CapStone/notes/data-capture-handshake.md` — Phase 1 foundation (still valid for future data-capture runs)
- `~/Gauntlet/CapStone/notes/practitioner-notes-lawson.md` — Lawson Harris on user-level-dependent cue timing (drives v1+ design)
- `~/Gauntlet/CapStone/notes/emg-fatigue-explainer.md` — peak + 15% threshold explainer
- `~/Gauntlet/CapStone/captures/` — captured sessions + analysis artifacts (Python scripts, plots)
- `~/.claude/plans/we-are-targeting-bicep-binary-cherny.md` — private plan file
