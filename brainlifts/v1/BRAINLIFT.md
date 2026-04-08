# AI Movement Screening Tool BrainLift

## Owners
- Kelsi Andrews

## Purpose

### Purpose
The purpose of this BrainLift is to establish the cognitive design framework for a movement screening tool that uses phone camera pose estimation to detect compensation patterns, maps them along validated fascial chains to identify upstream drivers, and generates personalized reports with cited evidence. It is built on the core belief that **upstream compensation reasoning — the clinical thinking behind 6-8% recurrence vs 50-72% — should be accessible to anyone with a phone**, and that **credibility is built through transparency and measurable outcomes, not institutional endorsement**. Existing tools either measure joints without interpretation (DARI Motion, Kinetisense), offer AI pose estimation without clinical reasoning (Uplift Labs, CueForm), provide clinical assessment without automation (FMS, SFMA), or assess static posture on a debunked premise (PostureScreen, Moti Physio). This product closes that gap: dynamic movement assessment + fascial chain reasoning as internal scaffold + personalized triage reports with inline evidence citations. The free screen is the gateway; the sEMG hardware is the product.

### North Star
*"Can we identify upstream compensation drivers from dynamic movement video, and does addressing them reduce recurrence, prevent injury, and improve measurable muscle function — ultimately validated by sEMG?"*

### In Scope
- **Dynamic Movement Assessment:** Compensation pattern detection using fascial chains as internal reasoning scaffold (SBL/BFL/FFL).
- **Freemium Gateway:** Free personalized screen → paid sEMG hardware + longitudinal tracking.
- **Transparent Evidence:** Every claim cited inline to its research source.
- **CC/CP Framework:** Stecco's Center of Coordination / Center of Perception as the encodable logic model.
- **Three Validation Metrics:** Recurrence reduction, injury prevention, muscle measurement improvement.
- **Research Instrument:** Controlled alpha with consented participants and clinician validation.

### Out of Scope
- **Static Posture Assessment:** Debunked — "poor" posture does not predict pain (Swain 2020).
- **Injury Prediction:** Screening scores don't predict injury (Bahr 2016).
- **FDA-Regulated Diagnostic Claims:** Output is educational triage, not diagnosis.
- **Unconsented Data Collection:** Alpha is controlled; no tracking without consent.

---

## DOK 4 - Spiky Points of View (SPOVs)

- **SPOV 1: The app replaces clinical judgment for discovering where systemic dysfunction manifests.** "Just knowing" is the practitioner's term for pattern matching built through years of trial and error. The app encodes that pattern matching and delivers the system-level view on screen one instead of visit four.

    - **Elaboration:** See enough bodies, and you learn that knee valgus + hip drop + ankle restriction travel together. The tacit knowledge literature confirms experts can't accurately describe their own reasoning; they rationalize and reconstruct (PMC 1475611). But the input-output pairs are observable and enumerable. AI gradient boosting classifiers already detect compensatory movements more sensitively than experienced physiotherapists (PMC12383302). LSTM networks detect injury-precursing changes ~2.5 sessions before symptoms. The app is the hub of trial and error: it needs controlled, consented data with clinician validation, and the alpha generates exactly that. Stecco's CC/CP makes the reasoning encodable: detected compensation at joint X → trace upstream along chain → identify candidate driver at joint Y. The Gnat 2022 RCT validated this — CC-targeted treatment resolved pain in 1 session vs 3 for local-only. The app doesn't replace what happens AFTER discovery — touch, patient history, clinical nuance. It replaces the 3-4 visit discovery cycle that burns patient time and money finding what pattern matching identifies immediately.

- **SPOV 2: PT clinical reasoning and fascial chain science are causal, not correlative — the tool will prove or disprove it.** PTs have decades of evidence that treating upstream works. Fascial chain science has anatomical evidence these structures are connected. But zero cross-citations exist between CV and fascial chain research — the sEMG hardware closes the loop.

    - **Elaboration:** Hip strengthening resolves knee pain (Ferber n=199), SFMA-guided treatment drops recurrence from 50% to 6.25%. SBL 3/3 transitions verified across 14 studies (Wilke 2016), independently confirmed by Kalichman (2025) without citing Wilke. But zero cross-citations exist between CV and fascial chain research across 4,071 papers (Semantic Scholar, April 2026). Five independent barriers kept these fields apart. The sEMG hardware closes the loop: CV detects the pattern, the chain map predicts which muscles should be involved, sEMG measures whether they actually are. If the fascial map predicts activation, the relationship is causal. If not, we've disproved it with controlled, consented alpha data. Either outcome is publishable. The counter-evidence is real — force transmission explains only ~10% of variance (Nature Sci Rep 2023), within-chain ROM correlates weakly (r=0.32-0.44). The tool doesn't assume the causal link — it tests it.

