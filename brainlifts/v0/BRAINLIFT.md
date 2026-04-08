# AI Movement Screening Brainlift

## Owners
- Kelsi Andrews

## Purpose

### Purpose
The purpose of this BrainLift is to establish the cognitive design framework for a biomechanical movement screening tool that uses phone camera pose estimation to detect risk factors, maps them along validated fascial chains to identify likely root causes, and generates personalized reports. It is built on the core belief that **the body behaves as a connected system, not a collection of independent joints**, and that for movement screening, **the proxy between what a clinician detects and what a user understands is the design problem**. Existing movement tools either measure joints without interpretation (DARI Motion, Kinetisense), offer AI pose estimation without clinical reasoning (Uplift Labs, VueMotion), provide clinical assessment without automation (FMS), or attempt automation without chain-level root cause mapping (LLM-FMS at 91% accuracy but keyframes only, no chain logic). This product closes that gap: automated pose estimation + fascial chain reasoning + personalized triage reports that give users language for professional conversations.

### North Star
*"Can we make the body's chain-level behavior observable and actionable — first through video proxy, then through direct measurement?"*

### In Scope
- **Cognitive Design:** How the user thinks during each phase of interaction (cognitive map).
- **Decision Architecture:** Decision points and their cognitive load at every phase.
- **Confusion Prevention:** Where confusion occurs and how the design prevents it.
- **Proxy Design:** How the tool bridges between clinical assessment and user understanding.
- **Triage Framing:** How output is structured as conversation starters, not diagnoses.

### Out of Scope
- **Full Technical Architecture:** This focuses on the cognitive "why" and "what," not implementation. See capstone-complete.md for engineering details.
- **Asset Specifications:** Visual design details, skeleton overlay specs, and animation specs are separate.
- **Diagnosis or Treatment:** This is a triage tool. No FDA-regulated claims, no treatment protocols.
- **Weak-Evidence Chains:** Spiral Line (moderate), Lateral Line (limited), Superficial Front Line (none) are excluded.

## DOK 4 - Spiky Points of View (SPOVs)

- **SPOV 1: Chain-aware video triage catches systemic dysfunction that symptom-focused clinical visits miss.**
    - **Elaboration:** A 5-minute video screen provides a system-level view that time-constrained clinical encounters systematically miss — not because clinicians can't do it, but because the visit structure doesn't reward it. Clinical visits start with "my knee hurts" and examine the knee. Billing codes and time pressure don't reward tracing ankle restriction → knee valgus → hip drop → contralateral shoulder compensation. Zero cross-citations exist between CV and fascial chain research across 4,071 papers (Semantic Scholar, April 2026) — the integration has no precedent. The $3.8B PT software market builds billing tools, not clinical reasoning (Precedence Research). The tool's value is as a proxy between clinical assessment and user understanding: the user arrives at a professional visit saying "your tool found knee collapse + ankle restriction + hip drop along the same chain" instead of "my knee hurts." Output is structured as conversation starters for professional visits, not standalone conclusions.

- **SPOV 2: Clinical expertise is pattern matching, and pattern matching can be encoded in rules.**
    - **Elaboration:** 80% of clinical pattern recognition for movement screening can be captured in computable rules — that 80% is currently locked behind a $150-2000 paywall. What a skilled PT does is recognize co-occurring patterns: knee valgus + ankle restriction + hip drop = SBL involvement. The tacit knowledge literature says experts can't accurately describe their own logic — they rationalize and reconstruct (PMC 1475611). But the patterns are observable and enumerable. AI gradient boosting classifiers already detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302). LSTM networks detect injury-precursing changes ~2.5 sessions before symptoms. The irreducible 20% requiring touch, intuition, and patient history is why the tool refers to professionals rather than replacing them. The rule system encodes observable pattern matching, not diagnostic judgment.

- **SPOV 3: The body is a system, and treating joints independently produces wrong answers.**
    - **Elaboration:** Any screening tool that scores joints independently will give the right measurement and the wrong interpretation. The SBL connects plantar fascia through calves, hamstrings, and erector spinae to scalp fascia (3/3 transitions verified, 14 studies; Wilke 2016). The BFL connects lats through thoracolumbar fascia to contralateral glutes and vastus lateralis (3/3 verified, 8 studies). Whether the mechanism is fascial tension (Myers), neuromuscular compensation (Schleip), or habitual patterning — the observable co-occurrence is the same. Lehman's 10cm displacement limit attacks mechanical transmission, but Schleip's reframe of fascia as a sensory organ means the mechanism may be neurological, making the limit irrelevant. Hypermobile athletes show 3.5° lower valgus and 4.5° greater external rotation during the same movements (PMC8558993) — fixed thresholds calibrated on adult males systematically misclassify them. Hypermobility detection must modify the interpretation framework, not just the threshold values.

