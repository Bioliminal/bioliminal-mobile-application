# BRAINLIFT
# AI Movement Screening Tool
*Upstream Compensation Identification Through Computer Vision and Fascial Chain Reasoning*

Cognitive Design & User Thinking Analysis
Version 1.0 — April 8, 2026

**Owners**
Kelsi Andrews

---

## Purpose

This tool makes upstream compensation reasoning — the clinical thinking behind 6-8% recurrence vs 50-72% — accessible to anyone with a phone. Today that reasoning lives in ~4,000 Rolfers and a subset of PTs trained in regional interdependence. The free movement screen (personalized report + recommended steps) is the gateway; the sEMG hardware is the product. Fascial chain reasoning is cited transparently where it informs the logic — the app shows its evidence, not hides it.

> **North Star**
> *"Can we identify upstream compensation drivers from dynamic movement video, and does addressing them reduce recurrence, prevent injury, and improve measurable muscle function — ultimately validated by sEMG?"*

### In Scope

- Dynamic movement assessment with fascial chain reasoning cited where relevant
- Freemium gateway: free personalized screen → paid sEMG hardware
- Stecco's CC/CP framework as the encodable logic model
- Three validation metrics: recurrence reduction, injury prevention, muscle measurement improvement
- Transparent evidence citations throughout the app
- Full 3-phase arc: video proxy (Phase 1) → sEMG validation (Phase 2) → real-time muscle visualization (Phase 3)
- 4 screening movements: overhead squat, single-leg balance, overhead reach, forward fold
- 3 validated fascial chains as internal reasoning scaffold: Superficial Back Line (SBL), Back Functional Line (BFL), Front Functional Line (FFL)
- Triage-level confidence with per-joint uncertainty surfacing
- Hardware-backed claims as the end state
- Data logging in controlled alpha for hypothesis testing

### Out of Scope

- Static posture assessment (debunked — Swain 2020)
- Injury prediction from screening scores alone (Bahr 2016)
- FDA-regulated diagnostic claims
- Fascial chain diagnosis as user-facing output (chains are the internal map, not the user-facing claim)
- Chains with weak or no evidence: Spiral Line (moderate), Lateral Line (limited), Superficial Front Line (none)
- Replacing professional judgment
- Unconsented or uncontrolled data collection

---

## DOK 4 — Spiky Points of View

*A Spiky POV is a well-reasoned, actionable, and often contrarian argument developed through the synthesis of multiple insights. It is "spiky" because it takes a strong, defensible stance. These drive the entire design.*

### SPOV 1: The app replaces clinical judgment for discovering where systemic dysfunction manifests

> **Assertion**
> "Just knowing" is pattern matching — and ML does pattern matching better at scale than trial and error across 3-4 PT visits.

"Just knowing" is the practitioner's term for pattern matching built through years of trial and error — see enough bodies, and you learn that knee valgus + hip drop + ankle restriction travel together. The tacit knowledge literature confirms experts can't accurately describe their own reasoning; they rationalize and reconstruct after the fact (PMC 1475611). But the input-output pairs — "when you see these findings together, the driver is upstream" — are observable and enumerable. AI gradient boosting classifiers already detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302). LSTM networks detect injury-precursing changes ~2.5 sessions before symptoms appear. The app is the hub of trial and error: ML doesn't need years of clinical experience to recognize that knee valgus clusters with hip drop along the SBL — it needs controlled, consented data with clinician validation, and the alpha generates exactly that. Stecco's CC/CP framework makes the reasoning encodable: detected compensation at joint X → trace upstream along the chain map → identify candidate driver at joint Y. The Gnat 2022 RCT validated this logic — CC-targeted treatment resolved pain in 1 session vs 3 for local-only. The app doesn't replace what happens AFTER discovery — the touch, the patient history, the clinical nuance. It replaces the 3-4 visit discovery cycle that currently burns patient time and money finding what pattern matching identifies immediately.

*Opponent*: PTs and clinicians who argue automated pattern matching cannot replace the discovery process that requires hands-on assessment and clinical training. Also Lehman's camp arguing the chain map guiding the pattern matching is itself arbitrary.

**Design rule**: The app surfaces upstream driver candidates on the first screen using ML pattern matching over the chain map. Discovery is never gated behind repeated assessments. The 20% requiring touch, history, and clinical nuance is where the tool refers to professionals — not before.

---

### SPOV 2: PT clinical reasoning and fascial chain science are causal, not correlative — the tool will prove or disprove it

> **Assertion**
> Two fields study the same phenomenon from opposite ends. The tool bridges them and tests whether the relationship is causal.

Two fields study the same phenomenon from opposite ends. PTs have decades of clinical evidence that treating upstream drivers works — hip strengthening resolves knee pain (Ferber n=199), SFMA-guided treatment drops recurrence from 50% to 6.25%, thoracic manipulation relieves neck pain better than local mobilization. Fascial chain science has anatomical evidence that these structures are physically connected — SBL 3/3 transitions verified across 14 studies (Wilke 2016), independently confirmed by Kalichman (2025) without citing Wilke. But zero cross-citations exist between CV and fascial chain research across 4,071 papers (Semantic Scholar, April 2026). The PT world knows upstream treatment works but doesn't map it to fascial anatomy. The fascia world maps the anatomy but has no scalable way to test whether the map predicts clinical outcomes. Five independent barriers — each sufficient alone — kept these fields apart: Hill-type models that can't represent chains, CV metrics that ignore clinical meaning, FDA blocking causal claims, genuine fascial evidence gaps, and the two-communities problem where practitioners can't code and engineers don't know fascia exists. Fascia is newly researched and it's easier to build products from what's already validated — which is why every funded platform (Hinge $3B, Sword $4B) built exercise-correction tools, not reasoning tools. The sEMG hardware closes the loop: CV detects the pattern, the chain map predicts which muscles should be involved, and sEMG measures whether they actually are. If the fascial map predicts the activation pattern, the relationship is causal. If it doesn't, we've disproved the hypothesis with controlled, consented data from alpha testing with clinician validation. Either outcome is publishable. Either outcome has value.

*Opponent*: Academics who argue you can't productize unvalidated science. Both fields' gatekeepers who don't see the other as relevant. The counter-evidence is real: force transmission explains only ~10% of remote tissue displacement variance (Nature Sci Rep 2023), within-chain ROM correlates weakly (r=0.32-0.44). The tool doesn't assume the causal link — it tests it.

**Design rule**: The alpha collects data in controlled environments with consented participants and clinician validation. Every session logs landmarks, angles, chain attributions, and sEMG activation data. The matched vs mismatched experiment — does the fascial map predict the measured activation pattern? — runs under research conditions. No user data is tracked without consent. We never assert the causal link before the data supports it.

---

### SPOV 3: Give away the reasoning, sell the confirmation — credibility doesn't have to be locked behind a paywall

> **Assertion**
> The reasoning layer should be free. The physical measurement that confirms it is the product.

Every competitor charges for the screening itself: PostureScreen $249/yr, DARI enterprise-only, FMS $599, Symmio $49-99/mo, MyoVision ~$4,000 hardware. The entire industry assumes the reasoning is the product. It's not — the confirmation is. A free, personalized movement screen with chain-level reasoning and actionable steps is genuinely valuable on its own. That's why people use it, that's why they share it, that's why instructors group-share it with clients. The premium tier is the sEMG hardware that CONFIRMS the pattern isn't just visual — it's muscular. Advanced longitudinal tracking that shows change over time. Practitioner features for clinical use. The free experience isn't a teaser or a demo — it's complete. The gaming industry proved this model at scale: Fortnite generated $9.1B from a free game. Riot Games pulls $1.75B/year from a free game. The core experience is world-class and free, premium features are irresistible but optional. Health hasn't adopted this model because health companies monetize access to reasoning — they lock credibility behind paywalls and institutional gatekeeping. ~4,000 Rolfers worldwide, $1,100-2,000 for a 10-series. Zero consumer apps with chain reasoning (2025 Frontiers systematic review of 8 apps). The accessibility barrier isn't technical — it's economic. Remove the paywall, cite the evidence transparently, and the outreach is massive. PT patient acquisition costs $75-200 per new patient — a free screening tool that delivers warm referrals undercuts that entirely, creating a two-sided network effect that no paid competitor can replicate.

