# Lifting Sciences for Injury Prevention — Complete Research Document

**Last updated:** 2026-04-08
**Status:** DOK 1 + DOK 2 complete for all 30 subcategories. DOK 3 Insights and DOK 4 SPOVs pending.
**Product architecture:** Camera-first free app + premium EMG compression garment companion
**Prototype spec:** 4-channel sEMG (erector spinae L/R + quad VL/VM) + camera + haptic cueing = $121

---

## Purpose Statement

The purpose of this research is to build a research-backed foundation for a two-layer injury prevention system for novice lifters: a free smartphone camera app that provides real-time form correction via AI pose estimation, paired with a premium EMG-enabled compression garment that detects muscle activation patterns, fatigue onset, and compensation — closing the gap between what the eye can see and what's happening underneath.

**Core belief:** The camera sees the movement but only the muscles tell the truth. Beginners don't quit the gym because they lack information — they quit because they got hurt, and nobody caught it in time.

**Target user:** Someone who wants to lift but is held back by fear of injury, inability to afford a trainer, or a previous bad experience that destroyed their confidence.

**In Scope:**
- Biomechanics of how lifting injuries happen in beginners and the physiological warning signs that precede them
- Muscle activation science — fatigue detection, compensation patterns, and what sensors can detect that eyes cannot
- Visual form assessment — what cameras/coaches can and can't detect, and where the gap is
- Feedback and motor learning — what kind of real-time intervention actually changes beginner behavior
- Existing solutions landscape and whitespace analysis
- Opposing research — why this hardware approach could fail

**Out of Scope:**
- Specific exercise programming or training plans
- Clinical rehabilitation (prevention, not recovery)
- Manufacturing and materials engineering for production garment
- Competitive/elite athlete use cases

---

## Knowledge Tree Structure

6 categories, 30 subcategories, problem-first organization.

1. How Beginners Get Injured in the Gym (1.1–1.6)
2. The Invisible Signals (2.1–2.5)
3. What the Eye Can See vs. What It Misses (3.1–3.4)
4. Feedback That Changes Behavior (4.1–4.5)
5. Existing Solutions & Their Gaps (5.1–5.5)
6. The Case Against — Why This Might Not Work (6.1–6.7)

---

## Category 1: How Beginners Get Injured in the Gym

### 1.1 Injury Epidemiology in Resistance Training

**Source:** Keogh & Winwood (2017), The Epidemiology of Injuries Across the Weight-Training Sports, Sports Medicine. Backup: Bonilla et al. (2022), IJERPH.

**DOK 1 — Facts:**
- Injury incidence in weight training: 0.24–4.4 injuries per 1000 hours depending on discipline
- Bodybuilding/recreational has lowest rates (0.24–1.0/1000h); strongman highest (4.5–6.1/1000h)
- Most common injury sites: shoulder (10.5–50%), lower back (12.9–48%), knee (11–21%)
- Most common injury types: strains (muscle), tendinitis, sprains (ligament) — 46–60% of cases
- Acute injuries more common than chronic (26–72% vs 25–50%)
- Traditional strength training is the safest resistance training method
- Overall risk: 1–2 injuries per lifter per year across strength sports

**DOK 2 — Context:** The three body regions that dominate injury statistics — shoulder, lower back, and knee — are exactly where sEMG sensors and camera need to focus. These correspond to the highest-load joints in compound lifts. The relatively low injury rate means detection must be precise — we're looking for rare but high-consequence events.

---

### 1.2 Spinal Injury Mechanisms Under Load

**Source:** Marras & Granata (1997), EMG-assisted model for spine loading during whole-body free-dynamic lifting, J Electromyography & Kinesiology. Backup: Marras et al. (2017) co-contraction review.

**DOK 1 — Facts:**
- Spinal loading during lifting depends on BOTH kinematics (joint angles) AND muscle co-contraction forces
- Kinematics-only models systematically underestimate actual spinal loading because they miss co-contraction
- EMG-assisted biomechanical models are the only validated approach to estimate true compressive and shear forces on the spine during dynamic lifting
- The erector spinae generates the largest moment about the lumbar spine during lifting — its fatigue state directly determines injury risk
- Lumbar flexion under load shifts load from muscles to passive spinal structures (discs, ligaments)