- **SPOV 4: This is a research instrument first — the product direction follows the data.**
    - **Elaboration:** The tool starts as an alpha test, not a product launch. We could be right, wrong, or on the verge of something completely different. Fascial chain science is stuck in the same vicious cycle Merletti documented for sEMG: no tools → no data → no validation → no tools (Frontiers in Neurology 2021, 18-paper special issue, 80 authors). This tool tests three hypotheses against a controlled alpha set with clinician validation: (1) can video-observable patterns proxy for what practitioners detect by touch? (2) do motion-capture thresholds remain meaningful with MediaPipe's 5-10° real-world error? (3) is chain-level attribution more accurate than treating findings independently? Every session logs raw landmarks, joint angles, confidence scores, chain attributions, and recommendations. If the proxy fails, we pivot to Phase 2 sEMG. The data determines the product, not the other way around.

## User/Player Cognitive Map

- **Phase 1: Landing — "Why should I do this?"** — Landing page: what the tool does, ~5 min, free, no account. User thinks: "I'm skeptical" OR "I'm excited." Decision: do I trust this? Confusion risk: may expect diagnosis, not triage. Design response: frame as "5-minute movement check," show sample report upfront, no jargon. (LOW load)

- **Phase 2: Camera Setup** — Camera permission + setup checklist (angle, lighting, clothing, distance). User thinks: "Ugh, so much work. Right angle? Right clothes?" Confusion risk: 5 simultaneous requirements; silent tracking failure. Design response: progressive validation one requirement at a time with green checkmarks; real-time skeleton overlay shows if tracking works; specific feedback ("try removing your jacket"). (HIGH load)

- **Phase 3a: First Movement (Overhead Squat)** — Live skeleton overlay + instructions + rep counter. User thinks: "This is so cool. Am I doing this right?" Confusion risk: watching skeleton instead of focusing on form; glitchy landmarks break trust. Design response: per-joint confidence colors (green/yellow/red); audio cue if landmark unreliable. (MEDIUM load)

- **Phase 3b: Movements 2-4 (Single-Leg Balance, Overhead Reach, Forward Fold)** — Same interface, different movement. User thinks: movement 2 still interested, movements 3-4 "how many more?" Confusion risk: boredom/fatigue; tracking issues (ankle occlusion in forward fold) erode trust. Design response: progress indicator ("2 of 4"); ~60 sec per movement; preliminary findings between movements ("We noticed something in your left hip"). (MEDIUM load)

- **Phase 4: Results / Report** — Personalized report: findings, chain mapping, confidence indicators, discussion points. User thinks: "Is this really for me? Can it tell this from a few moves? What do I do with this?" Confusion risk: chain language ("Superficial Back Line") means nothing; no clear next action = useless. Design response: body-path language ("knee → hip → lower back are connected") not chain names; confidence colors on every finding; 2-3 conversation starters ("Ask your PT about..."); print/share button. (HIGH load)

## Cognitive Load Analysis

- **Extraneous reduced:** All clinical terminology translated to body-part language ("knee → hip → lower back" not "Superficial Back Line"). Progressive validation in setup (one requirement at a time). Per-joint confidence colors for instant visual processing without reading.
- **Germane maximized:** Preliminary findings surfaced between movements to build narrative and active pattern discovery ("We noticed something in your left hip — let's check it in the next movement"). Report structured as a story of connected findings, not a list of scores.
- **Intrinsic managed:** One phase at a time. Setup requirements validated progressively. Movements capped at ~60 sec each. Report layered: summary first, details on expand. Working memory <4 items in early phases.