- **SPOV 3: Give away the reasoning, sell the confirmation — credibility doesn't have to be locked behind a paywall.** Every competitor charges for screening. The entire industry assumes the reasoning is the product. It's not — the confirmation is. The free screen is genuinely valuable; the premium tier is sEMG hardware that confirms the pattern is muscular, not just visual.

    - **Elaboration:** PostureScreen $249/yr, DARI enterprise-only, FMS $599, Symmio $49-99/mo. A free, personalized movement screen with chain-level reasoning and actionable steps is genuinely valuable on its own — that's why people share it. The gaming industry proved this at scale: Fortnite generated $9.1B from a free game; Riot pulls $1.75B/year. Health hasn't adopted this because health companies monetize access to reasoning. ~4,000 Rolfers worldwide, $1,100-2,000 for a 10-series, zero consumer apps with chain reasoning (2025 Frontiers systematic review of 8 apps). PT patient acquisition costs $75-200 — a free screening tool delivering warm referrals undercuts that entirely. The reasoning is never gated behind a paywall.

- **SPOV 4: Credibility is built through transparency and measurable outcomes, not institutional endorsement.** The biggest barrier is trust. The app cites every claim to its evidence source inline — not on a separate science page, but where the reasoning happens. "Here's what the research shows" is educational; "you have SBL dysfunction" is clinical.

    - **Elaboration:** America distrusts big pharma, insurance companies, and for-profit medical businesses. The $3.8B PT software market builds billing tools. Hinge Health builds credibility through Harvard partnerships; Sword through employer contracts. The entire industry's model is authority by association. "Your knee and hip compensate together" links to Wilke 2016. This isn't claiming medical knowledge — it's providing research transparently. Domain knowledge comes from the research. PTs, speed school instructors, and pilates instructors assess outputs to verify credibility — they don't build the knowledge, they validate it. The tool is stress tested against clinicians but does not rely on them. Legal boundaries between educational and clinical claims must be researched before launch.

- **SPOV 5: Static posture assessment is dead — dynamic movement is how systemic issues are found.** Swain et al. (2020) confirmed it: "poor" posture does not predict pain. Systemic issues reveal themselves under stress — a restricted hip is invisible standing still but shows up during a squat.

    - **Elaboration:** Yet PostureScreen ($249/yr), Moti Physio ($5,850), and decades of chiropractic practice are built on static posture. Hypermobile athletes show 3.5° lower knee valgus and 4.5° greater external rotation during movement (PMC8558993) — invisible in static assessment. The tool runs 4 functional movements because each loads the system differently and forces compensations to surface. But Bahr (2016) showed screening scores don't predict injury — so the tool doesn't score movements; it reads compensation patterns across joints under load and traces them upstream. And it does this longitudinally, because movement classification systems lose advantage at 6-12 months (PMC6441589). The value is tracking pattern change over time, not one-shot scoring.

---

## User/Player Cognitive Map

- **Phase 1: Landing — "What is this?"** — ~5 min free movement check, sample report, no account required. User thinks: "Is this legit? Another fitness app?" Evidence citations visible on landing. Frame as "movement check" not "biomechanical screening." (LOW load)

- **Phase 2: Camera Setup** — Camera permission + progressive setup checklist (angle, lighting, fitted clothing, distance). One requirement at a time with green checkmarks. Real-time skeleton overlay shows if tracking works. Specific feedback ("try removing your jacket"). Skeptical users drop here if tracking fails silently. (HIGH load)

- **Phase 3: Movement Assessment** — Live skeleton overlay + instructions + rep counter. 4 movements: overhead squat, single-leg balance, overhead reach, forward fold. Per-joint confidence colors (green/yellow/red). ~60 sec per movement. Preliminary findings between movements ("We noticed something in your left hip"). Progress indicator ("2 of 4"). (MEDIUM load)

- **Phase 4: Results / Report** — Personalized compensation patterns as body-path connections ("your knee → hip → lower back compensate together" not "SBL involvement"). Confidence colors on every finding. Each finding cites evidence (expandable). Layered: summary first, details on expand. Ends with specific actions: share with practitioner, try recommended steps, get hardware for confirmation. (HIGH load)

- **Phase 5: Share / Act** — One-tap share, print/PDF. Discussion points are specific ("Ask about your hip mobility and how it affects your knee"). Recommendations cite evidence. Find-a-practitioner if they don't have one. Primary CTA based on findings severity. (MEDIUM load)

