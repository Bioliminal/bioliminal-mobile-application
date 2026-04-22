# MoveScope: AI Movement Screening with Fascial Chain Intelligence

> **HISTORICAL — post-showcase product vision.** Describes the 4-movement fascial-chain screening product. That scope is post-showcase: the near-term deliverable is the showcase **Thu 2026-04-23 16:40** — single-movement bicep curl, pose-authoritative rep counting, three-channel cueing, no-hardware pose-only path. Authoritative scope: `bioliminal-ops/decisions/2026-04-22-showcase-scope.md`.

---

## The Problem

Movement screening costs $150-2,000 and requires a trained professional. Most athletes — especially youth and recreational — never get screened. They find out something's wrong when they get hurt.

Current AI movement tools can tell you *what's* happening ("your knee collapses"). They can't tell you *why*, or what to do about it. That interpretation — connecting a knee problem to its root cause in the ankle or hip — lives entirely in practitioners' heads.

## The Solution

A browser-based triage tool that runs from a phone camera. Four movements, five minutes. It detects biomechanical risk factors, maps them along validated fascial chains to identify likely root causes, and generates a personalized report.

**Same symptom. Different body. Different recommendation.**

| Person A | Person B |
|----------|----------|
| Knee valgus + ankle restriction + no hypermobility | Knee valgus + full ankle ROM + hypermobility markers |
| *"Your knee collapse is likely compensating for restricted ankle mobility. Mobilize your ankles first — knee valgus often resolves without direct knee work."* | *"Your joints have more range than average but your knee is collapsing under load. This is a stability issue, not mobility. Prioritize neuromuscular control training."* |

**This is not a diagnostic tool.** It identifies who should see a professional and gives them something specific to discuss when they do.

## Why This Doesn't Exist

A citation analysis of 7 landmark papers across computer vision, biomechanics, and fascial chain science (4,071 classified citing papers via Semantic Scholar, April 2026) found **zero cross-citations between computer vision and fascial chain research in either direction**. The three fields required to build this tool have no history of academic exchange.

Five independent barriers have prevented the integration:

| Barrier | Why It Blocks |
|---------|---------------|
| **Biomechanics paradigm lock-in** | Hill-type muscle models (1938-present) treat each muscle as independent — architecturally can't represent chains |
| **CV benchmark culture** | Pose estimation optimizes for position accuracy, not clinical meaning — measurement is the terminal deliverable |
| **FDA regulatory moat** | Causal claims trigger full SaMD classification; all commercial tools deliberately stop at kinematics |
| **Fascial evidence gaps** | Force transmission limited to ~10cm in cadaveric studies; skeptics have legitimate arguments |
| **Two-communities problem** | Practitioners can't code; engineers don't know fascial chains exist |

We're not fixing any of these barriers. We're building the interpretation layer that sits between them — using only the science that holds up, positioned as triage rather than diagnosis.

## The Science

We restrict chain mapping to the three pathways with strong anatomical evidence from multiple independent studies:

| Chain | Evidence | Verified Transitions | Independent Studies |
|-------|----------|---------------------|---------------------|
| Superficial Back Line | Strong | 3/3 | 14 |
| Back Functional Line | Strong | 3/3 | 8 |
| Front Functional Line | Strong | 2/2 | 6 |

*Source: Wilke et al. (2016), Archives of Physical Medicine and Rehabilitation. Independently confirmed by Kalichman (2025) — a separate review that does not cite Wilke yet reaches the same evidence hierarchy.*

We intentionally **exclude** the Spiral Line (moderate, 5/9), Lateral Line (limited, 2/5), and Superficial Front Line (zero evidence). This limits coverage but ensures every chain mapping has a validated anatomical basis.

### Engaging the Skeptics

Greg Lehman's critique — that fascial force transmission maxes out at ~10cm — targets direct mechanical chain effects. Our approach doesn't depend on long-range force transmission. We detect **co-occurring compensatory movement patterns** that practitioners empirically associate with chain dysfunction. Whether the mechanism is fascial tension, neuromuscular compensation, or habitual patterning, the observable video signature is the same.

## How It Works

```
Phone Camera → MediaPipe BlazePose (33 landmarks) → Joint Angle Analysis
    → Fascial Chain Mapping → Per-Joint Confidence Scoring → Personalized Report
```