*Opponent*: VCs who say health can't be freemium — unit economics don't work without subscription gates. Practitioners who see free tools as devaluing their expertise. Competitors whose entire revenue model depends on charging for screening.

**Design rule**: The free tier delivers a complete, valuable experience — personalized report, chain-level reasoning, actionable steps, cited evidence. The reasoning is never gated behind a paywall. sEMG hardware, longitudinal tracking, and practitioner features are the premium tier. The confirmation costs money. The reasoning doesn't.

---

### SPOV 4: Credibility is built through transparency and measurable outcomes, not institutional endorsement

> **Assertion**
> The biggest barrier isn't technical — it's trust. Transparent citations and measurable results replace the institutional credibility model.

The biggest barrier isn't technical — it's trust. America distrusts big pharma, insurance companies, and for-profit medical businesses. People need help but don't trust the systems offering it. The $3.8B PT software market builds billing tools. Hinge Health builds its credibility through Harvard and Mayo Clinic partnerships. Sword Health through employer contracts. The entire industry's credibility model is institutional endorsement — authority by association. But consumers don't trust institutions. They trust results they can verify. The app cites every claim to its evidence source — not on a separate science page like Welltory, but inline, where the reasoning happens. "Your knee and hip compensate together" links to Wilke 2016. "Upstream treatment reduces recurrence" links to the SFMA and Ferber data. The user sees the research, not a logo wall of university partners. This isn't claiming medical knowledge — it's providing research transparently. The distinction matters legally: "here's what the research shows" is educational; "you have SBL dysfunction" is a clinical claim. Transparent citation actually strengthens the regulatory position by making the tool explicitly educational. The credibility path: cite the evidence → users see results → users share results → practitioners notice → credible PTs and speed school instructors who value proof over protocol endorse it because they've seen what it does, not because they were paid to. Doctors will naturally endorse when they see the outcomes. You don't need to buy authority upfront — you earn it through proof. No consumer health app does this. That's the gap.

*Opponent*: Clinicians and corporate medical companies who argue a source can't be credible without MD backing. Regulatory lawyers who worry that citing research creates implied clinical claims. The entire medical credibility apparatus that equates authority with institutional affiliation.

**Design rule**: Every claim in the app is cited inline to its evidence source. Domain knowledge comes from the research — fascial chain science, regional interdependence evidence, mechanotransduction data. PTs, speed school instructors, and pilates instructors assess the tool's outputs against their clinical experience to verify credibility. The tool is stress tested against clinicians but does not rely on them for its knowledge or function. Legal boundaries between educational and clinical claims are researched before launch, not after.

---

### SPOV 5: Static posture assessment is dead — dynamic movement is how systemic issues are found

> **Assertion**
> Compensation patterns only emerge under load. Every static posture tool is measuring the wrong thing.

Static posture captures a moment in time. Everyone has a different body, different posture, different comfort threshold — and none of it predicts pain. Swain et al. (2020) systematic review confirmed it: "poor" posture does not predict pain. The posture-pain causal link is debunked. Yet entire product categories are built on it — PostureScreen ($249/yr), Moti Physio ($5,850 hardware), and decades of chiropractic practice built around postural correction. They're measuring the wrong thing. Systemic issues reveal themselves under stress. A restricted hip is invisible standing still — it shows up when the body has to compensate around it during a squat. Weak knees don't appear in a postural photo — they appear when loaded. Hypermobile athletes show 3.5° lower knee valgus and 4.5° greater external rotation during movement (PMC8558993) — completely invisible in static assessment. Dynamic movement is where compensation patterns emerge, where the chain-level relationships between joints become observable, where the body tells the truth about what's driving what. The tool runs 4 functional movements — overhead squat, single-leg balance, overhead reach, forward fold — because each one loads the system differently and forces compensations to surface. But dynamic assessment alone isn't enough either: Bahr (2016) showed screening scores don't predict injury. The tool doesn't score movements — it reads compensation patterns across joints under load and traces them upstream. And it does this longitudinally, not as a one-shot, because movement classification systems lose their advantage over general exercise at 6-12 months (PMC6441589). The value is tracking how patterns change over time, not a single assessment.

*Opponent*: PostureScreen and the static postural analysis industry. Chiropractors who build practices around postural correction. Moti Physio and Janda-based practitioners who infer muscle status from static alignment. Also Bahr's camp — who'd agree static is dead but argue dynamic screening doesn't predict outcomes either.

**Design rule**: The tool assesses dynamic movement only — no static posture scoring. All assessments are functional movements under load. Findings are compensation patterns under stress, not resting alignment. Assessment is longitudinal — tracking pattern change over time, not one-shot scoring.

---

## User/Player Cognitive Map

*Break down exactly what the user is thinking, deciding, and potentially confused by during every phase of interaction.*

### Phase 1: Landing — "What is this?" (LOW load)

| Dimension | Analysis |
|---|---|
| **User sees** | Landing page: ~5 min free movement check, sample report, no account required |
| **User thinks** | "Is this legit? Another fitness app?" Split between curiosity and skepticism. If they came from a friend/instructor share, trust is higher. |
| **Decision point** | Do I trust this enough to try it? (cognitive) |
| **Cognitive load** | LOW (2 items): what does it do + is it credible |
| **Confusion risk** | May expect a medical tool or a generic fitness app — this is neither. If framing is too clinical, skeptics bounce. Too casual, they don't take it seriously. |
| **Design response** | Frame as "5-minute movement check." Show sample report upfront so they see what they get. Evidence citations visible on landing — not buried in a science page. No account wall. |

### Phase 2: Camera Setup (HIGH load)

| Dimension | Analysis |
|---|---|
| **User sees** | Camera permission prompt, then setup checklist (frontal view, lighting, fitted clothing, distance, clear background) |
| **User thinks** | "This is a lot. Right angle? Right clothes? Is this worth the effort?" |
| **Decision point** | Is my setup good enough to continue? (spatial + cognitive) |
| **Cognitive load** | HIGH (5+ items): camera permission, angle, lighting, clothing, distance, background |
| **Confusion risk** | 5 simultaneous requirements. Skeptical users from Phase 1 drop here. Silent tracking failure — if it doesn't work and they don't know why. |
| **Design response** | Progressive validation: one requirement at a time, green checkmark before next. Real-time skeleton overlay shows if tracking works. Specific feedback ("try removing your jacket"). |

### Phase 3: Movement Assessment (MEDIUM load)

| Dimension | Analysis |
|---|---|
| **User sees** | Live skeleton overlay + movement instructions + rep counter. 4 movements: overhead squat, single-leg balance, overhead reach, forward fold. |
| **User thinks** | Movement 1: "This is cool. Am I doing it right?" Movement 2: still engaged. Movements 3-4: "How many more?" |
| **Decision point** | Am I performing correctly? Do I keep going? (spatial) |
| **Cognitive load** | MEDIUM (3-4 items): movement instructions, watching skeleton, self-monitoring form, progress |
| **Confusion risk** | Watching skeleton instead of focusing on form. Glitchy landmarks (ankle occlusion in forward fold) break trust. Boredom/fatigue by movement 4. |
| **Design response** | Per-joint confidence colors (green/yellow/red). Progress indicator ("2 of 4"). ~60 sec per movement. Preliminary findings between movements ("We noticed something in your left hip — let's check it in the next movement"). |

### Phase 4: Results / Report (HIGH load)

| Dimension | Analysis |
|---|---|
| **User sees** | Personalized report: compensation patterns mapped as body-path connections, confidence indicators, evidence citations inline, recommended steps, discussion points for practitioners |
| **User thinks** | "Is this really about MY body? Can it tell this from 4 movements? What do I do now?" |
| **Decision point** | Do I believe this? What do I do with it? (cognitive) |
| **Cognitive load** | HIGH (4+ items): understanding findings, understanding connections between joints, evaluating cited evidence, deciding next steps |
| **Confusion risk** | If chain language leaks through ("SBL involvement") — meaningless to users. No clear next action = interesting but useless. Too much information overwhelms. |
| **Design response** | Body-path language: "your knee → hip → lower back compensate together" not chain names. Confidence colors on every finding. Each finding cites its evidence source (expandable, not cluttering). Layered: summary first, details on expand. Ends with 2-3 specific actions: share with practitioner, try recommended steps, get hardware for confirmation. |

