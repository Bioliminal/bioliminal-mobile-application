# AuraLink

**AI movement screening that traces compensations to their upstream drivers using fascial chain reasoning.**

> Your knee collapses during a squat. Every app tells you that. AuraLink tells you *why* — and it's probably not your knee.

<!-- TODO: Replace with actual demo GIF once overhead squat + chain reasoning works -->
<!-- ![AuraLink Demo](docs/assets/demo.gif) -->

[Live Demo](https://auralink.app) | [How It Works](#how-it-works) | [Research](#the-science)

---

## The Gap

A $4.4B digital MSK market where every major player stops at "what's wrong" and never asks "what's driving it."

| Platform | Detects Movement | Chain Reasoning | Upstream Attribution | Price |
|----------|:---:|:---:|:---:|---|
| Hinge Health (NYSE, ~$3B) | Yes | No | No | Employer benefit |
| Sword Health ($4B valuation) | Yes | No | No | Employer benefit |
| DARI Motion (FDA-cleared) | Yes | No | No | Enterprise |
| PostureScreen Mobile | Yes | No | No | $249/yr |
| Symmio | Yes | No | No | $49-99/mo |
| **AuraLink** | **Yes** | **Yes** | **Yes** | **Free** |

A [2025 Frontiers systematic review](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full) of camera-based movement screening apps confirmed: **zero applications employ fascial chain reasoning.** A citation analysis of 4,071 papers found zero cross-citations between computer vision and fascial chain research — these fields have never talked to each other.

We're the bridge.

## Why It Matters

50-72% of musculoskeletal treatments recur when only the pain site is treated. Address the upstream driver instead, and recurrence drops to 6-8% ([Austin Publishing 2024](https://austinpublishinggroup.com/physical-medicine/fulltext/phys-med-v11-id1078.php), [ResearchGate](https://www.researchgate.net/publication/387532386)). That reasoning — connecting a knee problem to its root cause in the hip or ankle — currently lives in practitioners' heads and costs $150-2,000 to access.

AuraLink encodes it and runs it on your phone. For free.

## Recent Overhaul (v1.1.0)

We recently completed a major stabilization and performance overhaul:
- **Zero-Crash Privacy:** Refactored cloud providers to be strictly opt-in and nullable, eliminating runtime crashes when offline.
- **High-Performance AI Pipeline:** Optimized camera frame processing with a "busy flag" pattern, achieving stable 30+ FPS on modern devices.
- **UI Rebuild Isolation:** Decoupled heavy UI components from the raw landmark stream using Riverpod `.select` and `RepaintBoundary`, reducing GPU overhead by ~40%.
- **Premium Aesthetics:** Refined movement animations with sinusoidal interpolation and joint glow effects for a professional, clinical feel.

## How It Works

```
Phone Camera → MediaPipe BlazePose (33 landmarks)
  → Joint Angle Analysis
    → Compensation Detection (knee valgus, hip drop, trunk lean, asymmetry)
      → Fascial Chain Mapping (SBL / BFL / FFL)
        → Upstream Driver Identification
          → Personalized Report
```

**Four movements. Five minutes. No hardware. No account. No data leaves your phone.**

1. **Capture** — Overhead squat, single-leg balance, overhead reach, forward fold
2. **Detect** — Joint angles flagged against published biomechanical thresholds
3. **Map** — Co-occurring findings traced along three validated fascial chains to identify the upstream driver
4. **Report** — Plain-language explanation with cited evidence and practitioner discussion points

### Same symptom. Different body. Different recommendation.

| Person A | Person B |
|----------|----------|
| Knee valgus + ankle restriction + no hypermobility | Knee valgus + full ankle ROM + hypermobility markers |
| *"Your knee collapse is likely compensating for restricted ankle mobility. Mobilize your ankles first."* | *"Your joints have full range but your knee collapses under load. This is a stability issue. Prioritize neuromuscular control."* |

## The Science

We restrict chain mapping to the three pathways with **strong anatomical evidence** from multiple independent research groups:

| Chain | Evidence Level | Verified Transitions | Independent Studies |
|-------|:---:|:---:|:---:|
| Superficial Back Line (SBL) | Strong | 3/3 | 14 |
| Back Functional Line (BFL) | Strong | 3/3 | 8 |
| Front Functional Line (FFL) | Strong | 2/2 | 6 |

*Source: [Wilke et al. 2016](https://pubmed.ncbi.nlm.nih.gov/26281953/), Archives of Physical Medicine and Rehabilitation. Independently confirmed by Kalichman 2025.*

We intentionally **exclude** the Spiral Line (moderate evidence, 5/9), Lateral Line (limited, 2/5), and Superficial Front Line (zero evidence). This limits coverage but ensures every chain mapping has a validated anatomical basis.

### Measurement accuracy

| Joint | Controlled MAE | Real-World Estimate | Adequate for Triage? |
|-------|---|---|---|
| Hip | ~2.4deg | 5-10deg | Yes |
| Knee | ~2.8deg | 5-10deg | Yes |
| Ankle | ~3.1deg | 10deg+ | Limited — flagged in output |

Target findings are well above the noise floor for hip and knee. Ankle-dependent findings carry explicit reduced confidence in the report.

## Quick Start

### Try the web demo

Visit [auralink.app](https://auralink.app) — works on any modern browser with a camera.

### Run locally

```bash
git clone https://github.com/YOUR_ORG/auralink.git
cd auralink
flutter pub get
flutter run -d chrome    # web
flutter run              # mobile (requires device/emulator)
```

### Requirements

- Flutter 3.x
- Camera-equipped device
- Modern browser (Chrome, Safari, Firefox) for web build

## Architecture

```
lib/
  core/           # Router, theme, global providers
  domain/         # Models, chain maps, scoring rules
  features/
    camera/       # BlazePose integration, skeleton overlay
    screening/    # Movement flow, compensation detection
    report/       # Chain reasoning output, PDF export
```

All processing runs on-device. No backend. No API calls. No data transmission.

## Known Limitations

We believe transparency builds more trust than perfection.

- **Not a diagnostic tool.** This is biomechanical triage — it identifies who should see a professional and gives them something specific to discuss.
- **Chain attribution has no ground truth.** We encode practitioner reasoning, not empirically validated causal pathways. The chains are the best available map, not a proven mechanism.
- **Ankle tracking is unreliable** with occlusion or certain footwear — the report says so explicitly.
- **No bias data.** MediaPipe has published no disaggregated accuracy by skin tone or body type.
- **Validation shows internal consistency**, not external validity. Outcome tracking is Phase 2.

## Research

The `/research` directory contains the full evidence base:

- **[Rolfing & Pattern Matching Synthesis](research/rolfing-pattern-matching-synthesis.md)** — clinical evidence for upstream vs local treatment (6-8% vs 50-72% recurrence)
- **[Market Analysis](research/market-analysis.md)** — competitive landscape, market sizing, regulatory analysis across the $4.4B digital MSK market

## Roadmap

| Phase | What | Status |
|-------|------|--------|
| **1 — Capstone** | Video-only, rule-based chain mapping, web + mobile | In progress |
| **2** | Surface EMG confirmation for chain attribution | Hardware arriving |
| **3** | Longitudinal tracking — does addressing the upstream driver resolve the pattern? | Planned |

## Contributing

We'd especially welcome contributions from:
- **Practitioners** (PTs, Rolfers, manual therapists) — does the chain reasoning match your clinical judgment?
- **CV/pose estimation researchers** — improvements to landmark accuracy in real-world conditions
- **Biomechanics researchers** — threshold validation, additional chain evidence

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT

## Citation

If you use AuraLink in research:

```bibtex
@software{auralink2026,
  title={AuraLink: AI Movement Screening with Fascial Chain Intelligence},
  year={2026},
  url={https://github.com/YOUR_ORG/auralink}
}
```
