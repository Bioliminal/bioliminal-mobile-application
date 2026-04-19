# Haptic Cueing Pipeline — Firmware ↔ App Handshake (Phase 2)

**Builds on** `data-capture-handshake.md` (Phase 1) — raw-stream wiring, BLE FF02 packet format, firmware "no onboard DSP" discipline all carry forward.

**Status:** approved 2026-04-18 — firmware implementation in progress by firmware claude; app-side implementation can start in parallel. Joint integration test once both sides land.

**Audience:** Bioliminal mobile-app Claude (working in `/Users/rajatarora/Gauntlet/CapStone/bioliminal-mobile-application/`).

---

## Why this phase exists

Phase 1 captured two real bicep-curl sessions and validated the hardware pipeline. Analysis revealed that the originally-proposed algorithm (`baseline = max(peak_1..3)` then freeze by rep 5) **fails** on real data because biceps EMG peaks keep rising through mid-set on real subjects. Button-timing noise in the first 3 reps amplified the problem.

This phase specifies the **revised algorithm** (calibration window + rolling baseline), **introduces the FF04 command characteristic** for app→firmware haptic commands, and wires **CV-based compensation detection** into the cue decision. Architecture is also future-proofed for multi-sensor / multi-motor expansion.

### What the Phase 1 data told us

- Rep-to-rep noise CV: **9.41%** on stable reps — matches literature 8–12% band. Supports 15% drop threshold.
- Rajiv's 27-rep set: peaks climbed from ~100 at rep 1 to **318.9 at rep 16** (recruitment phase), plateaued through rep 24, collapsed to 7.5 at rep 27 (failure). Textbook fatigue curve.
- Rajat's 30-rep set: peaks rose from ~1050 (RAW range) to ~1700 with no decline. Example of a set where the algorithm should fire **no** cues (never reached fatigue).
- Software envelope (rectify RAW → 4th-order IIR LP, effective ~70 Hz -3 dB cutoff; see §Envelope derivation note on the 5 Hz mis-description) correlates **0.885** with the hardware ENV channel — pipeline validated.
- MDF (median frequency) **not useful** for dynamic curls. Stick with peak-amplitude.

---

## The algorithm (data-backed v1)

```
STATE: Idle
  User starts session in app UI → transition to Calibrating.

STATE: Calibrating  (reps 1..5)
  - Subscribe to EMG stream (FF02) and BlazePose frame stream.
  - Detect reps from elbow-angle peak/trough (reuse ScreeningController pattern).
  - Per rep: extract peak of SOFTWARE envelope over rep window
    (rectify RAW channel + 4th-order IIR LP; see §Envelope derivation — the 5 Hz label in earlier drafts is wrong, actual is ~70 Hz).
  - Accumulate baseline = max(peak_1..peak_N) as reps come in.
  - Record pose reference: shoulder-Y and torso-pitch averaged over reps 1..3.
  - Emit NO CUES regardless of any drop value.
  - On 5th rep complete → transition to Active.

STATE: Active  (reps 6+)
  - Baseline = rolling max over last 5 peaks (NEVER FROZEN; always ratchets).
  - drop = 1 - (peak_N / baseline)
  - compensation_active = (Δshoulder_Y > SHOULDER_THRESH)
                       OR (Δtorso_pitch > TORSO_THRESH)
                       from the calibration reference.
  - Decision tree (first match wins):
      if drop > 0.50                       → STOP (no cue)
      elif compensation_active             → silent suppress (v0) / FORM cue (v1)
      elif drop > 0.25 AND cooldown_ok     → URGENT fatigue cue
      elif drop > 0.15 AND cooldown_ok     → FADE fatigue cue
      else                                 → no cue
  - cooldown_ok: (rep_N - last_cue_rep) >= 2

  End Set → transition to Complete.
```

**Constants:**
```dart
const REP_CALIBRATION_COUNT   = 5;
const FATIGUE_FADE_THRESHOLD  = 0.15;
const FATIGUE_URGENT_THRESHOLD = 0.25;
const FATIGUE_STOP_THRESHOLD  = 0.50;
const CUE_COOLDOWN_REPS       = 2;
const SHOULDER_DRIFT_DEG      = 7.0;
const TORSO_PITCH_DRIFT_DEG   = 10.0;
const BASELINE_ROLLING_WINDOW = 5;   // reps
```