1. **Capture**: 4 movements — overhead squat, single-leg balance, overhead reach, forward fold
2. **Track**: MediaPipe BlazePose extracts 33 body landmarks in real-time
3. **Analyze**: Joint angles flagged against published biomechanical thresholds (knee valgus >10deg, asymmetry >10deg)
4. **Map**: Co-occurring findings connected along three validated fascial chains to identify root causes
5. **Score**: Per-joint confidence (green/yellow/red) based on occlusion and tracking quality
6. **Report**: Personalized recommendations adapted to the individual's specific pattern

### Measurement Accuracy

| Joint | Controlled (MAE) | Real-World Estimate | Adequate for Triage? |
|-------|-------------------|--------------------|-----------------------|
| Hip | ~2.4deg | 5-10deg | Yes |
| Knee | ~2.8deg | 5-10deg | Yes |
| Ankle | ~3.1deg | 10deg+ (unreliable with occlusion) | Limited — flagged in output |

Our target findings are well above the noise floor for hip and knee. Ankle-dependent findings carry explicit reduced confidence.

## What We're Testing

Three unvalidated inferences that form the bridge between pose estimation and fascial chain science:

1. **Proxy hypothesis**: Can co-occurring joint angle patterns observable on video serve as proxies for what practitioners detect by touch?
2. **Threshold portability**: Do clinical thresholds from motion capture remain meaningful with 5-10deg real-world error?
3. **Chain attribution**: Is a chain-level root cause attribution more accurate than treating each finding independently?

### Validation

10 test subjects validated against 2-3 clinicians across three layers:

- **Layer 1**: Do our joint angle measurements match clinician observations?
- **Layer 2**: Do clinicians agree with our root-cause chain mapping?
- **Layer 3**: Is the chain-aware recommendation more useful than symptom-only output?

This is a feasibility demonstration — sufficient to surface which layer is failing, not to establish statistical reliability.

## Known Limitations

- **Ankle tracking unreliable** with occlusion or certain footwear — communicated in output
- **No bias data** — MediaPipe has published no disaggregated accuracy by skin tone or body type
- **Chain attribution has no ground truth** — we encode practitioner reasoning, not empirically validated causal pathways
- **Validation shows internal consistency**, not external validity — outcome tracking is Phase 2

## Tech Stack

Everything runs in the browser. No backend. Free to deploy.

- MediaPipe BlazePose (JavaScript SDK)
- HTML/CSS/JS or React
- HTML5 Canvas (skeleton overlay + confidence visualization)
- Rule-based decision trees (scoring + chain mapping)
- GitHub Pages or Vercel (free hosting)

## Team & Timeline

| Week | Deliverables |
|------|-------------|
| 1 | Pose estimation pipeline + overhead squat & single-leg balance scoring |
| 2 | Remaining movements + fascial chain mapping + report generation + UI |
| 3 | Confidence indicators + clinician validation on 10 subjects + demo |

| Person | Owns |
|--------|------|
| A | MediaPipe integration + skeleton overlay + confidence visualization |
| B | Joint angle math + movement threshold scoring |
| C | Fascial chain decision tree + compensation detection |
| D | Report generation + clinician validation + presentation |

## Future Vision

| Phase | What | Proves |
|-------|------|--------|
| **Phase 1** (Capstone) | Video-only, rule-based chain mapping | The reasoning layer works; proxy inference is plausible |
| **Phase 2** | Add surface EMG for key muscle groups | Ground truth for chain attribution — does video agree with direct muscle data? |
| **Phase 3** | Real-time visualization overlay | Skeleton + muscle activation heatmap — physically *see* how your body moves |

## The Novel Contribution

This is not an AI in the machine-learning sense. The intelligence is in the **rule system that encodes expert fascial chain logic** — translating reasoning that currently lives in practitioners' heads into computable rules that can run at scale, for free, on a phone.

No existing tool — commercial or academic — integrates fascial chain logic into automated movement screening. A systematic search of commercial platforms (Kinetisense, DARI Motion, Uplift Labs, VueMotion, Model Health) and academic literature through April 2026 confirms this gap. The citation network proves these fields have never talked to each other.

We're the bridge.