## Experts
- **Jan Wilke** (Fascial chain evidence hierarchy — SBL/BFL/FFL = strong; foundation for which chains we include)
- **Greg Lehman** (Most-cited fascial chain skeptic — 10cm displacement limit; every chain attribution must survive his argument)
- **Timothy Hewett** (ACL prediction landmark — 2.5x valgus moment; biomechanical findings validate chain patterns without chain language)
- **Robert Schleip** (Fascia as sensory organ — neurological mechanism reframe; fills Lehman's blind spot)
- **Thomas Myers** (Anatomy Trains creator — concedes evidence is lacking; framework we're encoding)

## DOK 3 - Insights

- **Insight 1: The body lies about where it hurts — and the design must prove it.** Users believe pain = problem location. The design answer is SHOWING co-occurring patterns they can verify: "Your knee collapses AND your ankle is restricted AND your hip drops." Credibility comes from pattern recognition, not assertion.

- **Insight 2: Absence of evidence is the research opportunity, not the disqualification.** Only 2 of 9 force transmission studies were in vivo (Krause 2016). Thin evidence for an under-tested model is different from thin evidence for a failed model. Willingness to find "this doesn't work" makes it research, not advocacy.

- **Insight 3: The video proxy works at triage — with constraints.** Hip/knee: 2-3° MAE controlled, 5-10° real-world. Ankles: unreliable (Pearson r as low as 0.45). Knee valgus >10° (2.5x ACL risk per Hewett 2005) is above the noise floor. Constrain what you measure (hip/knee), how (controlled setup, fitted clothing), and what you claim (triage).

- **Insight 4: Selective skepticism beats wholesale belief or rejection.** Restrict to 3 chains with strong evidence (SBL/BFL/FFL). Exclude 3 without (Spiral/Lateral/SFL). Be explicit about exclusions and why. Wilke (2016) and Kalichman (2025) independently converge on the same hierarchy without citing each other.

- **Insight 5: Lehman attacks the wrong mechanism, and Schleip explains why.** Lehman's 10cm limit demolishes mechanical transmission. But Schleip reframes fascia as a sensory organ — if the mechanism is neurological, the limit is irrelevant. The tool encodes the pattern, not the mechanism.

- **Insight 6: The sEMG adoption trap predicts the fascial evidence cycle.** Merletti's vicious cycle (no adoption → no data → no validation → no adoption) is the same trap fascial science is in. A free tool that logs every session breaks the data barrier. Even if chain logic is wrong, the dataset has value.

- **Insight 7: Fixed thresholds systematically fail underrepresented populations.** Hypermobile athletes show 3.5° lower valgus and 4.5° greater external rotation (PMC8558993). Women, youth, and rehabilitating individuals are least studied in pose estimation and biomechanics. Hypermobility detection must modify interpretation, not just thresholds.

## DOK 2 - Knowledge Tree

### Category 1: Fascial Chain Evidence

- **Subcategory 1.1: Anatomical Continuity (Supporting)**
    - **Source:** Wilke et al. (2016), *Archives of Physical Medicine and Rehabilitation*
    - **DOK 1:** SBL: 3/3 transitions verified, 14 studies — strong. BFL: 3/3 verified, 8 studies — strong. FFL: 2/2 verified, 6 studies — strong. Spiral: 5/9 — moderate. Lateral: 2/5 — limited. SFL: 0 — none.
    - **DOK 2:** Three of six chains have strong evidence; three do not. The divide is binary. Restricting to SBL/BFL/FFL is the only defensible position. Independently confirmed by Kalichman (2025) without citing Wilke.
    - **Link:** https://pubmed.ncbi.nlm.nih.gov/26281953/

- **Subcategory 1.2: Force Transmission (Challenging)**
    - **Source:** Krause et al. (2016), *Journal of Anatomy*
    - **DOK 1:** Only 9 of 1,022 articles met cadaveric force measurement criteria. SBL: 7-69% force transfer between biceps femoris and sacrotuberous ligament. Only 2 of 9 studies in vivo. Cadaveric preparation alters tissue properties.
    - **DOK 2:** Force evidence is thin and methodologically compromised, reflecting under-investigation not disproof. The primary evidence does not reflect living mechanical behavior.
    - **Link:** https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/

- **Subcategory 1.3: The Skeptical Case (Challenging)**
    - **Source:** Lehman (2012), greglehman.ca
    - **DOK 1:** Max mechanical displacement 4-10 cm. Lines may be arbitrary dissection artifacts. "Fascial adhesions" lack testable definition. Clinical extrapolation outruns evidence.
    - **DOK 2:** Lehman's displacement argument applies to mechanical transmission only. If the mechanism is neurological (Schleip), it attacks the wrong target. Lines with strong evidence (SBL/BFL/FFL) are empirically distinguishable from lines without.
    - **Link:** https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling

### Category 2: Pose Estimation Accuracy

- **Subcategory 2.1: Joint-Specific Performance (Supporting + Challenging)**
    - **Source:** PMC 10886083; PMC 11644880; PMC 11566680
    - **DOK 1:** Hip: 2.35° MAE — reliable. Knee: 2.82° MAE — reliable. Ankle: 3.06° MAE, Pearson r as low as 0.45 — unreliable with occlusion. Jacket spiked RMSE from 25mm to 54mm. Only 43% of push-up trials below 5° MAE. No disaggregated accuracy by skin tone or body type.
    - **DOK 2:** Hip/knee adequate for >10° threshold detection. Ankle unreliable. Real-world conditions double or triple error. Setup guidance and real-time tracking quality feedback are essential, not nice-to-haves.
    - **Link:** https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/

- **Subcategory 2.2: FMS Validation Gap (Challenging)**
    - **Source:** SOMA (2024)
    - **DOK 1:** Only FMS-specific study using MediaPipe. Explicitly exploratory with no accuracy claims. No ICC, sensitivity/specificity, or RMSE reported.
    - **DOK 2:** No published study validates MediaPipe for FMS-style scoring. Our tool enters unvalidated territory — both the risk and the research contribution.
    - **Link:** https://soar.usa.edu/phjpt/vol4/iss3/2/

### Category 3: Clinical Thresholds & Injury Prediction

- **Subcategory 3.1: ACL Risk Factors (Supporting)**
    - **Source:** Hewett et al. (2005)
    - **DOK 1:** Knee valgus >10° = 2.5x ACL risk (p<0.001). 8° greater abduction in injured athletes. 73% specificity, 78% sensitivity from abduction moment alone.
    - **DOK 2:** The 10° valgus threshold is well above MediaPipe's hip/knee noise floor. Strongest evidence that video triage can detect clinically meaningful risk factors.
    - **Link:** https://pubmed.ncbi.nlm.nih.gov/15722287/

- **Subcategory 3.2: Hypermobile Compensation (Challenging)**
    - **Source:** PMC8558993; PMC9397026
    - **DOK 1:** Hypermobile athletes: 3.5° lower minimum knee valgus, 4.5° greater peak external rotation vs controls. Neuromuscular adaptation, not structural difference. Proprioceptive deficits at knee (6.9° vs 4.6° passive error).
    - **DOK 2:** Hypermobile individuals move differently during the same tasks, within pose estimation error margins. Fixed thresholds will systematically misinterpret their patterns.
    - **Link:** https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/

### Category 4: The Integration Gap

- **Subcategory 4.1: Citation Silo Evidence (Supporting)**
    - **Source:** Semantic Scholar API analysis, April 2026
    - **DOK 1:** 4,071 classified citing papers across 7 landmark works. CV ↔ Fascial: zero citations either direction. CV ↔ Biomechanics: 0.9% one-directional. Each field cites itself (CV 29.7%, Biomechanics 53.5%, Fascial 38.5%).
    - **DOK 2:** The three fields needed for this tool have no history of exchange. The gap is structural — five compounding barriers, each independently sufficient.

- **Subcategory 4.2: Five Independent Barriers (Supporting)**
    - **Source:** Capstone composite analysis
    - **DOK 1:** (1) Hill-type models can't represent chains. (2) CV optimizes for MPJPE, not clinical meaning. (3) FDA blocks causal claims. (4) Fascial evidence has genuine gaps. (5) Two-communities problem.
    - **DOK 2:** Five compounding barriers explain why this tool doesn't exist. Overcoming it requires a team that speaks both clinical and technical languages.

### Category 5: Regulatory & Market Context

- **Subcategory 5.1: FDA Positioning (Challenging)**
    - **Source:** FDA CDS Guidance (Jan 2026), General Wellness Guidance (Jan 2026)
    - **DOK 1:** DARI Motion FDA 510(k): limited to "quantifying and displaying." General Wellness: must not "prompt or guide specific clinical action." All commercial platforms restrict to joint-level kinematics.
    - **DOK 2:** Output must be educational triage. "Ask your PT about X" is defensible; "do X for your knee" is not. This constraint aligns with the tool's value as a conversation starter.
    - **Link:** https://www.fda.gov/media/109618/download

### Category 6: Competitive Landscape

- **Subcategory 6.1: What Ships Today (Supporting)**
    - **Source:** Commercial landscape analysis, April 2026
    - **DOK 1:** Kinetisense: most feature-complete, FMS partnership, 40+ ROM measurements — not fascial chain logic. DARI Motion: only FDA-cleared, 8-camera — no causal mapping. LLM-FMS: 91% accuracy from keyframes — academic only, no chain reasoning. No browser-based validated consumer screening product exists.
    - **DOK 2:** No commercial or academic tool integrates fascial chain logic into automated movement screening. The novelty claim holds.
    - **Link:** https://www.kinetisense.com/modules/kinetisense-advanced-movement-screen/