**Why rolling-max baseline beats freeze-once-established:** on real data, peaks continue rising well past rep 5 during the recruitment phase. A rolling window keeps ratcheting through the rise, naturally plateaus when peaks do, and "forgets" the noisy early markers. Validated against Rajiv's session — the revised algorithm fires FADE around rep 18 (coach-intuitive moment), not rep 3 (which was the bug in v0).

**Why skip cues during calibration:** early reps have the worst button-timing and positional noise. False-early cues desensitize the user before real fatigue has a chance to emerge.

---

## BLE protocol

### FF02 NOTIFY (unchanged from Phase 1)

308 bytes @ 40 Hz. 3 channels × 50 samples × u16 LE (RAW, RECT, ENV) preceded by 8-byte header (seq_num, t_us_start, channel_count, samples_per_channel, flags).

### FF04 WRITE (NEW — phone → firmware)

Variable-length payload. `[opcode u8][payload...]`.

| Opcode | Name | Payload | Effect |
|---|---|---|---|
| `0x10` | `PULSE_BURST` | `[motor_idx u8][duty u8][n u8][on_ms u16 LE][off_ms u16 LE]` | Fire `n` pulses of `on_ms` at PWM duty `duty`, with `off_ms` gaps, on motor `motor_idx`. Overrides any currently-running burst on that motor. |
| `0x11` | `STOP_HAPTIC` | `[motor_idx u8]` | Stop motor `motor_idx` immediately. |
| `0x12` | `SET_SESSION_STATE` | `[state u8]` | `0=Idle 1=Calibrating 2=Active`. Firmware logs to Serial; placeholder for future LED indicator. App should call at every state transition. |

**Pre-defined cue payloads** (app-side should have constants for these):

| Cue | 8-byte payload (hex) | Decoded |
|---|---|---|
| FADE fatigue | `10 00 B4 02 C8 00 96 00` | motor=0, duty=180, n=2 pulses, 200 ms on, 150 ms off |
| URGENT fatigue | `10 00 E6 02 C8 00 96 00` | motor=0, duty=230, n=2 pulses, 200 ms on, 150 ms off |
| FORM alert (v1, parked) | `10 00 E6 03 64 00 50 00` | motor=0, duty=230, n=3 pulses, 100 ms on, 80 ms off (staccato) |

Motors 1–3 are reserved for future hardware expansion (upper trap, forearm, wrist). Writes to unwired motors are silently ignored by the firmware.

---

## App-side work (yours)

### Directory layout (suggestion — app claude's call on the final shape)

```
lib/features/bicep_curl/
  controllers/
    bicep_curl_controller.dart       # sealed-class state machine
  services/
    fatigue_algorithm.dart            # pure-function algorithm
    envelope_derivator.dart           # rectify + 4th-order IIR LP on RAW channel
    compensation_detector.dart        # pose Δ-from-reference logic
    cue_dispatcher.dart               # wraps HardwareController.sendCommand with semantic cue names
  models/
    rep_record.dart                   # {rep_num, t_start, t_peak, peak_env_value, pose_delta}
    cue_event.dart                    # {rep_num, type, timestamp}
    compensation_reference.dart       # {shoulder_y_ref, torso_pitch_ref}
  views/
    bicep_curl_view.dart              # UI
```

### HardwareController extensions

Already exposes `rawEmgStream` (`SampleBatch` objects from the 308-byte parser) from Phase 1. Add:

```dart
Future<void> sendCommand(List<int> bytes) async {
  // Write bytes to FF04 characteristic.
  // Pattern proven at lib/features/dev/views/ble_debug_view.dart:238
  // Use withoutResponse: !writeProp to be efficient.
}

Future<void> fireFatigueFade()   async => sendCommand([0x10, 0x00, 0xB4, 0x02, 0xC8, 0x00, 0x96, 0x00]);
Future<void> fireFatigueUrgent() async => sendCommand([0x10, 0x00, 0xE6, 0x02, 0xC8, 0x00, 0x96, 0x00]);
Future<void> fireFormAlert()     async => sendCommand([0x10, 0x00, 0xE6, 0x03, 0x64, 0x00, 0x50, 0x00]);
Future<void> stopHaptic([int motorIdx = 0])  async => sendCommand([0x11, motorIdx]);
Future<void> setSessionState(int state)       async => sendCommand([0x12, state]);
```

