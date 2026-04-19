# Rep Data Capture Pipeline — Firmware ↔ App Handshake

**Title purpose:** Capture real per-rep EMG data from live bicep curls so we can validate and tune the fatigue-detection algorithm against ground truth *before* committing firmware and app to production cueing logic. Two phases: **Phase 1 = raw EMG capture + EMG-only rep segmentation**; **Phase 2 = CV sync** (cross-validate pose-derived rep boundaries against EMG-derived ones).

**Author:** firmware claude (works in `/Users/rajatarora/Gauntlet/CapStone/esp32-firmware/`)
**Audience:** app claude (works in `/Users/rajatarora/Gauntlet/CapStone/bioliminal-mobile-application/`)
**Date:** 2026-04-16
**Status:** approved by user — ready to execute on both sides
**Related docs:**
- `~/Gauntlet/CapStone/notes/project-status-2026-04-16.md` — overall project state
- `~/Gauntlet/CapStone/notes/emg-fatigue-explainer.md` — peak + 15% explainer

---

## Context (why data capture before cueing)

We drafted a research-grounded algorithm: per-rep peak EMG tracking, adaptive baseline, 15% drop threshold, pose-gated pulse bursts at BDC. Every parameter has a citation behind it — but **no parameter has been validated against this particular user's own EMG signal on this particular MyoWare placement on this particular biceps.** Literature values are starting points; real-world noise and envelope shape could differ materially.

Before shipping cueing logic we want to:
1. Confirm the envelope shape assumption (clean rise → peak → fall per rep) holds in practice
2. Measure actual rep-to-rep noise CV (literature says 8–12%; is ours tighter or looser?)
3. See when amplitude plateaus across a real set (literature says "after ~rep 3"; where does it land for us?)
4. Sanity-check that 15% drop maps to the coach-intuitive "fade" moment for *this* sensor setup

Capture 5–10 sets of 10+ reps spanning fresh/fatigued/near-failure, inspect the data, then harden the algorithm. **We cannot skip this step.**

**Raw-data integrity is the Phase 1 primary goal.** Every downstream computation (envelope, rep segmentation, peak detection, fatigue threshold, MDF shift analysis) can be redone in software if the raw samples are preserved. If we lose raw samples, we cannot revisit any of those decisions later.

---

## What the MyoWare 2.0 actually outputs (citation-backed)

