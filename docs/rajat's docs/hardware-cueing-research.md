# Hardware & Cueing Modality Research Notes

## Context
These notes capture research findings and Rajiv's thinking from a BrainLift deep-dive session (April 2026) focused on cueing actuation mechanisms for the closed-loop neuromuscular coaching product.

**All sources in this document were accessed 2026-04-07 unless otherwise noted.**

---

## Core Thesis: Graduated Pressure > Vibrotactile Buzzing

Rajiv's position: graduated pressure actuation is post-MVP but the strength of the product value-add hinges on it. Vibrotactile is the MVP proof-of-concept, but the real product needs to feel like guidance, not notification.

### Somatosensory Basis
- **Vibrotactile** (ERM/LRA) → activates **Pacinian corpuscles** (FA-II mechanoreceptors) → fast-adapting → habituates within 5-15 seconds of sustained stimulation → says "something is happening here"
- **Sustained pressure** → activates **Merkel cells** (SA-I) and **Ruffini endings** (SA-II) → slow-adapting → maintains signal for duration of stimulus → says "move this direction with this force"
- Key source: [Johansson & Flanagan (2009) "Coding and use of tactile signals from the fingertips in object manipulation tasks"](https://www.nature.com/articles/nrn2621) — *Nature Reviews Neuroscience* 10, 345-359
- Implication: a vibrotactile cue delivered at set start habituates within seconds. A pressure cue can remain "on" for a full 45-second set and the user continuously perceives it.

### Six Parameterizable Dimensions of Manual Cueing (from practitioner literature)
| Dimension | What practitioners describe |
|---|---|
| **Location** | Over target muscle belly or bony landmark |
| **Pressure magnitude** | ~0.5-2N "awareness touch" to ~5-20N "push into my hand" |
| **Pressure direction** | **Single most important variable.** The vector carries the movement instruction |
| **Timing** | Applied *before* the error phase — anticipatory, not reactive |
| **Duration** | Brief (1-3s) for attention; sustained (full rep) for proprioceptive loading |
| **Release pattern** | Gradual = "you've got it, maintain." Abrupt = testing independence |

Vibration can replicate ~30% of what a trainer's hand does (the attentional tap). Pressure with direction captures ~70% of the value.

---

## Cueing Modality Landscape (Ranked by Feasibility)

### 1. Vibrotactile (MVP baseline)
- ERM coin motors, LRA actuators
- Cheap, safe, low-power. Precision Microdrives is go-to vendor
- Skin spatial resolution ~2-4cm on torso, finer on forearm
- **Limitation:** Pacinian habituation kills sustained cueing
- **Best use:** discrete pre-rep "attention here" alerts
- Sources: [Vibrotactile stimulation habituation study](https://pubmed.ncbi.nlm.nih.gov/22254645/), [Bark et al. "Effects of Vibrotactile Feedback on Human Learning of Arm Motions"](https://pmc.ncbi.nlm.nih.gov/articles/PMC4623827/)

### 2. Twisted String Actuators (TSA) — MVP parallel track candidate
- **Mechanism:** motor twists bundled strings → effective length shrinks → linear pull on load (squeeze band)
- **Stupidly simple:** pager motor + nylon string can lift 7kg. Appears in children's robotics books
- **BOM for prototype:** < $20 (small DC motor, nylon string, velcro band, Arduino Nano/ESP32)
- **Buildable in a weekend** alongside vibrotactile MVP
- **Paper on TSA for haptic force rendering:** [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2405896318332956)
- **[Hackaday overview](https://hackaday.com/2015/01/17/twisted-string-actuators/)**: simple, cheap, high gear ratio
- **Limitations:** nonlinear response (twists vs displacement — less critical for squeeze band than precision positioning), nylon string fatigue with repeated cycling, slower than vibrotactile (sub-second, fine for pre-rep cueing)
- **2025 comprehensive review:** [Twisted string actuators: Comprehensive review](https://www.sciencedirect.com/science/article/pii/S0263224125021839)
- **Rajiv's take:** TSA is cheap enough and simple enough that NOT doing it as a parallel track would be leaving easy data on the table. A/B test TSA squeeze vs vibrotactile buzz with EMG verification.

### 3. Electrotactile (skin stimulation, not muscle)
- Low-intensity electrical current activates superficial skin afferents (tingling sensation)
- Flat electrodes, no moving parts, instantaneous, spatially precise
- Demonstrated in [full-body suit (Nature Communications)](https://www.nature.com/articles/s41467-026-71171-y) and [super-resolution skin patches (Science Advances)](https://www.science.org/doi/10.1126/sciadv.abp8738)
- **Downside:** sensation is tingling not squeeze, requires per-user calibration (skin impedance)
- **Verdict:** complement to pressure, not replacement for "digitized touch" claim

### 4. Skin Stretch
- Lateral displacement of skin via small motors conveys directional information
- Activates slow-adapting receptors differently than both vibration and normal pressure
- [Demonstrated on thigh-worn device](https://www.researchgate.net/publication/221011725_A_Wearable_Skin_Stretch_Device_for_Haptic_Feedback) — directional cues during walking, skills retained after removal
- [Frontiers in Neurorobotics](https://www.frontiersin.org/journals/neurorobotics/articles/10.3389/fnbot.2017.00031/full)
- **Key advantage:** encodes DIRECTION (the most important dimension of manual cueing)
- **Verdict:** hybrid (pressure for magnitude + skin stretch for direction) maps onto more of the six manual cueing dimensions

### 5. Subthreshold EMS (proprioceptive cueing, not motor contraction)
- Below contraction threshold, excites muscle spindle Ia afferents → proprioceptive "tap"
- Validated for [Parkinson's gait cueing](https://pmc.ncbi.nlm.nih.gov/articles/PMC4942708/) and [proprioceptive illusion](https://jneuroengrehab.biomedcentral.com/articles/10.1186/s12984-021-00870-y)
- Most physiologically compelling — taps directly into proprioceptive pathways, not cutaneous
- **Rajiv's note:** different regulatory surface than full NMES. Worth flagging as v2 modality
- **Limitation:** per-user calibration to stay below motor threshold

### 6. Tendon Vibration (proprioceptive illusion)
- ~30-100Hz on tendons creates perceived limb movement up to 40°
- [Goodwin et al. 1972 in Science](https://www.science.org/doi/10.1126/science.175.4028.1382)
- Adapts over time — better for burst cues at set initiation than sustained
- NOT the target use case: we want muscle activation awareness, not perceived movement

### 7. Pneumatic Bladders (post-MVP gold standard)
- **[Force Jacket — Delazio et al. CHI 2018](https://dl.acm.org/doi/10.1145/3173574.3173894)** — 26 pneumatic airbags on torso, Disney Research/CMU. Closest to "feels like a hand pressing." ~5 lbs with tubing
- **[Tasbi — Pezent et al. World Haptics 2019](https://ieeexplore.ieee.org/document/8816098/)** — squeeze + vibrotactile hybrid wristband, forces up to 15N, 50x50x15mm form factor
- **[Soft robotic wrist device with rPAMs](https://pmc.ncbi.nlm.nih.gov/articles/PMC7805937/)** — reverse pneumatic artificial muscles, first soft haptic device for real-time feedback
- **[AirPush — CHI 2024](https://dl.acm.org/doi/10.1145/3613904.3642536)** — multi-dimensional force feedback, pneumatic wearable
- **[HaptX Gloves](https://haptx.com)** — commercial, 133 microfluidic pneumatic actuators per hand
- **Limitation:** requires pump/valve infrastructure, bulky, 200-800ms inflation latency
- **Verdict:** the dream actuator but needs miniaturization. 12+ month custom fab timeline

### 8. Thermal / Foam Rolling — Not viable for real-time cueing
- Peltier elements: 1.4-2.4s rise time, high power, sweat degrades contact
- Foam rolling: pre-exercise preparation only, validates that mechanical pressure enhances activation

---

## Motor Unit Spatial Activation & Actuator Placement

### Key Finding: Motor Units Are Regional, But Skin Resolution Is the Bottleneck

Motor unit fibers cluster within 5-10mm cross-sectional territories (not spanning whole muscle). In compartmentalized muscles (triceps, gastroc), territories don't cross compartment boundaries. Different regions of the same muscle activate independently — confirmed by Wakahara (regional activation predicted regional hypertrophy after 12 weeks).

However, **skin two-point discrimination is the binding constraint** for actuator spacing:

| Body Region | Two-Point Discrimination Threshold |
|---|---|
| Forearm | 25-50 mm |
| Upper arm | ~45 mm |
| Thigh/calf | 30-45 mm |
| Torso/back | 40-60 mm |

Sources:
- [Bodine et al. (1988)](https://pubmed.ncbi.nlm.nih.gov/1702521/) — motor unit territory clustering
- [English et al.](https://www.researchgate.net/publication/14951585_Compartmentalization_of_Muscles_and_Their_Motor_Nuclei_The_Partitioning_Hypothesis) — compartmentalization hypothesis
- [Wakahara et al. (2013)](https://pubmed.ncbi.nlm.nih.gov/23657165/) — regional activation predicts regional hypertrophy
- [Latorre et al. (2024)](https://www.nature.com/articles/s41598-024-54405-1) — HD-EMG resolves motor unit positions
- [Deshpande et al. (2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8541989/) — two-point discrimination thresholds

### Design Implications

- **1 band** = sufficient for binary cue (on/off). Simplest MVP.
- **2 bands spaced ~50mm** = minimum for user to distinguish proximal vs distal cues on a limb.
- **4-6 actuators around limb** = adds value for directional encoding (medial/lateral). Note: the claim that circumferential discrimination is better than longitudinal lacks a clean primary source — receptive field elongation along the limb axis theoretically supports it, but direct arm-specific comparison data is missing.
- **Many small localized TSAs** = overkill. Muscle physiology supports regional cueing but skin can't resolve it that finely.

### POC Recommendation
Two TSA squeeze bands spaced 50mm apart on target muscle group + one vibrotactile motor co-located with each band. Enables:
- A/B: TSA squeeze vs vibrotactile buzz (same location)
- Spatial: proximal vs distal cueing (two distinguishable zones)
- Hybrid: buzz as "attention" + squeeze as "sustained cue"
- BOM: ~$40-50 total

---

## Rajiv's Hardware Roadmap Vision

**MVP (2.5-week POC):**
- Vibrotactile (LRA) for discrete alerts
- TSA squeeze band as parallel track ($20 BOM, weekend build)
- A/B test both with EMG verification — this IS the research platform SPOV in action

**Post-MVP (3-6 months):**
- Miniaturized pneumatic system (Force Jacket approach shrunk to single limb band)
- Skin stretch for directional cueing dimension
- Custom micro-pumps, thin-film silicone bladders, integrated PCB

**V2 (12+ months):**
- Subthreshold EMS for proprioceptive cueing
- Distributed pressure arrays modulating all six dimensions
- Self-contained pneumatic competitive with Whoop/Apple Watch form factor

---

## Pressure Actuator Primary Sources *[All accessed 2026-04-07]*

| Source | Venue | Key Finding |
|---|---|---|
| [Delazio et al. "Force Jacket"](https://dl.acm.org/doi/10.1145/3173574.3173894) | CHI 2018 | 26 pneumatic airbags produce distinguishable pressure sensations on torso |
| [Pezent et al. "Tasbi"](https://ieeexplore.ieee.org/document/8816098/) | World Haptics 2019 | Squeeze + vibrotactile hybrid outperforms either alone, 15N force, wristwatch form |
| [Polygerinos et al. soft robotic glove](https://link.springer.com) | ~2015 | Fiber-reinforced pneumatic actuators, 5-10N per finger, wearable |
| [Ilievski/Whitesides "Pneu-Nets"](https://onlinelibrary.wiley.com) | Angewandte Chemie 2011 | Foundation for soft pneumatic actuators at 30-70 kPa |
| [Soft robotic wrist rPAMs](https://pmc.ncbi.nlm.nih.gov/articles/PMC7805937/) | PMC 2021 | First soft haptic device for real-time feedback |
| [AirPush](https://dl.acm.org/doi/10.1145/3613904.3642536) | CHI 2024 | Pneumatic wearable, multi-dimensional force feedback |
| [Min et al. "Ultralight Soft Wearable Haptic"](https://advanced.onlinelibrary.wiley.com/doi/full/10.1002/aisy.202500374) | Adv Intell Sys 2025 | Shear + normal + vibration in one interface |
| [Patel et al. "Wearable Haptic Feedback Interfaces"](https://advanced.onlinelibrary.wiley.com/doi/10.1002/adfm.202417906) | Adv Func Mat 2026 | Comprehensive review of the entire field |
| [TSA for haptic force rendering](https://www.sciencedirect.com/science/article/pii/S2405896318332956) | ScienceDirect 2018 | Confirms TSA mechanism works for haptic feedback |
| [TSA comprehensive review](https://www.sciencedirect.com/science/article/pii/S0263224125021839) | Measurement 2025 | State of the art, scalability, limitations |

---

## Cueing Effectiveness Primary Sources *[All accessed 2026-04-07]*

| Source | Venue | Key Finding |
|---|---|---|
| [Johansson & Flanagan](https://www.nature.com/articles/nrn2621) | Nature Rev Neurosci 2009 | Merkel/Ruffini encode sustained pressure; Pacinian encodes vibration |
| [Sigrist et al.](https://link.springer.com/article/10.3758/s13423-012-0333-8) | Psychonomic Bull Rev 2013 | Haptic guidance helps novices, needs fading to avoid dependency |
| [Marchal-Crespo & Reinkensmeyer](https://jneuroengrehab.biomedcentral.com/articles/10.1186/1743-0003-6-20) | J NeuroEng Rehab 2009 | Haptic guidance vs error amplification for motor learning |
| [Cacciatore et al.](https://www.sciencedirect.com/science/article/abs/pii/S0167945710001569) | Human Movement Sci 2011 | Alexander Technique manual guidance: ~50% lower peak-to-peak torque |
| [Scapulothoracic EMG study](https://www.sciencedirect.com/science/article/abs/pii/S105064111830453X) | 2019 | Tactile + verbal guidance: 9/10 exercise-guidance combos improved EMG or kinematics |
| [Lehecka et al. gluteal cues](https://pmc.ncbi.nlm.nih.gov/articles/PMC10909302/) | IJSPT 2024 | Verbal cues increased glute force 13.5%; tactile did not. But tactile increased broad jump 3% |
| [Shoulder EMG — Huang et al.](https://journals.humankinetics.com/view/journals/jsr/27/5/article-p424.xml) | J Sport Rehab 2018 | Any feedback > no feedback for EMG amplitude. Tactile+verbal ≈ verbal alone |
| [Plyometric shoulder EMG](https://pubmed.ncbi.nlm.nih.gov/35093619/) | 2022 | Verbal and tactile feedback effects in overhead athletes |
| [UW AMP Lab](https://depts.washington.edu/amplify/past-projects/haptic-feedback/) | UW | EMG → proportional vibrotactile armband for myoelectric awareness |
| [EMG vibrotactile biofeedback dystonia](https://jneuroengrehab.biomedcentral.com/articles/10.1186/s12984-019-0620-y) | J NeuroEng Rehab 2019 | Proportional vibration biofeedback improves motor control |

---

## Prior Art / Competitors in Cueing Space

### Muscle Minder (FORCE Technology / UBC SPIN Lab)
- **What:** prototype exercise shirt with twisted string actuators, squeeze before each bicep curl
- **Team:** Vanessa Carpenter (FORCE Technology), Prof. Karon MacLean (UBC SPIN Lab), PhD candidates Laura Cang, Soheil Kianzad
- **Evaluation:** n=6, single exercise (bicep curl). Pre-rep squeeze > continuous or no cue for EMG
- **Status:** research prototype only. No published paper in peer-reviewed venue. No product, no company, no continued development
- **What they don't have:** closed loop, CV, agentic reasoning, fascial-chain intelligence, multi-exercise, path to market
- Sources: [FORCE Technology case study](https://forcetechnology.com/en/cases/haptic-interfaces-mind-muscle-connections-electronics), [Carpenter portfolio](https://vanessacarpenter.com/portfolio/muscle-minder/)

### mTrigger
- **What:** $449 single-channel wireless sEMG biofeedback device + mobile app
- **What they do:** real-time EMG visualization, clinician sets MVC target, patient tries to hit it, visual/audio/haptic feedback proportional to activation level
- **Validated:** [gait rehab reliability study (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8296262/)
- **What they DON'T do:** no CV, no agentic reasoning, no spatial cueing ("feel it HERE"), no multi-channel cross-muscle analysis, no closed loop (single-channel meter, not coach), no pre-rep timing
- **Positioning:** clinical rehab tool sold through PT supply chains, not consumer fitness
- **Significance:** proves PTs will pay $449/unit for single-channel sEMG biofeedback. Market validation
- Sources: [mTrigger product page](https://mtrigger.com/products/mtrigger-biofeedback-system-individual-unit-mtrigger-1), [The Science](https://mtrigger.com/pages/the-science)

---

## Key Literature Gap

**No head-to-head study comparing vibration vs pressure for proprioceptive cueing during resistance exercise exists.** Additionally, almost all tactile cueing studies used human hands, not devices. No systematic comparison of device-delivered cueing modalities with EMG verification across exercises has been published. This is both a research contribution opportunity and the foundation for the "research platform" SPOV.

---

## Rajiv's Key Design Decisions (from this session)

1. **Lean away from buzzing** — graduated pressure is closer to how practitioners actually cue
2. **Pre-rep cueing > continuous cueing** — supported by Muscle Minder finding and Lawson's timing dimension
3. **TSA as MVP parallel track** — cheap enough ($20) and simple enough to A/B test against vibrotactile
4. **The cueing purpose is NOT limb guidance or movement illusion** — it's: (a) wrong-muscle-firing alert, (b) right-muscle reinforcement, (c) positional correction
5. **MVP proves the intelligence loop; the actuation roadmap earns the "digitized hand" claim**