**DOK 2 — Context:** This is the foundational "camera can't see this" finding. Two lifters with identical spinal angles can have radically different spinal loading depending on their muscle co-contraction pattern. EMG on the erector spinae is the only way to estimate whether the spine is protectively co-contracting or dangerously failing.

---

### 1.3 Knee Injury Mechanisms During Squatting

**Source:** Bonilla et al. (2022), Exercise selection and common injuries in fitness centers, IJERPH. Backup: Waryasz & McDermott (2008) on PFPS.

**DOK 1 — Facts:**
- Knee injuries account for 11–21% of all resistance training injuries
- Knee injuries more common in weightlifting (21%) than powerlifting — attributed to greater squat depth
- Dynamic knee valgus (inward collapse) is the primary biomechanical mechanism for ACL injury
- Patellofemoral pain syndrome is the most common chronic knee complaint in gym-goers
- Quadricep dominance (weak hamstrings relative to quads) increases ACL strain

**DOK 2 — Context:** Camera is strong here — knee valgus is well-captured by video (RMSE 3–10°). EMG adds the WHY: vastus medialis fatiguing before vastus lateralis causes the valgus. Detecting muscle imbalance before visible valgus is the early warning.

---

### 1.4 Shoulder Injury Mechanisms in Pressing & Overhead

**Source:** Motlagh & Lipps (2024), Contribution of muscular fatigue and shoulder biomechanics to shoulder injury during bench press, J Strength Cond Res.

**DOK 1 — Facts:**
- Shoulder is the #1 injury site in resistance training (10.5–50% of all injuries)
- The shoulder is a non-weight-bearing joint — not built for the loads imposed during bench press and overhead press
- Muscular fatigue of rotator cuff stabilizers during pressing allows humeral head migration, causing impingement
- Incorrect technique and muscle imbalance (overdeveloped anterior deltoid/pec relative to posterior stabilizers) promotes instability
- Bench press shoulder injuries linked to excessive shoulder abduction >75° and excessive ROM past chest

**DOK 2 — Context:** Supports torso-garment approach for bench press. EMG on posterior deltoid and infraspinatus could detect stabilizer fatigue before impingement. However, for beginners, shoulder injuries during bench are less severe than spinal injuries during deadlifts — injury prevention priority should weight toward lower back/knee first.

---

### 1.5 The Novice Vulnerability Window

**Source:** Parakkat (2004), Effect of experience level on motor control development, Ohio State dissertation. Backup: Armstrong (2018), Waterloo thesis.

**DOK 1 — Facts:**
- Novice lifters show significantly different muscle co-activation patterns compared to experienced lifters
- Experienced lifters develop more efficient recruitment — fewer muscles co-contracting, lower muscular cost for same external load
- Novice lifters exhibit higher antagonist co-contraction (muscles fighting each other), leading to higher spinal loading AND faster fatigue
- Motor control differences between novice and experienced lifters are measurable via EMG even when the external movement looks similar
- Transition from novice to skilled lifting motor patterns takes months of consistent practice

**DOK 2 — Context:** Most important finding for the product thesis. Beginners look like they're doing the same movement as experts, but their muscles are doing something fundamentally different — less efficient, more fatiguing, higher spinal loading. A camera watching a novice and expert performing the same squat might rate both "acceptable," but the novice's spine is under significantly more load. Only EMG reveals this hidden danger.

---

### 1.6 Fatigue as Injury Trigger

**Source:** Bakhshinejad et al. (2025), Effects of intensity and fatigue on kinetics and kinematics of barbell squat, bench press, and deadlift, Sports Medicine - Open.

**DOK 1 — Facts:**
- Systematic review covering fatigue-induced changes across the three major compound lifts
- As fatigue accumulates: bar velocity decreases, range of motion changes, joint angles shift, muscle recruitment alters
- In squats: fatigue causes increased forward trunk lean and reduced depth — shifting load from quads to lower back
- In deadlifts: fatigue causes increased lumbar flexion (rounding) and reduced hip extension — the disc injury mechanism
- In bench press: fatigue causes bar path and shoulder kinematic changes increasing impingement risk
- These kinematic changes are progressive — worsen with each rep in a fatigued set
- Velocity decline is a reliable proxy for fatigue accumulation — but measures the RESULT, not the CAUSE