Source: [MyoWare 2.0 Advanced Guide (Advancer Technologies, 2022)](https://cdn.sparkfun.com/assets/learn_tutorials/1/9/5/6/MyoWare_v2_AdvancedGuide-Updated.pdf).

The base MyoWare 2.0 sensor exposes **three analog output pins on the same board** — no shield required:

| Pin | Signal | Gain | Filter stages |
|---|---|---|---|
| **RAW** | amplified bipolar EMG, centered at VCC/2 | G = 200 (fixed) | Active HP 1st order fc = 20.8 Hz, active LP 1st order fc = 498.4 Hz |
| **RECT** | full-wave rectified version of RAW | G = 200 (fixed) | Same bandpass + full-wave rectifier |
| **ENV** | smoothed rectified envelope | G = 200 × R/140 kΩ (pot-adjustable) | Bandpass + rectifier + linear passive LP fc = 3.6 Hz |

From the Technical Specifications panel:
- Supply: 2.27 V min, 3.3 V / 5 V typ, 5.47 V max
- Input impedance: 800 GΩ
- CMRR: 140 dB
- Rectification: full-wave
- Sample rate: *"Not applicable — MyoWare Sensor is analog. See measuring device specifications."*

From the Power Spectrum panel (verbatim):
> "Surface EMG signals typically have an amplitude of 0 – 10 mV (peak to peak) and a frequency band of 10 – 500 Hz. MyoWare has a first order passband of 20 – 500 Hz which is ideal for capturing the bulk of the power spectrum while removing unwanted signal sources such as motion artifacts."

**Practical implications for us:**
- At-muscle amplitude 0–10 mV p-p × gain 200 = **0–2 V p-p at the RAW pin**
- Centered at VCC/2 (≈1.65 V on 3.3 V rail); RAW ADC readings span roughly 0.65–2.65 V during strong contraction
- Passband 20–500 Hz → Nyquist = **1 kHz minimum**; we use **2 kHz** for headroom and clean FFT/MDF analysis
- On 12-bit ESP32 ADC over 0–3.3 V: 1 LSB ≈ 0.8 mV. The full 2 V swing uses ~2500 codes.

---

## Wiring (done 2026-04-16)

All three MyoWare 2.0 outputs are now wired to ESP32 ADC1 pins:

| MyoWare pin | ESP32 pin | ADC channel | Signal |
|---|---|---|---|
| **ENV** | GPIO34 | ADC1_CH6 | hardware envelope (rectified + 3.6 Hz LP) |
| **RAW** | GPIO35 | ADC1_CH7 | amplified bipolar EMG, 20–500 Hz, centered at VCC/2 |
| **RECT** | GPIO32 | ADC1_CH4 | full-wave rectified (no envelope smoothing) |

The firmware README (`esp32-firmware/README.md`) is currently out of date — still says only ENV + VIN + GND are soldered. Update when the new sketch lands.

Why three channels instead of one: **RAW alone is sufficient** (RECT and ENV are derivable in software). But capturing RECT and ENV from the hardware gives us a validation reference — if our software pipeline's derived ENV drifts from the hardware ENV channel, that's a software pipeline bug worth catching before we commit algorithm parameters.

---

## BLE protocol

### Existing characteristic, repurposed payload

| Char | Props | Payload | Direction |
|---|---|---|---|
| `0xFF02` | `READ`, `NOTIFY` | 308 bytes per notify at 40 Hz | ESP32 → phone |

### 308-byte packet format

```
byte 0:        seq_num (u8, wraps — lets phone detect dropped packets)
bytes 1–4:     t_us_start (u32 LE, microseconds since boot, marks first sample in batch)
byte 5:        channel_count (u8, value = 3 for RAW + RECT + ENV)
byte 6:        samples_per_channel (u8, value = 50)
byte 7:        flags (bit 0 = clip occurred on RAW; bit 1 = clip on RECT; bit 2 = clip on ENV)
bytes 8–107:   RAW samples  (50 × u16 LE, range 0–4095)
bytes 108–207: RECT samples (50 × u16 LE, range 0–4095)
bytes 208–307: ENV samples  (50 × u16 LE, range 0–4095)
```

**Invariants:**
- seq_num increments by 1 per notify, wraps at 256 → 0. Phone must detect gaps.
- t_us_start is monotonic (except on the once-every-71-min u32 overflow, which phone should handle by tracking unwrapped timestamps)
- All ADC values are **verbatim** — no firmware-side scaling, smoothing, rectifying, downsampling, or quantization beyond the raw 12-bit ADC reading
- ENV channel shows the MyoWare's own analog-hardware envelope for validation; it is NOT a firmware-computed envelope

---

## Firmware work

**Sketch:** `esp32-firmware/bicep_raw_stream/bicep_raw_stream.ino`. Replaces `esp32_ble_test.ino` for Phase 1 data capture. Existing sketches (`emg_read`, `emg_fatigue`, `motor_test`, `esp32_ble_test`) kept as references.

### Modules

1. **Hardware-timer-driven ADC:** `esp_timer` or `hw_timer_t` fires every 500 µs (2 kHz). ISR reads GPIO35 (RAW), GPIO32 (RECT), GPIO34 (ENV) in sequence. ESP32 ADC1 single-read latency ≈ 11 µs per channel; three reads fit in the 500 µs window. Samples go into a lock-free ring buffer. Jitter target < 20 µs for clean FFT/MDF downstream.
2. **Packet assembly:** main loop pulls 50 sample-triplets from ring buffer every 25 ms. Fills the 308-byte packet.
3. **BLE notify:** write packet to `FF02`, trigger notify. Cadence = 40 Hz.
4. **Sequence number** wraps. Phone detects BLE drops via gap.
5. **Clip detector:** if any sample hits 0 or 4095 during the batch, set the corresponding bit in byte 7 so the phone can flag the window.
6. **Zero onboard signal processing.** Full stop.

### Estimated effort
~200 LOC Arduino sketch. One day including bench verification with scope.

### What I'm NOT doing

- Not touching the mobile app repo
- Not computing envelope, rep detection, fatigue, or haptic output in firmware
- Not adding the `FF04` command characteristic in Phase 1 (that arrives with the cueing implementation later, post data-validation)

---

## App work (what app claude builds)

### New feature module: `lib/features/data_capture/`

```
lib/features/data_capture/
  controllers/
    data_capture_controller.dart        # sealed-class state machine
  services/
    raw_packet_parser.dart               # decode 308-byte BLE packet → SampleBatch
    envelope_derivator.dart              # software rectify + LP on RAW channel
    rep_segmenter.dart                   # pure state machine on derived envelope
    data_capture_storage.dart            # local binary blob + Firebase Storage
  models/
    sample_batch.dart                    # {seq_num, t_us_start, raw[], rect[], env[]}
    capture_session.dart                 # full session record
    rep_record.dart                      # per-rep summary
  views/
    data_capture_view.dart               # Start/Stop, live chart, health indicators
```

### Controller — sealed state machine

Mirror the `ScreeningController` pattern at `/lib/features/screening/controllers/screening_controller.dart:14–68`:

```dart
sealed class DataCaptureState {}
class CaptureIdle extends DataCaptureState {}
class CaptureRecording extends DataCaptureState {
  final String sessionId;
  final DateTime startTime;
  final List<SampleBatch> batches;   // or an on-disk append buffer
  final List<RepRecord> reps;
  final int droppedPacketCount;
  final int clipCount;
  final RepSegmenterState segmenterState;
}
class CaptureSaving extends DataCaptureState { ... }
class CaptureComplete extends DataCaptureState { ... }
```

### Envelope derivation (software)

Runs on the phone against the RAW channel:
1. DC-remove: subtract running mean (or just subtract 2048 — the theoretical VCC/2 midpoint)
2. Full-wave rectify: `abs(sample - mean)`
3. Lowpass: 4th-order IIR, effective -3 dB cutoff ~70 Hz from DC (the coefficients shipped with this handshake were mis-labeled as 5 Hz Butterworth; see haptic-cueing-handshake §Envelope derivation for the audit). Well above hardware's ~3.6 Hz analog cutoff, so the software envelope is noisier than the hardware ENV channel — correlation is still 0.885.

Store the derived envelope values alongside captured raw samples. At analysis time we can re-derive with different filters without re-capturing.

### Rep segmenter (state machine over derived envelope)

```
IDLE:
  derived_env < REP_ON_THRESH
  → when derived_env > REP_ON_THRESH for ≥150 ms:
      transition to ACTIVE, record t_start_us, reset peak tracker

ACTIVE:
  track peak_value and t_peak_us (updated when current > peak)
  → when derived_env < REP_OFF_THRESH for ≥500 ms:
      transition to REP_COMPLETE, record t_end_us

REP_COMPLETE:
  emit rep record, return to IDLE
```

**Tunable thresholds (starting values, revised later from captured data):**
- `REP_ON_THRESH` = 30 % of rolling 60 s max of derived envelope
- `REP_OFF_THRESH` = 20 % of rolling 60 s max
- `MIN_REP_DURATION_MS` = 800 (reject noise bursts)
- `MAX_REP_DURATION_MS` = 6000 (reject held isometrics)

These are *capture-module* thresholds, not the fatigue-cueing thresholds. Fatigue cueing parameters come from the analysis pass.

### UI (minimum viable)

- Start / Stop button (big)
- Live chart of last 10 s showing RAW (thin line) and derived envelope (thick overlay)
- Current rep count + current rep peak
- Health indicators: dropped-packet count, clip count, hardware-ENV vs software-derived-ENV cross-correlation (target > 0.95)
- Pre-set fields: weight (lb), arm (L/R)
- Post-set RPE slider (1–10)
- Post-session: auto-save local, "Sync to cloud" button

Good-to-have:
- Rep markers overlaid on the chart at detected start / peak / end
- Rep list with peak values for visual sanity

### Storage strategy

**Primary: local packed-binary blob + JSON metadata.**
- Path: `<app_documents_dir>/data_capture/bicep_curl/<session_id>.bin` (samples) + `.json` (metadata + reps)
- Binary format: little-endian interleaved uint16 triples: `[raw_0, rect_0, env_0, raw_1, rect_1, env_1, ...]`. Sample rate is fixed at 2 kHz so no per-sample timestamp needed in the blob — derive `t_us = sample_index * 500` plus a session-start offset.
- 30 s × 2 kHz × 3 ch × 2 B = **360 KB per session binary** (vs ~1.4 MB JSON). 10 sessions ~3.6 MB.

**Secondary: Firebase Storage upload.** Firestore docs cap at 1 MB; use Firebase Storage for the binary blob and a small Firestore doc for metadata with a pointer:
- Firestore: `/users/<uid>/data_captures/<session_id>` — metadata + rep summaries + storage path
- Firebase Storage: `/data_captures/<uid>/<session_id>.bin` — the raw sample blob

### Reused existing building blocks

| What | Where | Why |
|---|---|---|
| BLE notify subscription scaffolding | `/lib/core/services/hardware_controller.dart:125–133` | Pattern to lift and re-wire for the 308-byte raw packet format |
| Riverpod `Notifier` + sealed state machine | `/lib/features/screening/controllers/screening_controller.dart:14–68` | Template for DataCaptureController |
| Firestore client | `cloud_firestore: ^6.2.0` in `pubspec.yaml` | Metadata |
| Firebase Storage | will need to add `firebase_storage: ^13.2.0` if not present | Binary blob |
| BLE connection lifecycle | `hardwareControllerProvider` | Scans/connects already handled |
| Permission handling | existing BLE flows | No new permissions for EMG-only Phase 1 |

### Not used in Phase 1

- ML Kit pose detection — **explicitly off.** No camera, no skeleton overlay. Phase 2 only.
- Existing `rep_capture` stub — different feature; leave alone or replace, app claude's call.
- `FF04` command characteristic — not yet exposed by firmware; haptic output not wired in Phase 1.

### Critical files app claude will touch

**Create:**
- `lib/features/data_capture/**` (per tree above)

**Modify:**
- `lib/core/services/hardware_controller.dart` — replace the 10-byte envelope parse with a 308-byte raw-packet parser. Expose `rawEmgStream` emitting `SampleBatch` objects.
- `lib/core/router.dart` — add `/data-capture` route
- Dev/home screen — add a "Capture Data" entry point

**No changes to:** camera, screening, or rep_capture features.

---

## Phase 2 — CV sync (future, after 5+ sessions captured)

Once we have enough raw EMG data to validate the segmenter and algorithm thresholds, layer BlazePose on top:

**What CV adds:**
1. Ground-truth rep boundaries from elbow-angle peak/trough detection
2. Distinguishes concentric vs eccentric unambiguously (elbow angle direction)
3. Measures concentric/eccentric durations directly
4. Enables pose-compensation gate (shoulder drift, torso pitch) in production cueing

**Sync mechanism:**
- Capture both EMG samples and BlazePose landmark frames, both timestamped against the same monotonic `t_us`
- Per rep, compare EMG-derived `t_start/t_peak/t_end` against pose-derived
- Compute fixed phase offsets: does EMG envelope peak lead or lag elbow-angle peak? By how much?
- Bake the offset into production cueing so "fire haptic at BDC" uses true BDC, not EMG-inferred approximation

**Schema extension:** session document gains `pose_frames[]`, per rep gains `pose_t_start_us / pose_t_peak_us / pose_t_end_us`.

**Why not sync in Phase 1:** want to establish what EMG-only gives us first. If EMG-only rep segmentation holds up across the 5–10 sets, CV becomes a pure validator/compensation detector. If EMG-only is noisy, CV becomes necessary for segmentation too. Data decides.

---

## Data → algorithm tuning loop

Once we have 5+ sessions captured:

1. Export binary blobs + JSON to desktop (AirDrop / `scp` / Firebase download)
2. Python/Dart notebook: load sessions, plot traces, mark detected reps
3. Concrete questions to answer:
   - Does peak really land mid-concentric (visually against the envelope shape)?
   - Rep-to-rep CV of peak values on a non-fatigued set? (target < 12%)
   - At what rep does peak stop rising within a fatiguing set?
   - Where does peak drop 15% from within-set max?
   - Does a 15% drop subjectively align with user-reported "I started to struggle"? (cross-reference post-set RPE)
   - Does software-derived ENV match hardware ENV? (correlation, phase offset)
4. Adjust algorithm constants
5. Only then implement production `bicep_curl.ino` + `BicepCurlController` with tuned values

---

## Open questions (things app claude + user should weigh in on)

1. **Where does the capture module live in the UI?** — new `/data-capture` route, Dev tab under Settings, or replace the `rep_capture` stub?
2. **Firebase auth for uploads** — reuse app's existing auth session, or dedicated data-capture flow?
3. **Session metadata annotation** — weight, arm, post-set RPE. All optional, all valuable. Suggest yes to all.
4. **Packet drop handling** — if `seq_num` gaps are detected mid-session, do we abort, insert a `Missing` marker and continue, or retry? Suggest: continue with marker, flag session in metadata, so we don't throw away otherwise-good data.
5. **How many sessions before we tune?** — 5 sessions across 3 weights (light/moderate/heavy) with at least one going to subjective failure. User decides when enough.

---

## Verification

### Hardware / firmware bench checks (before app integration)

1. Solder continuity confirmed (done 2026-04-16): RAW → GPIO35, RECT → GPIO32, ENV → GPIO34.
2. Flash `bicep_raw_stream.ino`. Serial shows `RAW+RECT+ENV stream @ 2 kHz, 40 Hz notify, 308 B/pkt`.
3. Scope on a trigger GPIO toggled per ADC-triplet read: verify 500 µs ± 20 µs spacing.
4. In `BleDebugView`, confirm `FF02` notify packets are 308 bytes, arriving at ~40 Hz.
5. Raw-value sanity with live muscle:
   - **RAW:** at rest ≈ 2048; hard contraction excursions ~800–3300
   - **RECT:** at rest ≈ 0–200; contraction peaks 1500–3500
   - **ENV:** at rest ≈ 0–200; contraction rises smoothly to 2000–3500 (adjust gain pot)
6. Clip detector: force hard contraction; verify clip bit set in header byte 7 when any channel saturates.

### App-side capture checks

7. User hits Start, does 10 reps, hits Stop.
8. Local binary blob exists at expected path; size ≈ 2 kHz × 3 ch × 2 B × duration.
9. `seq_num` column gap-free — zero dropped packets in a 30 s recording under normal proximity.
10. Software-derived envelope matches hardware ENV channel (cross-correlation > 0.95) — validates the software pipeline against the known-good hardware reference.
11. Rep segmenter identifies 10 reps when user does 10 reps — no doubles, no misses.
12. Firebase sync (if invoked) succeeds; retrieved blob byte-identical to local file.

### Pass criteria

- Raw data integrity: every ADC sample preserved byte-identical from ADC → BLE → local storage → Firebase
- Zero `seq_num` gaps across a 30 s capture
- Software ENV reproduces hardware ENV within tight bounds
- Round-trips lossless
- At least 5 complete sessions captured across fresh / fatigued / near-failure before moving to algorithm tuning

---

## Next actions

1. **User** ✅ — soldering done.
2. **Firmware claude** — build `bicep_raw_stream.ino` with hardware-timer 3-channel ADC capture, 308-byte packets at 40 Hz, zero onboard processing. Bench-verify timing with scope. Update `esp32-firmware/README.md` wiring table.
3. **App claude** — build `data_capture` feature: 308-byte raw-packet parser in `HardwareController`, `rawEmgStream` of `SampleBatch`, `RepSegmenter` on software-derived envelope from RAW, local binary storage, optional Firebase Storage upload. Surface live hardware-ENV vs software-ENV cross-correlation in the UI as a health indicator.
4. **User** — capture 5+ sessions across fresh/fatigued/near-failure conditions with session metadata (weight, arm, post-set RPE).
5. **Group analysis** — export to notebook; validate or revise the 15% / 25% thresholds, baseline ratchet window, rep-segmentation ON/OFF thresholds.
6. Only after data validates the algorithm do we move to the production `bicep_curl.ino` + `BicepCurlController` cueing pipeline.

— firmware claude out