- **Phase 6: Premium Conversion** — sEMG hardware for confirmation, longitudinal tracking. "The screen identified the pattern — the hardware proves it's muscular, not just visual." Show alpha user before/after data. Never pressure — the free experience is complete. (MEDIUM load)

- **Phase 7: Hardware Experience** — sEMG sensors + placement guide + BLE pairing + real-time muscle activation overlay + haptic cueing. Step-by-step placement with visual confirmation. Start with one sensor, build to three. Simple activation display (green = firing, red = not). Haptic cueing introduced gradually. (HIGH load)

- **Phase 8: Longitudinal Return** — Dashboard showing pattern changes over time. Plain language: "Your hip-knee compensation pattern has reduced by X since last month." Celebrate meaningful change. If no change, adjust recommendations. (LOW load)

---

## Cognitive Load Analysis

- **Extraneous reduced:** All clinical terminology translated to body-path language. No chain names in user-facing output. Evidence citations expandable, not cluttering. Progressive validation in setup (one requirement at a time). Per-joint confidence colors for instant visual processing.
- **Germane maximized:** Preliminary findings surfaced between movements to build narrative ("We noticed something in your left hip — let's check it in the next movement"). Report structured as connected findings, not a list of scores. Inline citations let curious users go deeper.
- **Intrinsic managed:** One phase at a time. Movements capped at ~60 sec. Report layered: summary first, details on expand. Hardware onboarding starts with one sensor. Working memory <4 items in early phases. Detection vs confirmation distinction explicit at conversion.

---

## Experts

