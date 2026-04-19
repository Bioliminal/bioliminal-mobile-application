# EMG Peak + Fatigue Threshold — The Two Foundations

Reference notes for the closed-loop haptic cueing algorithm on the Bioliminal garment (ESP32 + MyoWare EMG + ERM motor + phone CV).

Saved 2026-04-16. Keep this next to the handshake doc; it explains *why* the numbers are what they are.

---

## What is a "peak"?

EMG is a messy signal. The raw voltage from the electrodes flickers hundreds of times per second as individual motor units fire. To make it usable we do two things in the firmware:

1. **Rectify** — take the absolute value, so negative spikes become positive. Now the signal is always ≥ 0.
2. **Smooth** — apply a low-pass filter (≈5 Hz) over a rolling ≈100 ms window. This turns the jittery raw signal into a clean line called the **envelope**.

The envelope is "how hard is the muscle working right now." During one bicep curl rep, it looks roughly like this:

```
amplitude
   │        ╭─────╮        ← peak
   │       ╱       ╲
   │      ╱         ╲
   │     ╱           ╲_____     ← eccentric (lower drive)
   │____╱                   ╲__
   └─────────────────────────── time
   rest   lift    hold  lower  rest
```

The **peak** = the maximum value of that envelope during the rep. Typically it lands mid-concentric, when the forearm is horizontal (~90° elbow flexion) — that's the point of maximum mechanical disadvantage for the biceps, so the muscle has to fire hardest there.

**Peak in one sentence:** "How hard did the biceps work at its hardest moment during this rep."

### Peak across a whole set

We capture one peak per rep. Across a set, the pattern is:

- **Reps 1–3:** peaks *rise*. Muscle is warming up, progressively recruiting more motor units. Rep 3 usually beats rep 1.
- **Mid set:** peaks *plateau* near the within-set maximum. Muscle is at full recruitment; the only way to push harder is to compensate with synergists or cheat with momentum.
- **Late reps:** peaks *fall*. Muscle can no longer recruit the same output — firing rates drop, the ceiling lowers. This is fatigue.

The fatigue signal we care about is: **how far has today's peak fallen from the within-set maximum?**

### Why peak and not RMS or iEMG?

Alternatives:
- **RMS (root-mean-square)** — averages the envelope energy across the rep.
- **iEMG (integrated EMG)** — area under the envelope curve for the rep.

Both are valid. We use peak because:
- It's computationally trivial (just track the max during each rep)
- Peak amplitude tracks fatigue progression well in the mid-to-late set region (the zone we actually care about)
- It's less sensitive to rep-duration variation. A slow rep has more area under the curve; peak is less confounded.

Downside: peak is noisier rep-to-rep than RMS. We handle that with the 15% threshold (see below).

---

## Why 15% drop?

The fatigue cue fires when `1 − (peak_N / baseline) > 0.15`. Three reasons stacked for why 15% is the right number:

### 1. Noise floor

Single-channel surface EMG has natural rep-to-rep variation of **~8–12% coefficient of variation** even on a well-rested subject. Sources:
- Electrode skin contact shifts slightly between reps
- Skin sweat changes impedance over a set
- Tiny arm rotation changes the muscle's angle under the sensor
- The muscle's own motor-unit recruitment varies stochastically

A 5% drop could easily be noise. Even a 10% drop is only barely above the noise band. **15% is the first threshold where you can be confident the drop is real, not measurement artifact.**

### 2. It matches the coach-intuitive moment

Strength coaches describe the "you're starting to fade, tighten up" moment in two frameworks:

- **RPE / RIR scale** — Reps In Reserve 2–3 (lifter has 2–3 reps left before failure). This is the zone where a cue has real traction: the user can still respond, but fatigue is real. Cueing earlier is ignored; cueing later is too late.
- **Velocity-based training** — 20% velocity loss from rep 1 is the most-studied cutoff for ending a set while preserving strength and power gains (Pareja-Blanco et al., 2017 and follow-ups).

EMG peak drop and velocity loss aren't 1:1 — they're related but different physics. Velocity falls monotonically across a set; EMG peak rises-plateaus-falls. The rough translation: **a 15% EMG peak drop from within-set max correlates to the same RIR 2–3 moment that a 20% velocity loss does**. Coaches call this moment out; the algorithm does the same.

### 3. Early enough to actually help

- **10% drop:** too early and too noisy. False positives would fire cues on clean reps, desensitizing the user.
- **20% drop:** the muscle is deeper into fatigue. At 20–25% drop, users are often already compensating (shoulder swing, momentum) and a cue can't rescue the rep.
- **15% drop:** past noise, past the rising-amplitude phase, but still in the zone where the user has 1–2 more reps of runway to respond to the cue.

**Concrete example:**