**DOK 2 — Context:** Bridge between Category 1 (injury) and Category 2 (signals). Fatigue CAUSES the kinematic changes that CAUSE injuries. Camera sees the kinematic changes. EMG detects the fatigue that precedes them. Critical question: how many reps of warning does EMG give before camera detects the kinematic change? If 2–5 reps, that's the product's core value.

---

## Category 2: The Invisible Signals

### 2.1 Muscle Fatigue Biomarkers via EMG

**Source:** Rampichini et al. (2020), Complexity analysis of surface EMG for assessing myoelectric manifestation of muscle fatigue, Entropy.

**DOK 1 — Facts:**
- Classic fatigue biomarkers: median frequency (MDF) decreases, mean frequency (MNF) decreases, RMS amplitude increases during sustained/repeated contractions
- MDF shift is the most widely used and validated fatigue index — power spectrum compresses toward lower frequencies as fast-twitch fibers fatigue
- RMS amplitude increase reflects recruitment of additional motor units to compensate for force loss
- Newer complexity metrics (sample entropy, fractal dimension) capture non-linear changes linear metrics miss
- Dynamic contractions are harder to analyze than isometric — movement artifact and changing muscle length contaminate signal
- For dynamic tasks: consecutive FFT windows tracking MDF peak values across reps is recommended

**DOK 2 — Context:** BioAmp at ~$10/channel can detect RMS amplitude changes (envelope mode). MDF shift requires frequency-domain analysis needing higher sampling rates — ADS1292R at $40–50/2ch is required. For MVP, RMS amplitude changes may suffice as fatigue proxy. For the "2–5 rep early warning" claim, MDF tracking is needed (v2 upgrade).

---

### 2.2 Compensation Patterns — When the Wrong Muscle Takes Over

**Source:** Hakariya et al. (2023), Differences in muscle synergies between skilled and unskilled athletes in power clean, J Sports Sciences.

**DOK 1 — Facts:**
- Skilled athletes use fewer, more coordinated muscle synergies — 3–4 patterns vs 5–6 in unskilled
- Unskilled athletes show excessive co-contraction and less differentiated timing between groups
- The difference is in WHEN muscles activate relative to each other (temporal coordination), not just HOW MUCH
- These synergy differences are consistent and measurable across individuals within skill categories

**DOK 2 — Context:** Compensation isn't just "wrong muscle fires" — it's "wrong muscle fires at the wrong time." Multi-channel EMG with timing analysis can detect this. Single-channel cannot. Argues for 4+ channels minimum.

---

### 2.3 Left/Right Asymmetry & Agonist-Antagonist Ratios

**Source:** Ruas et al. (2019), Alternative methods of determining H:Q ratios, Sports Medicine - Open.

**DOK 1 — Facts:**
- Conventional H:Q ratio (hamstring peak / quad peak concentric): normal ~0.5–0.8
- Functional H:Q ratio (eccentric hamstring / concentric quad): recommended ≥1.0 for knee stability
- H:Q below threshold associated with increased ACL injury risk — particularly women
- EMG-based ratio estimation (comparing RMS amplitudes) is viable real-time alternative to isokinetic dynamometry
- Bilateral asymmetry >10–15% between limbs is clinically meaningful

**DOK 2 — Context:** Bilateral EMG during squats can flag asymmetry in real time. Simple RMS amplitude comparison works — achievable at MVP tier. The >15% threshold gives a concrete trigger for haptic cueing.

---

### 2.4 Spinal Loading — What Kinematics Alone Can't Tell You

**Source:** Marras & Granata (1997) + Granata et al. (2005), Co-contraction recruitment and spinal load during isometric trunk flexion/extension.

**DOK 1 — Facts:**
- Co-contraction of trunk muscles increases spinal stability BUT also increases compressive load by 12–18%
- Novice lifters show higher trunk co-contraction than experienced — spines under MORE load at same external weight
- Kinematics-only model predicts ~60–70% of actual spinal load; remaining 30–40% from co-contraction invisible to cameras/IMUs
- EMG-assisted model adds muscle force estimates, closing the gap

