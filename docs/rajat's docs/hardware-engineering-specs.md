# Hardware Engineering Specifications

**Last updated:** 2026-04-07
**Source session:** Hardware spec session (Session 2)
**Sources:** Research agent outputs, hardware-cueing-research.md, hardware-handover.md, Deshpande et al. (2021)

---

## 1. Routed-String TSA Engineering Details

*[Research compiled 2026-04-07 from TSA tier research agent and routed-string TSA research agent]*

### Routing mechanism
- **PTFE-lined Bowden-style channels** sewn or bonded into compression fabric
- Small-diameter PTFE tubing: **1.5mm ID** (Amazon, ~$5/meter)
- String: Dyneema/Spectra braided, 0.3–0.5mm diameter

### Friction budget
- PTFE-on-Dyneema friction coefficient: **mu ~0.04–0.08**
- Force loss follows capstan equation: **T_out = T_in × e^(mu × theta)**
- **~10–30% force loss per 90-degree bend** depending on routing quality
- Straight runs add negligible loss
- **Maximum practical routing distance: 30–40cm** before friction eats >40% of input force
- **Wrist-to-upper-arm route (~25cm, one gentle curve): ~15–20% loss** — manageable with a mid-tier motor

### Contact pad design
- End effector: **10–20mm diameter rigid disc**, 3D-printed in TPU (Shore 85A)
- Face: **Shore 30A–50A silicone** or foam for skin comfort
- String terminates through disc center, pulling it into skin against compression fabric as reaction structure
- Optional: **25mm spreader plate** to distribute force over ~5cm² and avoid point loading

### Multi-string from one motor
- A single TSA motor twisting multiple strings **bundles and couples forces inherently** — all endpoints activate simultaneously at roughly equal force
- **Independent control requires one motor per string**
- Compromise: one motor per functional group (e.g., all forearm flexor pads activate together)
- Differential routing (different string lengths/friction paths) gives crude force ratios but is **not independently controllable**

### Key design implication
- Compression base layer is **essential** to provide rigid-enough anchor for contact pad reaction force
- **Pre-tensioning string ~0.5–1N** is needed to take up slack from fabric deformation
- Sewn PTFE guide channels outperform adhesive-bonded channels for durability

### DIY BOM for 3-channel routed system
Under **$30** total: N20 gear motors ($2–3 ea × 3), 1.5mm PTFE tubing ($5), Dyneema spool ($8), compression sleeve ($8–15)

---

## 2. Auto-Calibration via EMG-Threshold Staircase

*[Research compiled 2026-04-07 from EMG auto-calibration research agent]*

### Force sensing approach
- **Motor current sensing** is the cheapest viable force proxy
- Components: low-side shunt resistor (0.1Ω) + INA219 current monitor — **~$2 total**
- Accuracy: **±10–15%** during slow, quasi-static squeezes (friction and inertia degrade dynamic accuracy)
- Sufficient for finding perceptual thresholds — not measuring exact Newtons
- **Skip load cell (HX711) for production;** use it only for one-time bench characterization of current-to-force relationship
- Strain gauge on string is fragile and not recommended

### Staircase algorithm
1. Set baseline EMG RMS over 2-second quiet window
2. Apply squeeze at minimum intensity (lowest PWM)
3. Wait **200–500ms settling** (to reject motion artifact from actuator onset)
4. Measure EMG RMS over 500ms window
5. If EMG RMS changed **>10–15% above baseline** → threshold found
6. If not → increment squeeze intensity by one step, repeat
7. If threshold found → back off one step, increment again to confirm (staircase reversal)
8. Converges in **~10–20 steps** to a reliable perceptual/activation threshold

### Existing device calibration approaches (for reference)
- **mTrigger and Myontec** both use MVC normalization — user performs maximum voluntary contraction, thresholds set as percentage (typically 10–30% MVC for functional tasks) *[Accessed 2026-04-07]*
- Some devices use submaximal reference contractions for populations where true MVC is unreliable (post-stroke, post-surgical)
- Our EMG-threshold staircase automates a similar percentage-of-baseline method

### Published support
- Karavas et al. (2017) — adaptive impedance in exosuits using EMG *[Accessed 2026-04-07]*
- Panarese et al. (2009) — EMG-modulated haptic feedback *[Accessed 2026-04-07]*
- Tchimino et al. (2022) — adaptive vibrotactile stimulation intensity based on skin impedance *[Accessed 2026-04-07]*
- General finding: physiological-signal-adaptive systems improve usability and reduce habituation vs fixed-intensity cues

---

## 3. Safety Constraints (Specific Numbers)

*[Research compiled 2026-04-07 from wearable safety research agent]*

### Circumferential pressure limits
| Threshold | Pressure | Consequence |
|---|---|---|
| Safe continuous (therapeutic garments) | **15–30 mmHg** (Class I–II compression) | No circulatory compromise |
| Venous occlusion risk | **>40–60 mmHg** | Impedes venous return |
| Arterial occlusion risk | **>180–200 mmHg** | Blocks arterial flow (basis for BP cuff limits) |
| Intermittent squeeze (brief) | Can exceed 30 mmHg briefly | Must not sustain |

**Design rule:** TSA must be designed to **fail-open** under power loss. Continuous compression must stay under **30 mmHg**. *[Decision made 2026-04-07]*