### Phase 5: Share / Act (MEDIUM load)

| Dimension | Analysis |
|---|---|
| **User sees** | Share button, print/PDF option, "show your PT" discussion points, recommended movement practices, option to share with instructor |
| **User thinks** | "I want to show someone this" OR "I'll try the recommendations first" OR "I don't know what to do with this" |
| **Decision point** | Share, act on recommendations, or do nothing? (cognitive) |
| **Cognitive load** | MEDIUM (3 items): share options, recommended actions, who to show it to |
| **Confusion risk** | Too many options paralyze. "Show your PT" assumes they have one. Recommendations without evidence feel generic. |
| **Design response** | Primary CTA: one clear next step based on findings severity. Share is one tap. Discussion points are specific: "Ask about your hip mobility and how it affects your knee" not generic. Recommendations cite evidence for why. Find-a-practitioner if they don't have one. |

### Phase 6: Premium Conversion (MEDIUM load)

| Dimension | Analysis |
|---|---|
| **User sees** | After using the free screen (possibly multiple times or after sharing), they encounter the premium tier: sEMG hardware for confirmation, longitudinal tracking, advanced features |
| **User thinks** | "The free screen showed me something real. Can the hardware actually prove it? Is it worth the money?" |
| **Decision point** | Is the confirmation worth paying for? (cognitive) |
| **Cognitive load** | MEDIUM (3 items): what hardware does, cost, whether free screen was valuable enough to upgrade |
| **Confusion risk** | "Why do I need hardware if the free screen already told me the problem?" The value of CONFIRMATION vs DETECTION must be clear. |
| **Design response** | Show what sEMG adds that video can't: actual muscle activation data confirming the pattern. "The screen identified the pattern — the hardware proves it's muscular, not just visual." Show before/after data from alpha users. Never pressure — the free experience is complete. |

### Phase 7: Hardware Experience (HIGH load)

| Dimension | Analysis |
|---|---|
| **User sees** | sEMG sensors, placement guide, BLE pairing, real-time muscle activation overlay during movements, haptic cueing |
| **User thinks** | "Where do these go? Is this right? Oh wow I can see my muscles firing." |
| **Decision point** | Is my placement correct? Do I trust this data? (spatial + cognitive) |
| **Cognitive load** | HIGH (5+ items): sensor placement, pairing, interpreting activation data, haptic feedback, movement execution |
| **Confusion risk** | Wrong sensor placement = bad data and broken trust. Too much new information at once. Haptic cueing during movement is a lot to process. |
| **Design response** | Step-by-step sensor placement with visual guide and confirmation. Start with one sensor, not all three. Build up to full measurement. Real-time overlay shows activation simply (green = firing, red = not). Haptic cueing introduced gradually. |

### Phase 8: Longitudinal Return (LOW load)

| Dimension | Analysis |
|---|---|
| **User sees** | Dashboard showing pattern changes over time. Previous vs current compensation patterns. Progress toward resolving upstream drivers. |
| **User thinks** | "Is it getting better? Are the recommendations working?" |
| **Decision point** | Keep going with current approach or change something? (cognitive) |
| **Cognitive load** | LOW (2 items): is it improving + what to do next |
| **Confusion risk** | Small changes feel meaningless. No change feels like failure. Improvement in numbers they don't understand. |
| **Design response** | Plain language progress: "Your hip-knee compensation pattern has reduced by X since last month." Celebrate meaningful change. If no change, adjust recommendations. Longitudinal data is the product's long-term value — make it feel personal and actionable, not clinical. |

---

## Cognitive Load Analysis

### Cognitive Load by Phase

| Phase | Load | What the Brain Processes | How We Reduce It |
|---|---|---|---|
| Landing | Low | What does it do + is it credible (2 items) | No jargon, sample report preview, evidence citations visible, clear time commitment |
| Camera Setup | High | Permission, angle, light, clothing, distance, background (5+ items) | Progressive validation — one requirement at a time with visual confirmation |
| Movement Assessment | Medium | Instructions, skeleton, form, progress (3-4 items) | Real-time skeleton overlay, per-joint confidence colors, preliminary findings between movements |
| Results / Report | High | Findings, connections, cited evidence, next steps (4+ items) | Body-path language, confidence colors, layered disclosure (summary → details), specific actions |
| Share / Act | Medium | Share options, recommended actions, who to show (3 items) | Single primary CTA based on severity, one-tap share, specific discussion points |
| Premium Conversion | Medium | What hardware does, cost, value of confirmation (3 items) | Clear detection vs confirmation distinction, alpha user data, no pressure |
| Hardware Experience | High | Sensor placement, pairing, activation data, haptic feedback, movement (5+ items) | Step-by-step guide, one sensor at a time, simple activation display, gradual haptic introduction |
| Longitudinal Return | Low | Is it improving + what to do next (2 items) | Plain language progress, celebrate change, adjust recommendations if no change |

### Key Cognitive Load Principles Applied

- **Reduce extraneous load**: All clinical terminology translated to body-part language ("your knee → hip → lower back compensate together" not "Superficial Back Line involvement"). Evidence citations are expandable, not cluttering. Progressive validation in setup. No jargon on any user-facing surface.
- **Maximize germane load**: Preliminary findings surfaced between movements to build a narrative and active pattern discovery ("We noticed something in your left hip — let's check it in the next movement"). Report structured as a story of connected findings, not a list of scores. Evidence citations let curious users go deeper.
- **Manage intrinsic load**: One phase at a time. Setup requirements validated progressively. Movements capped at ~60 sec each. Report layered: summary first, details on expand. Hardware onboarding starts with one sensor, not all three. Working memory <4 items in early phases.

### Potential Confusion Points & Mitigations

| Potential Confusion | Why It Might Happen | Design Mitigation |
|---|---|---|
| "Is this a medical diagnosis?" | Clinical-sounding language creates false authority | Frame as "movement check" and "conversation starters." Explicit disclaimer visible at all times. Cite evidence as educational, not diagnostic. |
| "The skeleton is glitchy — is this thing broken?" | MediaPipe tracking fails with loose clothing, poor lighting, or self-occlusion | Real-time confidence indicators per joint. Specific guidance: "Try removing your jacket" or "Move to better lighting." |
| "What is a Superficial Back Line?" | Chain terminology leaks into user-facing output | Never use chain names in user-facing output. Body-path language only: "ankle → knee → hip → lower back connection." |
| "What do I do with this report?" | Results without clear next steps feel academic | Every report section ends with a specific action. Primary CTA based on findings severity. Discussion points for practitioners are specific, not generic. |
| "Why do I need hardware if the app already found the problem?" | Detection vs confirmation distinction unclear | Explicit framing: "The screen identified the pattern — the hardware proves it's muscular." Show what sEMG data looks like vs video-only. |
| "I don't have the right clothes/space" | Setup requirements create barriers before value is demonstrated | Show sample results BEFORE setup to demonstrate value. Minimal viable setup: any well-lit room, shorts and t-shirt, phone propped 6ft away. |
| "Where do these sensors go?" | sEMG placement is unfamiliar | Step-by-step visual guide with placement confirmation. Start with one sensor. Verify signal quality before proceeding. |

---

## Experts

*A curated list of the leading thinkers, researchers, and practitioners whose work informs this BrainLift.*

### Expert 1: Carla & Antonio Stecco