**DOK 2 — Context:** The 30–40% of spinal load invisible to cameras is where injuries happen silently. Strongest research argument for why camera-only is insufficient and why the EMG garment is worth the premium price.

---

### 2.5 Neural Drive & Motor Control Under Fatigue

**Source:** Rampichini et al. (2020) + Bakhshinejad et al. (2025).

**DOK 1 — Facts:**
- Under fatigue: motor unit firing rate decreases, recruitment of higher-threshold units increases, synchronization between units increases
- Increased motor unit synchronization manifests as lower-frequency EMG content — detectable via MDF shift
- Once recruitment limits reached, force output drops — this is the point of form breakdown
- Temporal sequence: MDF shift → force decline → velocity decrease → kinematic change

**DOK 2 — Context:** The temporal sequence is the basis for the "2–5 rep warning window" claim. EMG fatigue markers precede the recruitment limit which precedes the force drop which precedes the visible form breakdown.

---

## Category 3: What the Eye Can See vs. What It Misses

### 3.1 Visual Form Assessment Accuracy by Experts

**Source:** Falk, Aasa & Berglund (2021), Visual assessment accuracy of lumbo-pelvic movements during squat and deadlift, Musculoskeletal Science & Practice.

**DOK 1 — Facts:**
- Experienced physical therapists could not visually detect posterior pelvic tilt until it exceeded 34°
- IMU-based measurement detected tilt changes at much smaller magnitudes
- Inter-rater reliability for visual assessment of squat/deadlift form is moderate at best

**DOK 2 — Context:** If trained PTs can't see dangerous pelvic tilt until 34°, beginners watching in the gym mirror have no chance. Both camera and EMG outperform the human eye.

---

### 3.2 Camera & Pose Estimation Capabilities

**Source:** Bhadane et al. (2025), Systematic review of movement tracking for real-time monitoring in the gym, WIREs Data Mining & Knowledge Discovery.

**DOK 1 — Facts:**
- Markerless pose estimation achieves RMSE <10° for most joint angles during standard exercises vs VICON
- Smartphone systems run at 25–30+ fps with sub-50ms latency
- Accuracy degrades with fast movements, barbell occlusion, poor lighting, loose clothing
- ML classifiers on pose landmarks achieve 85–95% accuracy for correct vs incorrect squat form

**DOK 2 — Context:** Camera layer is mature enough for MVP. Handles visible markers at sufficient accuracy. The limitation is that visible markers are downstream of the actual problem (fatigue, compensation). Camera sees the symptom; EMG sees the cause.

---

### 3.3 The Visibility Gap — What No Eye Can See

**Source:** Marras & Granata (1997) + Rampichini et al. (2020).

**DOK 1 — Facts:**
- Internal spinal loading: invisible to any external observation
- Muscle fatigue onset (MDF shift, RMS increase): invisible — occurs before movement changes
- Motor unit recruitment strategy changes: invisible
- Muscle co-contraction magnitude: invisible — identical posture can mean 30–40% different spinal loads
- Left/right activation asymmetry: invisible until large enough to produce visible movement asymmetry

**DOK 2 — Context:** This list defines the exact value proposition of the EMG layer over the free camera app.

---

### 3.4 The Timing Problem — When Visible Breakdown Is Too Late

**Source:** Bakhshinejad et al. (2025) + Rampichini et al. (2020).

**DOK 1 — Facts:**
- Temporal sequence: EMG fatigue markers → force output decline → velocity decrease → kinematic change (visible)
- Gap between EMG change and visible kinematic change: estimated 2–5 reps in heavy compound lifts
- Velocity decline is intermediate — precedes visible form change but follows EMG fatigue onset
- By the time lumbar flexion is visible on camera during deadlift, erector spinae has been failing for multiple reps

**DOK 2 — Context:** Camera-based prevention is reactive — sees the movement that's already dangerous. EMG-based is predictive — detects the fatigue that will cause the dangerous movement. The 2–5 rep window is the core value.

---

## Category 4: Feedback That Changes Behavior

### 4.1 Motor Learning Principles for Resistance Training

**Source:** van Dijk (2006), Motor skill learning and augmented feedback, University of Twente dissertation.