### Electrical safety (skin-contact devices)
- IEC 60601-1 leakage current limits: **10μA DC** for patient-contact devices (normal conditions), **50μA** single-fault
- sEMG is **passive sensing** (microvolts) — near-zero risk. Concern is fault-mode leakage from electronics
- Perception threshold for skin-contact current: ~0.5–1mA AC (60Hz), ~2–5mA DC
- EMS/NMES: IEC 60601-2-10 governs. Currents >10mA near thorax risk cardiac interference. **Defer to v2+**

### Electrode skin reactions
- **Ag/AgCl disposable electrodes:** irritation in **10–20% of users** after 24+ hours continuous wear (gel + adhesive)
- **Dry stainless steel electrodes:** nickel content sensitizes **~10–15% of population**
- Medical-grade silicone or gold-plated contacts are safest for extended wear
- ISO 10993 (biocompatibility testing) applies to any material in prolonged skin contact (>24hrs)
- **For MVP:** disposable Ag/AgCl, replaced between sessions. No prolonged-contact concern

### FDA classification line
| Claim | Classification | Regulatory burden |
|---|---|---|
| "Helps you train harder" / "tracks muscle activity" | **General wellness — exempt** (2016 General Wellness Policy) | None |
| "Reduces injury risk" / "aids recovery from injury" | **Class II medical device** (510(k) required) | Substantial |
| "Diagnoses muscle dysfunction" | **SaMD (Software as Medical Device)** | Clinical validation required |

**Cautionary tale — mTrigger:** Same underlying technology as Athos (single-channel sEMG biofeedback), but registered as FDA Class II because it explicitly targets rehab. Different claims, same tech, completely different regulatory burden. *[mTrigger product page, accessed 2026-04-07]*

**Our framing:** "Training and educational tool, not diagnostic or therapeutic." Language must be disciplined across all materials. *[Decision made 2026-04-07]*

### Liability framing precedents
- **Whoop:** "Performance optimization," no medical claims, extensive ToS disclaimers
- **Athos:** "Muscle activity tracking, for informational purposes only"
- **Common strategy:** Launch as wellness, collect data, pursue medical clearance later as separate SKU

### Incident history
- No major FDA recalls specific to sEMG fitness wearables to date
- EMS/TENS recalls for excessive output (e.g., iReliev 2020)
- Fitbit Ionic recall (2022, 1.7M units) for battery overheating — relevant wearable burn precedent
- Compex EMS: isolated skin burn reports from dried-out gel pads / poor contact

---

## 4. Phone-as-Hub Architecture Constraint

*[Analysis performed 2026-04-07]*

### The question
Can a smartphone simultaneously run MediaPipe pose estimation AND maintain a BLE connection receiving 2-4 channel sEMG at 500Hz?

### Analysis
- **MediaPipe Pose:** ~30fps processing on modern phones, uses GPU/NPU. Occupies one processing pipeline
- **BLE 4.2 throughput:** 20–30 kB/s practical application throughput
- **sEMG data rate:** 4 channels × 500Hz × 2 bytes = **4 kB/s** — well within BLE margin (uses ~15-20% of available throughput)
- **Concurrency:** Both run on separate threads. iOS Core Bluetooth and Android BLE APIs support background data receipt while camera is active
- **BLE connection interval:** 15–30ms typical, introducing that much latency per packet — acceptable for haptic feedback loop

### Verdict
**Feasible on phones from ~2022+.** Older/budget phones may struggle with simultaneous GPU load (CV) + BLE stack reliability. Need to establish minimum-spec target devices during testing.

### Risk
- If CV processing causes frame drops, BLE connection intervals may be missed → data gaps in sEMG stream
- Mitigation: buffer sEMG data on MCU, transmit in batches. Accept slight latency increase (~50ms) for reliability

---

## 5. Deshpande Localization Finding

*[Deshpande et al. (2021), PMC8541989, accessed 2026-04-07]*

### Finding
On the torso, vibrotactile localization accuracy was **60.7%** vs force localization accuracy of **54.6%**. Vibration was slightly MORE accurate for spatial localization than sustained force.

### Design implication
- **Vibration is better for "where"** — spatial attention direction ("this muscle, not that one")
- **Pressure is better for "how long / how much"** — sustained engagement, graduated magnitude
- Supports the **hybrid approach:** use vibration to localize, use pressure to sustain. They are complementary, not competing

### Caveat
Study was on the torso, not limbs. Limb spatial resolution differs. But the receptor-type distinction (Pacinian for vibration localization vs Merkel/Ruffini for sustained pressure) generalizes across body regions.

---

## Sources

- Deshpande et al. (2021), "Vibrotactile vs force spatial discrimination," PMC8541989. *[Accessed 2026-04-07]*
- Johansson & Flanagan (2009), "Coding and use of tactile signals," *Nature Reviews Neuroscience* 10, 345-359. *[Accessed 2026-04-07]*
- IEC 60601-1 medical electrical equipment safety standard. *[Accessed 2026-04-07]*
- FDA General Wellness Policy (2016), FDA CDS Guidance (Jan 2026). *[Accessed 2026-04-07]*
- mTrigger product page, mtrigger.com. *[Accessed 2026-04-07]*
- Karavas et al. (2017), adaptive impedance in exosuits using EMG. *[Accessed 2026-04-07]*
- Tchimino et al. (2022), adaptive vibrotactile stimulation intensity. *[Accessed 2026-04-07]*
