# BRAINLIFT
# AI Movement Screening Tool
*Bridging Computer Vision and Fascial Chain Science for Accessible Biomechanical Triage*

Cognitive Design & User Thinking Analysis
Version 1.0 — April 6, 2026

**Owners**
Kelsi Andrews

---

## Purpose

This tool exists to make the body's movement logic visible. Today, the connection between where it hurts and why it hurts lives exclusively in practitioners' heads. We're building the bridge from "your knee collapses" to "here's why, and here's what your body is actually doing" — starting with video inference, eventually backed by direct measurement (sEMG) and real-time visualization.

Movement screening costs $150–2000 and requires a trained professional. Most athletes — especially youth, women, and recreational — never get screened. They find out something's wrong when they get injured. The core bet is that video can be a reliable enough proxy for what clinicians detect by touch to make fascial chain reasoning accessible to anyone with a phone.

> **North Star**
> *"Can we make the body's chain-level behavior observable and actionable — first through video proxy, then through direct measurement?"*
> If the proxy doesn't hold, nothing downstream matters. Every design decision filters through this.

### In Scope

- Full 3-phase arc: video proxy (Phase 1) → sEMG validation (Phase 2) → real-time muscle visualization (Phase 3)
- 4 screening movements: overhead squat, single-leg balance, overhead reach, forward fold
- 3 validated fascial chains: Superficial Back Line (SBL), Back Functional Line (BFL), Front Functional Line (FFL)
- Triage-level confidence with per-joint uncertainty surfacing
- Personalized reports that give users language for professional conversations
- Hypermobility detection modifying interpretation framework
- Hardware-backed claims as the end state
- Data logging for hypothesis testing (proxy, threshold portability, chain attribution)

### Out of Scope

- Diagnosis, treatment prescription, or clinical-grade accuracy claims
- Chains with weak or no evidence: Spiral Line (moderate), Lateral Line (limited), Superficial Front Line (none)
- Replacing professional judgment
- Consumer medical device claims without validation data
- FDA-regulated diagnostic claims or SaMD classification

---

## DOK 4 — Spiky Points of View

*A Spiky POV is a well-reasoned, actionable, and often contrarian argument developed through the synthesis of multiple insights. It is "spiky" because it takes a strong, defensible stance. These drive the entire design.*

### SPOV 1: Chain-aware video triage catches systemic dysfunction that symptom-focused clinical visits miss

> **Assertion**
> A 5-minute video screen with chain logic provides a system-level view that time-constrained clinical encounters systematically miss — not because clinicians can't do it, but because the visit structure doesn't reward it.

A 15-minute clinical visit starts with the chief complaint: "my knee hurts." The clinician examines the knee. They may check the hip. They rarely trace a pattern from ankle restriction through knee valgus to hip drop to contralateral shoulder compensation. Not because they can't — but because the visit structure, billing codes, and time pressure don't reward it. The $3.8B physical therapy software market builds billing and scheduling tools, not clinical reasoning (Precedence Research). Clinical reasoning in physical therapy is "qualitatively different" from physician diagnosis — it focuses on movement patterns and functional behavior that resist discrete categorical encoding (Physical Therapy, 2004).

A video tool that runs 4 whole-body movements and maps co-occurring findings along validated chains surfaces the systemic pattern BEFORE the visit happens. The user arrives saying "your tool found knee collapse + ankle restriction + hip drop along the same chain" instead of "my knee hurts." This isn't worse-than-clinical — it's differently useful. It provides the system-level view that time-constrained clinical encounters systematically miss.

The citation analysis confirms the structural isolation: across 4,071 classified citing papers from 7 landmark works, there are zero cross-citations between computer vision and fascial chain research in either direction (Semantic Scholar, April 2026). The integration this tool proposes has no precedent in the academic record.

*Opponent*: Clinicians who argue that no automated tool can replace clinical reasoning. They're right — but the claim isn't replacement. It's that a 5-minute pre-visit screen gives the clinician a better starting point than "it hurts here."

**Design rule**: The tool's output must be structured as conversation starters for professional visits, not standalone conclusions. Every report ends with specific discussion points, not treatment plans.

---

### SPOV 2: Clinical expertise is pattern matching, and pattern matching can be encoded in rules

> **Assertion**
> 80% of clinical pattern recognition for movement screening can be captured in computable rules — and that 80% is what's currently locked behind a $150–2000 paywall.

What a skilled PT does during a movement assessment is recognize co-occurring patterns: knee valgus + ankle restriction + hip drop = SBL involvement. They've seen thousands of bodies and built internal models of which findings cluster together and what the clusters mean. The tacit knowledge literature says experts can't accurately describe their own logic — they rationalize and reconstruct during articulation, producing misleading descriptions of their actual reasoning process (PMC 1475611). But the PATTERNS they recognize are observable and enumerable.

You don't need the expert's self-description of their logic; you need the input-output pairs: "when you see these findings together, what do you conclude?" Those can be encoded. Not perfectly — the irreducible 20% that requires touch, intuition, and patient history is why the tool refers to professionals rather than replacing them. The "two communities" problem (Cambridge Judge Business School) means the people who understand fascial chains don't write software, and the people who write software don't know fascial chains exist. This tool bridges that gap by encoding the observable patterns, not the tacit judgment.

