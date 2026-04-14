# MVP Build Decisions & BOM

**Last updated:** 2026-04-07
**Source session:** Hardware spec session (Session 2)
**Sources:** Research agent outputs (triceps vs biceps, sleeve vs strap), hardware tier research, hardware-handover.md

---

## 1. MVP Exercise: Bicep Curl

*[Decision made 2026-04-07. Supersedes hardware-handover.md suggestion to "consider triceps."]*

### Decision
**Bicep curl with dumbbell** is the MVP demo exercise, not tricep pushdown.

### Reasoning

| Factor | Bicep Curl | Tricep Pushdown |
|---|---|---|
| **Equipment needed** | Dumbbell (anywhere, trade show floor) | Cable machine (gym only) |
| **Demo narrative** | "Stop curling with your forearms" — universally relatable | "Activate long head vs lateral head" — niche |
| **Electrode placement** | Anterior arm: obvious landmarks, convex surface holds electrodes, less variable subcutaneous fat | Posterior arm: more variable fat distribution, long head harder to isolate |
| **Signal distinction** | Biceps vs brachioradialis (between-muscle) — large, easy-to-detect signal difference | Long head vs lateral head (within-muscle) — tighter spacing needed, more sophisticated signal processing |
| **Spatial resolution** | Upper arm ~45mm 2-point discrimination → 2 zones sufficient for biceps vs brachioradialis | Same 2 zones, but distinguishing triceps heads requires better electrode precision |
| **Mind-muscle connection pain point** | Forearm/brachioradialis compensation is the first thing lifters notice | Triceps and back are "harder to feel" — stronger need but harder to demo |

### Physiology note
Wakahara et al. (2013) showed regional activation in triceps predicted regional hypertrophy — lateral head grew more after pushdowns, long head more after overhead extensions. This makes triceps the stronger *scientific* case for per-head cueing. However, for an MVP, we need to prove the concept works at all, not prove per-head granularity. The biceps vs brachioradialis distinction is a larger, more detectable signal difference and a more compelling demo story. *[Wakahara et al. 2013, PubMed 23657165, accessed 2026-04-07]*

### What this means for hardware
- 2 sEMG channels: one on biceps belly, one on brachioradialis (forearm)
- Reference electrode on olecranon (elbow bony prominence)
- TSA band on upper arm (biceps region)
- Vibrotactile on distal forearm (>3cm from electrodes)
- Demo flow: user curls, system detects brachioradialis dominant activation, vibrates "wrong muscle" alert + squeezes biceps region as "focus here" cue

### Save for v2
Triceps per-head cueing with routed contact pads — becomes a differentiating feature once the closed-loop concept is proven.

---

## 2. Form Factor: Compression Sleeve + Velcro Pods

*[Decision made 2026-04-07. Based on sleeve vs strap research agent findings.]*

### Decision
**Compression sleeve with velcro-mounted modular pods** — the standard approach in wearable haptics research labs (MIT Media Lab, KAIST). *[Accessed 2026-04-07]*

### Why not pure bands?
- Modular velcro/neoprene bands **shift on sweaty skin** during dynamic movement (compound lifts, curls)
- Each band is independent → poor inter-band coordination, exposed cables snag
- Donning 3-4 bands is tedious and looks clunky

### Why not pure sleeve?
- Size-specific (arm circumference varies wildly across users)
- Electrode positions are fixed → misalignment with target muscles is hard to correct
- Harder to iterate (sewing changes vs snapping on a new pod)

### Hybrid approach
1. Buy a **$5–15 athletic compression arm sleeve** (Amazon, any sport brand)
2. Sew in **electrode snap pockets** at approximate muscle belly locations using conductive snap buttons
3. Sew **PTFE routing channels** (1.5mm ID tubing) along sleeve exterior for TSA strings
4. Attach **3D-printed pods** (containing motor, driver, vibration motor) via **velcro patches** sewn onto the sleeve
5. Pod positions are adjustable per user anatomy
6. Compression provides excellent electrode-skin contact
7. Sleeve acts as reaction structure for TSA contact pad pull force

### Build method
- **Base garment:** Compression arm sleeve, polyester/spandex blend, $8–15
- **Electrode pockets:** Cut small slits, sew conductive snap buttons (3.5mm press studs, ~$0.10 ea), line pocket with non-conductive fabric to isolate from sleeve
- **PTFE channels:** Stitch 1.5mm ID PTFE tubing along seam lines between snap button locations and motor hub location (near elbow)
- **Pod housing:** 3D-print in PLA/PETG, 30×30×20mm per pod, with velcro loop base and snap-fit lid
- **Electrode-to-MCU wiring:** Thin shielded wire (30 AWG) routed through sleeve fabric between pockets and MCU hub
- **Estimated modification time:** 3–5 hours with a sewing machine

### Cost
- Compression sleeve: $8–15
- Snap buttons + conductive fabric: $3
- PTFE tubing: $5
- Velcro patches: $2
- 3D-printed pods (3): $5 (filament cost)
- **Total form factor cost: ~$25–30** (excluding electronics)

---

## 3. Budget BOM Tiers (Specific Part Numbers)

*[BOM compiled 2026-04-07. Prices verified against SparkFun, Mouser, AliExpress, Pololu, Crowd Supply as of session date.]*

### Tier 1: Bare-Minimum Full System — ~$25

*"Does this concept work at all?" Build in an afternoon.*