**DOK 1 — Facts:**
- Motor skill acquisition: cognitive (analytical), associative (refinement), autonomous (automatic)
- Beginners in cognitive stage benefit most from explicit feedback
- Augmented feedback accelerates learning in cognitive stage
- Guidance hypothesis: too much concurrent feedback creates dependency
- Fading schedules (reducing feedback frequency) produce better long-term retention than constant feedback

**DOK 2 — Context:** The three-state cueing gradient (Correction → Reinforcement → Fade) maps directly to this framework. The product needs a built-in fading algorithm — not just detecting problems, but strategically withdrawing cueing to build independence.

---

### 4.2 Real-Time Feedback Modalities Compared

**Source:** Sigrist et al. (2013), Augmented visual, auditory, haptic, and multimodal feedback in motor learning, Psychonomic Bulletin & Review.

**DOK 1 — Facts:**
- Visual feedback: best for spatial accuracy tasks
- Auditory feedback: best for timing tasks
- Haptic feedback: best for force/effort tasks, shows LEAST dependency/guidance effect
- Multimodal (combining modalities) generally outperforms single-modality
- Haptic valuable when visual/auditory channels already loaded (gym environment)

**DOK 2 — Context:** Strongly supports multi-modal: camera for visual feedback (form on phone), haptic for force/activation (vibration on garment). Haptic's low dependency finding means the compression shirt's cueing is less likely to create reliance than screen-based coaching.

---

### 4.3 Feedback Timing — Pre-Rep vs. Mid-Rep vs. Post-Set

**Source:** Sigrist et al. (2013) — same source as 4.2.

**DOK 1 — Facts:**
- Concurrent feedback (during movement): faster initial learning, can create dependency
- Terminal feedback (after movement): slower initial learning, better long-term retention
- Bandwidth feedback (only when error exceeds threshold): optimal balance
- For safety-critical applications: concurrent feedback justified even at cost of some dependency

**DOK 2 — Context:** For injury prevention: mid-rep haptic for safety. For skill development: post-set visual analysis for learning. Product does both.

---

### 4.4 Dependency & Fading — Building Independence

**Source:** van Dijk (2006) + Lauber & Keller (2014), European J Sport Science.

**DOK 1 — Facts:**
- Guidance hypothesis well-replicated: constant feedback improves performance DURING feedback but degrades when removed
- Fading from 100% to ~33% over sessions produces superior retention
- Self-controlled feedback (learner chooses when) produces better learning than externally imposed
- Initial high-frequency transitioning to low-frequency produces best rehabilitation outcomes

**DOK 2 — Context:** Product needs built-in fading. A product that always cues creates a dependent user. A product that strategically fades creates a competent lifter.

---

### 4.5 EMG Biofeedback for Muscle Activation Retraining

**Source:** Toledo-Peral et al. (2022), VR/AR for rehabilitation using EMG as control/biofeedback, Electronics.

**DOK 1 — Facts:**
- EMG biofeedback has long history in rehabilitation — stroke, knee rehab, pelvic floor
- Visual EMG biofeedback improves targeted muscle activation in rehab populations
- Effect strongest when target muscle is difficult to voluntarily activate
- Transfer from biofeedback-trained activation to unmonitored movement is inconsistent

**DOK 2 — Context:** Evidence supports EMG biofeedback CAN change which muscles people recruit — but primarily in clinical rehab, not gym. Transfer problem is the same guidance hypothesis concern. Fading schedule is critical.

---

## Category 5: Existing Solutions & Their Gaps

### 5.1 Personal Training & Coaching

**Source:** Lauber & Keller (2014), European J Sport Science.

**DOK 1 — Facts:**
- Human coaching combines visual observation, verbal cueing, tactile cueing, motivational support, adaptive programming
- No technology currently replicates all modalities simultaneously
- Trainer cost: $50–150/session, 2–3x/week = $400–1800/month
- Trainer visual assessment reliability is moderate — different trainers disagree on same movement

**DOK 2 — Context:** Product doesn't replace a trainer — provides sensing and cueing capabilities at 1/100th the cost per session. Motivation and programming remain gaps.

---

### 5.2 Camera-Based Form Correction Apps

**Source:** Bhadane et al. (2025), WIREs Data Mining & Knowledge Discovery.