- **Carla & Antonio Stecco** (CC/CP Framework — encodable reasoning model for upstream driver identification)
- **Wainner & Sueki** (Regional Interdependence — academic framework for upstream > local treatment)
- **Roald Bahr** (Screening ≠ Prediction — defines what the tool cannot claim)
- **Reed Ferber / Donna Earl-Boehm** (Hip-for-Knee RCT n=199 — strongest proximal-distal evidence)
- **Jan Wilke** (Fascial Chain Evidence Hierarchy — SBL/BFL/FFL foundation)
- **Greg Lehman** (Most-cited fascial skeptic — 10cm displacement limit; every chain attribution must survive his argument)
- **Robert Schleip** (Fascia as sensory organ — neurological mechanism fills Lehman's blind spot)
- **Helene Langevin** (Connective tissue + meridians — 80% acupoint/fascial plane overlap)
- **Peter Dorsher** (91% SBL/Bladder correspondence — independent TCM-fascial convergence)
- **Leonid Kalichman** (Independent confirmation of Wilke's chain hierarchy without citing Wilke)
- **Keith Baar** (Fibroblast refractory period — 6hr; determines loading protocol timing)
- **Brad McKay** (External focus advantage is null after bias correction — defends attentional focus)
- **Timothy Hewett** (ACL valgus threshold — 10° = 2.5x risk; validates video proxy at triage)
- **Thomas Myers** (Anatomy Trains creator — the map; concedes evidence gaps)
- **Roberto Merletti** (sEMG adoption trap — predicts hardware barriers the product must overcome)
- **LLM-FMS Research Team** (91% accuracy from keyframes — closest technical analog, defines the gap)

---

## DOK 3 - Insights

- **Insight 1:** PTs discover upstream drivers through 3-4 repeat visits of trial and error. The tool encodes that same pattern matching and delivers the system-level view on screen one instead of visit four.

- **Insight 2:** Myers' Anatomy Trains tells you what's connected (the map). Stecco's CC/CP tells you what to DO about it (the reasoning). The tool encodes both layers — neither alone is sufficient.

- **Insight 3:** Force transmission explains only ~10% of variance; within-chain ROM correlates weakly (r=0.32-0.44). Thinking systemically works, but proving WHICH chain is involved is harder than v0 assumed. Chains remain the best available heuristic — two independent reviews converge on the same hierarchy — but chain-specificity is a hypothesis the tool is positioned to test.

- **Insight 4:** 50-72% recurrence for local treatment vs 6-8% for upstream reasoning (SFMA 6.25% vs 50%; lateral elbow 8% vs 72%). Not incremental — the difference between treatment that sticks and treatment that doesn't. The RESTORE trial (n=492, Lancet) showed sustained 3-year improvement with AU$5-8K savings.

- **Insight 5:** Zero cross-citations between CV and fascial chain research across 4,071 papers. Nobody built this because nobody speaks both languages. The sEMG hardware proves whether correlation is causal. If the product validates the claim, it's a product. If not, it's a research instrument. The product IS the research either way.

- **Insight 6:** The free screen must be genuinely valuable — not a teaser. If it helps people, they share it. Instructors group-share with clients. ~4,000 Rolfers charge $1,100-2,000 for a 10-series. A free app with the same reasoning scaffold reaches more people in a week than Rolfing reaches in a year.

- **Insight 7:** Swain (2020): "poor" posture does not predict pain. Weak knees don't show up standing still — they show up squatting. Stress is the signal. Every tool built on static posture is measuring the wrong thing.

---

## DOK 2 - Knowledge Tree

### Category 1: Fascial Chain Evidence

- **Subcategory 1.1: Anatomical Continuity (Supporting)**
    - **Source:** Wilke et al. (2016), *Archives of Physical Medicine and Rehabilitation*
    - **DOK 1:** SBL: 3/3 transitions, 14 studies — strong. BFL: 3/3, 8 studies — strong. FFL: 2/2, 6 studies — strong. Spiral: 5/9 — moderate. Lateral: 2/5 — limited. SFL: 0 — none.
    - **DOK 2:** Three of six chains have strong evidence; three do not. The divide is binary. Restricting to SBL/BFL/FFL is the only defensible position. Independently confirmed by Kalichman (2025) without citing Wilke.
    - **Link:** [PubMed 26281953](https://pubmed.ncbi.nlm.nih.gov/26281953/)

- **Subcategory 1.2: Force Transmission (Challenging)**
    - **Source:** Krause et al. (2016), *Journal of Anatomy*
    - **DOK 1:** Only 9/1,022 articles met cadaveric force criteria. SBL: 7-69% transfer. Only 2/9 in vivo. Cadaveric preparation alters tissue properties.
    - **DOK 2:** Thin and methodologically compromised — under-investigation, not disproof.
    - **Link:** [PMC 5341578](https://pmc.ncbi.nlm.nih.gov/articles/PMC5341578/)

- **Subcategory 1.3: The Skeptical Case (Challenging)**
    - **Source:** Lehman (2012), greglehman.ca
    - **DOK 1:** Max displacement 4-10cm. Lines may be dissection artifacts. Lehman endorses Schleip's neurological model as more plausible.
    - **DOK 2:** Displacement argument applies to mechanical transmission only. If mechanism is neurological (Schleip), limit is irrelevant. Lines with strong evidence are empirically distinguishable from those without.
    - **Link:** [greglehman.ca](https://www.greglehman.ca/blog/2012/10/26/fascia-science-stretching-the-relevance-of-the-gluteus-maximus-and-latissimus-dorsi-sling)

### Category 2: Regional Interdependence & Recurrence

- **Subcategory 2.1: Upstream vs Local Treatment (Supporting)**
    - **Source:** Multiple converging studies
    - **DOK 1:** SFMA-guided 6.25% vs 50% recurrence. Lateral elbow regional 8% vs 72%. Hip+core vs knee-only: 1 week faster (Ferber n=199). Stecco FM: 1 session vs 3. RESTORE trial (n=492, Lancet): 3-year improvement, AU$5-8K savings.
    - **DOK 2:** Systems thinking produces dramatically better outcomes across conditions and study designs. The recurrence gap is the product's reason to exist.
    - **Links:** [Austin Publishing 2024](https://austinpublishinggroup.com/physical-medicine/fulltext/phys-med-v11-id1078.php), [PubMed 25102167](https://pubmed.ncbi.nlm.nih.gov/25102167/), [PubMed 37060913](https://pubmed.ncbi.nlm.nih.gov/37060913/)

- **Subcategory 2.2: CC/CP Framework (Supporting)**
    - **Source:** Stecco Fascial Manipulation, Gnat 2022 RCT
    - **DOK 1:** CC = upstream driver. CP = symptom site. Chain reasoning resolved pain in 1 session vs 3 for local (Gnat 2022). Greater durability at 30 days.
    - **DOK 2:** CC/CP is the encodable reasoning model: detected compensation → trace upstream → identify candidate CC → recommend intervention at CC.
    - **Link:** [MDPI Life 2022](https://www.mdpi.com/2075-1729/12/2/222)

### Category 3: Pose Estimation Accuracy

- **Subcategory 3.1: Joint-Specific Performance (Supporting + Challenging)**
    - **Source:** PMC 10886083; PMC 11644880; PMC 11566680
    - **DOK 1:** Hip: 2.35° MAE. Knee: 2.82° MAE. Ankle: Pearson r as low as 0.45. Jacket spiked RMSE from 25mm to 54mm. Only 43% of push-up trials below 5° MAE.
    - **DOK 2:** Hip/knee adequate for >10° thresholds. Ankle unreliable. Real-world doubles error. Setup guidance is essential, not optional.
    - **Link:** [PMC 10886083](https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/)

### Category 4: Counter-Evidence & Limits

- **Subcategory 4.1: Chain Specificity Challenged (Challenging)**
    - **Source:** PubMed 28222845; MDPI Diagnostics 2025; Nature Sci Rep 2023
    - **DOK 1:** Remote stretching increased ROM in ALL planes, not just chain-predicted. Within-chain ROM r=0.32-0.44. Force transmission ~10% of variance. Remote ROM ~5°, possibly below MCID. Movement classification loses advantage at 6-12mo.
    - **DOK 2:** Evidence supports "think beyond the pain site" more strongly than "follow this specific line." Chain-specificity is a hypothesis — the tool tests it.
    - **Links:** [PubMed 28222845](https://pubmed.ncbi.nlm.nih.gov/28222845/), [Nature Sci Rep 2023](https://www.nature.com/articles/s41598-023-30775-x)

- **Subcategory 4.2: Posture-Pain Debunked / Screening ≠ Prediction (Challenging)**
    - **Source:** Swain 2020; Bahr 2016
    - **DOK 1:** "Poor" posture does not predict pain. FMS does not reduce injury. Screening-to-outcome link broken without chain reasoning.
    - **DOK 2:** No static posture. No injury prediction claims. Dynamic movement + longitudinal tracking + upstream reasoning.
    - **Links:** [PubMed 32014781](https://pubmed.ncbi.nlm.nih.gov/32014781/), [BJSM 2016](https://bjsm.bmj.com/content/50/13/776)

### Category 5: The Integration Gap

- **Subcategory 5.1: Citation Silo (Supporting)**
    - **Source:** Semantic Scholar API analysis, April 2026
    - **DOK 1:** 4,071 papers, 7 landmarks. CV ↔ Fascial: zero citations either direction. Each field cites itself (CV 29.7%, Biomechanics 53.5%, Fascial 38.5%).
    - **DOK 2:** The three fields needed for this tool have no history of exchange. The integration has zero precedent.

- **Subcategory 5.2: sEMG Adoption Trap (Supporting)**
    - **Source:** Merletti et al. (2021), *Frontiers in Neurology* — 18-paper special issue, 80 authors
    - **DOK 1:** Vicious cycle: no teaching → no competence → no publications → no funding → no teaching.
    - **DOK 2:** Fascial chain science is in the same loop. The free tool breaks the data barrier. The product addresses Merletti's cycle directly.
    - **Link:** [PMC7906963](https://pmc.ncbi.nlm.nih.gov/articles/PMC7906963/)

### Category 6: Regulatory & Market Context

- **Subcategory 6.1: FDA & Competitive Landscape (Supporting + Challenging)**
    - **Source:** FDA CDS/Wellness Guidance Jan 2026; Market analysis April 2026
    - **DOK 1:** DARI 510(k): limited to "quantifying and displaying." Hinge/Sword position CV as wellness, not FDA-cleared. "Movement patterns" = safe; "compensation" = borderline. Every funded platform answers "is the exercise correct?" — none answer "what drives this pattern?" Zero apps with chain reasoning (Frontiers 2025). TAM ~$4.1B; SOM Year 5 ~$12.9M ARR.
    - **DOK 2:** Follow Hinge/Sword wellness precedent. Educational framing + transparent citations strengthen regulatory position. Legal boundaries between educational and clinical claims must be researched before launch.
    - **Links:** [FDA CDS Guidance](https://www.fda.gov/media/109618/download), [Frontiers 2025](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full)

### Category 7: sEMG Hardware & Business Model

- **Subcategory 7.1: Hardware & Pricing (Supporting)**
    - **Source:** Partner POC; Market analysis
    - **DOK 1:** 3x MyoWare 2.0 + ESP32 + vibration motor = ~$160 BOM. Retail $199-249. Athos failed (18% data loss, discontinued 2021) because they skipped the science. Free tier: personalized screen + chain reasoning + cited evidence. Premium: $14.99-19.99/mo + hardware. Practitioner SaaS: $49-99/mo.
    - **DOK 2:** Consumer sEMG failed because companies sold measurement without reasoning. The tool inverts this: reasoning layer (free) creates demand for measurement (paid). Build the why before selling the what.

---

*BrainLift v1 assembled April 8, 2026. Research base from capstone research directory (4 rounds of fact-checking). Full evidence base with expanded elaborations in BRAINLIFT-RESEARCHED.md.*