**Who**: Fascial Manipulation founders; Carla Stecco is Professor of Anatomy, University of Padova
**Focus**: Developed the Center of Coordination (CC) / Center of Perception (CP) framework — the distinction between where pain is felt (CP) and where the restriction driving it lives (CC). Hyaluronan densification model: pain correlates with fascial layer thickening. RCT data shows chain-reasoning treatment resolves pain in 1 session vs 3 for local-only (Gnat 2022).
**Why Follow**: The CC/CP framework is the encodable reasoning model for the tool. "Your pain is here (CP), but the driver is upstream (CC)" is exactly what the algorithm does: detect compensation → trace upstream → identify candidate driver. The Gnat 2022 RCT is the strongest evidence that this reasoning produces better outcomes.
**Where**: [MDPI Life 2022](https://www.mdpi.com/2075-1729/12/2/222), [FM Meta-analysis 2025](https://www.researchgate.net/publication/387532386)

### Expert 2: Wainner & Sueki

**Who**: Physical therapy researchers
**Focus**: Regional interdependence model — the academic framework proving that treating upstream drivers produces better outcomes than local-only treatment. Established the theoretical basis for why addressing a remote site resolves a local symptom.
**Why Follow**: Regional interdependence is the academic validation of what the tool does. It provides the peer-reviewed framework for "treat the driver, not the symptom" that doesn't depend on fascial chain language.
**Where**: [PubMed 23758151](https://pubmed.ncbi.nlm.nih.gov/23758151/)

### Expert 3: Roald Bahr

**Who**: Sports medicine physician and researcher
**Focus**: Published the landmark critique showing that screening (including FMS) does not predict injury (BJSM 2016). Fundamentally changed how screening claims can be framed.
**Why Follow**: Bahr defines what we CANNOT claim. The tool does not predict injury — it identifies compensation patterns and traces them upstream. Bahr's work ensures the product stays defensible by never claiming prediction from screening scores.
**Where**: [BJSM 2016](https://bjsm.bmj.com/content/50/13/776)

### Expert 4: Reed Ferber / Donna Earl-Boehm

**Who**: Biomechanics researchers
**Focus**: Conducted the strongest single proximal-distal RCT: hip strengthening + knee exercises > knee exercises alone for patellofemoral pain (n=199). Pain resolved 1 week faster with the upstream approach (PubMed 25102167).
**Why Follow**: This is the most rigorous evidence that addressing the upstream driver (hip) produces better outcomes than treating only the pain site (knee). The study design — upstream vs local — is exactly the matched vs mismatched experiment the tool needs to run at scale.
**Where**: [PubMed 25102167](https://pubmed.ncbi.nlm.nih.gov/25102167/)

### Expert 5: Jan Wilke

**Who**: Professor, Goethe University Frankfurt
**Focus**: Published the foundational systematic review (2016) establishing which fascial chains have anatomical evidence. SBL: 3/3 transitions, 14 studies. BFL: 3/3, 8 studies. FFL: 2/2, 6 studies. Also ran remote-effects RCT showing lower-limb stretching improves cervical ROM.
**Why Follow**: Wilke's evidence hierarchy is the foundation for which chains the tool uses as its internal reasoning scaffold. His insistence on evidence-based selectivity — not theoretical enthusiasm — models the tool's approach.
**Where**: [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)

### Expert 6: Greg Lehman

**Who**: Physiotherapist, chiropractor, biomechanics researcher
**Focus**: Most widely-cited fascial chain skeptic. 10cm displacement limit on mechanical force transmission. Argues lines are dissection artifacts. Clinical extrapolation outruns evidence.
**Why Follow**: Lehman is the strongest opponent of chain-based reasoning. Every chain attribution in the tool must survive his displacement argument. Critically, Lehman himself endorses Schleip's neurological model — meaning even the biggest critic concedes a mechanism exists, just not the mechanical one.
**Where**: [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)

### Expert 7: Robert Schleip

**Who**: Director, Fascia Research Group, Ulm University
**Focus**: Reframes fascia from mechanical tissue to a sensory organ — rich in proprioceptors and mechanoreceptors (~250M sensory endings). Ruffini endings stimulated by slow deep pressure lower sympathetic tone and reduce fascial stiffness. The neurological mechanism.
**Why Follow**: Schleip fills Lehman's blind spot. If the mechanism is neurological rather than mechanical, the 10cm displacement limit attacks the wrong target. This reframe means video-observable co-occurring patterns matter regardless of the underlying mechanism — the tool encodes the pattern, not the mechanism.
**Where**: [Frontiers in Pain Research 2025](https://www.frontiersin.org/journals/pain-research/articles/10.3389/fpain.2025.1712242/full), [PubMed 15922099](https://pubmed.ncbi.nlm.nih.gov/15922099/)

### Expert 8: Helene Langevin

**Who**: Director, NCCIH (National Center for Complementary and Integrative Health), NIH
**Focus**: Demonstrated 80% of acupuncture points coincide with intermuscular/intramuscular connective tissue planes (2002). Sustained stretching triggers Resolvin production (anti-inflammatory) and fibroblast expansion up to 200%.
**Why Follow**: Langevin bridges Western fascial science and TCM, providing independent anatomical evidence for the structural overlap. Her mechanotransduction work (stretching → resolvin production) is relevant if the intervention layer ships.
**Where**: [PubMed 12467083](https://pubmed.ncbi.nlm.nih.gov/12467083/), [PMC4946323](https://pmc.ncbi.nlm.nih.gov/articles/PMC4946323/)

### Expert 9: Peter Dorsher

**Who**: Mayo Clinic physician and researcher
**Focus**: Mapped 91% correspondence between the SBL and Bladder Meridian — the strongest single pairing between fascial chains and TCM meridians. 89% correspondence across 9 meridian-to-myofascial-chain pairings. 92% overlap between myofascial trigger points and classical acupuncture points.
**Why Follow**: Independent anatomical convergence between Western fascial chain mapping and traditional Chinese meridian mapping on the same physical substrate. Not a product claim — cited for intellectual honesty about the convergence.
**Where**: [ResearchGate](https://www.researchgate.net/publication/228503992)

### Expert 10: Leonid Kalichman

**Who**: Professor, Ben-Gurion University of the Negev
**Focus**: Independent narrative review of myofascial continuity (2025) arriving at the same chain evidence hierarchy as Wilke — SBL/BFL/FFL strongly supported, Spiral/Lateral moderate, SFL lacks validation — without citing Wilke.
**Why Follow**: Independent convergence from two unconnected research groups strengthens the case that the 3-chain restriction is scientifically defensible, not an artifact of one team's bias. Reports fascia transmits up to 30% of mechanical forces in vitro.
**Where**: [PubMed 41316622](https://pubmed.ncbi.nlm.nih.gov/41316622/)

### Expert 11: Keith Baar

**Who**: Professor, UC Davis; mechanotransduction researcher
**Focus**: Discovered fibroblasts become mechanically "deaf" after ~10 minutes of loading, with a 6-hour refractory period before pathway reactivation. This determines optimal loading protocol timing.
**Why Follow**: If the intervention layer ships, Baar's refractory period dictates how exercises are prescribed — short bouts with rest, not continuous loading. Shaw et al. 2017 showed 15g gelatin + 50mg Vitamin C before loading doubled collagen synthesis markers.
**Where**: [PubMed 27834241](https://pubmed.ncbi.nlm.nih.gov/27834241/)

### Expert 12: Brad McKay

**Who**: Motor learning researcher
**Focus**: Re-analyzed the attentional focus literature using Robust Bayesian methods (2024). Found that the external focus advantage — long considered settled science — drops to g=0.01 (null) after correcting for publication bias.
**Why Follow**: McKay's re-analysis defends internal/attentional focus as viable. If directing attention to the loaded tissue matters for mechanoreceptor response (Schleip's model), this removes the objection that "external focus is always better."
**Where**: [PubMed 38315516](https://pubmed.ncbi.nlm.nih.gov/38315516/)

### Expert 13: Timothy Hewett

**Who**: Professor, Mayo Clinic; biomechanics researcher
**Focus**: Landmark ACL prediction — knee valgus >10° = 2.5x risk (p<0.001). 8° greater abduction in injured athletes. Abduction moment alone: 73% specificity, 78% sensitivity.
**Why Follow**: Hewett's 10° valgus threshold is well above MediaPipe's noise floor for hip/knee (5-10° real-world). The strongest evidence that video-based triage can detect clinically meaningful patterns. His biomechanical findings map onto chain predictions without using chain language — a bridge between biomechanics and chain reasoning.
**Where**: [PubMed 15722287](https://pubmed.ncbi.nlm.nih.gov/15722287/)

### Expert 14: Thomas Myers

**Who**: Creator of the Anatomy Trains model
**Focus**: Proposed the myofascial meridian framework mapping continuous lines of connective tissue. Concedes "hard evidence of effects from bodywork or movement training, however attractive intuitively, is so far lacking" (2018).
**Why Follow**: Myers created the theoretical framework being encoded as the tool's internal reasoning scaffold. His willingness to concede evidence gaps models the intellectual honesty the tool must maintain. The chains are the MAP — what's connected — while Stecco provides the REASONING — what to do about it.
**Where**: [anatomytrains.com](https://www.anatomytrains.com/), [Myers 2018 Response](https://www.anatomytrains.com/blog/2018/11/12/anatomy-trains-fact-or-fiction-tom-myers-responds/)

### Expert 15: Roberto Merletti

**Who**: Professor Emeritus, Politecnico di Torino
**Focus**: Documented the vicious cycle preventing clinical sEMG adoption — synthesized findings across an 18-paper special issue (80 authors, 7 countries) in Frontiers in Neurology (2021). No teaching → no competence → no publications → no funding → no positions → no teaching.
**Why Follow**: sEMG IS the product. Merletti's adoption trap predicts exactly the barriers the hardware tier will face and explains why the data collection barrier must be broken first. The tool breaks this cycle by making the software layer free and the hardware accessible.
**Where**: [PMC7906963](https://pmc.ncbi.nlm.nih.gov/articles/PMC7906963/)

### Expert 16: LLM-FMS Research Team (PLOS ONE 2025)

**Who**: Academic team behind the first LLM-based FMS scoring pipeline
**Focus**: 91% accuracy (kappa 0.82) scoring Functional Movement Screens from skeleton keyframes using LLM-based prompting. 1,812 keyframes, 45 subjects.
**Why Follow**: Proves automated movement quality assessment from pose estimation keypoints is technically feasible. Their limitations — keyframe-only, no live video, no chain reasoning — define the gap this tool fills. The closest technical analog.
**Where**: [PMC 11896072](https://pmc.ncbi.nlm.nih.gov/articles/PMC11896072/)

---

## DOK 3 — Insights

*Insights are the building blocks of the Spiky POVs. Each represents an original conclusion or connection generated after processing information from multiple sources.*

### Insight 1: Target the chain from the start — trial and error is the old paradigm

PTs discover upstream drivers through repeated visits and clinical intuition. The patient comes in for knee pain, the PT treats the knee, it comes back, they check the hip, it improves — took 3-4 visits to find what chain reasoning identifies in the first screen. AI gradient boosting classifiers already detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302). The tool doesn't replace the PT — it gives them the system-level view on visit one instead of visit four.

### Insight 2: The map and the reasoning are different tools — the product encodes both

Myers' Anatomy Trains tells you what's connected (SBL: plantar fascia → hamstrings → erector spinae). Stecco's CC/CP framework tells you what to DO about it (pain at the knee is the CP; the hip restriction driving it is the CC — treat the CC). The tool needs both layers: Myers' map determines which joints to examine together; Stecco's CC/CP provides the algorithmic logic that traces from detected compensation upstream to candidate driver. Neither alone is sufficient — a map without reasoning says "these are connected" but not what to do; reasoning without a map says "look upstream" but not where upstream is.

### Insight 3: The value is whole-body reasoning, not chain specificity — but chains are still the best map

Force transmission explains only ~10% of remote tissue displacement variance (Nature Sci Rep 2023). Within-chain ROM correlates weakly (r=0.32-0.44). Remote stretching increases ROM in ALL planes, not just the chain-predicted plane. The evidence says: thinking systemically works, but proving WHICH specific chain is involved is harder than v0 assumed. The chains remain the best available heuristic for organizing where to look — two independent reviews (Wilke 2016, Kalichman 2025) converge on the same evidence hierarchy without citing each other. More research is needed on whether chain-specific attribution adds value over general upstream reasoning. The tool is positioned to generate that data.

### Insight 4: Recurrence is the metric that proves whole-body treatment works — not incremental improvement, paradigm shift

50-72% of patients treated locally come back. 6-8% treated with upstream reasoning come back (SFMA 6.25% vs 50%; lateral elbow regional vs local 8% vs 72%). This isn't a marginal improvement — it's the difference between a treatment that sticks and one that doesn't. It means the body-as-a-whole approach isn't theoretical — it produces measurably different outcomes. The RESTORE trial (n=492, Lancet) showed sustained 3-year improvement with AU$5-8K cost savings. If the tool can demonstrate that users who address upstream drivers have lower recurrence, that's not just product validation — it's proof the reasoning works.

### Insight 5: Two fields, one wall, and the product IS the research

CV researchers optimize for MPJPE. Fascial researchers defend basic science. Zero cross-citations between the fields across 4,071 papers (Semantic Scholar, April 2026). Nobody built this because nobody speaks both languages. We can because we have knowledge of both fields, and ML can correlate pattern matching with the scientific method. The sEMG hardware proves whether the pattern is correlative or causal. If the product validates the claim, it's a product. If it doesn't, it's still a research instrument that generated the first controlled dataset linking CV-detected movement patterns to chain-level reasoning. The product IS the research either way.

### Insight 6: Accessible + credible + shareable = the freemium model for health

The free screen must be genuinely valuable — not a demo, not a teaser. If it helps people understand their movement patterns and gives them actionable steps, they share it. The more people see it, the more who convert to premium (full reasoning, longitudinal tracking) and hardware (sEMG confirmation). Instructors can group-share results with clients. The gaming industry proved this: Fortnite and Riot Games make the core experience free and world-class, then monetize premium features — the most profitable model in the industry. ~4,000 Rolfers worldwide charge $1,100-2,000 for a 10-series. A free app with the same reasoning scaffold reaches more people in a week than Rolfing reaches in a year.

### Insight 7: Static posture is a snapshot of nothing — dynamic movement is where the body tells the truth

Swain et al. (2020) systematic review: "poor" posture does NOT predict pain. Everyone has a different body, different posture, different comfort threshold — static assessment captures a moment in time that means nothing about function. Dynamic movement is where systemic issues reveal themselves. Weak knees don't show up standing still; they show up squatting. A restricted hip doesn't matter until the body has to compensate around it during a lunge. Stress is the signal — load the system and watch what compensates. Every tool built on static posture (PostureScreen, traditional postural analysis) is measuring the wrong thing. The product assesses movement, not posture.

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

DOK 2 — Summary: Three of six proposed myofascial meridians have strong, independently verified anatomical evidence. Three do not. The divide is binary. Restricting the tool to SBL, BFL, and FFL as its internal reasoning scaffold is the only defensible position. Independently confirmed by Kalichman (2025) without citing Wilke.

Link: [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)

#### Subcategory 1.2: Independent Confirmation

Source: Kalichman (2025). "Myofascial Continuity: Review of Anatomical and Functional Evidence." *Body Work and Movement Therapies*.

DOK 1 — Facts:
- Narrative review that does NOT cite Wilke
- Same hierarchy: SBL/BFL/FFL = strongly supports; Spiral/Lateral = moderate; SFL = lacks validation
- Reports fascia transmits up to 30% of mechanical forces in vitro
- Human evidence for epimuscular myofascial force transmission is limited

DOK 2 — Summary: Independent convergence on the same evidence hierarchy from two unconnected research groups strengthens the case that the 3-chain restriction is scientifically defensible. The 30% force transmission figure is in vitro only — translation to living tissue is unproven.

Link: [PubMed 41316622](https://pubmed.ncbi.nlm.nih.gov/41316622/)

#### Subcategory 1.3: Force Transmission

Source: Krause et al. (2016). "Intermuscular Force Transmission Along Myofascial Chains." *Journal of Anatomy*.

DOK 1 — Facts:
- Only 9 of 1,022 screened articles met cadaveric force measurement criteria
- SBL: 7-69% force transfer between biceps femoris and sacrotuberous ligament (cadaveric)
- Only 2 of 9 studies in vivo
- Cadaveric preparation (formalin fixation, freezing) alters tissue mechanical properties

DOK 2 — Summary: Force transmission evidence is thin and methodologically compromised. The primary evidence does not reflect living mechanical behavior. Under-investigation, not disproof.

Link: [PMC 5341578](https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/)

#### Subcategory 1.4: The Skeptical Case

Source: Lehman (2012). "Fascia Science: Stretching the Relevance." greglehman.ca.

DOK 1 — Facts:
- Maximum mechanical displacement in cadaveric pull studies is 4-10 cm
- Lines may be arbitrary dissection artifacts
- "Fascial adhesions" lack testable definition
- Clinical extrapolation outruns evidence
- Lehman endorses Schleip's neurological model as more plausible

DOK 2 — Summary: Lehman's strongest argument — the 10cm displacement limit — applies to mechanical force transmission only. If the mechanism is neurological (Schleip), the displacement argument is irrelevant. Lines with strong evidence (SBL/BFL/FFL) are empirically distinguishable from lines without, weakening the "arbitrary dissection" argument.

Link: [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)

### Category 2: Regional Interdependence & Recurrence

#### Subcategory 2.1: Upstream vs Local Treatment Outcomes

Source: Multiple studies converging on the same finding.

DOK 1 — Facts:
- SFMA-guided vs standard care recurrence: 6.25% vs 50% (Austin Publishing 2024)
- Lateral elbow: regional vs local injection recurrence: 8% vs 72% (ResearchGate)
- PFP: hip+core vs knee-only (n=199): pain resolved 1 week faster (Ferber, PubMed 25102167)
- Stecco FM: chain vs local reasoning: pain resolved in 1 session vs 3 sessions (Gnat 2022, MDPI Life)
- Knee OA: closed chain + conventional vs conventional: pain SMD -1.18, function SMD -1.27 (PMC10344405)
- Thoracic manipulation for neck pain: -13.63mm on 100mm VAS vs local mobilization (PLOS ONE 2019)
- RESTORE trial CFT vs usual care (n=492, Lancet): sustained 3-year improvement, AU$5-8K savings (PubMed 37060913)

DOK 2 — Summary: Systems/chain-level thinking produces measurably better outcomes than local treatment across multiple conditions, study designs, and research groups. The recurrence gap (6-8% vs 50-72%) is the core evidence that upstream reasoning works. This is the product's reason to exist.

Links: [Austin Publishing 2024](https://austinpublishinggroup.com/physical-medicine/fulltext/phys-med-v11-id1078.php), [PubMed 25102167](https://pubmed.ncbi.nlm.nih.gov/25102167/), [PubMed 37060913](https://pubmed.ncbi.nlm.nih.gov/37060913/)

#### Subcategory 2.2: Stecco CC/CP Framework

Source: Stecco Fascial Manipulation research.

DOK 1 — Facts:
- Center of Coordination (CC): where the restriction lives (upstream driver)
- Center of Perception (CP): where the pain is felt (symptom site)
- Chain-reasoning treatment resolved pain in 1 session vs 3 for local treatment (Gnat 2022 RCT)
- Greater magnitude and durability at 30-day follow-up for chain reasoning
- 2025 meta-analysis of 15 FM RCTs: effect size = -0.80 for pain outcomes (very low certainty rating)
- Chronic LBP patients show 25% increase in thoracolumbar fascia thickness (PubMed 24131461)

DOK 2 — Summary: The CC/CP distinction is exactly what the tool does: detected compensation at joint X → trace upstream → identify candidate CC → recommend intervention at CC. This is the encodable reasoning model. The Gnat RCT provides the strongest evidence that this reasoning produces faster, more durable outcomes.

Links: [MDPI Life 2022](https://www.mdpi.com/2075-1729/12/2/222), [ResearchGate FM Meta-analysis](https://www.researchgate.net/publication/387532386)

### Category 3: Pose Estimation Accuracy

#### Subcategory 3.1: Joint-Specific Performance

Source: PMC 10886083 — MediaPipe vs. marker-based motion capture during treadmill gait.

DOK 1 — Facts:
- Hip: 2.35° MAE, high Pearson r — most reliable
- Knee: 2.82° MAE, high Pearson r — reliable
- Ankle: 3.06° MAE, Pearson r as low as 0.45 — unreliable with occlusion
- Left-limb angles consistently more accurate than right due to camera-position-dependent occlusion

DOK 2 — Summary: Hip and knee tracking adequate for detecting findings above 10° thresholds. Ankle tracking unreliable. Controlled-condition numbers should never be cited as blanket accuracy.

Link: [PMC 10886083](https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/)

#### Subcategory 3.2: Real-World Degradation

Source: PMC 11644880, PMC 11566680.

DOK 1 — Facts:
- Jacket spiked positional RMSE from 25-35 mm to 53.6 mm
- Monocular phone: median RMSE 56.3 mm; stereo: 30.1 mm
- Only 43% of push-up trials achieved MAE below 5°

DOK 2 — Summary: Real-world conditions double or triple pose estimation error. Clothing is insidious — users won't know it's the problem. Setup guidance and real-time tracking quality feedback are essential, not nice-to-haves.

Links: [PMC 11644880](https://pmc.ncbi.nlm.nih.gov/articles/PMC11644880/), [PMC 11566680](https://pmc.ncbi.nlm.nih.gov/articles/PMC11566680/)

#### Subcategory 3.3: FMS Validation Gap

Source: SOMA (2024).

DOK 1 — Facts:
- Only FMS-specific study using MediaPipe
- Explicitly exploratory with no accuracy claims
- No ICC, sensitivity/specificity, or RMSE reported

DOK 2 — Summary: No published study validates MediaPipe for FMS-style scoring. The tool enters unvalidated territory — both the risk and the research contribution.

Link: [SOMA](https://soar.usa.edu/phjpt/vol4/iss3/2/)

### Category 4: Counter-Evidence & Limits

#### Subcategory 4.1: Chain Specificity Challenged

Source: Multiple studies.

DOK 1 — Facts:
- Remote stretching increased ROM in ALL planes, not just SBL-predicted sagittal (PubMed 28222845)
- Within-chain ROM correlates weakly (r = 0.32-0.44) — one segment doesn't predict another (MDPI Diagnostics 2025)
- Force transmission explains only ~10% of remote tissue displacement variance (Nature Sci Rep 2023)
- Remote ROM effects are ~5° — possibly below MCID (Burk & Wilke 2019)
- Movement classification systems show no long-term superiority (6-12mo) over general exercise (PMC6441589)

DOK 2 — Summary: The evidence supports "think beyond the pain site" much more strongly than "follow this specific fascial line." Whether identifying the SPECIFIC chain matters, or any upstream assessment produces similar results, is uncertain. The chains remain the best available map but chain-specificity is a hypothesis, not a foundation.

Links: [PubMed 28222845](https://pubmed.ncbi.nlm.nih.gov/28222845/), [Nature Sci Rep 2023](https://www.nature.com/articles/s41598-023-30775-x)

#### Subcategory 4.2: Posture-Pain Link Debunked

Source: Swain et al. (2020). Systematic review.

DOK 1 — Facts:
- "Poor" posture does not predict pain
- Static postural deviation is the wrong input for movement screening
- The Rolfing "tissue sculpting" model requires ~9,075 Newtons for 1% fascial deformation (Chaudhry 2008) — debunked

DOK 2 — Summary: Static posture assessment is built on a debunked premise. Dynamic movement assessment is the right approach — compensation patterns emerge under load, not at rest.

Links: [PubMed 32014781](https://pubmed.ncbi.nlm.nih.gov/32014781/), [PubMed 18723456](https://pubmed.ncbi.nlm.nih.gov/18723456/)

#### Subcategory 4.3: Screening ≠ Prediction

Source: Bahr (2016). BJSM.

DOK 1 — Facts:
- FMS has poor-to-moderate injury prediction validity
- FMS corrective exercise improves scores but does not reduce injury
- Screening-to-outcome link is broken without chain-specific reasoning

DOK 2 — Summary: The tool cannot claim to predict injury. It identifies compensation patterns and traces them upstream. The value is in pattern identification and upstream reasoning, not in a screening score.

Link: [BJSM 2016](https://bjsm.bmj.com/content/50/13/776)

### Category 5: Mechanotransduction & Loading Science

#### Subcategory 5.1: Cellular Evidence

Source: Multiple mechanotransduction studies.

DOK 1 — Facts:
- Isometric loading increases type I collagen + scleraxis (tendon markers); dynamic loading produces type II collagen (scar/fibrocartilage) (ScienceDirect S0945053X22000464)
- 20s isometric holds increased tendon stiffness; matched-volume 1s pulses produced zero change (Kubo, PubMed 25739556)
- 4% strain = anabolic; 8% strain = pro-inflammatory (PMC2893340)
- Fibroblasts become mechanically "deaf" after ~10 min; 6-hour refractory period (Baar, PubMed 27834241)
- Sustained stretching triggers Resolvin production + fibroblast expansion up to 200% (Langevin, PMC4946323)
- Rest intervals outperform continuous loading for collagen synthesis (PMC4256895)

DOK 2 — Summary: The cellular mechanisms are well-established in vitro. Loading mode determines tissue identity — isometric produces tendon markers, dynamic produces scar. Translation to whole-body outcomes is unproven. Relevant if/when the intervention layer ships.

Links: [PubMed 27834241](https://pubmed.ncbi.nlm.nih.gov/27834241/), [PMC4946323](https://pmc.ncbi.nlm.nih.gov/articles/PMC4946323/)

#### Subcategory 5.2: Translation Gap

Source: Chaudhry et al. (2008), in vitro substrate limitations.

DOK 1 — Facts:
- ~2,000 lbs of force needed for 1% deformation of dense fascia (fascia lata)
- In vitro substrates are orders of magnitude stiffer than living tissue
- Applied strains in culture (10-20%) vastly exceed anything achievable through exercise
- No validated causal pathway connecting in vitro mechanotransduction to specific exercise protocols

DOK 2 — Summary: Cellular science predicts loading effects should work. Whether specific exercises produce sufficient strain in the right tissue in living humans is unproven. The tool should measure this, not assert it.

Link: [PubMed 18723456](https://pubmed.ncbi.nlm.nih.gov/18723456/)

### Category 6: TCM-Fascial Correspondence

#### Subcategory 6.1: Structural Overlap

Source: Dorsher (2009), Langevin & Yandow (2002).

DOK 1 — Facts:
- 80% of acupuncture points coincide with intermuscular/intramuscular fascial planes (Langevin, PubMed 12467083)
- 89% correspondence across 9 meridian-to-myofascial-chain pairings (Dorsher 2009)
- SBL maps to Bladder Meridian with 91% overlap — strongest single pairing
- 92% overlap between 255 myofascial trigger points and classical acupuncture points (Dorsher 2006-2008)

DOK 2 — Summary: The structural overlap between Western fascial chain mapping and TCM meridian mapping is independently documented and statistically strong. This isn't a product claim — it's cited for intellectual honesty about the convergence of independent anatomical traditions on the same physical substrate.

Links: [PubMed 12467083](https://pubmed.ncbi.nlm.nih.gov/12467083/), [ResearchGate Dorsher](https://www.researchgate.net/publication/228503992)

### Category 7: The Integration Gap

#### Subcategory 7.1: Citation Silo Evidence

Source: Citation network analysis via Semantic Scholar API, April 2026.

DOK 1 — Facts:
- 7 landmark papers analyzed across CV, biomechanics, and fascial chain science (4,071 classified citing papers)
- CV ↔ Fascial: zero citations in either direction
- Biomechanics ↔ CV: 5.1% (biomechanics cites CV) vs 0.9% (CV cites biomechanics) — one-directional
- Biomechanics ↔ Fascial: 8.4% (fascial cited by biomechanics) vs 0.05% (reverse)
- Each field cites itself: CV 29.7%, Biomechanics 53.5%, Fascial 38.5%

DOK 2 — Summary: The three fields required to build this tool have no history of academic exchange. Zero cross-citations between CV and fascial chain research. The integration is genuinely novel — not a gap that's slowly closing, but a wall between fields that never had a reason to reference each other.

#### Subcategory 7.2: Five Independent Barriers

Source: Composite analysis from capstone research.

DOK 1 — Facts:
- Barrier 1: Hill-type muscle models (since 1938) structurally can't represent cross-body chains
- Barrier 2: CV optimizes for MPJPE/PCK, not clinical meaning
- Barrier 3: FDA classification blocks causal claims
- Barrier 4: Fascial evidence has genuine gaps
- Barrier 5: Two-communities problem — practitioners can't code, engineers don't know fascia

DOK 2 — Summary: Five compounding barriers, each independently sufficient, explain why this tool doesn't exist. The gap is a coordination failure, not an oversight.

#### Subcategory 7.3: sEMG Adoption Trap

Source: Merletti et al. (2021). Frontiers in Neurology — synthesis across 18-paper special issue, 80 authors, 7 countries.

DOK 1 — Facts:
- Vicious cycle: no teaching → no competence → no publications → no funding → no positions → no teaching
- 21/28 interviewees (Cappellini et al.): difficult interpretation without specific education
- 20/28: insufficient education during refresher courses

DOK 2 — Summary: Fascial chain science is stuck in the same vicious cycle Merletti documented for sEMG. A free tool that logs sessions breaks the data collection barrier. The tool addresses this directly — free software layer, accessible hardware tier.

Link: [PMC7906963](https://pmc.ncbi.nlm.nih.gov/articles/PMC7906963/)

### Category 8: Regulatory & Market Context

#### Subcategory 8.1: FDA Positioning

Source: FDA CDS Guidance (Jan 2026), General Wellness Guidance (Jan 2026).

DOK 1 — Facts:
- DARI Motion FDA 510(k): limited to "quantifying and graphically displaying human movement patterns"
- CDS Criterion 1 blocks tools that process images for medical purposes — phone camera video processed for movement analysis could qualify
- General Wellness: must not "prompt or guide specific clinical action or medical management"
- Market leaders (Hinge, Sword) position CV movement analysis as wellness, NOT FDA-cleared
- "Movement patterns" and "body connections" = safe language; "compensation," "dysfunction," "drivers of pain" = borderline/device territory

DOK 2 — Summary: The regulatory landscape forces the tool to frame output as educational. "Here's what the research shows" is defensible; "you have this condition" is not. Follow Hinge/Sword precedent: launch as wellness. Transparent evidence citations strengthen the educational positioning. Legal boundaries between educational and clinical claims must be researched before launch.

Links: [FDA CDS Guidance](https://www.fda.gov/media/109618/download), [Arnold & Porter Jan 2026](https://www.arnoldporter.com/en/perspectives/advisories/2026/01/fda-cuts-red-tape-on-clinical-decision-support-software)

#### Subcategory 8.2: Competitive Landscape

Source: Market analysis, April 2026.

DOK 1 — Facts:
- Every funded platform answers "is the exercise correct?" — none answer "what is driving this pattern?"
- Hinge Health: $3B market cap, TrueMotion CV, no chain reasoning
- Sword Health: $4B valuation, acquired Kaia for $285M, no chain reasoning
- PostureScreen: static posture, no chain reasoning, $249/yr
- Symmio: 89% agreement with trained PT, no chain reasoning
- 2025 Frontiers systematic review of 8 camera-based movement screening apps: zero with fascial chain reasoning
- No documented case of consumer screening → practitioner referral at scale in MSK

DOK 2 — Summary: The white space is confirmed: no commercial tool combines CV movement screening with chain-level reasoning for upstream compensation identification. The entire field operates on exercise-correction, not causal reasoning.

Links: [Frontiers 2025](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full)

#### Subcategory 8.3: Market Sizing

Source: Market analysis, April 2026.

DOK 1 — Facts:
- Digital MSK care: $4.44B (2024), 17.7% CAGR
- U.S. AI in physical therapy: $178M (2025), 25.2% CAGR
- TAM: ~$4.1B | SAM: ~$348M | SOM (Year 5): ~$12.9M ARR
- 800,000+ addressable US practitioners (PTs + chiros + ATs + clinical massage + fitness trainers)
- PT patient acquisition cost: $75-200 per new patient
- Digital MSK sector raised $223M in H1 2024

DOK 2 — Summary: The addressable market is large and growing. The most direct analog — U.S. AI in PT at $178M growing 25.2% — is the fastest-growing adjacent segment. Conservative Year 5 SOM of $12.9M ARR is achievable with 50K consumer subscribers + 10K hardware units + 2K practitioner SaaS seats.

### Category 9: sEMG Hardware & Business Model

#### Subcategory 9.1: Partner Hardware

Source: Partner's POC research.

DOK 1 — Facts:
- 3x MyoWare 2.0 sensors (~$130) — placement rotates per chain
- ESP32 with BLE (~$15)
- 1x coin vibration motor LRA (~$10) in Velcro strap
- Phone with MediaPipe Pose
- Total BOM: ~$160-180
- Scale manufacturing estimate: $80-100 BOM at 1,000+ units
- Retail target: $199-299

DOK 2 — Summary: The hardware is feasible at consumer price points. The $160 experiment — same exercise, with and without sEMG confirmation — is the first direct test of whether CV-detected patterns correspond to measurable muscle activation.

#### Subcategory 9.2: Consumer sEMG Failure History

Source: Verification results, market analysis.

DOK 1 — Facts:
- Athos: 18% data loss from contact issues in controlled settings. Consumer line discontinued 2021.
- OMsignal: shut down 2017
- Textile electrodes can't isolate specific muscles
- The Athos "37% deviation" figure is fabricated — from an AI-generated article with fake expert quotes
- Only peer-reviewed Athos validation (Lynn et al. 2018): comparable to research-grade in controlled isokinetic conditions, but 18% discard rate

DOK 2 — Summary: Consumer sEMG failed because hardware companies skipped the science. They tried to sell measurement without reasoning. The tool inverts this: the reasoning layer (free software) creates the demand for measurement (paid hardware). Build the why before selling the what.

#### Subcategory 9.3: Pricing Architecture

Source: Market analysis, April 2026.

DOK 1 — Facts:
- Free tier: personalized movement screen, chain-level reasoning, recommended steps, cited evidence
- Premium: $14.99-19.99/month — full longitudinal tracking, advanced features
- Hardware: $199-249 sEMG kit, included in premium subscription
- Practitioner SaaS: $49-99/month per clinician
- Comparable: WHOOP $30/mo (hardware included in membership)

DOK 2 — Summary: The pricing architecture follows the freemium model: free core experience that's genuinely valuable, premium tier for confirmation and longitudinal tracking, hardware as the product. Never gate reasoning behind a paywall.

### Category 10: Clinical Thresholds & Population Variability

#### Subcategory 10.1: ACL Risk Factors

Source: Hewett et al. (2005). PubMed 15722287.

DOK 1 — Facts:
- Knee valgus >10° = 2.5x ACL risk (p<0.001)
- 8° greater abduction in injured athletes
- 20% higher ground reaction force
- Abduction moment alone: 73% specificity, 78% sensitivity

DOK 2 — Summary: Hewett's 10° valgus threshold is above MediaPipe's noise floor (5-10° real-world). The strongest evidence that video-based triage can detect clinically meaningful patterns.

Link: [PubMed 15722287](https://pubmed.ncbi.nlm.nih.gov/15722287/)

#### Subcategory 10.2: Hypermobile Compensation

Source: PMC8558993, PMC9397026.

DOK 1 — Facts:
- 3.5° lower minimum knee valgus vs controls
- 4.5° greater peak knee external rotation
- Neuromuscular adaptation, not structural difference
- Proprioceptive deficits at knee: 6.9° vs 4.6° passive error
- Hypermobile children show gastrocnemius-dominant landing strategy with reduced semitendinosus activity

DOK 2 — Summary: Hypermobile individuals move differently during the same tasks — within pose estimation error margins. Fixed thresholds systematically misinterpret their patterns. The tool must account for this.

Links: [PMC8558993](https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/), [PMC9397026](https://pmc.ncbi.nlm.nih.gov/articles/PMC9397026/)

---

## Key Assumptions

### User Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| Users can operate a smartphone camera and follow setup instructions | Basic phone literacy for setup and movement execution | Users unable to complete setup or requiring extensive guidance |
| Users have or can access fitted clothing and adequate space/lighting | Loose clothing degrades tracking accuracy by up to 2x (jacket: 25mm → 54mm RMSE) | High rate of poor tracking quality; users reporting "it didn't work" |
| Users are willing to spend 5 minutes doing 4 movements for a free result | Value proposition must overcome setup friction | High dropout between Phase 2 (setup) and Phase 4 (results) |
| Users will trust an app that cites research but has no MD endorsement at launch | Transparent evidence citations build credibility without institutional backing | Users dismiss results as "not real" despite cited evidence |
| Users who see value will share results with friends/practitioners | Shareability drives organic growth in the freemium model | Low share rates despite high completion rates |

### Technology Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| MediaPipe hip/knee tracking is reliable enough for >10° threshold detection | 5-10° real-world error must be below clinically meaningful thresholds | Clinician validation shows flagged findings don't match clinical observation |
| Browser-based processing is fast enough for real-time skeleton overlay | JavaScript SDK must process frames without visible lag | Users report glitchy or delayed overlay, breaking trust |
| sEMG sensors at ~$160 BOM produce clinically meaningful activation data | Consumer-grade sensors must distinguish activation patterns per chain | Activation data doesn't correlate with CV-detected compensation patterns |
| BLE pairing and sensor placement can be made simple enough for non-technical users | Hardware onboarding must be completable without expert help | High hardware return rates or support tickets about placement |

### Design Theory Assumptions

| Assumption | Must Be True | Failure Signal |
|---|---|---|
| Fascial chain patterns and upstream compensation are related | Co-occurring movement patterns along validated chains reflect real biomechanical relationships | Clinicians consistently disagree with chain attributions |
| The video proxy works at triage level | Video-observable patterns can serve as proxies for what practitioners detect by touch | Chain-aware recommendations are no more accurate than symptom-only descriptions |
| ML pattern matching can encode upstream reasoning | The discovery step of clinical reasoning is encodable from controlled, consented data | ML model doesn't outperform random chain attribution |
| The freemium model converts | Users who get value from the free screen will pay for hardware confirmation | Conversion rate below 1% despite high engagement |
| sEMG confirmation adds enough value over video-only | Hardware measurement meaningfully improves on video-only assessment | Users who buy hardware report no perceived improvement over free screen |

**If design theory assumptions fail**: The alpha testing will surface this. If chain attribution doesn't outperform symptom-only analysis, the tool has still generated the first controlled dataset linking CV patterns to chain-level reasoning — publishable and valuable as a research instrument. The product IS the research.

---

## Self-Critique

- [x] Every SPOV has a named opponent
- [x] Every SPOV has a design rule that constrains a real decision
- [x] Every DOK 3 insight traces to DOK 2 sources but isn't a restatement of any one source
- [x] The cognitive map has all 6 dimensions for every phase
- [x] Working memory items are enumerated in each phase
- [x] Key assumptions have failure modes
- [x] DOK 2 sources include both supporting AND challenging evidence

**Flags**: None. All quality checks pass.

**Note**: DOK 2 Knowledge Tree draws from extensively fact-checked research documents (4 rounds of verification, PMC cross-checks, citation network analysis). All PMC/PubMed numbers have been cross-checked against primary sources. The Athos 37% deviation figure was identified as fabricated and excluded. PMC12864725 was identified as methodologically compromised and excluded.

---

*BrainLift v1 assembled April 8, 2026. Research base from capstone research directory (compiled April 2026, 4 rounds of fact-checking applied). Built on v0 foundation with thesis shift driven by rolfing-pattern-matching-synthesis.md and yijinjing-fascial-chain-remodeling.md.*
