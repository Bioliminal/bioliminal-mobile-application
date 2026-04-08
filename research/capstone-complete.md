# Capstone Research: AI Movement Screening Tool — Complete Reference

---

## Table of Contents

- [Part 1: Project Overview](#part-1-project-overview)
- [Part 2: Research Findings](#part-2-research-findings)
- [Part 3: Fascial Chain Science Deep Dive](#part-3-fascial-chain-science-deep-dive)
- [Part 4: MediaPipe Accuracy Analysis](#part-4-mediapipe-accuracy-analysis)
- [Part 5: Why This Integration Doesn't Exist](#part-5-why-this-integration-doesnt-exist)
- [Part 6: Citation Network Analysis](#part-6-citation-network-analysis)
- [Part 7: Competitive Landscape](#part-7-competitive-landscape)
- [Part 8: Source Verification Appendix](#part-8-source-verification-appendix)
- [Master Reference List](#master-reference-list)

---

## Part 1: Project Overview

*Source: capstone-overview.md*

### The Problem

Movement screening costs $150–2000 and requires a trained professional. Most athletes — especially youth and recreational — never get screened. They find out something's wrong when they get hurt.

We're building a browser-based triage tool that runs from a phone camera. You do 4 movements (~5 minutes). It detects biomechanical risk factors, maps them along validated fascial chains to identify likely root causes, and generates a personalized report. Same symptom, different body, different recommendation.

**This is not a diagnostic tool.** It identifies who should see a professional and gives them something specific to discuss when they do.

### What This Looks Like

Two people both show knee valgus during a squat:

**Person A**: Knee valgus + ankle restriction + no hypermobility
> "Your knee collapse is likely compensating for restricted ankle mobility (posterior chain connection). Mobilize your ankles first — knee valgus often resolves without direct knee work."

**Person B**: Knee valgus + full ankle ROM + hypermobility markers
> "Your joints have more range than average but your knee is collapsing under load. This is a stability and motor control issue, not mobility. Prioritize neuromuscular control training — stability over flexibility for your body."

Same finding. Different root cause. Different protocol.

### Why This Doesn't Exist Yet

AI movement tools exist — they tell you "your knee collapses." Fascial chain science explains why problems in one joint cause pain somewhere else. Nobody has connected these two things in software. A systematic search of commercial tools (Kinetisense, DARI Motion, Uplift Labs, VueMotion, Model Health) and academic literature through April 2026 confirms: no existing tool integrates fascial chain logic into automated movement screening (Wilke et al. 2016; landscape review, April 2026).

This isn't because nobody thought of it. Five distinct barriers have independently prevented the integration:

#### 1. Biomechanics Models Can't Represent Chains

Computational biomechanics has been locked into Hill-type muscle models since 1938 — 1D lumped-parameter models that treat each muscle as an independent actuator. OpenSim, AnyBody, and every major simulation platform uses this paradigm (Dao & Ho Ba Tho, 2018; Seth et al., 2018). These models architecturally cannot represent cross-body connective tissue force transmission. A 2018 systematic review of muscle modeling doesn't even list fascial exclusion as a gap — the field doesn't see it as missing (Dao & Ho Ba Tho, 2018). The 2018 BJSM consensus statement on fascial research explicitly identifies that neither the measurement tools nor the interdisciplinary coordination needed for integration currently exist (Zugel, Wilke, Hodges et al., 2018).

#### 2. Computer Vision Stops at Measurement

Pose estimation tools were built for gaming and animation, not clinical interpretation. The CV community optimizes for MPJPE and PCK — metrics that measure joint position accuracy, not clinical meaning. A Frontiers survey explicitly frames pose estimation as "an assistive tool for clinicians rather than an automatic machine" (Frontiers in Computer Science, 2023). No standardized method exists to map kinematic output to clinical assessment scales (PMC 12158133). Of 62 ML studies in medical imaging reviewed in one paper, none had potential for clinical use (PMC 9005663). A clinician's viewpoint "has not received adequate consideration or representation" in pose estimation research (PMC 8588262).

#### 3. Regulation Walls Off Causal Claims

DARI Motion — the first FDA-cleared markerless motion system (March 2019) — is limited to "quantifying and graphically displaying human movement patterns" with no causal or diagnostic claims. Under the 21st Century Cures Act, clinical decision support software escapes regulation only if it supports rather than replaces practitioner judgment and makes no claims "prompting specific clinical action" (Arnold & Porter, Jan 2026). Any software attributing movement dysfunction to fascial chain pathology would trigger full SaMD classification, requiring clinical validation the evidence base cannot currently support (Greenlight Guru; Sidley Austin, 2024). All major commercial platforms uniformly restrict to joint-level kinematics — a consistent, deliberate design pattern mirroring these constraints.

#### 4. The Science Has Real Gaps

Fascial chain skeptics have legitimate arguments. Greg Lehman cites cadaveric data showing force transmission maxes out at ~10cm, undermining whole-body chain claims (Lehman, 2012). The Superficial Front Line has zero anatomical evidence across seven studies (Wilke et al., 2016). Cadaveric preparation (formalin fixation, freezing) alters tissue properties, and only 2 of 9 force transmission studies were conducted in vivo (Krause et al., 2016). Even Tom Myers concedes "hard evidence of effects from bodywork or movement training, however attractive intuitively, is so far lacking" (Myers, 2018). These gaps are real — we address them by restricting our chain mapping to the three pathways with strong evidence and framing the tool's output as hypothesis-generating, not diagnostic.

#### 5. Nobody Speaks Both Languages

This is a documented "two communities" problem: practitioners and engineers operate in different worlds with different cultures, reward structures, and timelines (Cambridge Judge Business School). Clinical reasoning in physical therapy is "qualitatively different" from standard diagnostic categories — it focuses on movement patterns and functional behavior that resist discrete categorical encoding (Physical Therapy, 2004). The $3.8B physical therapy software market builds billing and scheduling tools, not clinical reasoning (Precedence Research). The people who understand fascial chains don't write software; the people who write software don't know fascial chains exist.

### Our Position in the Gap

We're not trying to fix biomechanics models, publish to CVPR, or seek FDA clearance. We're building a rule-based interpretation layer — the piece the CV community deliberately skips — using only the three fascial chains with strong evidence, positioned as educational triage that supports practitioner judgment rather than replacing it. The novel contribution is the translation of practitioner reasoning into computable rules by a team that understands both sides.

### Core Hypotheses

This project tests three unvalidated inferences that together form the bridge between pose estimation and fascial chain science:

1. **The proxy hypothesis**: Co-occurring joint angle patterns observable on video can serve as proxies for what practitioners detect by touch. No published study validates this specific inference. We test it by comparing our chain attributions against clinician agreement.

2. **The threshold portability hypothesis**: Clinical thresholds established with motion capture systems (e.g., knee valgus >10° = 2.5x ACL injury risk) remain meaningful when applied to MediaPipe data with 5–10° real-world error. We test it by measuring whether our flagged findings align with clinician observations on the same subjects.

3. **The chain attribution hypothesis**: When multiple co-occurring findings map to a known fascial chain, the chain-level root cause attribution is more accurate than treating each finding independently. We test it by asking clinicians to evaluate both our chain-aware and chain-naive outputs for the same subjects.

### How It Works

1. **Camera captures 4 movements**: overhead squat, single-leg balance, overhead reach, forward fold
2. **AI pose estimation** (MediaPipe BlazePose) tracks 33 body landmarks in real-time
3. **Joint angle analysis** flags issues using published biomechanical thresholds — knee valgus, ankle restriction, hip drop, shoulder asymmetry, forward head posture, left-right imbalances
4. **Fascial chain mapping** connects co-occurring findings along three validated myofascial pathways (Superficial Back Line, Back Functional Line, Front Functional Line) to identify likely root causes
5. **Per-joint confidence scoring** surfaces detection quality — green/yellow/red per landmark based on occlusion and tracking confidence
6. **Personalized report** adapts recommendations based on the individual's specific combination of findings, including hypermobility markers

### The Science

#### Fascial Chains

We restrict our chain mapping to the three pathways with strong anatomical evidence from multiple independent studies:

| Chain | Evidence | Verified Transitions | Studies |
|-------|----------|---------------------|---------|
| Superficial Back Line | Strong | 3/3 | 14 |
| Back Functional Line | Strong | 3/3 | 8 |
| Front Functional Line | Strong | 2/2 | 6 |

Source: Wilke et al. (2016), Archives of Physical Medicine and Rehabilitation. Independently confirmed by Kalichman (2025), Body Work and Movement Therapies — a separate narrative review that does not cite Wilke yet arrives at the same chain-level evidence hierarchy.

We intentionally exclude the Spiral Line (moderate evidence, 5/9 transitions), Lateral Line (limited, 2/5), and Superficial Front Line (no verified transitions). This limits our coverage but ensures every chain mapping our tool produces has a validated anatomical basis.

**Force transmission evidence**: In-vitro studies show fascia can transmit up to 30% of mechanical forces (Kalichman 2025). A matched-pairs study (n=26) demonstrated that lower-limb stretching increased cervical ROM by ~5° (p<0.05), providing preliminary in-vivo support for remote effects along myofascial meridians (Wilke et al. 2016, Journal of Bodywork and Movement Therapies).

**Known limitations of fascial chain theory**: Maximum mechanical displacement in cadaveric pull studies is 4–10 cm (Lehman 2012). Cadaveric preparation methods (formalin fixation, freezing/thawing) alter collagen cross-linking and tendon modulus, meaning measured force transfer values may not reflect living tissue behavior (Krause et al., 2016). Our tool does not claim to detect fascial tension directly — it identifies co-occurring movement patterns consistent with chain-level dysfunction.

**Engaging the skeptics**: Lehman's 10cm force transmission limit is a critique of direct mechanical chain effects. Our approach does not depend on long-range force transmission — we detect co-occurring compensatory movement patterns that practitioners empirically associate with chain dysfunction. Whether the mechanism is fascial tension, neuromuscular compensation, or habitual movement patterning, the observable video signature is the same. Our chain mapping encodes the practitioner's pattern recognition, not a claim about tissue mechanics.

#### Pose Estimation Accuracy

MediaPipe BlazePose accuracy is **joint-specific and condition-dependent**, not a single number:

| Joint | Controlled Conditions | Real-World Estimate | Source |
|-------|----------------------|--------------------|--------|
| Hip | ~2.4° MAE | 5–10° | PMC 10886083 |
| Knee | ~2.8° MAE | 5–10° | PMC 10886083 |
| Ankle | ~3.1° MAE | 10°+ (unreliable with occlusion) | PMC 10886083 |

Controlled figures are from treadmill gait analysis with fixed camera position and consistent lighting. Real-world degradation factors include clothing (one subject's jacket spiked error from 25mm to 54mm RMSE), camera angle, lighting, and self-occlusion (PMC 11644880).

**Threshold portability problem**: Our clinical thresholds (knee valgus >10°, asymmetry >10°) were established using motion capture or goniometry, not phone cameras. Applying thresholds from one measurement system to a less accurate system assumes errors are symmetric and centered. A systematic bias (MediaPipe consistently over/underestimating valgus) would shift the effective threshold. Our target findings are well above the noise floor for hip and knee tracking, but we acknowledge the thresholds are approximate when applied to this measurement tool.

**This is adequate for triage, not diagnosis.** Ankle-dependent findings carry lower confidence, which the tool communicates explicitly.

**No published study has validated MediaPipe for FMS-style scoring** — the only FMS-specific paper (SOMA, 2024) is explicitly exploratory with no accuracy claims. We do not claim clinical-grade precision.

#### Clinical Thresholds

- Knee valgus >10° = 2.5x ACL injury risk (clinically established via motion capture)
- Left-right asymmetry >10° = documented injury predictor
- These thresholds are published and are detectable within MediaPipe's reliable accuracy range for hip and knee joints, though they were validated with higher-precision instruments

### What This Is (and Isn't)

**This is a clinical reasoning system**, not an AI in the machine-learning sense. MediaPipe provides the input (joint positions from video). The novel contribution is the **rule system that encodes expert fascial chain logic** — translating reasoning that currently lives in practitioners' heads into computable rules that can run at scale, for free, on a phone.

The intelligence is in the integration: which co-occurring patterns map to which chains, how hypermobility modifies the interpretation, and how to generate root-cause-aware recommendations rather than symptom descriptions.

This rule system encodes practitioner reasoning but has not been validated against treatment outcomes. Validation requires demonstrating that following chain-aware recommendations leads to better outcomes than following symptom-only recommendations — a question our clinician testing begins to address but cannot definitively answer at capstone scale.

### Known Limitations

- **Ankle tracking is unreliable** with occlusion or certain footwear — ankle-dependent findings display reduced confidence
- **Camera angle matters** — the tool provides setup guidance (frontal view, well-lit, tight clothing) and warns when tracking quality degrades
- **Not a replacement for professional screening** — a triage tool that identifies risk factors and suggests when to seek professional evaluation
- **Fascial chain mapping from video is a proxy** — we detect movement pattern correlations consistent with chain dysfunction, not fascial tension directly. Whether these patterns reflect fascial mechanics, neuromuscular compensation, or habitual patterning is an open question.
- **No bias data exists** — MediaPipe has published no disaggregated accuracy data by skin tone or body type. For a tool positioned as accessible to underserved populations, this is a significant equity concern. We cannot claim equal performance across all users, and performance may degrade for darker skin tones, larger body types, or atypical proportions. We flag this as a priority for future validation rather than treating it as an edge case.
- **Chain attribution has no ground truth** — our fascial chain logic encodes practitioner pattern recognition, not empirically validated causal pathways. We cannot currently verify whether the chain attribution is correct; only treatment outcome tracking would provide that evidence.

### Validation Strategy

We validate by separating what we're testing into layers and collecting data that can confirm or falsify each one independently.

**Layer 1 — Measurement accuracy**: Do our joint angle measurements match clinician observations? We show clinicians MediaPipe output for each subject and ask whether the flagged findings (valgus, asymmetry, restriction) align with what they see.

**Layer 2 — Chain attribution accuracy**: Do clinicians agree with our root-cause mapping? We present the chain attribution separately from the measurement and ask clinicians to evaluate whether the proposed root cause matches their clinical judgment.

**Layer 3 — Recommendation utility**: Is the chain-aware recommendation more useful than a symptom-only description? We show clinicians both outputs (chain-aware vs. chain-naive) for the same subject and ask which is more accurate and more actionable.

**Layer 4 — Self-report follow-up**: After generating a report, the tool asks users to try the recommended protocol for 2 weeks and report whether their movement improved. Even a few responses provide directional evidence on whether chain attribution leads to the right intervention.

**Sample**: 10 test subjects validated against 2–3 clinicians. This is a feasibility demonstration, not a powered validation study — sufficient to surface which layer is failing and generate hypotheses, not to establish statistical reliability.

**Data infrastructure**: Every session logs raw landmark coordinates, computed joint angles, confidence scores, chain attributions, and final recommendations. This creates a validation dataset for post-capstone analysis regardless of sample size.

### Future Vision: From Video Proxy to Direct Measurement

The capstone is Phase 1 of a larger arc. The end goal is a device that shows which muscles are actively being used — letting someone physically see how their body behaves during movement.

| Phase | What | Proves |
|-------|------|--------|
| **Phase 1** (Capstone) | Video-only, rule-based chain mapping | The reasoning layer works; proxy inference is plausible |
| **Phase 2** | Add surface EMG (sEMG) for key muscle groups during screening | Ground truth for chain attribution — does the video proxy agree with direct muscle activation data? |
| **Phase 3** | Real-time visualization overlay — skeleton + muscle activation heatmap | The "physically see how your body behaves" product |

Phase 2 closes the proxy gap: sEMG sensors on muscles along the 3 chains (gastroc, glutes, erector spinae for SBL; lats, glute max, contralateral VL for BFL) directly measure whether the muscles are firing. When the video says "this chain is involved," the EMG data confirms or refutes it. Consumer-grade sEMG is accessible (~$30–50/sensor for MyoWare).

**Architecture for extensibility**: The chain mapping engine accepts scored inputs, not raw landmarks. An "evidence source" field on every finding ("source: video, confidence: 0.82") today becomes ("source: video + sEMG, confidence: 0.91") tomorrow. Same reasoning engine, richer inputs.

### Tech Stack

Everything runs in the browser. No backend server. Free to deploy.

- MediaPipe BlazePose (pose estimation, JavaScript SDK)
- HTML/CSS/JS or React (frontend)
- HTML5 Canvas (skeleton overlay + confidence visualization)
- Rule-based decision trees (scoring + chain mapping)
- GitHub Pages or Vercel (free hosting)

### Timeline (3 Weeks)

| Week | Deliverables | Risk |
|------|-------------|------|
| 1 | Pose estimation pipeline + overhead squat & single-leg balance scoring with published thresholds | MediaPipe integration complexity |
| 2 | Remaining 2 movements + fascial chain mapping (3 chains) + personalized report generation + UI | Chain logic encoding |
| 3 | Per-joint confidence indicators + validate against 2–3 clinicians on 10 test subjects + film demo subjects + presentation | Clinician availability |

### Team Split

| Person | Owns | Interface With |
|--------|------|----------------|
| A | MediaPipe integration + skeleton overlay + confidence visualization | B (landmark data format) |
| B | Joint angle math + movement threshold scoring | A (input), C (scored findings) |
| C | Fascial chain decision tree + compensation detection | B (input), D (chain findings) |
| D | Report generation + clinician validation + presentation | C (input) |

**Risk mitigation**: B and C co-own the chain mapping interface definition. If C underdelivers, B can contribute to chain logic since they own the upstream scoring.

### Demo Plan

**Live**: A volunteer does an overhead squat and single-leg balance in front of a laptop. The screen shows their skeleton in real-time with joints colored by confidence and risk (red/yellow/green). After all 4 movements, the system generates a personalized report. Different volunteer = different report.

**Backup**: Pre-recorded video of two different people getting two different root-cause profiles for the same surface-level finding.

### Future Work

- Full Beighton hypermobility protocol integration (91.9% sensitivity demonstrated in literature)
- Deceleration quality assessment
- ML classifiers trained on collected screening data to supplement rule-based system
- Longitudinal tracking to measure protocol effectiveness
- Expanded chain coverage as evidence base grows

---

## Part 2: Research Findings

*Source: research-all-findings.md — Phase 2 deep-dive findings relevant to the capstone. Phase 1 AI-in-sports landscape sections included for context where they intersect with movement screening and injury prediction.*

### Section 1: Player Performance Analytics & Real-Time Decision Support

#### Deployed Systems

| League | Partner | System | Scale |
|--------|---------|--------|-------|
| NFL | AWS | Digital Athlete | 38 5K cameras, 500M data points/week, all 32 teams |
| NFL | Microsoft | Surface Copilot+ | 2,500+ PCs on sidelines, real-time play filtering (Aug 2025) |
| NBA | Azure | Body tracking | 29 body points per player at 60 Hz, 15–16 GB/game |
| NBA | AWS | Defensive Box Score, Shot Difficulty, Gravity | Neural network analytics via Bedrock + SageMaker |
| MLB | Google Cloud | Scout Insights | AI-powered real-time Gameday analysis (March 2026) |
| Soccer | Stats Perform | Opta xG | 20 factors/shot, trained on ~1M shots, real-time APIs |

#### Key Claims
- Philadelphia 76ers president Daryl Morey confirmed the team uses LLMs trained on scouting notes + tracking data: "We absolutely use models as a vote in any decision." (Source: The Ringer)
- Academic systematic review of basketball prediction ML models found accuracy ranges from 58% to 98.9%; highest was 98.90% using MLP neural network on EuroLeague data (Ballı et al. 2021). NBA-specific highest was 93.81% using Random Forest (Migliorati 2020). Review covers NBA, EuroLeague, and CBA (PMC12200876)
- Dynamic prediction models improve from 62% at game start to 78% by final quarter when incorporating fatigue and tactical data
- Sports analytics market: $4.79B (2024), projected $24B+ by 2032

#### Sources
- https://www.nfl.com/playerhealthandsafety/equipment-and-innovation/aws-partnership/building-a-digital-athlete-using-ai-to-rewrite-the-playbook-on-nfl-player-safety
- https://pmc.ncbi.nlm.nih.gov/articles/PMC12200876/

---

### Section 2: Injury Prevention & Biomechanics

#### Deployed Systems

| Company | Method | Validated Results |
|---------|--------|-------------------|
| Zone7 | ML on workload/readiness data | 72.4% pre-injury detection, 1–7 days advance, 11 clubs, 423 injuries |
| NFL Digital Athlete | 38 cameras + RFID tracking | 17% concussion reduction (2024), 14% strain reduction since 2023 |
| Catapult | GPS wearables | Used by Bengals, Jets, Raiders, 49ers, Buccaneers |
| Kitman Labs | ML on workload + readiness + testing | Deployed across NFL, MLB, NHL, rugby |

#### ML Accuracy Benchmarks

| Method | Accuracy | Source |
|--------|----------|--------|
| Random Forest (injury prediction) | 87.5% median across 18 studies | PMC12383302 |
| CNN (video biomechanics) | 91% median, 94% expert agreement | PMC12383302 |
| LSTM (ground reaction force) | <5% mean absolute error vs. lab | PMC12383302 |

#### Key Claims
- Only 43.84% of published studies demonstrated adequate model validation (PMC12383302)
- NFL concussion reduction figure has no independent validation — originates solely from NFL-published data
- Integrated AI biomechanics systems achieved 23% reduction in reinjury rates and 3.4x athlete adherence to load protocols
- Markerless CV pose estimation achieves 86% agreement with lab assessment in 2-minute field protocols
- Field bifurcating into real-time wearable monitoring AND retrospective predictive platforms — teams use both

#### Sources
- https://zone7.ai/case-studies/validation-study/validation-study-injury-risk-forecasting-with-zone7-ai/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC12383302/

---

### Section 3: AI Speed/Agility Training & Movement Quality Assessment

#### Existing Products

| Tool | What It Does | Target | Price |
|------|-------------|--------|-------|
| VueMotion / Motion IQ | Sprint mechanics from phone video (ground contact time, flight time, stride length) | Elite coaches (80+ teams, 50 countries) | Enterprise pricing |
| Ochy | AI gait analysis in 60 seconds from phone | Runners, retailers (shoe fitting) | Consumer |
| FastAI | Sprint form analysis, detects over-striding, poor hip flexion | Consumer | App Store |
| TechniqueView | AI pose overlay for 15+ sports | Consumer | $10/month |
| Yogger | Joint angle tracking, movement assessments | Consumer/Teams | $10–30/month |
| ReMotion AI | Sprint coaching with real-time in-rep feedback | Athletes/coaches | Early access (Jan 2026) |
| Sparta Science | Force plate + AI (1M+ scans database) | NFL, NBA, MLB, military, Parisi Speed School | Enterprise ($15K+ hardware) |
| OpenCap | Open-source: 2 smartphones + OpenSim for kinematics | Academic/clinical | Free (open source) |

#### Key Findings
- **Automated FMS from phone video does not commercially exist.** LLM-FMS achieved 91% accuracy but academic-only, static keyframes only
- Parisi Speed School (100+ franchise locations, 1M+ athletes trained) uses Sparta force plates for initial assessment but has NO AI video tool in their standard workflow
- Sprint mechanics measurement from phone: ~3–5 degree accuracy (VideoRun2D, OpenCap)
- Current AI training tools predominantly trained on professional/elite adult male data — gaps in youth-specific and female athlete models
- Youth sports software segment: $1.36B (2025) projected to $3.93B by 2034

#### Sources
- https://www.vuemotion.com/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/

---

### Section 4: Hypermobility, Biomechanical Markers & Explainable Injury AI

#### Hypermobility in Sports

| Finding | Stat | Source |
|---------|------|--------|
| Knee injury risk (contact sports, hypermobile) | OR = 4.69 | PubMed 20601606 |
| Shoulder injury risk (hypermobile athletes) | OR = 3.25 (95% CI 1.64–6.43) | PMC8077913 (Lunding et al. 2021, meta-analysis of 6 studies, 2335 athletes; low quality evidence per GRADE) |
| Overall injury rate difference (hypermobile vs not) | NOT significant (p=0.74 per Table 3; p=0.66 in conclusion — discrepancy within paper) | PMC6196975 |
| Recovery time when injured | 50% of hypermobile athletes injured 2–6 months | PMC6196975 |
| Non-hypermobile more likely to get sprains | p=0.03 | PMC6196975 |
| Only hypermobile athletes experienced dislocations | 3 cases | PMC6196975 |

#### Video-Based Hypermobility Detection
- A pose-estimation Beighton score tool achieved **91.9% sensitivity and 42.4% specificity** for detecting generalized joint hypermobility, validated on 125 adults from an EDS clinic (PubMed 41639883)
- Assessed elbows, knees, fifth fingers, thumbs, and spine from standard video clips
- Academic only — not a product

#### Why Injury Prediction Works (Explainable AI)
- **Knee abduction moment** is the strongest single ACL predictor: injured female athletes had 2.5x higher abduction moment (p<0.001), 8 degrees greater knee abduction angle, 20% higher GRF. Abduction moment alone: 73% specificity, 78% sensitivity (PubMed 15722287)
- **SHAP analysis**: ACL Risk Score (0.394), Load Balance Score (0.218), Fatigue Score (0.072) as top predictors (PMC12964768)
- **Meta-analysis of ML for ACL prediction**: AUC 0.79, sensitivity 0.57, specificity 0.87 — models better at ruling out risk than confirming it (ScienceDirect S096801602500273X)
- Markerless AI motion capture: mean joint-angle error 2.31 degrees, ICC >0.80 (Frontiers in Physiology 2025)

#### Hypermobile Athlete Compensation Patterns
- Asymptomatic hypermobile athletes during cutting: 3.5 degrees lower minimum knee valgus, 4.5 degrees greater peak knee external rotation vs controls — they adapt via neuromuscular control (PMC8558993)
- Hypermobile dancers approximate turnout using knee rotation instead of hip external rotators
- Hyperlordotic gymnasts recruit spinal extension instead of hip extension
- Hypermobile children show gastrocnemius-dominant landing strategy with reduced semitendinosus activity
- Hypermobile individuals show proprioceptive deficits at the knee (6.9° vs 4.6° passive error at 30° flexion) and greater postural sway; 8 weeks of closed-chain exercises significantly improved proprioception (PMC9397026)

#### Key Gap
**No AI system exists that combines hypermobility detection with sport-specific injury risk stratification.** No AI injury prediction model has been tested for differential performance on hypermobile vs non-hypermobile subpopulations.

#### Sources
- https://pubmed.ncbi.nlm.nih.gov/41639883/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8077913/
- https://pubmed.ncbi.nlm.nih.gov/15722287/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC12964768/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC9397026/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6196975/

---

### Section 5: Deceleration Mechanics, Braking Steps & Injury Risk

#### Key Biomechanics
- Deceleration produces peak GRF of ~5.91 N/kg and loading rates of 466 BW/sec — **2.7x greater than acceleration forces**
- Peak mechanical power during deceleration: -35 W/kg (1.7–2.0x greater than acceleration power)
- Peak anterior shear forces average 9.51 N/kg at ~50% stance phase — primary ACL strain mechanism
- ACL injuries occur within **50ms of ground contact** — no time for correction once final foot contact is made
- Athletes who subsequently tore ACLs showed 8.63 degrees vs 1.66 degrees hip adduction and 8.57 degrees vs 0.65 degrees knee valgus during maximal deceleration (Dix et al., cited in Harper et al. 2022 review, PMC9474351)
- 180-degree turn from 20m approach requires 5–6 braking steps; 45-degree turn requires only 0.4 steps

#### Reactive vs Planned Cutting
- Reactive cutting produces **64% less braking impulse** during penultimate step compared to planned cutting
- This forces **1.6x more braking demand** onto the final foot contact where ACL loading is highest
- Preplanned cutting generates 14% greater braking impulse in penultimate step and achieves sharper angles (62.7 degrees vs 52.0 degrees)
- Limited reaction time (~600ms) prevents anticipatory postural adjustments

#### Deceleration Index
- DI = deceleration time / acceleration time
- High DI = efficient braking relative to acceleration capacity
- Low DI = ACL injury vulnerability and inadequate force attenuation
- Change of direction performance correlates more with eccentric strength than concentric strength

#### Video-Observable Markers of Dangerous Deceleration
- Knee valgus (frontal plane knee projection angle)
- Lateral trunk flexion
- Extended knee postures at initial contact
- Hip internal rotation
- Insufficient posterior center-of-mass displacement relative to braking foot

#### AI Feasibility
- A 2D qualitative scoring system for deceleration showed ICC 0.94–1.00 for inter/intra-rater reliability across all 5 criteria; the integrated frontal plane assessment correctly classified 96–98% of athletes into high vs low knee abduction moment groups (PMC8595159)
- LSTM-based automated video analysis detected ACL injury patterns with **AUC 0.88 and balanced accuracy 0.80** (PMC10935765)
- Current pose estimation: 5–15 degree error margins in controlled settings; degrades for multi-directional movements
- **No consumer tool measures deceleration quality**

#### Terminology Note
"Negative step" in sport science means foot landing behind center of mass during sprint **acceleration** (a good technique). Deceleration literature uses "braking steps," "penultimate/antepenultimate foot contacts," and "braking impulse."

#### Sources
- https://pmc.ncbi.nlm.nih.gov/articles/PMC9474351/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8595159/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10935765/

---

### Section 6: Screenable Conditions & Open Datasets

#### What Can Be Screened from Phone Video

| Condition | Accuracy | Method | Dataset Available? |
|-----------|----------|--------|-------------------|
| FMS (7 movement patterns) | 91% accuracy, kappa 0.82 | LLM + pose keyframes | Yes — 1,812 frames (Figshare) + 158GB Azure Kinect (Figshare) |
| Scoliosis (from gait) | 95% balanced, AUC 0.839 from photo | Silhouette analysis / CNN | Yes — Scoliosis1K: 447,900 frames, 1,050 adolescents |
| ACL injury risk patterns | AUC 0.88 from game footage | LSTM + 3D pose estimation | Yes — AthletePose3D: 1.3M frames (GitHub) |
| Forward head posture | 78.27% accuracy, F1 77.54% | Graph convolutional network on 13 upper body joints | Partial |
| Knee valgus (dynamic) | >96% classification | 2D video scoring (5 criteria) | Partial |
| Hypermobility (Beighton) | 91.9% sensitivity, 42.4% specificity | Pose estimation on standard video | No public dataset |
| Deceleration quality | >96% classification (high vs low knee loading) | 2D qualitative scoring | No public dataset |
| Gait abnormalities | ICC >0.75 vs Vicon gold standard | MediaPipe/OpenPose | Yes — GaitMed, OpenCap |
| Squat quality | ~94% agreement with expert feedback | Pose estimation + angle thresholds | Yes — via FMS datasets |

#### Detection Gaps (NOT reliably detectable from single phone camera)
- Anterior pelvic tilt — validated only from radiographs or depth sensors
- Hip impingement (FAI) — no published video screening tool
- Frontal-plane knee valgus from sagittal view — requires frontal camera
- Flat feet/overpronation — no peer-reviewed single-camera benchmarks
- Muscle strength imbalance — requires multi-view or force measurement

#### Open Datasets

| Dataset | Size | Content | Access |
|---------|------|---------|--------|
| LLM-FMS | 1,812 annotated keyframes, 45 subjects | All 7 FMS movements with hierarchical scoring labels | Figshare (DOI: 10.6084/m9.figshare.c.7601630.v1) |
| Azure Kinect FMS | 158 GB, 45 subjects, 1,812 recordings | RGB + depth + 3D skeleton + 2D pixel trajectories | Figshare (Nature Scientific Data) |
| Scoliosis1K | 447,900 frames, 1,050 adolescents | Privacy-preserved silhouette gait sequences | Public (zhouzi180.github.io/Scoliosis1K/) |
| AthletePose3D | ~1.3M frames, 165K poses, 8 athletes | Running, track & field, figure skating | GitHub (calvinyeungck/AthletePose3D) |
| OpenCap | 1,176 subjects, 1,433 hours | Marker-based + keypoints + anatomical markers | simtk.org/projects/opencap |
| GaitMed | Medical gait dataset | Musculoskeletal disease classification | Public (Springer) |

#### Sources
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10935765/

---

### Section 7: Fascia Science, Myofascial Chains & Movement AI

#### Validated Fascial Chains (Strong Evidence)

| Chain | Path | Force Transmission Evidence |
|-------|------|------------------------------|
| Superficial Back Line (SBL) | Plantar fascia → calves → hamstrings → erector spinae → scalp fascia | 3/3 transitions verified; 7–69% force transfer between biceps femoris and sacrotuberous ligament (cadaveric data, Krause et al. 2016) |
| Back Functional Line (BFL) | Lat → thoracolumbar fascia → contralateral glute max → vastus lateralis | 3/3 transitions verified |
| Front Functional Line (FFL) | Adductor longus → contralateral rectus abdominis → pec major | 2/2 transitions verified |

#### Chains with Weaker Evidence
- Spiral Line: moderate evidence (cross-body rotational pattern)
- Lateral Line: limited evidence
- Superficial Front Line: NO fascial linkage between rectus abdominis and rectus femoris — lacks anatomical continuity
- Deep Front Line: conceptual, connects tibialis anterior through iliopsoas/diaphragm to deep spinal muscles

#### Key Claims
- Biotensegrity model: body as continuous tensional network where bones are held together by resting muscle tone of viscoelastic muscular chains in a tension-dependent manner — force applied anywhere distributes throughout the system (PubMed 29317079; note: published in *Medical Hypotheses*, a theoretical/speculative journal)
- Stretching lower limbs improves cervical ROM in flexion and extension — in vivo evidence for distal-to-proximal fascial force transmission through SBL (PMC7096016)
- Fascia is now understood as a "dynamic sensory and mechanometabolic organ" — not passive packaging (Frontiers in Pain Research 2025)
- Fascial tissue exhibits densification, fibrosis, and inflammation as pathological changes
- Multi-component exercise programs (strength + balance + neuromuscular conditioning) reduce sports injuries by ~27–66% depending on study design, but this evidence is for general training programs, not fascial-specific interventions (PMC11988859: RR 0.73 for soccer; Lauersen et al. 2014: ~66% reduction for strength training). The Fascia Institute website attributes a "30–50%" figure to these programs, but the original research does not isolate fascial training as the mechanism.
- AI gradient boosting classifiers detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302)
- LSTM networks detect injury-precursing mechanical changes ~2.5 training sessions before symptoms (PMC12383302)

#### Observable Compensation Patterns by Chain
- **SBL dysfunction**: tight hamstrings + low back pain + forward head posture clustering
- **BFL dysfunction**: lat underactivation → shoulder compensation → neck tension (cross-body diagonal)
- **FFL dysfunction**: hip adductor tightness + opposite shoulder rounding
- **Spiral Line**: rotational asymmetry + IT band tightness + opposite neck rotation restriction
- Frozen shoulder linked to contralateral hip and pelvic instability through diagonal lat-glute connections

#### The Gap
**"No peer-reviewed study was found that explicitly applies fascial chain logic inside an AI movement analysis pipeline."** — AI operates on joint kinematics; fascial chain reasoning exists only in practitioners' heads. Nobody has bridged these.

#### Sources
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7096016/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6241620/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC12383302/

---

### Summary of All Research Gaps

#### Uncovered AI-in-Sports Verticals
1. Sports betting/gambling AI
2. Equipment and gear optimization
3. Stadium operations AI
4. Training personalization beyond injury prevention
5. NHL-specific AI deployments

#### Open Technical Problems
6. Single-camera foul detection in basketball (50% accuracy, below human 70–75%)
7. Frontal-plane knee valgus from sagittal camera view
8. Anterior pelvic tilt from standard RGB video
9. Muscle activation detection from video (requires EMG)
10. Real-time deceleration quality scoring from single camera in field conditions

#### Validation Gaps
11. Only 43.84% of AI sports biomechanics studies used adequate validation
12. NFL injury reduction claims lack independent validation
13. No unified accuracy benchmarks for AI scouting
14. No AI injury model tested for differential performance on hypermobile athletes
15. MediaPipe has no published disaggregated accuracy data by skin tone or body type
16. No peer-reviewed validation of MediaPipe for FMS-style scoring

#### Novel Integration Gaps (Our Capstone)
17. **No AI system integrates fascial chain logic** — confirmed gap
18. **No hypermobility-aware movement screening tool** — confirmed gap
19. **No automated FMS from live video** — academic only (static keyframes)
20. **No consumer deceleration quality assessment** — confirmed gap

---

## Part 3: Fascial Chain Science Deep Dive

*Source: fascial-chain-science.md*

### Key Findings

1. Three specific chains (Superficial Back Line, Back Functional Line, Front Functional Line) have strong anatomical evidence, but force transmission data is mostly cadaveric with limited human in-vivo data.
2. The remote-effects hypothesis (lower-limb stretching improving cervical ROM) has modest empirical support from small RCTs — effect sizes are small and bias is prevalent.
3. Prominent critics argue mechanical displacement is too small (4–10 cm max) to justify clinical extrapolations.

### Anatomical Continuity Evidence

From Wilke et al. (2016), Archives of Physical Medicine and Rehabilitation — the foundational systematic review across six Myers-proposed meridians:

| Chain | Verified Transitions | Total Studies | Evidence Strength |
|-------|---------------------|---------------|-------------------|
| Superficial Back Line (SBL) | 3/3 | 14 | Strong |
| Back Functional Line (BFL) | 3/3 | 8 | Strong |
| Front Functional Line (FFL) | 2/2 | 6 | Strong |
| Spiral Line | 5/9 | 21 | Moderate |
| Lateral Line | 2/5 | 10 | Limited |
| Superficial Front Line | 0/? | 7 | **None** |

Independently confirmed by Kalichman (2025), Body Work and Movement Therapies — a separate narrative review that does not cite Wilke yet arrives at the same chain-level evidence hierarchy (SBL/BFL/FFL = strongly supports; Spiral/Lateral = moderate; SFL = lacks validation).

### Force Transmission

- Krause et al. (2016), Journal of Anatomy (PMC 5341578): Only 9 of 1,022 screened articles met criteria for direct cadaveric force measurement
- For SBL: moderate evidence for force transfer at all three transitions (plantar fascia → Achilles → hamstrings → sacrotuberous ligament/thoracolumbar fascia)
- In-vitro: fascia can transmit up to **30% of mechanical forces** (Kalichman 2025)
- Human in-vivo evidence remains limited as of 2025
- A Cureus 2026 paper studied the posterior spiral chain in vivo but full text was not extractable

### The Remote Effects Study

The capstone doc's "lower limb stretching improves cervical ROM" claim traces to:

**Wilke et al. (2016), Journal of Bodywork and Movement Therapies** (PubMed 27124264):
- 26 healthy participants, matched-pairs design
- Intervention: 3x30-second static stretches of gastrocnemius and hamstrings
- Result: cervical flexion/extension ROM increased from 143.3 to 148.2 degrees (p<0.05)
- That's a **~5 degree improvement** — statistically significant, clinically modest
- Authors explicitly called for larger RCTs

**2019 meta-analysis** (Journal of Sport Rehabilitation):
- Remote myofascial interventions produce statistically significant but small improvements
- Effect sizes: ~9% or ~5 degrees in cervical ROM, 1–3 cm in sit-and-reach
- Noted selection and measurement bias as key limitations across included RCTs

### Major Criticisms

#### Greg Lehman (most widely-cited skeptic)

1. **Displacement is trivially small**: Lats-glutes BFL connection shows max displacement of 4–10 cm (4 inches) from pull point. Extrapolating to clinical dysfunction 30–50 cm away has no biomechanical justification.
2. **Arbitrary chain selection**: If fascia is continuous throughout the body, specific "lines" are arbitrary. No principled reason to treat one path over another.
3. **Undefined pathology**: "Fascial adhesions" that practitioners claim to release lacks a clear, testable definition.
4. **Clinical extrapolation outruns evidence**: Basic biomechanical research does not support the clinical claims made in practice.

#### Thomas Myers' response
- States he would revise or abandon the model given sufficient contrary evidence
- Argues critics misrepresent what the model claims
- Has not revised the model

#### Methodological concerns across reviews
- Cadaver fixation alters tissue mechanical properties
- Force application methods vary widely between studies
- No standardized outcomes
- Anatomical variation between subjects makes chain mapping inconsistent

### Clinical Decision-Making Tools

**None found.** No validated clinical decision-making tool built explicitly on Anatomy Trains chain mapping exists in peer-reviewed literature as of 2025–2026.

What does exist:
- Fascial Distortion Model (separate from Myers' meridians) — used in some manual therapy practices
- 19 RCTs/crossover trials using remote myofascial release clinically (mostly targeting SBL for chronic low back pain) — but research use, not codified protocols
- Educational frameworks on Physiopedia and similar platforms — not validated clinical tools

**Honest characterization**: Fascial chain theory is widely adopted in practice but not yet formalized in evidence-based clinical decision tools.

### Implications for Capstone

- Restrict to SBL, BFL, FFL only — these have defensible evidence
- Don't claim to detect fascial tension — claim to detect co-occurring movement patterns consistent with chain-level dysfunction
- Acknowledge the displacement critique explicitly
- The absence of any existing decision tool is both a novelty argument and a caution: nobody has validated this approach

### Sources

1. Wilke et al. (2016). What Is Evidence-Based About Myofascial Chains: A Systematic Review. *Archives of Physical Medicine and Rehabilitation*. [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)
2. Krause et al. (2016). Intermuscular Force Transmission Along Myofascial Chains: A Systematic Review. *Journal of Anatomy*. [PMC 5341578](https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/)
3. Can Myofascial Interventions Have a Remote Effect on ROM? A Systematic Review and Meta-Analysis (2019). *Journal of Sport Rehabilitation*. [Link](https://journals.humankinetics.com/view/journals/jsr/29/5/article-p650.xml)
4. Wilke et al. (2016). Remote Effects of Lower Limb Stretching: Preliminary Evidence for Myofascial Connectivity? *Journal of Bodywork and Movement Therapies*. [PubMed 27124264](https://pubmed.ncbi.nlm.nih.gov/27124264/)
5. Lehman (2012). Fascia Science: Stretching the Relevance of the Gluteus Maximus and Latissimus Dorsi Sling. [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)
6. Kalichman (2025). Myofascial Continuity: Review of Anatomical and Functional Evidence. *Body Work and Movement Therapies*. [PubMed 41316622](https://pubmed.ncbi.nlm.nih.gov/41316622/)
7. In Vivo Evidence of Myofascial Force Transmission Along the Posterior Spiral Chain (2026). *Cureus*. [Link](https://www.cureus.com/articles/453269)
8. Myers Responds to Lehman's Fascia Science. [Anatomy Trains Blog](https://www.anatomytrains.com/blog/2015/06/03/fascia-mashers-and-fascia-bashers/)
9. Effect of Remote Myofascial Intervention on Musculoskeletal Health (2024–2025). *Advanced Rehabilitation*. [Link](https://www.advrehab.org/Journal/-125/pdf-55966-10?filename=Reza_PDF.pdf)

---

## Part 4: MediaPipe Accuracy Analysis

*Source: mediapipe-accuracy.md*

### Key Findings

1. The "2–3 degree error" claim is real but narrowly scoped — from controlled treadmill gait analysis, not general movement screening. Ankle error reaches 10+ degrees under the same conditions.
2. No published study has validated MediaPipe BlazePose for FMS scoring — the only FMS-specific study is explicitly exploratory with no accuracy claims.
3. Accuracy degrades substantially in real-world conditions — a jacket in one study spiked positional RMSE from ~25–35 mm to 53.6 mm.

### Joint-Specific Accuracy (Controlled Conditions)

From PMC 10886083 — MediaPipe vs. marker-based motion capture during treadmill gait:

| Joint | MAE | Pearson r | Notes |
|-------|-----|-----------|-------|
| Hip | 2.35° | High | Most reliable |
| Knee | 2.82° | High | Reliable |
| Ankle | 3.06° | As low as 0.45 | Drops severely with contralateral leg occlusion |

**Critical context**: These numbers come from treadmill walking — a highly constrained single-plane movement with fixed camera angle and consistent lighting. Not generalizable to multi-plane functional movements.

### What the Frontiers 2025 Review Actually Says

The capstone cited Frontiers in Physiology 2025. That mini-review reports accuracy thresholds as:
- **Under 20° error** for movements greater than 90°
- **~10° error** for movements up to 40°
- **Below 10° error** for static angles

This is nowhere near a blanket "2–3 degrees."

### Real-World Degradation

#### Clothing and Background
- One subject wearing a jacket spiked positional RMSE from 25–35 mm to **53.6 mm** due to landmark confusion from background interference (PMC 11644880)

#### Camera Setup
- Monocular (single phone): median positional RMSE of **56.3 mm**
- Dual-camera stereo: median RMSE of **30.1 mm**
- Stereo setup knee angle RMSE: 7.7–10.3° during squats (PMC 11644880)
- Left-limb angles consistently more accurate than right due to camera-position-dependent occlusion (PMC 10886083)

#### Movement Complexity
- Only **43% of push-up trials** achieved MAE below 5° (PMC 11566680)
- 70.9% of trials had positional error below 30 mm — meaning ~30% do not

#### Lighting
- Mean IoU drops from ~88% (controlled indoor) to ~79% (outdoor night)
- Low light causes motion blur destroying edge features the neural network requires

#### 3D Models
- High-complexity 3D BlazePose models introduce **severe distortions** from the 3D-uplifting process
- Progressive accuracy degradation as model complexity increases — counterintuitive finding (ResearchGate 398607117)

### Comparison to Gold Standard

- MediaPipe vs. Qualisys optical motion capture: Pearson r = 0.80 ± 0.1 (lower limb), 0.91 ± 0.08 (upper limb)
- Strong for research-grade exploration, **weak for clinical decision-making**

### FMS-Specific Validation

**Only one study exists**: SOMA (2024), an exploratory study using MediaPipe to extract joint ROM from FMS videos.
- Concluded it could "identify compensatory movements and distinguish between correct and incorrect performances"
- Authors explicitly disclaim validation: "further research is required to establish its validity and reliability relative to clinician-based ocular inspection and gold-standard motion capture systems"
- **No ICC values, sensitivity/specificity, or RMSE reported**

### Known Bias Gaps

- **No disaggregated accuracy data by skin tone or BMI** exists in published BlazePose literature
- Original BlazePose paper (2020) acknowledges "a variety of appearances or outfits" as a known challenge but provides no data
- This is a documented gap, not a cleared concern

### Implications for Capstone

- **Adequate for triage**: Target findings (knee valgus >10°, L-R asymmetry >10°) are above the noise floor for hip and knee
- **Ankle-dependent findings should carry reduced confidence** and the tool should say so
- **Do not claim "2–3 degree accuracy"** — cite the joint-specific controlled figures and acknowledge real-world degradation
- **Per-joint confidence scoring** is a genuine technical contribution — most tools don't surface their own uncertainty
- **Setup guidance is essential**: frontal view, well-lit, fitted clothing, warn when tracking quality degrades

### Sources

1. Improving Gait Analysis Techniques with Markerless Pose Estimation Based on Smartphone Location. [PMC 10886083](https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/)
2. MediaPipe-based extraction of joint ROM for the FMS: An exploratory study. [SOMA](https://soar.usa.edu/phjpt/vol4/iss3/2/)
3. Accuracy Evaluation of 3D Pose Reconstruction Algorithms Through Stereo Camera Fusion. [PMC 11644880](https://pmc.ncbi.nlm.nih.gov/articles/PMC11644880/)
4. Commercial Vision Sensors and AI-Based Pose Estimation: A Mini Review. Frontiers in Physiology 2025. [Frontiers](https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2025.1649330/full)
5. A Comprehensive Analysis of ML Pose Estimation Models: A Narrative Review. [PMC 11566680](https://pmc.ncbi.nlm.nih.gov/articles/PMC11566680/)
6. A Deep Dive Into MediaPipe Pose for Postural Assessment: A Comparative Investigation. [ResearchGate](https://www.researchgate.net/publication/398607117)
7. BlazePose: On-device Real-time Body Pose Tracking (original paper). [arXiv 2006.10204](https://arxiv.org/abs/2006.10204)
8. Efficient Human Pose Estimation: Leveraging Advanced Techniques with MediaPipe. [arXiv](https://arxiv.org/html/2406.15649v1)

---

## Part 5: Why This Integration Doesn't Exist

*Source: why-the-gap-exists.md*

### Summary: Five Independent Barriers

The integration gap is not a single oversight — it is five compounding barriers, each independently sufficient to prevent the connection.

| # | Barrier | Type | Key Evidence |
|---|---------|------|-------------|
| 1 | Hill-type model lock-in | Architectural | 1D muscle models structurally can't represent chains |
| 2 | CV benchmark culture | Incentive | MPJPE/PCK optimize for position, not clinical meaning |
| 3 | FDA classification wall | Regulatory | Causal claims trigger full SaMD regulation |
| 4 | Thin fascial evidence | Scientific | Force limited to ~10cm; SFL has zero evidence |
| 5 | Two-communities problem | Disciplinary | Practitioners can't code; engineers don't know fascia |

---

### Barrier 1: Biomechanics Paradigm Lock-in

Hill-type muscle models have dominated computational biomechanics since 1938. They are 1D lumped-parameter models that treat each muscle as an independent actuator — with no architectural capacity for cross-body connective tissue force transmission (Dao & Ho Ba Tho, 2018; Seth et al., 2018).

OpenSim, AnyBody, and all major musculoskeletal simulation platforms use this paradigm. The framing of muscle force estimation as joint-by-joint redundancy resolution makes fascial chain thinking categorically incompatible without paradigm-level reframing (PMC 10521397).

Critically, Dao & Ho Ba Tho's 2018 systematic review of muscle modeling does **not** list fascia or myofascial force transmission as a modeling gap — the field does not frame fascial exclusion as a problem to solve.

The 2018 BJSM consensus statement (Zugel, Wilke, Hodges et al.) identifies no gold standards for fascial assessment, and explicitly calls for "a coordinated effort of researchers and clinicians combining mechanobiology, exercise physiology and improved assessment technologies" — acknowledging neither the tools nor the interdisciplinary structure currently exist.

**Sources:**
- Dao & Ho Ba Tho (2018). Systematic Review of Continuum Modeling of Skeletal Muscles. *Applied Bionics and Biomechanics*. [PMC 6305050](https://pmc.ncbi.nlm.nih.gov/articles/PMC6305050/)
- Seth et al. (2018). OpenSim: Simulating musculoskeletal dynamics. *PLOS Computational Biology*. [PMC 6061994](https://pmc.ncbi.nlm.nih.gov/articles/PMC6061994/)
- Zugel, Wilke, Hodges et al. (2018). Fascial tissue research in sports medicine: consensus statement. *BJSM*. [PMC 6241620](https://pmc.ncbi.nlm.nih.gov/articles/PMC6241620/)
- PMC 10521397 (2023). Biomechanical modeling for muscle force estimation.
- Journal of Applied Physiology (2017). Not merely a protective packing organ? [DOI](https://journals.physiology.org/doi/full/10.1152/japplphysiol.00565.2017)

---

### Barrier 2: Computer Vision Incentive Misalignment

CV researchers optimize for MPJPE and PCK — metrics measuring joint localization accuracy, not clinical utility. Most clinical assessments need 3D joint angles, yet the field optimizes for position-based metrics (Kinetix, 2023).

Open-source pose estimation (MediaPipe, OpenPose) was never designed for biomechanics — training datasets are "inconsistently and inaccurately labelled" for biomechanical purposes, and use requires deep learning expertise most clinicians lack (PMC 8884063).

The field explicitly positions measurement as the terminal deliverable. A Frontiers survey frames pose estimation as "an assistive tool for clinicians rather than an automatic machine" (Frontiers in Computer Science, 2023). A clinician's viewpoint "has not received adequate consideration or representation, and applications of pose estimation have not been contextualized within current models of clinical care" (PMC 8588262).

No standardized method exists to map motion capture data to clinical assessment scales — "the bridge between kinematic output and clinical scoring systems does not yet exist as a formalized methodology" (PMC 12158133).

Academic ML research volume is "aligned with academic incentives rather than clinical needs" — in one review of 62 ML studies in medical imaging, none had potential for clinical use (PMC 9005663).

The tools' origins compound this: CV and markerless motion capture were "often driven by entertainment industry needs" — gaming, animation, and sports broadcasting created tools optimized for visual plausibility, not clinical precision (Sports Medicine Open, 2018).

**Sources:**
- PMC 8884063. Applications and limitations of markerless motion capture for clinical gait biomechanics.
- PMC 8588262. Applications of Pose Estimation in Human Health and Performance across the Lifespan.
- PMC 12158133. Towards Intelligent Assessment in Personalized Physiotherapy with Computer Vision.
- PMC 9005663. Machine learning for medical imaging: methodological failures and recommendations.
- Frontiers in Computer Science (2023). Markerless human pose estimation for biomedical applications: a survey. [Link](https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2023.1153160/full)
- Sports Medicine Open (2018). Evolution of vision-based motion analysis. [DOI](https://link.springer.com/article/10.1186/s40798-018-0139-y)

---

### Barrier 3: FDA Regulatory Moat

DARI Motion's FDA 510(k) clearance (March 2019) limits intended use to "quantifying and graphically displaying human movement patterns" for pre/post rehabilitation evaluation — no causal or diagnostic claims (Orthopedics This Week).

Under the FDA 21st Century Cures Act, CDS software escapes device regulation only if it meets all four statutory criteria (21 U.S.C. § 360j(o)(1)(E)): (1) not intended to acquire, process, or analyze a medical image or a signal/pattern from a signal acquisition system; (2) intended to display, analyze, or print medical information; (3) intended to support or provide recommendations to a healthcare professional about prevention, diagnosis, or treatment; (4) intended to enable the HCP to independently review the basis for recommendations. Critically, Criterion 1 defines "medical image" to include "images that were not originally acquired for a medical purpose but are being processed or analyzed for a medical purpose" — meaning a phone camera video processed through pose estimation for movement risk assessment could be classified as a medical image, blocking the CDS exemption at the threshold (FDA CDS Guidance, Jan 2026).

Separately, the FDA's January 2026 **General Wellness** guidance (distinct from the CDS guidance) states that products using non-invasive sensing to estimate physiological parameters qualify as general wellness products only if they do not "include claims, functionality, or outputs that prompt or guide specific clinical action or medical management." Software making causal movement-dysfunction claims would likely fail this standard as well (Arnold & Porter, Jan 2026; Triage Health Law, Feb 2026).

SaMD clinical evaluation requires three pillars: valid clinical association, analytical validation, and clinical validation showing outcomes benefit. The clinical association pillar cannot be met given the current state of myofascial meridian research (Greenlight Guru).

Product liability for AI-enabled medtech applies under three theories: manufacturing defect, design defect, and failure to warn — making fascial chain causal outputs a direct liability vector (Sidley Austin, 2024).

All major commercial platforms (DARI Motion, Kinetisense, VueMotion) uniformly restrict to joint-level kinematics with no reference to fascial tissue — a consistent, deliberate design pattern.

**Sources:**
- FDA (Jan 2026). Clinical Decision Support Software — Guidance for Industry and FDA Staff. [FDA.gov](https://www.fda.gov/media/109618/download)
- FDA (Jan 2026). General Wellness: Policy for Low Risk Devices — Guidance. [FDA.gov](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications)
- Orthopedics This Week. FDA Clears First Markerless Motion Analytic System. [Link](https://ryortho.com/breaking/fda-clears-first-markerless-motion-analytic-system/)
- Arnold & Porter (Jan 2026). FDA Cuts Red Tape on CDS Software. [Link](https://www.arnoldporter.com/en/perspectives/advisories/2026/01/fda-cuts-red-tape-on-clinical-decision-support-software)
- Triage Health Law (Feb 2026). FDA Continues to Ease Regulatory Hurdles for Wearable Health Products. [Link](https://www.triagehealthlawblog.com/fda/fda-continues-to-ease-regulatory-hurdles-for-wearable-health-products/)
- Frier Levitt (Mar 2026). FDA Clarifies Regulatory Pathway for Clinical Decision Support Software. [Link](https://www.frierlevitt.com/articles/fda-clinical-decision-support-software-guidance/)
- Sidley Austin (2024). Product Liability Considerations for AI-Enabled Medtech. [Link](https://www.sidley.com/en/insights/publications/2024/01/product-liability-considerations-for-ai-enabled-medtech)
- Greenlight Guru. SaMD Clinical Evaluation. [Link](https://www.greenlight.guru/blog/samd-clinical-evaluation)
- PMC 4832222. Use of Clinical Movement Screening Tests to Predict Injury in Sport.

---

### Barrier 4: Fascial Chain Evidence Gaps

See also: Part 3 (Fascial Chain Science Deep Dive) for the full evidence review.

**Key skeptical arguments:**

Greg Lehman argues force transmission along fascial lines has maximum reach of ~10cm based on cadaveric studies (Vleeming 1995, Van Wingerden 2004), directly undermining whole-body chain dysfunction claims. He also argues fascial lines are "arbitrarily created during dissection" — dissection artifacts, not pre-existing structures.

Wilke et al. (2016) found **zero** anatomical evidence for the Superficial Front Line across seven studies. The Lateral Line (2/5 transitions) and Spiral Line (5/9 transitions) have significant gaps.

Cadaveric studies are methodologically compromised: formalin fixation increases collagen cross-linking, freezing/thawing alters tendon modulus, and traction in fascicle direction doesn't mimic muscular contraction (Krause et al., 2016).

Only 2 of 9 studies in the Krause systematic review were in vivo. The primary evidence base does not reflect living mechanical behavior.

Tom Myers himself conceded that "hard evidence of effects from bodywork or movement training, however attractive intuitively, is so far lacking" and that certain connections will likely be modified in future iterations (Anatomy Trains, 2018).

In vivo studies use functional outcomes (ROM) as proxies — a "black box" where causal conclusions about chain-mediated transmission cannot be drawn (Wilke et al., 2016).

**Sources:**
- Lehman (2012). Fascia Science blog post. [Link](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)
- Krause et al. (2016). Intermuscular force transmission along myofascial chains. *Journal of Anatomy*. [PMC 5341578](https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/)
- Wilke et al. (2016). What Is Evidence-Based About Myofascial Chains. *Archives of Physical Medicine and Rehabilitation*. [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)
- Bordoni & Myers (2020). Review of Theoretical Fascial Models. *Cureus*. [PMC 7096016](https://pmc.ncbi.nlm.nih.gov/articles/PMC7096016/)
- Myers (2018). Anatomy Trains: Fact or Fiction? [Link](https://www.anatomytrains.com/blog/2018/11/12/anatomy-trains-fact-or-fiction-tom-myers-responds/)

---

### Barrier 5: Knowledge Translation Failure

Tacit clinical knowledge is "in principle ineliminable" from practice — even explicit guidelines require implicit judgment to apply correctly (Wittgenstein's rule-following argument; PMC 1475611).

The deeper a domain expert's knowledge, the less able they are to describe their own logic — experts rationalize and reconstruct during articulation, producing misleading descriptions (Purdue ABE 565).

Clinical decision support systems face a named "two communities" problem: researchers and practitioners come from distinct worlds with different cultures, values, timelines, and reward structures (Cambridge Judge Business School).

Clinical reasoning in physical therapy is "qualitatively different" from physician diagnosis — it focuses on movement patterns and functional behavior that resist discrete categorical encoding (Physical Therapy, 2004).

Experienced clinicians actively resist CDSS — they are less likely to use and more likely to override such systems. 74% of organizations with CDSS report financial viability as a persistent struggle. 93% of CMIOs report at least one CDSS malfunction (NPJ Digital Medicine, 2020).

The PT software market ($3.8B projected by 2034) is focused almost exclusively on practice management, billing, and scheduling — not clinical reasoning encoding (Precedence Research).

**Sources:**
- PMC 1475611. Tacit knowledge as the unifying factor in EBM and clinical judgement.
- PMC 7005290. Overview of clinical decision support systems. *NPJ Digital Medicine* (2020).
- PMC 1307157. Medical Expert Systems — Knowledge Tools for Physicians (Shortliffe, 1986).
- Medical Law Review (2023). AI and clinical decision support: trust and liability. [DOI](https://academic.oup.com/medlaw/article/31/4/501/7176027)
- Physical Therapy (2004). Clinical Reasoning Strategies in Physical Therapy. [DOI](https://academic.oup.com/ptj/article/84/4/312/2805347)
- Cambridge Judge Business School. Knowledge translation in healthcare. [PDF](https://www.jbs.cam.ac.uk/fileadmin/user_upload/research/workingpapers/wp1005.pdf)

---

### Research Gaps

- No first-person accounts from CV researchers explaining why they stop at measurement
- No direct company statements from DARI, Kinetisense, or Uplift Labs on fascial chain exclusion decisions
- No documented case study of a failed attempt to encode manual therapy reasoning into software
- No quantitative data on disciplinary composition of movement software teams

---

## Part 6: Citation Network Analysis

*Source: citation-silo-evidence.md — Empirical evidence for the silo barrier (Barrier 5)*

### Method

Seven landmark papers across three fields — computer vision pose estimation, biomechanics/sEMG, and fascial chain science — were selected and their citing papers pulled from the [Semantic Scholar Academic Graph API](https://www.semanticscholar.org/product/api). Each citing paper was classified by field using keyword matching on title and venue (CV: pose estimation, deep learning, keypoint, etc.; Biomechanics: EMG, musculoskeletal, gait analysis, joint angle, etc.; Fascial: fascia, myofascial, connective tissue chain, etc.). Papers not matching any field were classified as "Other."

**Limitation**: Keyword classification is approximate. "Other" includes papers from adjacent fields (rehabilitation, sports science, robotics, etc.) that don't match the keyword sets. The analysis captures directional patterns, not exact percentages.

### Papers Analyzed

| Paper | Field | Total Citations | Citations Analyzed |
|-------|-------|---------------:|-------------------:|
| Bazarevsky et al. 2020 (BlazePose) | CV | 788 | 788 |
| Cao et al. 2019 (OpenPose) | CV | 5,407 | 1,000 |
| Merletti et al. 2021 (sEMG Barriers) | Biomechanics | 8 | 8 |
| Hewett et al. 2005 (ACL Predictor) | Biomechanics | 3,598 | 1,000 |
| Seth et al. 2018 (OpenSim) | Biomechanics | 1,041 | 1,000 |
| Wilke et al. 2016 (Myofascial Chains) | Fascial | 258 | 258 |
| Krause et al. 2016 (Force Transmission) | Fascial | 17 | 17 |

Source: Semantic Scholar API, queried April 2026. For papers with >1,000 citations, the API returns a sample of 1,000.

### Cross-Citation Matrix

|  | Cited by CV | Cited by Biomechanics | Cited by Fascial |
|--|:-----------:|:---------------------:|:----------------:|
| **CV papers** (n=1,788 classified) | **531 (29.7%)** | 91 (5.1%) | **0 (0.0%)** |
| **Biomechanics papers** (n=2,008 classified) | 18 (0.9%) | **1,075 (53.5%)** | 1 (0.05%) |
| **Fascial papers** (n=275 classified) | **0 (0.0%)** | 23 (8.4%) | **106 (38.5%)** |

### Key Findings

#### 1. CV ↔ Fascial: Complete Isolation

**Zero citations in either direction.** Out of 2,063 classified citations across both fields combined, not a single fascial chain paper cites a CV pose estimation paper, and not a single CV paper cites fascial chain research. These fields have never acknowledged each other's existence in the academic literature.

- BlazePose (788 citations): 0 from fascial chain research
- OpenPose (5,407 citations): 0 from fascial chain research
- Wilke 2016 (258 citations): 0 from CV research
- Krause 2016 (17 citations): 0 from CV research

#### 2. Biomechanics ↔ CV: Minimal, Asymmetric

CV papers are occasionally cited by biomechanics researchers (5.1%), but biomechanics papers are almost never cited by CV researchers (0.9%). The relationship is one-directional: biomechanics borrows CV tools, but CV doesn't look at biomechanics problems.

- Hewett's landmark ACL predictor paper (3,598 total citations) — cited by only 5 CV papers
- OpenSim (1,041 total citations) — cited by only 13 CV papers

#### 3. Biomechanics ↔ Fascial: Thin Bridge

Fascial chain papers receive some biomechanics citations (8.4% — 23 of 275), mostly because Wilke 2016 is classified in a rehabilitation/physical medicine journal that biomechanics researchers occasionally read. But biomechanics papers are almost never cited by fascial researchers (0.05% — 1 out of 2,008).

#### 4. Each Field Cites Itself

- CV papers: 29.7% of citations come from other CV researchers
- Biomechanics papers: 53.5% from other biomechanics researchers
- Fascial papers: 38.5% from other fascial chain researchers

The remainder in each case is "Other" — adjacent fields (robotics, rehabilitation, sports science, clinical medicine) that don't fall neatly into the three categories.

### What This Means for the Capstone

The integration this tool proposes — connecting CV pose estimation to fascial chain reasoning — has **zero precedent in the citation record**. This isn't a gap that's slowly closing. It's a wall between fields that have never had a reason to reference each other.

This transforms the capstone framing from "we built a thing" to "we identified a quantifiable coordination failure across three academic fields and built the first bridge." The citation data makes the silo argument empirical rather than anecdotal.

### Suggested Citation for the Capstone

"A citation analysis of 7 landmark papers across computer vision, biomechanics, and fascial chain science (4,071 classified citing papers via Semantic Scholar, April 2026) found zero cross-citations between computer vision and fascial chain research in either direction. Biomechanics papers were cited by CV researchers in only 0.9% of cases. The three fields required to build an integrated movement screening tool have no history of academic exchange."

---

## Part 7: Competitive Landscape

*Source: ai-movement-screening-landscape.md*

### Key Findings

1. Automated FMS scoring from video reaches ~91% accuracy in research settings, but no commercial product ships a validated, consumer-ready automated FMS scoring pipeline.
2. Several commercial tools ship and are in active clinical use — none incorporate fascial chain or myofascial meridian logic.
3. No evidence across academic literature, commercial products, or research prototypes (2023–2026) exists of any tool that maps automated biomechanical screening findings onto fascial lines. **The novelty claim holds.**

### Commercial Tools That Ship

#### Kinetisense
- Most feature-complete clinical tool in the space
- Formal FMS partnership with an Advanced Movement Screen (KAMS) — 12 assessments in 3 minutes using markerless 3D capture from a single camera
- Outputs joint ROM across 40+ measurements, symmetry scores
- Since January 2024: AI-driven "Corrective Engine" that auto-prescribes exercises
- Framework: tri-planar biomechanical analysis backed by 150+ peer-reviewed papers
- **Not fascial chain logic**

#### DARI Motion
- Only FDA-cleared markerless motion analysis system (8-camera setup)
- Used in orthopaedic and sports performance clinics
- Six output categories: motion health, performance, mobility, alignment, sway, force — all kinematic/kinetic
- No causal or root cause mapping framework in public documentation

#### Newer Consumer-Facing Entrants
- **Uplift Labs**: iPhone, sports performance focus
- **VueMotion**: Tested 80,000+ athletes, smartphone + cones setup, targeting normative database (H2 2025)
- **Model Health**: Two iOS devices, $1M pre-seed (2025), targeting rehab clinics
- All focus on quantifying movement patterns (joint angles, velocities, ground contact time) without interpretive causal frameworks

### Browser-Based Consumer Tools

- Browser-based tools using MoveNet, PoseNet, or BlazePose via TensorFlow.js exist as open-source libraries and demos
- No validated consumer product for clinical movement screening ships browser-native
- Commercial products require iOS apps (Uplift, Model Health) or proprietary hardware (DARI)
- YOLO11 Pose (late 2024) and DETRPose (2025) are current production-grade pose models but remain infrastructure, not screening products

### Automated FMS Scoring State of the Art

- **LLM-FMS dataset** (March 2025, PLOS ONE): 1,812 keyframe images from 45 subjects across all 7 FMS movements with hierarchical annotation
- Best published accuracy: **91% using LLM-based prompting** over skeleton keypoints, vs. 80–89% for prior deep learning methods
- Limitations: keyframe-based (not full-video), requires expert-designed prompts, still needs manual annotation to train
- No study validates automated FMS against clinical inter-rater reliability at scale
- 2024 multi-view deep neural network study: kappa of 0.640 (moderate agreement with human raters)

### Why the Fascial Chain Gap Exists

Fascial chains are a manual assessment framework requiring palpation and clinical interpretation — they have not been reduced to computable joint-angle rules. The AI movement screening field operates entirely on skeletal keypoint kinematics, which maps naturally to quantifiable geometric outputs. Fascial tension, load transmission along meridians, and tissue quality are not observable from video.

### Key Gaps in This Research

- Kinetisense's internal "FPM mapping tool" could not be fully characterized from public sources — may contain kinetic chain logic not described in marketing
- DARI Motion's proprietary AI interpretation layer is not publicly documented
- No preprints or conference papers (2023–2026) attempt to encode Anatomy Trains logic into a computable model, even as a prototype
- Browser-native validated screening tools may exist in clinical pilot deployments not captured by public search

### Sources

1. LLM-FMS: A fine-grained dataset for FMS action quality assessment. PLOS ONE. [PMC 11896072](https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/)
2. LLM-FMS full text. [PLOS ONE](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0313707)
3. Kinetisense KAMS Module. [kinetisense.com](https://www.kinetisense.com/modules/kinetisense-advanced-movement-screen/)
4. Kinetisense FMS Partnership. [kinetisense.com](https://www.kinetisense.com/fms-kinetisense/)
5. DARI Motion. [darimotion.com](https://darimotion.com/)
6. Model Health Portable Motion Capture. [modelhealth.io](https://www.modelhealth.io/portable-motion-capture)
7. Anatomy Trains. [anatomytrains.com](https://www.anatomytrains.com/about-us/)
8. VueMotion. [vuemotion.com](https://www.vuemotion.com/)
9. Uplift Labs. [uplift.ai](https://www.uplift.ai/)
10. Frontiers Systematic Review: Camera-based mobile apps for movement screening. [Frontiers](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full)
11. Markerless vision-based FMS evaluation with deep neural networks. [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2589004223027827)

---

## Part 8: Source Verification Appendix

*Compiled from: verification-results.md, pmc-crosscheck-results.md, audit-verdict.md*

This appendix summarizes what was verified, what was corrected, and what was cut across all research documents through four rounds of fact-checking.

### Overview of Verification Activity

| Round | Scope | Tool/Method |
|-------|-------|-------------|
| Round 1 | 7 priority claims from initial research angles | Full-text retrieval of primary sources |
| Round 2 | 16 unique PMC/PubMed citations in research-all-findings.md | Abstract/full-text cross-check |
| Round 3 | Document-level audit across all 7 docs | Source-by-source verdict (KEEP/FIX/CUT) |
| Round 4 | FDA guidance precision; Merletti citation structure | Primary source retrieval (FDA PDF, Frontiers Neurology) |

---

### What Was CUT

#### PMC12864725 (Hybrid IMU-sEMG, 92.3% accuracy) — REMOVED from all documents

This paper had severe methodological red flags and was removed from the ML Accuracy Benchmarks table in research-all-findings.md:

1. **"[insert sEMG system name if available]"** literally left in the published text — authors forgot to fill in their sensor name
2. **Joint angle numbers contradict themselves**: Abstract says 125° knee during running; supplementary figures say 45.2°
3. **No control group** — using "quasi-control" from warm-up data
4. **Suspiciously round muscle force numbers**: 150 N, 170 N, 230 N
5. **Mixed pilot and main study data** — consumer wearable data (n=4) alongside main study (n=50)

The remaining three rows in the ML benchmarks table (Random Forest 87.5%, CNN 91%, LSTM <5% MAE) all come from PMC12383302 and are fully verified.

#### Athos 37% deviation claim — FABRICATED, never used in these documents

A "37% deviation during squat-to-stand transitions" attributed to "a 2018 study in Journal of Electromyography and Kinesiology" originated from an Alibaba product insight article. The article quoted "Dr. Lena Torres, Biomechanist & Lead Researcher, UC San Diego Neuromuscular Lab" — a person who does not appear in any academic database. The figure does not appear in any peer-reviewed study. The only peer-reviewed Athos validation (Lynn et al. 2018, JSSM) found comparable performance to research-grade sEMG in controlled isokinetic conditions, but 18% of data sets were discarded for poor electrode contact. Athos ceased consumer operations in 2021 after acquisition by Myontec (2019).

---

### What Was FIXED

#### Fix 1: Kalichman 2025 — "corroborated" → "independently confirmed"

Kalichman (2025) does **not** cite Wilke et al. (2016). The two reviews arrived at identical chain-level evidence hierarchies without referencing each other. This makes the agreement stronger (genuinely independent), not weaker. All documents changed to "independently confirmed by Kalichman (2025)."

#### Fix 2: 30% force transmission — in-vitro caveat confirmed

The "up to 30% of mechanical forces" figure from Kalichman (2025) is in-vitro only. Human in-vivo evidence remains limited. All documents use the "in-vitro" qualifier. The SBL row in research-all-findings.md specifies "cadaveric data" for the 7–69% force transfer figure (Krause et al. 2016).

#### Fix 3: FDA guidance precision

The original documents conflated two distinct FDA regulatory pathways:
- **CDS guidance (21st Century Cures Act, Jan 2026)**: The relevant blocking criterion is Criterion 1 — the definition of "medical image" explicitly includes images not originally acquired for a medical purpose but being processed for a medical purpose. A phone camera video processed for movement risk assessment could be classified as a medical image under this definition.
- **General Wellness guidance (Jan 2026)**: This separately prohibits products from including "claims, functionality, or outputs that prompt or guide specific clinical action or medical management."

These are different pathways with different criteria. The stronger argument for this tool is the **General Wellness exemption** (non-invasive, not diagnostic, does not substitute for a cleared device, output frames professional referral rather than specific clinical action).

#### Fix 4: Shoulder OR=3.25 — misattributed, corrected in table

PubMed 20601606 (Pacey et al. 2010) reports only **knee** injury outcomes (OR = 4.69). It contains no data on shoulder injuries or OR = 3.25. The shoulder OR = 3.25 figure was correctly attributed to PMC8077913 (Lunding et al. 2021, meta-analysis of 6 studies, 2,335 athletes; low quality evidence per GRADE). The table in research-all-findings.md was corrected accordingly.

#### Fix 5: Overall injury p-value — discrepancy noted

PMC6196975 reports p=0.74 in Table 3 but p=0.66 in its conclusion. The primary result (Table 3) is p=0.74. The document notes this discrepancy within the paper itself.

#### Fix 6: 2D video scoring claim — separated into two distinct metrics

PMC8595159 (the 2D qualitative scoring paper) was originally stated as ">96% classification accuracy (ICC >0.94)." These are actually two separate findings: (a) the integrated frontal plane assessment correctly classified 96–98% of athletes into high vs low KAM groups; (b) ICC 0.94–1.00 is for inter/intra-rater reliability of the 2D scoring criteria, not classification accuracy. The research-all-findings.md table now reads: "ICC 0.94–1.00 for inter/intra-rater reliability; integrated frontal plane assessment correctly classified 96–98%."

#### Fix 7: Proprioceptive deficits — "elbow" removed

PMC9397026 documents proprioceptive deficits at the **knee** and greater postural sway. Elbow data is not present. The text was changed from "at elbow and knee" to "at the knee."

#### Fix 8: Biotensegrity source — journal noted

PubMed 29317079 (Dischiavi et al. 2018) is published in *Medical Hypotheses* — a theoretical/speculative journal, not an empirical research journal. This is flagged in the text.

#### Fix 9: "30–50% injury rate reduction from fascial training" — removed or re-attributed

This claim appeared without a PMC ID or URL in the fascia section. It was reframed: multi-component exercise programs (strength + balance + neuromuscular conditioning) reduce sports injuries by ~27–66% depending on study design (PMC11988859: RR 0.73 for soccer; Lauersen et al. 2014: ~66% reduction for strength training), but this evidence is for general training programs, not fascial-specific interventions.

#### Fix 10: CV review "61 studies" — scope corrected

PMC12481449 (Pecoraro et al. 2025) is a systematic review of CV in **neurological movement disorders only** (Parkinson's, dystonia, tremor, etc.). The 61/71 studies all concern neurological conditions. The claim was reframed: the finding is not "only 61 studies applied CV to clinical movement assessment" — it is "no comparable systematic review exists for musculoskeletal CV applications, which itself is evidence of the silo."

#### Fix 11: Merletti vicious cycle — editorial synthesis, not a single study

The "vicious cycle" in sEMG clinical adoption is an editorial synthesis across an 18-paper special issue. The 28 interviewees come from Cappellini et al. (one of 18 papers); 35 respondents from Manca et al. Citation should read: "Merletti et al. (2021) synthesized findings across an 18-paper special issue (80 authors, 7 countries)."

---

### What Was VERIFIED AND KEPT

| Source | Key Claims Verified |
|--------|---------------------|
| PMC12383302 (scoping review) | 43.84% adequate validation; RF 87.5%; CNN 91%, 94% expert agreement; LSTM <5% MAE; gradient boosting > physiotherapists; LSTM 2.5 sessions before symptoms — all exact matches |
| PubMed 15722287 (Hewett ACL) | 2.5x abduction moment, 8°, 20% GRF, 73%/78% — all four numbers exact |
| PubMed 41639883 (Beighton video tool) | 91.9% sensitivity, 42.4% specificity, 125 adults — exact match |
| PMC12964768 (SHAP analysis) | 0.394, 0.218, 0.072 — exact match from Table 5 |
| PMC8558993 (hypermobile cutting) | 3.5° lower knee valgus, 4.5° greater external rotation — confirmed |
| PMC9474351 (deceleration) | 8.63° vs 1.66° hip adduction, 8.57° vs 0.65° knee valgus — exact match (from Dix et al. as cited within) |
| PMC10935765 (LSTM ACL) | AUC 0.88, balanced accuracy 0.80 — exact match |
| PMC11896072 (LLM-FMS) | 1,812 keyframes, 45 subjects, 91% accuracy, kappa 0.82 — all confirmed |
| PMC9397026 (proprioception) | Knee deficits, postural sway, 8-week improvement — confirmed (elbow data absent, removed) |
| PMC12400819 (taekwondo AI) | κ = 0.897 — exact match |
| PubMed 20601606 (hypermobility knee) | OR = 4.69 — confirmed |
| PMC6196975 (hypermobility injuries) | 50% injured 2–6 months; sprains p=0.03; 3 dislocations — all confirmed |
| Wilke et al. 2016 (chain counts) | Transition counts match across all documents; independently confirmed by Kalichman 2025 |
| FDA CDS Guidance Jan 2026 | 4 criteria, General Wellness pathway, single-recommendation discretion — all confirmed from primary source |
| Zone7 72.4% | Verified from case study; self-published (not peer-reviewed), retrospective, out-of-sample — caveats already present |

---

### Overall Research Quality Assessment

The research base is well-sourced, properly caveated, and honest about limitations. The fascial chain skepticism is presented fairly alongside supporting evidence. The competitive landscape analysis is thorough.

**Three actions carried out from audit recommendations:**
1. PMC12864725 cut from all documents — the weakest link, not needed (other three ML benchmarks from PMC12383302 are solid)
2. FDA guidance attribution fixed — CDS vs. General Wellness pathways now precisely distinguished
3. Unsourced "30–50% injury reduction" claim sourced and reframed with specific studies and correct mechanism attribution

---

## Master Reference List

All PMC, PubMed, DOI, and URL references from across all sections, deduplicated and alphabetized by author/title.

---

**Arnold & Porter (Jan 2026).** FDA Cuts Red Tape on Clinical Decision Support Software.
https://www.arnoldporter.com/en/perspectives/advisories/2026/01/fda-cuts-red-tape-on-clinical-decision-support-software

**Bazarevsky, V. et al. (2020).** BlazePose: On-device Real-time Body Pose Tracking. arXiv 2006.10204.
https://arxiv.org/abs/2006.10204

**Bordoni, B. & Myers, T. (2020).** Review of Theoretical Fascial Models: Biotensegrity. *Cureus*. PMC 7096016.
https://pmc.ncbi.nlm.nih.gov/articles/PMC7096016/

**Cambridge Judge Business School.** Knowledge translation in healthcare.
https://www.jbs.cam.ac.uk/fileadmin/user_upload/research/workingpapers/wp1005.pdf

**Cao, Z. et al. (2019).** OpenPose: Realtime Multi-Person 2D Pose Estimation.
[Semantic Scholar]

**Dao, T.T. & Ho Ba Tho, M.C. (2018).** Systematic Review of Continuum Modeling of Skeletal Muscles. *Applied Bionics and Biomechanics*. PMC 6305050.
https://pmc.ncbi.nlm.nih.gov/articles/PMC6305050/

**DARI Motion.**
https://darimotion.com/

**Dischiavi, S.L. et al. (2018).** Rethinking Dynamic Knee Valgus and Its Relation to Knee Injury. *Medical Hypotheses*. PubMed 29317079.
https://pubmed.ncbi.nlm.nih.gov/29317079/

**FDA (Jan 2026).** Clinical Decision Support Software — Guidance for Industry and FDA Staff.
https://www.fda.gov/media/109618/download

**FDA (Jan 2026).** General Wellness: Policy for Low Risk Devices — Guidance.
https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications

**Frier Levitt (Mar 2026).** FDA Clarifies Regulatory Pathway for Clinical Decision Support Software.
https://www.frierlevitt.com/articles/fda-clinical-decision-support-software-guidance/

**Frontiers in Computer Science (2023).** Markerless Human Pose Estimation for Biomedical Applications: A Survey.
https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2023.1153160/full

**Frontiers in Pain Research (2025).** Fascia as a Dynamic Sensory and Mechanometabolic Organ.
https://www.frontiersin.org/journals/pain-research/articles/10.3389/fpain.2025.1712242/full

**Frontiers in Physiology (2025).** Commercial Vision Sensors and AI-Based Pose Estimation Frameworks: A Mini Review.
https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2025.1649330/full

**Frontiers in Sports and Active Living (2025).** Camera-based mobile apps for movement screening: systematic review.
https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full

**Greenlight Guru.** SaMD Clinical Evaluation.
https://www.greenlight.guru/blog/samd-clinical-evaluation

**Harper, D.J. et al. (2022).** Deceleration and Change of Direction. PMC 9474351.
https://pmc.ncbi.nlm.nih.gov/articles/PMC9474351/

**Hewett, T.E. et al. (2005).** Biomechanical Measures of Neuromuscular Control and Valgus Loading Predict ACL Injury. PubMed 15722287.
https://pubmed.ncbi.nlm.nih.gov/15722287/

**In Vivo Evidence of Myofascial Force Transmission Along the Posterior Spiral Chain (2026).** *Cureus*.
https://www.cureus.com/articles/453269

**Journal of Applied Physiology (2017).** Fascial tissue: not merely a protective packing organ?
https://journals.physiology.org/doi/full/10.1152/japplphysiol.00565.2017

**Kalichman, L. (2025).** Myofascial Continuity: Review of Anatomical and Functional Evidence. *Body Work and Movement Therapies*. PubMed 41316622.
https://pubmed.ncbi.nlm.nih.gov/41316622/

**Kinetisense KAMS Module.**
https://www.kinetisense.com/modules/kinetisense-advanced-movement-screen/

**Kinetisense FMS Partnership.**
https://www.kinetisense.com/fms-kinetisense/

**Krause, F. et al. (2016).** Intermuscular Force Transmission Along Myofascial Chains: A Systematic Review. *Journal of Anatomy*. PMC 5341578.
https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/

**Lehman, G. (2012).** Fascia Science: Stretching the Relevance of the Gluteus Maximus and Latissimus Dorsi Sling. greglehman.ca.
https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling

**LLM-FMS (2025).** A Fine-Grained Dataset for FMS Action Quality Assessment. *PLOS ONE*. PMC 11896072.
https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/

**LLM-FMS full text.** PLOS ONE.
https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0313707

**Lunding, J. et al. (2021).** Shoulder injury risk in hypermobile athletes. PMC 8077913.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8077913/

**LSTM-based automated video analysis — ACL patterns.** PMC 10935765.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10935765/

**Markerless vision-based FMS evaluation with deep neural networks.** ScienceDirect.
https://www.sciencedirect.com/science/article/pii/S2589004223027827

**Medical Law Review (2023).** AI and clinical decision support: trust and liability.
https://academic.oup.com/medlaw/article/31/4/501/7176027

**MediaPipe BlazePose original paper (2020).** Bazarevsky et al. arXiv 2006.10204.
https://arxiv.org/abs/2006.10204

**MediaPipe-based extraction of joint ROM for the FMS: An exploratory study.** SOMA (2024).
https://soar.usa.edu/phjpt/vol4/iss3/2/

**Merletti, R. et al. (2021).** sEMG Barriers — 18-paper special issue synthesis. *Frontiers in Neurology*.
[PMC7906963 — Frontiers in Neurology]

**Meta-analysis of ML for ACL prediction.** ScienceDirect S096801602500273X.
https://www.sciencedirect.com/science/article/pii/S096801602500273X

**Model Health Portable Motion Capture.**
https://www.modelhealth.io/portable-motion-capture

**Myers, T. (2018).** Anatomy Trains: Fact or Fiction?
https://www.anatomytrains.com/blog/2018/11/12/anatomy-trains-fact-or-fiction-tom-myers-responds/

**Myers, T.** Anatomy Trains.
https://www.anatomytrains.com/about-us/

**Myers Responds to Lehman's Fascia Science.** Anatomy Trains Blog (2015).
https://www.anatomytrains.com/blog/2015/06/03/fascia-mashers-and-fascia-bashers/

**NPJ Digital Medicine (2020).** Overview of clinical decision support systems. PMC 7005290.
https://pmc.ncbi.nlm.nih.gov/articles/PMC7005290/

**Orthopedics This Week.** FDA Clears First Markerless Motion Analytic System (DARI Motion, 2019).
https://ryortho.com/breaking/fda-clears-first-markerless-motion-analytic-system/

**Pacey, V. et al. (2010).** Generalized joint hypermobility and risk of lower limb joint injury. PubMed 20601606.
https://pubmed.ncbi.nlm.nih.gov/20601606/

**Pecoraro, V. et al. (2025).** Computer vision in movement disorders: systematic review. PMC 12481449.
[PMC12481449]

**Physical Therapy (2004).** Clinical Reasoning Strategies in Physical Therapy.
https://academic.oup.com/ptj/article/84/4/312/2805347

**PMC 1307157.** Medical Expert Systems — Knowledge Tools for Physicians (Shortliffe, 1986).
https://pmc.ncbi.nlm.nih.gov/articles/PMC1307157/

**PMC 1475611.** Tacit Knowledge as the Unifying Factor in Evidence-Based Medicine and Clinical Judgement.
https://pmc.ncbi.nlm.nih.gov/articles/PMC1475611/

**PMC 4832222.** Use of Clinical Movement Screening Tests to Predict Injury in Sport.
https://pmc.ncbi.nlm.nih.gov/articles/PMC4832222/

**PMC 6196975.** Hypermobility injury rates, recovery time, dislocation data.
https://pmc.ncbi.nlm.nih.gov/articles/PMC6196975/

**PMC 8558993.** Asymptomatic hypermobile athlete cutting mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/

**PMC 8588262.** Applications of Pose Estimation in Human Health and Performance across the Lifespan.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8588262/

**PMC 8595159.** 2D qualitative scoring system for deceleration / knee abduction moment classification.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8595159/

**PMC 8761154.** Deceleration and braking mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8761154/

**PMC 8884063.** Applications and Limitations of Markerless Motion Capture for Clinical Gait Biomechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC8884063/

**PMC 9005663.** Machine Learning for Medical Imaging: Methodological Failures and Recommendations.
https://pmc.ncbi.nlm.nih.gov/articles/PMC9005663/

**PMC 9397026.** Hypermobile individuals: proprioceptive deficits at the knee and postural sway.
https://pmc.ncbi.nlm.nih.gov/articles/PMC9397026/

**PMC 10069389.** Deceleration mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10069389/

**PMC 10521397 (2023).** Biomechanical modeling for muscle force estimation.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10521397/

**PMC 10586693.** Movement quality assessment.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10586693/

**PMC 10886083.** Improving Gait Analysis with Markerless Pose Estimation Based on Smartphone Location.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/

**PMC 10895398.** Deceleration mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC10895398/

**PMC 11504533 (Jiang et al. 2024).** sEMG + vision fusion for joint angle estimation.
https://pmc.ncbi.nlm.nih.gov/articles/PMC11504533/

**PMC 11566680.** A Comprehensive Analysis of ML Pose Estimation Models: A Narrative Review.
https://pmc.ncbi.nlm.nih.gov/articles/PMC11566680/

**PMC 11644880.** Accuracy Evaluation of 3D Pose Reconstruction Through Stereo Camera Fusion.
https://pmc.ncbi.nlm.nih.gov/articles/PMC11644880/

**PMC 11988859.** Multi-component training injury reduction (RR 0.73 for soccer).
https://pmc.ncbi.nlm.nih.gov/articles/PMC11988859/

**PMC 12158133.** Towards Intelligent Assessment in Personalized Physiotherapy with Computer Vision.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12158133/

**PMC 12200876.** Basketball prediction ML models systematic review (58%–98.9% accuracy range).
https://pmc.ncbi.nlm.nih.gov/articles/PMC12200876/

**PMC 12273744.** Deceleration mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12273744/

**PMC 12383302.** Scoping review: AI for sports biomechanics and injury prediction.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12383302/

**PMC 12400819.** Taekwondo AI judging kappa = 0.897.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12400819/

**PMC 12470057.** Fascia research.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12470057/

**PMC 12964768.** SHAP analysis: ACL Risk Score, Load Balance Score, Fatigue Score.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12964768/

**PMC 12378739.** Deceleration mechanics.
https://pmc.ncbi.nlm.nih.gov/articles/PMC12378739/

**PubMed 26281953 (Wilke et al. 2016).** What Is Evidence-Based About Myofascial Chains: A Systematic Review. *Archives of Physical Medicine and Rehabilitation*.
https://pubmed.ncbi.nlm.nih.gov/26281953/

**PubMed 27124264 (Wilke et al. 2016).** Remote Effects of Lower Limb Stretching: Preliminary Evidence for Myofascial Connectivity? *Journal of Bodywork and Movement Therapies*.
https://pubmed.ncbi.nlm.nih.gov/27124264/

**PubMed 41316622 (Kalichman 2025).** Myofascial Continuity: Review of Anatomical and Functional Evidence. *Body Work and Movement Therapies*.
https://pubmed.ncbi.nlm.nih.gov/41316622/

**PubMed 41639883.** Video-based Beighton score: 91.9% sensitivity, 42.4% specificity, 125 adults.
https://pubmed.ncbi.nlm.nih.gov/41639883/

**Remote myofascial interventions meta-analysis (2019).** *Journal of Sport Rehabilitation*.
https://journals.humankinetics.com/view/journals/jsr/29/5/article-p650.xml

**ResearchGate 398607117.** A Deep Dive Into MediaPipe Pose for Postural Assessment.
https://www.researchgate.net/publication/398607117

**Seth, A. et al. (2018).** OpenSim: Simulating Musculoskeletal Dynamics and Neuromuscular Control. *PLOS Computational Biology*. PMC 6061994.
https://pmc.ncbi.nlm.nih.gov/articles/PMC6061994/

**SHAP analysis — ACL risk predictors (2025).** *Nature*.
https://www.nature.com/articles/s41598-025-24144-y

**Sidley Austin (2024).** Product Liability Considerations for AI-Enabled Medtech.
https://www.sidley.com/en/insights/publications/2024/01/product-liability-considerations-for-ai-enabled-medtech

**Scoliosis1K dataset.** zhouzi180.github.io.
https://zhouzi180.github.io/Scoliosis1K/

**Sports Medicine Open (2018).** Evolution of vision-based motion analysis.
https://link.springer.com/article/10.1186/s40798-018-0139-y

**Triage Health Law (Feb 2026).** FDA Continues to Ease Regulatory Hurdles for Wearable Health Products.
https://www.triagehealthlawblog.com/fda/fda-continues-to-ease-regulatory-hurdles-for-wearable-health-products/

**Uplift Labs.**
https://www.uplift.ai/

**VueMotion.**
https://www.vuemotion.com/

**Wilke, J. et al. (2016).** What Is Evidence-Based About Myofascial Chains: A Systematic Review. *Archives of Physical Medicine and Rehabilitation*. PubMed 26281953.
https://pubmed.ncbi.nlm.nih.gov/26281953/

**Wilke, J. et al. (2016).** Remote Effects of Lower Limb Stretching: Preliminary Evidence for Myofascial Connectivity? *Journal of Bodywork and Movement Therapies*. PubMed 27124264.
https://pubmed.ncbi.nlm.nih.gov/27124264/

**Wilke et al. Evidence-Based Myofascial Chains.** Anatomy Trains resource.
https://www.anatomytrains.com/wp-content/uploads/2016/05/wilke-pdf.pdf

**Zone7 Injury Risk Forecasting Case Study.**
https://zone7.ai/case-studies/validation-study/validation-study-injury-risk-forecasting-with-zone7-ai/

**Zugel, M., Wilke, J., Hodges, P. et al. (2018).** Fascial Tissue Research in Sports Medicine: Consensus Statement. *BJSM*. PMC 6241620.
https://pmc.ncbi.nlm.nih.gov/articles/PMC6241620/

---

*Document compiled April 2026. All citations preserved exactly as they appear in source files. Four rounds of fact-checking applied. See Part 8 for full verification trail.*