**DOK 1 — Facts:**
- Multiple apps exist (Tempo, FITAI, Kemtai, QwikVBT) using pose estimation
- Accuracy 85–95% for correct/incorrect classification
- Limitations: require specific camera positioning, struggle with occlusion, no muscle data
- No published evidence any app reduces injury rates

**DOK 2 — Context:** Camera apps are Layer 1 — free acquisition tool. Gap they leave (no muscle data, no fatigue prediction) is what Layer 2 (EMG garment) fills.

---

### 5.3 Wearable Fitness Products

**Source:** Chen et al. (2025), Biomechanical monitoring of exercise fatigue using wearable devices, Bioengineering.

**DOK 1 — Facts:**
- Whoop/Oura/Garmin track HRV, sleep, strain — readiness markers, not real-time form or fatigue
- VBT devices track bar velocity — performance, not injury prevention
- No consumer wearable monitors muscle activation during lifting
- Athos (EMG compression garment) pivoted from consumer to elite sports

**DOK 2 — Context:** Whitespace is clear: no product combines camera form tracking with EMG muscle monitoring for gym use.

---

### 5.4 Consumer EMG Products — What Failed & Why

**Source:** Toon (2023), Incorporating end-user feedback in smart textile for sports training, University of Derby dissertation.

**DOK 1 — Facts:**
- Athos, Enflux, Myontec struggled with: signal quality during dynamic exercise, washability, electrode contact, cost, "so what" problem (data without actionable feedback)
- Biggest barrier is usability — putting it on, keeping it working during sweat, understanding the data
- End-user involvement in design significantly improved adoption willingness

**DOK 2 — Context:** Previous EMG products failed because they were sensing-only. Measured activation and showed data but didn't close the loop. Our product adds camera (form context), haptic cueing (behavior change), fading algorithm (independence). Camera-first strategy is key difference — free app gets adoption, premium hardware comes after trust.

---

### 5.5 The Whitespace

**Source:** Teikari & Pietrusz (2021), Precision strength training, SportRxiv preprint.

**DOK 1 — Facts:**
- Vision systems progressing rapidly but lack internal physiological state data
- Integrated sensing (external movement + internal muscle state) is the identified gap
- AI/ML models on combined kinematic + EMG data outperform either alone for injury risk prediction
- No commercial product offers this combined approach for consumers

**DOK 2 — Context:** Product sits exactly in this whitespace: camera (external) + EMG (internal) + haptic (intervention). Being first to market with it is the opportunity.

---

## Category 6: The Case Against — Why This Might Not Work

### 6.1 EMG Reliability Problems During Dynamic Exercise

**Source:** Disselhorst-Klug et al. (2020), Surface EMG barriers limiting clinical use, Frontiers in Neurology.

**DOK 1 — Facts:**
- sEMG affected by: electrode placement inconsistency, skin impedance variation (sweat, hair, fat), crosstalk, movement artifact
- Signal-to-noise ratio degrades during dynamic contractions vs isometric
- Inter-session repeatability poor without standardized placement
- Subcutaneous fat thickness affects signal amplitude — heavier individuals get weaker signals
- Problems managed through protocol and processing, not solved

**DOK 2 — Context:** Honest counter to EMG enthusiasm. In a gym with sweating, moving users, signal quality will be worse than research studies. Compression garment helps, disposable electrodes help, processing helps. But beginner population (often higher body fat) will have worse signal. Must be tested, not assumed.

---

### 6.2 Consumer EMG Has Failed Before — Every Time

**Source:** Toon (2023) + Disselhorst-Klug et al. (2020).

**DOK 1 — Facts:**
- Athos: significant funding, compression garments with EMG, pivoted to elite/team sports
- Enflux: smart clothing with EMG + IMU — appears defunct
- Myontec: compression shorts/shirts — remains niche in cycling/running
- Common failures: signal quality complaints, durability after washing, "so what" problem, high cost ($200–400+)

**DOK 2 — Context:** Must address every failure mode: signal quality → compression + disposable electrodes. Durability → removable electronics. "So what" → haptic cueing closes the loop. Cost → camera app is free, garment is premium upsell for users who've experienced value from free tier.

---