| Component | Part | Price | Source |
|---|---|---|---|
| sEMG (2ch) | DIY: 2× INA128 instrumentation amp IC | $8 | Mouser |
| TSA | SG90 micro servo + 30lb monofilament | $5 | AliExpress |
| Vibrotactile (2) | 2× generic 8mm flat coin ERM | $1 | AliExpress |
| MCU | Arduino Nano clone | $3 | AliExpress |
| Power | 9V battery + clip | $2 | Any |
| Mechanical | Elastic band + tape + breadboard | $3 | Any |
| Electrodes | Disposable Ag/AgCl snap pads (10-pack) | $3 | Amazon |
| **Total** | | **~$25** | |

**Limitations:** Noisy sEMG (DIY amp), weak squeeze (servo, 1-3N), on/off-only vibration, wired, no BLE. Good for: bench testing the closed-loop concept.

### Tier 2: Recommended MVP — ~$85

*Reliable enough for demo day. BLE to phone. Repeatable.*

| Component | Part | Price | Source |
|---|---|---|---|
| sEMG (2ch) | 2× BioAmp EXG Pill (Upside Down Labs) | $20 | Crowd Supply / Mouser |
| TSA | GA12-N20 gearmotor + Dyneema 0.5mm + A3144 hall sensor + magnet | $25 | AliExpress + Amazon |
| Motor driver | DRV8833 dual H-bridge breakout | $2 | AliExpress |
| Vibrotactile (3) | 3× Precision Microdrives 310-103 (10mm coin ERM) | $8 | Precision Microdrives |
| MCU | ESP32-S3 DevKit | $10 | AliExpress / Mouser |
| Power | 800mAh LiPo + TP4056 charger module | $8 | AliExpress |
| Form factor | Compression sleeve + velcro pods (see Section 2) | $28 | Mixed |
| Electrodes | Disposable Ag/AgCl snap pads (50-pack) | $5 | Amazon |
| Misc | PTFE tubing, Dyneema spool, wiring, connectors | $5 | Amazon |
| **Total** | | **~$85** | |

**Capabilities:** 2-channel sEMG with ~5μV noise floor, 5-15N controllable squeeze with position feedback (hall sensor), discrete vibrotactile alerts, BLE streaming to phone, 3+ hour battery life.

### Tier 3: Upgraded System — ~$150

*Adds frequency-domain EMG (fatigue/RIR tracking) and crisp haptics.*

| Component | Part | Price | Source |
|---|---|---|---|
| sEMG (2ch) | Protocentral ADS1292R breakout (PC-4126) | $45 | Mouser / Protocentral |
| TSA | Pololu 25D 47:1 gearmotor (#4861) + encoder (#4761) + Dyneema SK78 | $50 | Pololu |
| Motor driver | TB9051FTG with current sensing | $8 | Pololu |
| Vibrotactile (3) | 3× Jinlong Z-LRA-0825 (8mm LRA) + DRV2605L driver | $35 | Mouser / DigiKey |
| MCU | Adafruit Feather nRF52840 (built-in LiPo charger) | $25 | Adafruit |
| Power | 1000mAh LiPo | $10 | Adafruit |
| Form factor | Compression sleeve + velcro pods | $28 | Mixed |
| Electrodes | Ag/AgCl 50-pack | $5 | Amazon |
| **Total** | | **~$150** | |

**Key upgrades over Tier 2:**
- **ADS1292R:** 24-bit ADC, 125-8000 SPS per channel, >100dB CMRR. Enables median frequency shift tracking for fatigue detection → unlocks the RIR-confidence feature
- **Jinlong Z-LRA-0825 + DRV2605L:** 5-15ms response (vs 50-100ms ERM), 123 preset haptic waveforms, independently controllable frequency/amplitude. Users can distinguish haptic "words"
- **Pololu 25D + encoder:** 2256 CPR, 10-50N controllable force, PID-ready. Professional-feeling squeeze
- **nRF52840:** Best-in-class BLE stack, lowest power (5-6mA active CPU), built-in LiPo management

### Upgrade path decision tree

```
Start with Tier 2 ($85)
         │
         ├── sEMG signal too noisy / want fatigue tracking?
         │   └── Upgrade to ADS1292R (+$25 net)
         │
         ├── Vibration cues too imprecise / can't localize?
         │   └── Upgrade to LRA + DRV2605L (+$27 net)
         │
         ├── TSA squeeze too weak / inconsistent?
         │   └── Upgrade to Pololu 25D + encoder (+$25 net)
         │
         └── All working well at Tier 2?
             └── Don't upgrade. Ship the demo.
```

---

## Sources

- Wakahara et al. (2013), "Regional triceps activation predicts regional hypertrophy," PubMed 23657165. *[Accessed 2026-04-07]*
- Bodine et al. (1988), "Motor unit territory clustering," PubMed 1702521. *[Accessed 2026-04-07]*
- Biceps head activation, PubMed 20719658. *[Accessed 2026-04-07]*
- Upside Down Labs BioAmp EXG Pill, Crowd Supply. *[Accessed 2026-04-07]*
- Protocentral ADS1292R (PC-4126), Protocentral. *[Accessed 2026-04-07]*
- SparkFun MyoWare 2.0 (SEN-21265). *[Accessed 2026-04-07]*
- Pololu 25D gearmotor #4861, encoder #4761. *[Accessed 2026-04-07]*