| Rep | Peak envelope | Baseline | Drop % | Action |
|---|---|---|---|---|
| 1 | 820 | 820 | — | seed baseline |
| 2 | 900 | 900 | — | ratchet |
| 3 | 950 | 950 | — | ratchet |
| 4 | 940 | 950 | 1% | below threshold |
| 5 | 930 | 950 | 2% | below threshold |
| 6 | 880 | 950 | 7% | still noise |
| 7 | 810 | 950 | **15%** | **fire fatigue cue** |
| 8 | 790 | 950 | 17% | cooldown (2-rep) |
| 9 | 710 | 950 | **25%** | **fire urgent cue** |
| 10 | 620 | 950 | 35% | cooldown |

At rep 7, the baseline (950) stayed frozen because peak stopped rising. The 15% drop puts us at 807, and rep 7 came in at 810 — right at the edge. Cue fires. At rep 9, the drop has widened to 25% — the urgent threshold. The second, stronger cue fires.

### Companion thresholds

- **Lower bound (15%):** primary fatigue cue. Soft pulse at ~70% PWM intensity. "Start tightening up."
- **Upper bound (25%):** urgent cue. Stronger pulse at ~90% PWM intensity. "Last rep honest."
- **Override ceiling (50%):** stop cueing. User is past the point of useful intervention — no more cues will help, they'll just be noise. The set is effectively over and the app should consider auto-ending.

---

## Related decisions informed by the same logic

These aren't about the 15% number specifically but come from the same evidence base:

**Baseline = `max(peak_1..3)` with ratchet through the rising-amplitude phase.** Because EMG amplitude rises through early reps, seeding from rep 1 alone would make the drop signal go negative through mid-set and trigger nothing. Using the max of the first three reps, and continuing to ratchet up as long as peaks keep climbing, gives us the true within-set ceiling.

**Fatigue onset detection (adaptive).** Instead of hardcoding "start evaluating at rep 5," we watch for the moment the peak curve turns — two consecutive reps where `peak_N < peak_{N-1}`. That's when baseline freezes and drop evaluation begins. This adapts automatically: a heavy weight produces fatigue-onset at rep 3–4; a light weight at rep 10–11. The algorithm finds the RIR 2–3 moment at whatever rep it happens.

**Pulse timing: pre-rep, at the bottom of the curl.** Research on motor learning (Wulf constrained-action hypothesis; Vance 2004 and Iwata 2020 directly on biceps) shows that a tactile cue on the agonist muscle during the lift biases toward internal focus, which hurts strength output. Firing the cue in the 300–700 ms BDC pause means it doesn't compete with execution attention.

**Pulse shape: 2 pulses × 200 ms on / 150 ms off.** Continuous vibration habituates the Pacinian corpuscles within seconds. Pulsed patterns keep the cue salient across reps.

**2-rep cooldown between cues.** Firing a cue every rep would desensitize the user and create guidance dependency (Sigrist et al., 2013). A gap lets the receptors reset.

**Pose-compensation gate.** If the user cheats with shoulder swing (Δshoulder elevation > 5–7°) or torso pitch (> 8–10°), biceps EMG drops because load shifts to synergists — not because of genuine fatigue. Cueing on a cheated rep reinforces the bad movement. We suppress the cue when compensation is detected.

---

## Sources (key citations for the numbers)

- **EMG noise CV 8–12%:** Pincivero et al., 2000 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/10969195/)
- **EMG amplitude rises then plateaus through a set (biceps):** Wydra et al. UCF DPT Capstone — [STARS](https://stars.library.ucf.edu/dpt-capstone/29/)
- **EMG and velocity during set to failure (bench press):** Tsoukos et al., 2021 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/34329514/)
- **VL20 vs VL40 thresholds and outcomes:** Pareja-Blanco et al., 2017 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/27038416/)
- **VL to RIR translation:** Jukic et al., 2022, Sports Medicine — [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC9807551/)
- **RIR 2–3 discriminability zone:** Zourdos et al., 2016 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/26049792/); Helms & Cronin, 2016 — [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC4961270/)
- **Tactile-on-biceps induces internal focus:** Iwata et al., 2020 — [Springer](https://link.springer.com/chapter/10.1007/978-3-030-66169-4_36); Vance et al., 2004 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/15695233/)
- **Wulf constrained-action hypothesis meta-analysis:** Chua et al., 2021, Psych Bull — [PubMed](https://pubmed.ncbi.nlm.nih.gov/34843301/)
- **Compensation patterns in fatigued bicep curls (shoulder elevation, torso pitch):** Zhang et al., 2024 — [arXiv](https://arxiv.org/html/2402.11421v2)
- **Pacinian habituation to continuous vibration:** Hall, 2011 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/22254645/)
- **Pulse perception thresholds (≥30 ms = vibration, 150–250 ms comfortable):** Park et al., 2025, Sci Rep — [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC11814341/)
- **Haptic guidance requires fading to avoid dependency:** Sigrist et al., 2013 — [PubMed](https://pubmed.ncbi.nlm.nih.gov/23132605/)