### 6.3 The "So What" Problem — Detection ≠ Prevention

**Source:** Battis et al. (2023), Wearable biofeedback for spine motor control, Research Square preprint.

**DOK 1 — Facts:**
- Wearable biofeedback generally improves motor control during feedback sessions
- Evidence for long-term transfer (improvement persisting after feedback removed) is weak and inconsistent
- No study has demonstrated wearable biofeedback reducing actual injury rates in any population
- Gap between "improved control during feedback" and "fewer injuries over time" is unbridged

**DOK 2 — Context:** Biggest honest gap. We can detect fatigue (strong evidence). We can cue the user (moderate evidence). But nobody has proven detect → cue → behavior changes → injuries decrease. This gap is also the opportunity — being first to close it would be genuinely novel.

---

### 6.4 Beginner Compliance — Will They Actually Wear It?

**Source:** Toon (2023) + Battis et al. (2023).

**DOK 1 — Facts:**
- "Ease of use" is #1 adoption factor — above signal quality, above features
- Electrodes requiring skin prep, precise placement, or gel are the biggest compliance barriers
- Users willing to wear smart garments IF they look/feel like normal athletic wear
- Compliance drops sharply if setup time exceeds ~2 minutes

**DOK 2 — Context:** Compression shirt addresses this — looks like normal gym wear. Setup must be: put on shirt, open app, start lifting. Anything more complex loses the user.

---

### 6.5 Camera-Only May Be Enough

**Source:** Bhadane et al. (2025) + Marras & Granata (1997).

**DOK 1 — Facts:**
- Camera achieves <10° RMSE for most injury-relevant joint angles
- For visible form markers, camera accuracy is clinically sufficient
- Only RCT showing form improvement in novice exercisers used vision-based app, not EMG (Chae et al., 2023)
- Camera is free, frictionless, already validated

**DOK 2 — Context:** If product judged on visible form correction alone, camera may be "good enough." EMG layer's value rests entirely on invisible signals. Must prove marginal value through testing.

---

### 6.6 The Trainer Replacement Fallacy

**Source:** Lauber & Keller (2014) + Hegi et al. (2023), Frontiers in Sports and Active Living.

**DOK 1 — Facts:**
- Automated augmented feedback improves technique metrics in controlled settings
- Human coaching provides adaptive programming, motivation, social accountability, emotional support
- Exercise adherence more strongly predicted by social support than technical feedback quality
- Social/motivational element may matter more for beginners than technical correction

**DOK 2 — Context:** Product should be "invisible training partner" not "AI replacement for your coach." Complement to coaching for those who can't afford it.

---

### 6.7 False Safety & Risk Compensation

**Source:** Teikari & Pietrusz (2021) + Lauber & Keller (2014).

**DOK 1 — Facts:**
- Risk compensation (Peltzman effect): safety measures can lead to greater risk-taking
- Athletes with protective equipment play more aggressively
- Direct evidence for wearable-induced risk compensation in gym: none found
- Theoretical concern: beginner trusting "smart shirt" might attempt heavier weights too soon

**DOK 2 — Context:** Product should never say "you're safe to lift heavier." Should say "fatigue accumulating — reduce weight." Framing should encourage caution, not confidence. Never display a "safety score" implying permission to push limits.

---

## Hardware Research Findings

### IMU vs Camera vs EMG — Comparative Analysis

**Finding:** Camera + EMG is the optimal combination. IMU is redundant when camera is present.

**Camera advantages over IMU:**
- Knee valgus: camera RMSE 3–10° vs IMU RMSE 7–15° (Chia et al., 2021)
- Full kinetic chain from single camera vs 3–5 body-worn IMU sensors
- Zero hardware cost (phone), zero calibration, no drift
- IMU magnetometers corrupted by gym equipment (steel plates, racks)

**EMG adds what neither camera nor IMU can provide:**
- Fatigue prediction 2–5 reps before visible form breakdown
- Compensation pattern detection (wrong muscle firing)
- Internal spinal loading estimation (30–40% invisible to kinematics)
- Left/right activation asymmetry
- 95.4% fatigue classification accuracy via SVM on frequency features

**IMU's only unique advantage:** Bar velocity tracking (ICC 0.91–0.96). Performance metric, not injury prevention. Deferrable.