### BicepCurlController

Mirror `ScreeningController` at `/lib/features/screening/controllers/screening_controller.dart:14–68`:

```dart
sealed class BicepCurlState {}
class BicepCurlIdle extends BicepCurlState {}
class BicepCurlCalibrating extends BicepCurlState {
  final int repsCompleted;       // 0..4
  final List<double> peaks;      // peak envelope per completed rep
  final CompensationReference? ref;
}
class BicepCurlActive extends BicepCurlState {
  final int repsCompleted;
  final List<double> peaks;
  final CompensationReference ref;
  final int lastCueRep;          // -999 if none fired yet
  final List<CueEvent> cueHistory;
}
class BicepCurlComplete extends BicepCurlState {
  final List<double> peaks;
  final List<CueEvent> cueHistory;
  final Duration duration;
}
```

### Rep detection

Reuse the elbow-angle peak detector at `/lib/features/screening/controllers/screening_controller.dart:228–276`. Apply it to elbow angle = shoulder-elbow-wrist angle (use existing `pose_math.dart`).

### Envelope derivation

On every `SampleBatch` that arrives from `rawEmgStream`:
1. Extract RAW channel (bytes 8..107 from the packet, already parsed into a `List<int>` of 50 uint16 values).
2. Full-wave rectify: `abs(sample - running_mean)` — running mean ≈ 2048 (VCC/2 bias).
3. Lowpass: 4th-order IIR against the fixed 2 kHz sample rate. Coefficients are compile-time constants:
   ```
   b = [0.00013534, 0.00054136, 0.00081204, 0.00054136, 0.00013534]
   a = [1.0, -3.57795951, 4.82050302, -2.89387151, 0.65222746]
   ```
   **Filter characterization (audit 2026-04-18):** these coefficients do *not* correspond to `scipy.signal.butter(4, 5.0/(2000/2), 'low')` as originally described. The `a` coefficients fit a 4th-order Butterworth designed at ~50 Hz; the `b` coefficients fit ~75 Hz. `sum(b)/sum(a)` is 2.41, not unity, so this isn't a properly-normalized Butterworth. Effective -3 dB point relative to DC is ~70 Hz. For downstream consumers: use these coefficients verbatim to match the firmware-team reference pipeline; cue decisions operate on peak/baseline *ratios* so the non-unity DC gain cancels. If you ever replace them with a true 5 Hz design, re-run the Rajiv CSV replay and retune thresholds — envelope smoothness will change substantially.
   Use a direct-form-II transposed IIR implementation (not `filtfilt`, which is offline-only).
4. Within each rep window (from pose-derived rep boundaries), find `max(envelope)` = per-rep peak.

### Compensation detection

During reps 1–3 of Calibrating, record:
- `shoulder_y_ref` = mean of the (L or R, whichever matches the curling arm) shoulder landmark's y-coordinate across the rep-1..3 pose frames
- `torso_pitch_ref` = mean torso-pitch angle (line from mid-hip to mid-shoulder relative to vertical) across the same frames

Per rep in Active state, compute:
- `shoulder_delta_deg` = angular drift of shoulder from reference (convert y-coord drift to degrees using forearm length proxy, or just use raw y-delta and tune a y-based threshold)
- `torso_pitch_delta_deg` = current torso pitch − reference

If either exceeds its threshold (`SHOULDER_DRIFT_DEG=7`, `TORSO_PITCH_DRIFT_DEG=10`), compensation_active = true.

### View

- Live camera feed + BlazePose skeleton overlay (reuse the widget from the existing camera feature)
- Rep counter, prominent
- Calibration progress during Calibrating ("Calibrating: 3/5")
- Fatigue indicator (recent drop %, color-graded: green <10, yellow 10–25, red 25+)
- Cue fire indicator (brief flash or badge when a FF04 write goes out — useful during debug)
- "End Set" button