AI gradient boosting classifiers already detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302). LSTM networks detect injury-precursing mechanical changes ~2.5 training sessions before symptoms (PMC12383302). The technology to encode pattern matching exists — it just hasn't been connected to chain-level reasoning.

*Opponent*: Greg Lehman and the tacit knowledge researchers who argue that expert knowledge is "in principle ineliminable" from practice (Wittgenstein's rule-following argument). Also clinicians who see this as devaluing their expertise. 74% of organizations with CDSS report financial viability as a persistent struggle; 93% of CMIOs report at least one malfunction (NPJ Digital Medicine, 2020).

**Design rule**: The rule system encodes observable pattern matching, not diagnostic judgment. We will build explicit fascial chain decision trees mapping co-occurring findings to chain-level attributions. We will NOT encode treatment protocols, prognosis, or anything requiring patient history.

---

### SPOV 3: The body is a system, and treating joints independently produces wrong answers

> **Assertion**
> Any screening tool that scores joints independently will give the right measurement and the wrong interpretation. The design must never present a finding without its chain context.

Knee pain with forward shoulder rotation isn't two problems — it's likely one pattern. The SBL connects from plantar fascia through calves, hamstrings, and erector spinae to scalp fascia (3/3 transitions verified, 14 studies; Wilke 2016). The BFL connects lats through thoracolumbar fascia to contralateral glutes and vastus lateralis (3/3 transitions verified, 8 studies). When a shoulder rotates forward (lat shortening), the BFL pathway can create downstream effects through the hip to the contralateral knee. In-vitro studies show fascia can transmit up to 30% of mechanical forces (Kalichman 2025). A matched-pairs study (n=26) demonstrated that lower-limb stretching increased cervical ROM by ~5° (p<0.05), providing in-vivo support for remote effects along myofascial meridians (Wilke et al. 2016, JBMT).

Whether the mechanism is fascial tension (Myers), neuromuscular compensation (Schleip), or habitual patterning doesn't matter for the design — the observable co-occurrence is the same. Lehman's 10cm displacement limit challenges mechanical force transmission, but Schleip's reframing of fascia as a sensory organ — rich in proprioceptors and mechanoreceptors — suggests the mechanism may be neurological signaling, making the displacement limit irrelevant.

Hypermobile individuals make this even more complex: they show 3.5° lower minimum knee valgus and 4.5° greater peak knee external rotation during the same movements as controls (PMC8558993). Women, youth, and rehabilitating individuals are the least studied populations in both pose estimation and biomechanics research. MediaPipe has published no disaggregated accuracy data by skin tone or body type. A screening tool using fixed thresholds calibrated on adult male athletes will systematically misclassify these populations.

*Opponent*: Lehman, who argues the 10cm displacement limit means distant joints can't influence each other through fascia. Also the entire CV benchmark community, which treats each joint as an independent measurement (optimizing for MPJPE/PCK, not clinical meaning).

**Design rule**: The tool will NEVER present individual joint scores without chain context. Every finding is mapped to a chain pathway. Hypermobility detection modifies the interpretation framework, not just the threshold values.

---

### SPOV 4: This is a research instrument first — the product direction follows the data

> **Assertion**
> The tool starts as an alpha test, not a product launch. The data determines the future direction — we could be right, wrong, or on the verge of something completely different.

The fascial evidence gap exists because there's no scalable way to collect data. Merletti documented a vicious cycle in sEMG clinical adoption: clinicians won't adopt because research is thin, research stays thin because clinicians don't generate data (Merletti et al. 2021, Frontiers in Neurology — synthesis across 18-paper special issue, 80 authors, 7 countries). Fascial chain science is stuck in the exact same loop — no automated measurement tools → no scalable data collection → no validation studies → no tools.

This tool tests three unvalidated hypotheses against a controlled alpha set with clinician validation: (1) the proxy hypothesis — can co-occurring joint angle patterns observable on video serve as proxies for what practitioners detect by touch? (2) the threshold portability hypothesis — do clinical thresholds from motion capture remain meaningful with MediaPipe's 5–10° real-world error? (3) the chain attribution hypothesis — is chain-level root cause attribution more accurate than treating each finding independently?

Every session logs raw landmark coordinates, computed joint angles, confidence scores, chain attributions, and recommendations. The alpha determines the future direction. If the proxy hypothesis fails, we pivot to Phase 2 (sEMG validation) as the primary path. If chain attribution doesn't outperform symptom-only analysis, we know that too. The willingness to find "this doesn't work" is what makes it research rather than advocacy.

*Opponent*: Researchers who argue you can't collect valid data from uncontrolled consumer settings. Also teams that want to ship a product before proving the science.

**Design rule**: Alpha testing with clinician validation (10 subjects, 2–3 clinicians) before any public release. The data determines the product direction, not the other way around. We will NOT commit to a product direction the evidence doesn't support.

---

## User/Player Cognitive Map

*Break down exactly what the user is thinking, deciding, and potentially confused by during every phase of interaction.*

### Phase 1: Landing — "Why should I do this?" (LOW load)

| Dimension | Analysis |
|---|---|
| **User sees** | Landing page: what the tool does, ~5 min commitment, free, no account required |
| **User thinks** | "I'm skeptical. We'll see how this goes." OR "I'm excited, I hope this works." — split between curiosity and doubt |
| **Decision point** | Do I trust this enough to try it? (cognitive) |
| **Cognitive load** | LOW (2 items): what does it do + do I trust it |
| **Confusion risk** | Users may expect a medical diagnostic tool, not a triage screen. If framing is clinical, skeptics bounce. If too casual, they don't take results seriously. |
| **Design response** | Frame as "5-minute movement check" not "biomechanical screening." Show a sample report upfront so they know what they'll get. No jargon on landing page. |

### Phase 2: Camera Setup (HIGH load)

| Dimension | Analysis |
|---|---|
| **User sees** | Camera permission prompt, then setup checklist (frontal view, lighting, fitted clothing, distance, clear background) |
| **User thinks** | "Ugh, this is so much work. Am I wearing the right thing? Is this the right angle?" |
| **Decision point** | Is my setup good enough to continue? (spatial + cognitive) |
| **Cognitive load** | HIGH (5+ items): camera permission, angle, lighting, clothing, distance, background |
| **Confusion risk** | 5 simultaneous requirements. Users who are skeptical from Phase 1 drop off here. "This didn't work correctly, what am I doing wrong?" — if tracking fails silently, they don't know why. |
| **Design response** | Progressive validation: check one requirement at a time, confirm with green checkmark before moving to next. Show real-time skeleton overlay during setup so they can SEE whether tracking is working. If a jacket is causing problems, say so specifically. |

### Phase 3a: First Movement — Overhead Squat (MEDIUM load)

| Dimension | Analysis |
|---|---|
| **User sees** | Live skeleton overlay tracking their body + movement instructions + rep counter |
| **User thinks** | "Omg this is so cool. How does this work? Am I doing this right?" |
| **Decision point** | Am I performing the movement correctly? (spatial) |
| **Cognitive load** | MEDIUM (3–4 items): movement instructions, watching skeleton, self-monitoring form, rep count |
| **Confusion risk** | Excitement masks confusion. They may watch the skeleton more than focus on form. If tracking is glitchy (landmarks jumping), trust breaks immediately. |
| **Design response** | Skeleton overlay provides real-time feedback. Per-joint confidence colors (green/yellow/red) surface tracking quality. Brief audio or text cue if a landmark is unreliable. |

### Phase 3b: Movements 2–4 (MEDIUM load, declining engagement)

| Dimension | Analysis |
|---|---|
| **User sees** | Same interface, different movement (single-leg balance, overhead reach, forward fold) |
| **User thinks** | Movement 2: still interested. Movements 3–4: "How many more? Getting through it." |
| **Decision point** | Do I keep going or quit? (cognitive) |
| **Cognitive load** | MEDIUM (3 items): current movement instructions, how many left, am I doing this right |
| **Confusion risk** | Fatigue/boredom. Each movement adds time. If movement 3 has tracking issues (e.g., ankle occlusion during forward fold), they may lose faith in the whole system. |
| **Design response** | Progress indicator ("2 of 4 — almost done"). Keep each movement short (~60 sec). Surface interesting preliminary findings between movements to maintain engagement ("We noticed something in your left hip — let's check it in the next movement"). |

### Phase 4: Results / Report (HIGH load)

| Dimension | Analysis |
|---|---|
| **User sees** | Personalized report: findings, chain mapping visualization, confidence indicators, discussion points |
| **User thinks** | "Wow, is this really personalized for me? Can it really tell this from a few moves? Is it valid? What do I do with this information?" |
| **Decision point** | Do I believe this, and what do I do with it? (cognitive) |
| **Cognitive load** | HIGH (4+ items): understanding findings, understanding chain connections, evaluating confidence levels, deciding next steps |
| **Confusion risk** | Chain language ("Superficial Back Line") means nothing to users. If the report reads like a medical document, they either over-trust it or dismiss it. "What do I do with this information?" is the critical stuck point — if there's no clear next action, the report is interesting but useless. |
| **Design response** | Translate chains into body language: "Your knee → hip → lower back are connected" not "Superficial Back Line involvement." Confidence colors on every finding. End with 2–3 specific conversation starters: "Ask your PT about..." Clear call-to-action: print/share report, book with a professional, or try a recommended protocol. |

---

## Cognitive Load Analysis

### Cognitive Load by Phase

| Phase | Load | What the Brain Processes | How We Reduce It |
|---|---|---|---|
| Landing | Low | What does it do + do I trust it (2 items) | No jargon, sample report preview, clear time commitment |
| Camera Setup | High | Permission, angle, light, clothing, distance, background (5+ items) | Progressive validation — one requirement at a time with visual confirmation |
| First Movement | Medium | Instructions, skeleton, form, reps (3–4 items) | Real-time skeleton overlay, per-joint confidence colors, audio cues |
| Movements 2–4 | Medium | Instructions, progress, form (3 items) | Progress indicator, short movements (~60s), preliminary findings between movements |
| Results | High | Findings, chains, confidence, next steps (4+ items) | Plain language chain descriptions, confidence colors, specific conversation starters |

### Key Cognitive Load Principles Applied

- **Reduce extraneous load**: Translate all clinical terminology into body-part language the user already knows. "Your knee → hip → lower back are connected" not "Superficial Back Line involvement." No jargon on any user-facing surface.
- **Maximize germane load**: Surface preliminary findings between movements to build a narrative ("We noticed something in your left hip — let's check it"). This turns passive movement execution into active pattern discovery.
- **Manage intrinsic load**: Progressive disclosure in setup (one requirement at a time). Layered report (summary first, details on expand). Confidence colors provide instant visual processing without reading.

### Potential Confusion Points & Mitigations

| Potential Confusion | Why It Might Happen | Design Mitigation |
|---|---|---|
| "Is this a medical diagnosis?" | Clinical-sounding language creates false authority | Frame as "movement check" and "conversation starters." Explicit disclaimer visible at all times. |
| "The skeleton is glitchy — is this thing broken?" | MediaPipe tracking fails with loose clothing, poor lighting, or self-occlusion | Real-time confidence indicators per joint. If tracking degrades, surface specific guidance: "Try removing your jacket" or "Move to better lighting." |
| "What is a Superficial Back Line?" | Chain terminology is meaningless to non-practitioners | Never use chain names in user-facing output. Use body-path language: "ankle → knee → hip → lower back connection." |
| "What do I do with this report?" | Results without clear next steps feel academic | Every report section ends with a specific action: "Ask your PT about X" or "Try this 2-week protocol and report back." Print/share button prominent. |
| "I don't have the right clothes/space" | Setup requirements create barriers before value is demonstrated | Show sample results BEFORE setup to demonstrate value. Minimal viable setup: any well-lit room, shorts and t-shirt, phone propped 6ft away. |

---

## Experts

*A curated list of the leading thinkers, researchers, and practitioners whose work informs this BrainLift.*

### Expert 1: Jan Wilke

**Who**: Professor, Goethe University Frankfurt
**Focus**: Published the foundational systematic review (2016) establishing which fascial chains have anatomical evidence. Also ran the remote-effects RCT demonstrating lower-limb stretching improves cervical ROM. The most rigorous pro-chain researcher.
**Why Follow**: Wilke's evidence hierarchy (SBL/BFL/FFL = strong; Spiral = moderate; Lateral = limited; SFL = none) is the foundation for which chains we include and which we exclude. His insistence on evidence-based selectivity — not theoretical enthusiasm — models our approach.
**Where**: [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/), [PubMed 27124264](https://pubmed.ncbi.nlm.nih.gov/27124264/)

### Expert 2: Greg Lehman

**Who**: Physiotherapist, chiropractor, biomechanics researcher
**Focus**: Most widely-cited fascial chain skeptic. Argues force transmission maxes at ~10cm, fascial lines are arbitrary dissection artifacts, and clinical extrapolation outruns evidence.
**Why Follow**: Lehman is the strongest opponent of chain-based reasoning. His critiques define the boundaries of defensible claims. Every chain attribution in our tool must survive Lehman's displacement argument.
**Where**: [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)

### Expert 3: Timothy Hewett

**Who**: Professor, Mayo Clinic; biomechanics researcher
**Focus**: Landmark ACL prediction work — injured female athletes had 2.5x higher knee abduction moment, 8° greater valgus, 20% higher GRF (2005). Abduction moment alone: 73% specificity, 78% sensitivity.
**Why Follow**: Hewett's biomechanical findings map directly onto chain predictions without using chain language. His valgus-moment ACL prediction validates the pattern without needing fascial theory — making him a bridge between biomechanics and chain reasoning.
**Where**: [PubMed 15722287](https://pubmed.ncbi.nlm.nih.gov/15722287/)

### Expert 4: Robert Schleip

**Who**: Director, Fascia Research Group, Ulm University
**Focus**: Reframes fascia from mechanical tissue to a sensory organ — rich in proprioceptors and mechanoreceptors. Argues the mechanism of chain-level effects may be neurological signaling, not mechanical force transmission.
**Why Follow**: Schleip fills Lehman's blind spot. If the mechanism is neurological rather than mechanical, Lehman's 10cm displacement limit attacks the wrong target. This reframe is critical for defending why video-observable co-occurring patterns matter regardless of the underlying mechanism.
**Where**: [Frontiers in Pain Research 2025](https://www.frontiersin.org/journals/pain-research/articles/10.3389/fpain.2025.1712242/full)

### Expert 5: Thomas Myers

**Who**: Creator of the Anatomy Trains model
**Focus**: Proposed the myofascial meridian framework that maps continuous lines of connective tissue through the body. Concedes "hard evidence of effects from bodywork or movement training, however attractive intuitively, is so far lacking" (2018).
**Why Follow**: Myers created the theoretical framework we're encoding. His willingness to concede evidence gaps — and his statement that he would revise the model given contrary evidence — models the intellectual honesty our tool must maintain.
**Where**: [anatomytrains.com](https://www.anatomytrains.com/about-us/), [Anatomy Trains Blog](https://www.anatomytrains.com/blog/2018/11/12/anatomy-trains-fact-or-fiction-tom-myers-responds/)

### Expert 6: Leonid Kalichman

**Who**: Professor, Ben-Gurion University of the Negev
**Focus**: Published an independent narrative review of myofascial continuity (2025) that arrives at the same chain-level evidence hierarchy as Wilke — without citing Wilke. SBL/BFL/FFL = strongly supports; Spiral/Lateral = moderate; SFL = lacks validation.
**Why Follow**: Independent convergence on the same evidence hierarchy strengthens the case that the 3-chain restriction is scientifically defensible, not arbitrary.
**Where**: [PubMed 41316622](https://pubmed.ncbi.nlm.nih.gov/41316622/)

### Expert 7: Roberto Merletti

**Who**: Professor Emeritus, Politecnico di Torino
**Focus**: Documented the vicious cycle preventing clinical adoption of surface EMG — synthesized findings across an 18-paper special issue (80 authors, 7 countries) in Frontiers in Neurology (2021).
**Why Follow**: Merletti's sEMG adoption trap is the exact same cycle fascial chain science is stuck in. His work predicts the barriers we'll face in Phase 2 (sEMG validation) and explains why the data collection barrier must be broken first.
**Where**: [Frontiers in Neurology, PMC7906963](https://pmc.ncbi.nlm.nih.gov/articles/PMC7906963/)

### Expert 8: LLM-FMS Research Team (PLOS ONE 2025)

**Who**: Academic research team behind the first LLM-based FMS scoring pipeline
**Focus**: Achieved 91% accuracy (kappa 0.82) scoring Functional Movement Screens from skeleton keyframes using LLM-based prompting — the closest technical analog to what we're building.
**Why Follow**: Their work proves automated movement quality assessment from pose estimation keypoints is technically feasible. Their limitations (keyframe-only, no live video, no chain logic) define exactly the gap our tool fills.
**Where**: [PMC 11896072](https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/), [PLOS ONE](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0313707)

---

## DOK 3 — Insights

*Insights are the building blocks of the Spiky POVs. Each represents an original conclusion or connection generated after processing information from multiple sources.*

### Insight 1: The body lies about where it hurts — and the design must prove it

Users believe pain location equals problem location. Myers and every fascial practitioner says this too. But the design insight isn't that chains exist — it's that you have to SHOW someone their chain by surfacing co-occurring patterns they can see. "Your knee collapses AND your ankle is restricted AND your hip drops" is a pattern a user can verify against their own experience. The chain becomes credible not because you assert it but because the user recognizes the pattern in their own body. The design answer to breaking the mental model is evidence the user can feel, not claims they have to trust.

### Insight 2: Absence of evidence is the research opportunity, not the disqualification

Lehman is right that the evidence is thin. But thin evidence for a model that hasn't been adequately tested is different from thin evidence for a model that's been tested and failed. Only 2 of 9 force transmission studies were in vivo (Krause 2016). The SFL has zero evidence — but it also hasn't been studied with modern tools. This project doesn't assume chains are correct; it generates data that can confirm or falsify the proxy hypothesis. The willingness to find "this doesn't work" is what makes it research rather than advocacy.

### Insight 3: The video proxy can work at triage — but only with the right constraints

MediaPipe tracks hips and knees at 2–3° MAE in controlled conditions, degrading to 5–10° real-world. Ankles are unreliable (3° controlled, 10°+ with occlusion; PMC 10886083). But triage doesn't need clinical precision — it needs to correctly sort "probably fine" from "go see someone." Knee valgus >10° (2.5x ACL risk per Hewett 2005) is well above the noise floor for hip/knee tracking. The proxy works when you constrain what you measure (hip/knee, not ankle), how you measure it (controlled setup, fitted clothing, frontal camera), and what you claim (triage, not diagnosis). Phase 2 sEMG is the confirmation layer, not the rescue plan.

### Insight 4: Selective skepticism is stronger than wholesale belief or wholesale rejection

Wilke gets it right that you CAN establish chain-level evidence rigorously. Lehman gets it right that most chain claims outrun the evidence. The synthesis: restrict to the 3 chains with strong evidence (SBL/BFL/FFL), exclude the 3 without (Spiral/Lateral/SFL), and be explicit about what you're excluding and why. This is stronger than either camp alone — it's evidence-based selectivity rather than theoretical enthusiasm or blanket dismissal. The independent convergence of Wilke (2016) and Kalichman (2025) on the same evidence hierarchy — without citing each other — makes this selectivity empirically grounded.

### Insight 5: Lehman attacks the wrong mechanism, and Schleip explains why

Lehman's 10cm displacement limit demolishes the claim that fascia mechanically transmits force across the whole body. But Schleip's work reframes fascia as a sensory organ — rich in proprioceptors and mechanoreceptors (Frontiers in Pain Research 2025). If the mechanism is neurological signaling rather than mechanical force transmission, the 10cm limit is irrelevant. Whether the video-observable patterns reflect fascial tension, neuromuscular compensation, or habitual patterning, the observable signature is the same. The tool encodes the pattern, not the mechanism.

### Insight 6: The sEMG adoption trap predicts the fascial evidence cycle

Merletti documented a vicious cycle in sEMG: clinicians won't adopt because research is thin, research stays thin because clinicians don't generate data (Frontiers in Neurology 2021, 18-paper special issue). Fascial chain science is stuck in the exact same loop — no automated measurement tools → no scalable data collection → no validation studies → no tools. A free, browser-based screening tool that logs every session (landmarks, angles, confidence, chain attributions) breaks the data collection barrier. Even if the chain logic is wrong, the dataset has value.

### Insight 7: Fixed thresholds systematically fail hypermobile and underrepresented populations

Hypermobile athletes show 3.5° lower knee valgus and 4.5° greater external rotation during the same movements (PMC8558993). Women, youth, and rehabilitating individuals are the least studied populations in pose estimation and biomechanics research. MediaPipe has no published disaggregated accuracy by skin tone or body type. A screening tool using fixed thresholds calibrated on adult male athletes will systematically misclassify these populations. The design must account for this — hypermobility detection modifies the interpretation, not just the threshold.

---

## DOK 2 — Knowledge Tree

*The structured foundation of the BrainLift. Organized by category with DOK 1 facts and DOK 2 summaries from verified sources.*

### Category 1: Fascial Chain Evidence

#### Subcategory 1.1: Anatomical Continuity

Source: Wilke et al. (2016). "What Is Evidence-Based About Myofascial Chains." *Archives of Physical Medicine and Rehabilitation*.

DOK 1 — Facts:
- Superficial Back Line: 3/3 transitions verified across 14 studies — strong evidence
- Back Functional Line: 3/3 transitions verified across 8 studies — strong evidence
- Front Functional Line: 2/2 transitions verified across 6 studies — strong evidence
- Spiral Line: 5/9 transitions verified across 21 studies — moderate evidence
- Lateral Line: 2/5 transitions verified across 10 studies — limited evidence
- Superficial Front Line: 0 verified transitions across 7 studies — no evidence

DOK 2 — Summary: Three of six proposed myofascial meridians have strong, independently verified anatomical evidence. Three do not. The evidence hierarchy is not gradual — it's binary between the top three and the rest. Restricting a clinical tool to SBL, BFL, and FFL is not conservative; it's the only defensible position.

Link: [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)

#### Subcategory 1.2: Independent Confirmation

Source: Kalichman (2025). "Myofascial Continuity: Review of Anatomical and Functional Evidence." *Body Work and Movement Therapies*.

DOK 1 — Facts:
- Separate narrative review that does NOT cite Wilke
- Arrives at same hierarchy: SBL/BFL/FFL = strongly supports; Spiral/Lateral = moderate; SFL = lacks validation
- Reports fascia can transmit up to 30% of mechanical forces in vitro

DOK 2 — Summary: Independent convergence on the same evidence hierarchy from two unconnected research groups strengthens the case that the 3-chain restriction is scientifically defensible, not an artifact of one team's bias.

Link: [PubMed 41316622](https://pubmed.ncbi.nlm.nih.gov/41316622/)

#### Subcategory 1.3: Force Transmission

Source: Krause et al. (2016). "Intermuscular Force Transmission Along Myofascial Chains." *Journal of Anatomy*.

DOK 1 — Facts:
- Only 9 of 1,022 screened articles met criteria for direct cadaveric force measurement
- SBL: moderate evidence for force transfer at all three transitions (7–69% force transfer between biceps femoris and sacrotuberous ligament)
- Only 2 of 9 studies were in vivo
- Cadaveric preparation (formalin fixation, freezing) alters tissue mechanical properties

DOK 2 — Summary: The force transmission evidence base is thin and methodologically compromised by cadaveric preparation methods. The primary evidence does not reflect living mechanical behavior. This is a genuine limitation — but it reflects under-investigation, not disproof.

Link: [PMC 5341578](https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/)

#### Subcategory 1.4: The Skeptical Case

Source: Lehman (2012). "Fascia Science: Stretching the Relevance." greglehman.ca.

DOK 1 — Facts:
- Maximum mechanical displacement in cadaveric pull studies is 4–10 cm
- Lehman argues specific "lines" are arbitrary — dissection artifacts, not pre-existing structures
- "Fascial adhesions" that practitioners claim to release lack a clear, testable definition
- Clinical extrapolation outruns basic biomechanical evidence

DOK 2 — Summary: Lehman's strongest argument — the 10cm displacement limit — is specific to mechanical force transmission. If the mechanism is neurological (Schleip), the displacement argument is irrelevant. His argument about arbitrary line selection is weakened by the evidence hierarchy: lines with strong evidence (SBL/BFL/FFL) are empirically distinguishable from lines without (SFL).

Link: [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)

### Category 2: Pose Estimation Accuracy

#### Subcategory 2.1: Joint-Specific Accuracy

Source: PMC 10886083 — MediaPipe vs. marker-based motion capture during treadmill gait.

DOK 1 — Facts:
- Hip: 2.35° MAE, high Pearson r — most reliable
- Knee: 2.82° MAE, high Pearson r — reliable
- Ankle: 3.06° MAE, Pearson r as low as 0.45 — drops severely with contralateral leg occlusion
- Left-limb angles consistently more accurate than right due to camera-position-dependent occlusion
- Controlled treadmill conditions: fixed camera, consistent lighting, single-plane movement

DOK 2 — Summary: MediaPipe accuracy is joint-specific and condition-dependent. Hip and knee tracking are adequate for detecting findings above 10° thresholds. Ankle tracking is unreliable under real-world conditions. The controlled-condition numbers (2–3°) should never be cited as blanket accuracy claims.

Link: [PMC 10886083](https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/)

#### Subcategory 2.2: Real-World Degradation

Source: PMC 11644880 — Accuracy evaluation through stereo camera fusion.

DOK 1 — Facts:
- One subject's jacket spiked positional RMSE from 25–35 mm to 53.6 mm
- Monocular phone: median RMSE 56.3 mm; stereo: 30.1 mm
- Stereo knee angle RMSE: 7.7–10.3° during squats
- Only 43% of push-up trials achieved MAE below 5° (PMC 11566680)

DOK 2 — Summary: Real-world conditions can double or triple pose estimation error. Clothing is a particularly insidious factor because users won't know it's the problem. Setup guidance and real-time tracking quality feedback are essential design features, not nice-to-haves.

Links: [PMC 11644880](https://pmc.ncbi.nlm.nih.gov/articles/PMC11644880/), [PMC 11566680](https://pmc.ncbi.nlm.nih.gov/articles/PMC11566680/)

#### Subcategory 2.3: FMS Validation Gap

Source: SOMA (2024) — MediaPipe-based extraction of joint ROM for FMS.

DOK 1 — Facts:
- Only FMS-specific study using MediaPipe
- Explicitly exploratory with no accuracy claims
- Authors disclaim validation: "further research is required"
- No ICC values, sensitivity/specificity, or RMSE reported

DOK 2 — Summary: No published study validates MediaPipe for FMS-style scoring. Our tool enters unvalidated territory — which is both the risk and the research contribution.

Link: [SOMA](https://soar.usa.edu/phjpt/vol4/iss3/2/)

### Category 3: Clinical Thresholds & Injury Prediction

#### Subcategory 3.1: ACL Risk Factors

Source: Hewett et al. (2005). PubMed 15722287.

DOK 1 — Facts:
- Injured female athletes had 2.5x higher knee abduction moment (p<0.001)
- 8° greater knee abduction angle
- 20% higher ground reaction force
- Abduction moment alone: 73% specificity, 78% sensitivity

DOK 2 — Summary: Hewett's 10° valgus threshold is well above MediaPipe's hip/knee noise floor (5–10° real-world). This is the strongest evidence that video-based triage can detect clinically meaningful risk factors.

Link: [PubMed 15722287](https://pubmed.ncbi.nlm.nih.gov/15722287/)

#### Subcategory 3.2: Hypermobile Athlete Compensation

Source: PMC8558993 — Asymptomatic hypermobile athletes during cutting.

DOK 1 — Facts:
- 3.5° lower minimum knee valgus vs controls
- 4.5° greater peak knee external rotation
- Adaptation via neuromuscular control, not structural difference
- Hypermobile dancers approximate turnout using knee rotation instead of hip external rotators
- Hypermobile children show gastrocnemius-dominant landing strategy with reduced semitendinosus activity

DOK 2 — Summary: Hypermobile individuals move differently during the same tasks — and their differences fall within the error margin of many pose estimation systems. A tool using fixed thresholds will systematically misinterpret their movement patterns as "normal" when they may be compensating in ways that increase injury risk differently.

Links: [PMC8558993](https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/), [PMC9397026](https://pmc.ncbi.nlm.nih.gov/articles/PMC9397026/)

### Category 4: The Integration Gap

#### Subcategory 4.1: Citation Silo Evidence

Source: Citation network analysis via Semantic Scholar API, April 2026.

DOK 1 — Facts:
- 7 landmark papers analyzed across CV, biomechanics, and fascial chain science (4,071 classified citing papers)
- CV ↔ Fascial: zero citations in either direction
- Biomechanics ↔ CV: 5.1% (biomechanics cites CV) vs 0.9% (CV cites biomechanics) — one-directional
- Biomechanics ↔ Fascial: 8.4% (fascial cited by biomechanics) vs 0.05% (reverse)
- Each field primarily cites itself: CV 29.7%, Biomechanics 53.5%, Fascial 38.5%

DOK 2 — Summary: The three fields required to build an integrated movement screening tool have no history of academic exchange. This isn't a gap that's slowly closing — it's a wall between fields that have never had a reason to reference each other. The integration is genuinely novel.

#### Subcategory 4.2: Five Independent Barriers

Source: Composite analysis from capstone research (why-the-gap-exists.md).

DOK 1 — Facts:
- Barrier 1: Hill-type muscle models (since 1938) structurally can't represent cross-body chains
- Barrier 2: CV optimizes for MPJPE/PCK, not clinical meaning
- Barrier 3: FDA classification blocks causal claims (DARI limited to "quantifying and displaying")
- Barrier 4: Fascial evidence has genuine gaps (SFL = 0 evidence, displacement limit)
- Barrier 5: "Two communities" problem — practitioners can't code, engineers don't know fascia

DOK 2 — Summary: Five compounding barriers, each independently sufficient to prevent integration, explain why this tool doesn't exist. The gap is structural, not an oversight. Overcoming it requires a team that speaks both clinical and technical languages.

### Category 5: Regulatory & Market Context

#### Subcategory 5.1: FDA Positioning

Source: FDA CDS Guidance (Jan 2026), General Wellness Guidance (Jan 2026).

DOK 1 — Facts:
- DARI Motion FDA 510(k): limited to "quantifying and graphically displaying human movement patterns"
- CDS exemption Criterion 1: "medical image" includes images not originally acquired for medical purpose but processed for one
- General Wellness: must not "prompt or guide specific clinical action or medical management"
- SaMD clinical evaluation requires clinical association, analytical validation, and clinical validation
- All major commercial platforms restrict to joint-level kinematics — consistent deliberate design pattern

DOK 2 — Summary: The regulatory landscape forces a clear design constraint: the tool must frame output as educational triage that supports practitioner judgment, not as diagnostic or prescriptive. "Ask your PT about X" is defensible; "do X for your knee" is not. This constraint actually aligns with SPOV 1 — the tool's value is as a conversation starter, not a standalone conclusion.

Links: [FDA CDS Guidance](https://www.fda.gov/media/109618/download), [Arnold & Porter Jan 2026](https://www.arnoldporter.com/en/perspectives/advisories/2026/01/fda-cuts-red-tape-on-clinical-decision-support-software)

### Category 6: Competitive Landscape

#### Subcategory 6.1: What Ships Today

Source: Commercial landscape analysis, April 2026.

DOK 1 — Facts:
- Kinetisense: most feature-complete clinical tool, FMS partnership, 40+ ROM measurements, AI Corrective Engine — NOT fascial chain logic
- DARI Motion: only FDA-cleared markerless system (8-camera), 6 output categories — no causal mapping
- Uplift Labs, VueMotion, Model Health: smartphone-based, quantifying movement — no interpretive causal frameworks
- No browser-based validated consumer screening product exists
- Automated FMS from video: 91% accuracy (LLM-FMS) but academic only, static keyframes only

DOK 2 — Summary: The competitive landscape confirms the novelty claim: no commercial or academic tool integrates fascial chain logic into automated movement screening. The closest technical analog (LLM-FMS at 91%) proves keypoint-based movement assessment is feasible but stops at FMS scoring without chain reasoning.

Links: [kinetisense.com](https://www.kinetisense.com/modules/kinetisense-advanced-movement-screen/), [darimotion.com](https://darimotion.com/), [PMC 11896072](https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/)

---

## Key Assumptions

### User Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| Users can operate a smartphone camera | They need basic phone literacy to set up and run the screen | Users unable to complete setup or requiring extensive guidance |
| Users have or can access form-fitting clothing | Loose clothing degrades tracking accuracy by up to 2x (jacket: 25mm → 54mm RMSE) | High rate of poor tracking quality across sessions; users reporting "it didn't work" |
| Users are willing to spend 5 minutes doing 4 movements | The value proposition must be compelling enough to overcome setup friction | High dropout rate between Phase 2 (setup) and Phase 4 (results) |
| Users have adequate space and lighting | Minimum ~6ft clear space, decent lighting, phone propped at body height | Systematic tracking failures; per-joint confidence scores consistently red |

### Technology Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| Smartphone cameras meet minimum hardware requirements | MediaPipe BlazePose requires sufficient camera resolution and processing power | Certain phone models consistently produce unreliable tracking; need to identify minimum specs (possible Android/iPhone hardware constraints) |
| MediaPipe hip/knee tracking is reliable enough for 10°+ threshold detection | 5–10° real-world error must be below the clinical threshold we're detecting | Clinician validation shows flagged findings don't match clinical observation for hip/knee joints |
| Browser-based processing is fast enough for real-time overlay | JavaScript SDK must process frames without visible lag | Users report glitchy or delayed skeleton overlay, breaking trust in Phase 3 |

### Design Theory Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| Fascial chain patterns and joint issues are related | Co-occurring movement patterns along validated chains reflect real biomechanical relationships, whether the mechanism is fascial, neuromuscular, or habitual | Clinicians consistently disagree with chain attributions; no pattern correlation between co-occurring findings and chain pathways |
| The proxy hypothesis holds at triage level | Video-observable co-occurring patterns can serve as proxies for what practitioners detect by touch | Chain-aware recommendations are no more accurate than symptom-only descriptions when evaluated by clinicians |
| Hypermobility modifies interpretation meaningfully | Different thresholds/interpretation for hypermobile users produces better recommendations than fixed thresholds | Clinicians rate hypermobility-adjusted and fixed-threshold outputs equally |

**If the design theory assumptions fail**: The alpha testing will surface this. If chain attribution doesn't outperform symptom-only analysis, the pivot is toward supplemental hardware (Phase 2 sEMG) to ground-truth the proxy. The tool's architecture accepts scored inputs from any evidence source — the reasoning engine doesn't change, only the input quality.

---

## Self-Critique

- [x] Every SPOV has a named opponent
- [x] Every SPOV has a design rule that constrains a real decision
- [x] Every DOK 3 insight traces to DOK 2 sources but isn't a restatement of any one source
- [x] The cognitive map has all 6 dimensions for every phase
- [x] Working memory items are enumerated in each phase
- [x] Key assumptions have failure modes
- [x] DOK 2 sources include both supporting AND challenging evidence (Lehman, Krause methodological concerns, MediaPipe limitations)

**Flags**: None. All quality checks pass.

**Note**: The DOK 2 Knowledge Tree draws from the extensively fact-checked `research/capstone-complete.md` (4 rounds of verification, Part 8 source verification appendix). All PMC/PubMed numbers have been cross-checked against primary sources. Sources marked as verified in the research document are treated as verified here.

---

*BrainLift assembled April 6, 2026. Research base from capstone-complete.md (compiled April 2026, 4 rounds of fact-checking applied).*