### Form Factor Research — Compression Shirt vs Strap-Harness

**Compression shirt advantages:**
- Produces sEMG signal quality comparable to adhesive electrodes (Ohiri et al., 2022)
- Optimal electrode contact pressure: 15–20 mmHg delivered passively
- Lower experimental failure rates than strap-based systems (PMC 2018)
- Looks like normal gym wear — critical for intimidated beginners
- Compliance: setup under 2 minutes if garment-integrated

**Strap-harness advantages:**
- One-size adjustable (no S/M/L/XL problem)
- Pods repositionable for iteration
- Electronics removable for washing
- Leaves skin exposed for camera tracking

**Recommendation:** Harness for R&D (faster iteration). Compression shirt for consumer product (looks normal, passive contact, less intimidating).

### Partner Alignment Summary

**Fully aligned (8/12):** sEMG sensors (BioAmp), MCU (ESP32-S3), vibrotactile motors (coin ERM), power (LiPo + TP4056), electrodes (Ag/AgCl), phone architecture (camera + BLE), IMU exclusion, FDA strategy (general wellness).

**Divergent (4/12):** TSA squeeze (partner has, we don't yet), body region (lower body vs torso), form factor (compression shirt vs strap-harness), channel count (4 vs 8–14).

---

## 4-Channel Prototype Specification

**Total cost: $121**

| Component | Qty | Price | Placement | Research Justification |
|-----------|-----|-------|-----------|----------------------|
| BioAmp EXG Pill | 4 | $40 | L/R erector spinae + VL/VM quad | KT 1.2, 2.3, 2.4 |
| Ag/AgCl electrodes | 100 | $8 | Under each sensor | SENIAM standard |
| ESP32-S3 DevKitC | 1 | $12 | Waist hub pocket | Partner architecture |
| Coin vibration motors | 6 | $6 | L/R erector spinae, VM, glute med | KT 4.2, 4.3 |
| Smartphone + MediaPipe | 1 | $0 | Propped 6–8ft away | KT 3.2 |
| 800mAh LiPo + TP4056 | 1 | $10 | Waist hub pocket | ~7.6hr runtime |
| Compression shirt + shorts | 1 | $30 | Garment base | KT 6.4 |
| Wiring/build supplies | 1 | $15 | Internal connections | — |

**System loop:** Sense (4ch EMG) → Stream (ESP32 BLE) → See (phone camera MediaPipe) → Think (phone fuses EMG + camera) → Cue (BLE command → vibration motor) → Loop time ~50–200ms.

**5 validation questions this prototype answers:**
1. Can we get clean sEMG from erector spinae and quads during compound lifts through compression fabric?
2. Does EMG fatigue signal actually precede visible form breakdown? (2–5 rep window claim)
3. Does VL/VM ratio divergence precede visible knee valgus?
4. Does haptic cueing change what the beginner does on the next rep?
5. Will a beginner actually wear this?

---

## Sourcing — Austin, TX

**Wave 1 (arrives 1–2 days):** Amazon Prime — ESP32-S3 ($12), coin motors ($6), electrodes ($8), LiPo + TP4056 ($10), wires/breadboard ($8), compression shirt ($15), compression shorts ($15). Subtotal: ~$74.

**Wave 2 (arrives 2–5 days):** DigiKey or Mouser — BioAmp EXG Pill × 4 (~$40) + MOSFETs + headers. Subtotal: ~$47.

**Same-day option:** Micro Center Austin (10900 Domain Dr) — soldering iron, breadboards, wire strippers.

**While BioAmp ships:** Bench-test ESP32 + vibration motors. Build garment pockets. Validate BLE to phone app. When BioAmp arrives, plug in and start EMG testing immediately.

---

## Next Steps

1. **DOK 3 Insights:** Cross-reference findings across categories to identify patterns
2. **DOK 4 SPOVs:** Derive 3–5 contrarian theses from the insights
3. **Partner alignment:** Resolve 4 divergences (body region, form factor, TSA, channel count)
4. **Order hardware:** Wave 1 today, Wave 2 today, start testing in 48 hours
5. **Begin app development:** MediaPipe pose estimation prototype on phone