### Files to create / modify on your side

**Create:**
- `lib/features/bicep_curl/**` (per the tree above)

**Modify:**
- `lib/core/services/hardware_controller.dart` — add `sendCommand` + cue-specific wrappers
- `lib/core/router.dart` — add `/bicep-curl` route

**Don't touch:**
- Existing screening, camera, rep_capture, or settings features

---

## Compensation-cue semantics for v0 — silent suppression

When compensation is detected and drop exceeds fatigue threshold, **v0 does not fire any cue** (not the FADE, not a FORM cue). This keeps the semantic clean: every cue in v0 means "genuine fatigue, tighten up." A FORM cue will be added in v1 after the fitness expert weighs in on what "bad form" should mean and how we want to signal it.

You can still display a **visual** compensation indicator in the app (e.g., a "watch your shoulder" badge on the view) without firing the haptic — that's a UX-only decision.

---

## Extensibility hooks (architecture-ready, not-built-yet)

- **Multi-sensor:** BLE packet `channel_count` field scales; a 2nd MyoWare bumps it to 6 channels. Your parser should already handle variable `channel_count × samples_per_channel × 2` bytes past the header — don't hardcode 3.
- **Multi-motor:** `PULSE_BURST` takes `motor_idx 0..3`. Just add UI / logic to address motors 1–3 when hardware lands. Future cue semantics from fitness expert will drive which motors fire when.

## Three-channel cueing model (required for demo day)

Haptic is **one of three cue channels**, not the whole story. Every cue decision from the algorithm fans out across:

| Channel | Delivery | Timing capability |
|---|---|---|
| **Haptic** | BLE `PULSE_BURST` to ESP32 motor | pre-rep / post-rep (not mid-rep for vibration; mid-rep unlocked in v2 with pressure) |
| **Visual** | in-app UI — rep counter, fatigue bar, compensation badge, skeleton overlay highlights, live stabilizer meter (advanced) | any — pre-rep / mid-rep / post-rep / post-set |
| **Verbal** | on-device text-to-speech (e.g., `flutter_tts`) | any, but sparse by design |
| **Post-set debrief** | full dashboard screen after End Set — per-rep peak chart, annotated compensation events, cue timeline, form score | post-set only |

**User-level × channel matrix (active channels per profile):**

|  | Live haptic | Live visual | Live verbal | Post-set debrief |
|---|---|---|---|---|
| **Beginner** | minimal / off | minimal / off | minimal / off | **rich debrief** (primary experience) |
| **Intermediate** | fatigue cues (v0 baseline) | compensation badge + fatigue bar | light prompts | summary + fatigue curve |
| **Advanced** | fatigue + stabilizer warnings | live per-muscle activation meter | targeted stabilizer prompts | deep analytics + trends |

### What changes in the controller

The fatigue algorithm emits `CueDecision` objects. A `CueDispatcher` reads the active `CueProfile` and fans the decision out to whichever channels that profile has enabled:

```dart
class CueDecision {
  final CueContent content;   // fatigueFade / fatigueUrgent / compensationDetected / stabilizerWarning
  final int repNum;
  final Map<String, dynamic> meta;  // e.g., {"shoulder_drift_deg": 9.2}
}

class CueDispatcher {
  final CueProfile profile;
  Future<void> dispatch(CueDecision d) async {
    if (profile.haptic.enabled)  await _fireHapticFor(d);
    if (profile.visual.enabled)  _emitVisualFor(d);
    if (profile.verbal.enabled)  await _speakFor(d);
    _appendToSessionLog(d);   // always — feeds post-set debrief
  }
}
```

Key design rule: **every CueDecision always appends to the session log regardless of which channels fire in real time.** That way the post-set debrief always has the full story — including for a beginner profile where no live channel was used.

### Post-set debrief is a first-class feature, not an afterthought

For demo day the post-set debrief is **the anchor experience** — visually impressive, works without requiring the haptic to land convincingly on stage. The dashboard should render:

- Rep counter + duration
- Per-rep peak-envelope chart with baseline trajectory overlay
- Compensation events annotated with pose deltas ("rep 6: shoulder drifted 9.2°, torso pitch +11°")
- Cue timeline — which cues were fired (or would have been fired, for beginner profile), at which reps
- Form score (aggregate % of reps with no compensation events)
- Optional: fatigue curve, showing the drop trajectory across the set

The data already exists inside the controller's session log; the debrief is a rendering task.

### Demo day execution strategy

- **Lead with the beginner path** — silent set, dashboard opens at End Set, everything is in the debrief. Clean, visual, works reliably without relying on the haptic being audible/visible to the audience.
- **Flip to advanced** for 30 seconds to demonstrate reach — user-level selector swaps the profile; now live stabilizer meter + haptic + verbal prompt all fire on the same movement.
- Capability is demonstrated, and the simplest / most reliable path is the featured one.

## Forward-compatibility asks (v0 code-shape that makes v1+ cheap)

Two roadmap directions are already scoped and will extend Phase 2 without replacing it. Structuring v0 code to anticipate them costs nothing now and saves a refactor:

1. **User-level-dependent cueing (v1, Lawson principle):** per `practitioner-notes-lawson.md`, cue timing and density should scale with user skill. Beginners benefit from fewer, later cues (possibly post-set only); advanced users can absorb mid-rep cues. **Parameterize cue thresholds and payloads** rather than hardcoding them — a future `UserProfile` enum should be able to swap the algorithm's constants at runtime. Concretely:
   - `FatigueAlgorithm` takes a `CueProfile` object (thresholds, cooldown, timing mode) rather than using globals
   - `CueProfile.intermediate()` gives current v0 defaults; `.beginner()` and `.advanced()` land in v1

2. **Modality-agnostic cue interface (v2, TSA pressure):** graduated pressure via twisted string actuator is a roadmap item. It'll need new opcodes (`PRESSURE_RAMP` / `PRESSURE_HOLD` / `PRESSURE_RELEASE`) independent of the existing `PULSE_BURST`. To avoid refactoring the cue dispatch later, **prefer `fireCue(Cue cue)`** (where `Cue` encapsulates target actuator + payload) **over named wrappers like `fireVibrationFade()`**. The v0 cues are all vibration `PULSE_BURST`s, so v0 implementation is trivial; v2 adds pressure `Cue` subtypes without touching the fatigue algorithm.

These are code-shape nudges, not logic changes. v0 behavior is identical either way.

---

## Verification plan

1. **Raw command path test** (before building the controller): in `BleDebugView`, write the FADE payload `10 00 B4 02 C8 00 96 00` to FF04. Motor fires a 2-pulse 550 ms burst. Validates the command dispatch works before any app logic.
2. **Controller state-machine test:** unit-test the `fatigue_algorithm.dart` pure function with fabricated rep-peak sequences — verify calibration silence, rolling baseline ratchets, cooldown works, cue thresholds fire correctly.
3. **Replay test:** feed Rajiv's captured session file (from `captures/session_Rajiv47_20260417_211321.csv`) through the controller logic offline. Expected: no cues through rep 5; FADE around rep 18; URGENT around rep 22–24; STOP around rep 25–26.
4. **Live integration test:** connect to the firmware running `bicep_realtime.ino`, do a full set to RIR 2. Verify cues fire at the right moments and feel right physically.

---

## Open questions that need your input when you start implementing

1. **Where does this feature live in the nav?** — new `/bicep-curl` route, replace the `rep_capture` stub, or Dev tab entry? (Firmware doesn't care.)
2. **Visual feedback during silent-suppressed compensation?** — i.e., the haptic is silent but do you want a "fix your form" text/badge on-screen? (My two cents: yes, cheap UX win; user learns the compensation happened even without the vibration.)
3. **Post-session debrief screen?** — peak chart, rep count, cue history. Not negotiable: this is the demo-day anchor experience. Scope it generously.
4. **Connection-drop handling mid-set?** — pause / auto-reconnect / fail? Worth deciding before you wire the state machine.

---

## For handoff to the app-side developer

Onboarding prompt and v0 acceptance criteria live in a separate doc: **`app-dev-handoff.md`** (same folder). Send that alongside this handshake when kicking off the app-side work.

---

— firmware claude, handing off
