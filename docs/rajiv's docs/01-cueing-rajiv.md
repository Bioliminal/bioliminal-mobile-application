# Every EMG Wearable Built a Dashboard. None Built a Coach.

*Bioliminal Series, Post 1 of ~5 · Rajiv Nelakanti*

> **About this series.** Bioliminal is a closed-loop neuromuscular coach we're building as a four-person team through the Gauntlet AI fellowship. This is the first post in a team series. Coming next: the trainer-market de-bundling thesis (Rajiv), the sEMG signal chain at a consumer-realistic BOM (Rajat), the biomech ML pipeline that turns a single phone video into joint moments and muscle forces (Aaron), and the mobile and live-capture experience (Kelsi).

---

## The rep that looked fine

A man is doing pull-ups. Chin goes above the bar, the rep counts, the video looks clean. His biceps are doing most of the work and his lats are along for the ride. He doesn't know this. He has never known it. And in eight months his elbows are going to tell him.

That's the problem every EMG wearable in the last ten years was supposed to solve, and none of them did. Even if this guy had owned a $700 compression shirt (the kind that picks up the tiny electrical signals your muscles emit when they contract, and streams them to an app), the best it would have done is capture the signal, wait for the set to end, and show him a chart afterward. The coaching moment came and went and the product was not in the room for it.

This is the spiky claim the rest of the post is downstream of:

> **Measurement without intervention is the defining failure of the EMG wearable category.**

The industry raised real venture money to build beautifully engineered meters when the job was coaching. I'm building Bioliminal as the first serious attempt to close the *full* loop: sense, reason, cue, and then verify that the cue actually changed what the muscle did. The verify step is the one nobody has. It's where the AI-native part of the product actually lives.

And the sense step is already multimodal. We fuse sEMG with phone computer vision, because muscle activation and joint kinematics are two different signals that tell you two different things, and neither alone is enough to coach from.

---

## The category, flatly

A few representative products and what they cost.

**Athos.** Compression garment with 14 EMG channels, 2 heart-rate sensors, 2 breathing sensors. Current pricing: $398 for the compression shirt plus one Core, $547 for the full-body kit with one Core, $696 for the full-body kit with two Cores ([wearables.com product page](https://wearables.com/products/athos-shirt)). Signal quality has been validated in peer review against lab sEMG on major lower-body muscles ([Lynn et al., *J Sports Sci Med* 2018](https://pubmed.ncbi.nlm.nih.gov/29769821/)). The product is a meter with a dashboard.

**Myontec Mbody.** European smart shorts with sEMG, marketed to elite sport and research. €500 to €1,000+ depending on configuration. [myontec.com](https://www.myontec.com/).

**mTrigger.** Clinical sEMG biofeedback unit paired with a phone app, aimed at PTs, OTs, and athletic trainers. Feedback is real-time visual activation on the app, including a game mode for patient engagement. $499 for the individual unit, $1,399 for the clinical bundle ([mtrigger.com](https://mtrigger.com/)). A better information display than the rest of the category, but just still an information display. The clinician is expected to turn the trace into coaching.

**The CV form-check category.** AiKYNETIX, Kemtai, Form Fix, CueForm AI, and a growing pile of similar apps. All running pose estimation (MediaPipe or MoveNet under the hood) to flag movement faults from phone video. They see *what moved*. They cannot see *what fired*. A knee that tracks correctly on camera while the glute is silent and the tensor fasciae latae is doing the work is invisible to every product in this bucket. Adding sEMG to CV is the missing channel, and nobody in the CV camp is doing it.

All of these products exist because the underlying science is real (sEMG on one side, markerless pose estimation on the other). None of them ever crossed the threshold from *information product* to *coaching product*. None of them can say "feel it *here*, not there" and then confirm they changed anything.

---

## Why the category kept missing it

Three reasons, roughly in order of how annoying I find them.

**1. Sensors are legible to investors. Interventions aren't.** A 14-channel sEMG garment is a thing you can demo. A closed coaching loop is a behavior change you have to measure over weeks. The first pitch deck is easy. The second one isn't. So the category kept building the first one.

**2. Hardware-first organizations treated coaching as a UX layer.** My read, from looking at what each product actually shipped rather than what the founders said, is that these companies solved the front-end sensing problem beautifully and then bolted a coaching experience on top. The coaching theory (how cueing is supposed to work, when to fire it, which muscle, what modality) lived downstream of the hardware rather than upstream of it. The tell is what the UI does once the signal is clean. Every product in this space shows you a chart.

**3. There is almost no theory of device-delivered cueing.** This one is the most interesting. The literature on *tactile cueing for muscle activation during exercise* is small, inconsistent, and almost entirely based on experimenter hands rather than devices.

That last point deserves its own section, because the honest version of my pitch depends on being straight about what the evidence says and doesn't.

---

## What the cueing literature actually says

The tactile-cueing evidence is genuinely mixed, and I want to walk through it in both directions.

**The "tactile doesn't help much" camp:**

- **Huang et al. (2018).** 30 subjects, shoulder exercises, EMG amplitude measured. Any feedback beat no feedback. Tactile plus verbal was approximately equal to verbal alone. Tactile didn't add on top ([*J Sport Rehabil* 2018](https://journals.humankinetics.com/view/journals/jsr/27/5/article-p424.xml)).
- **Lehecka et al. (2024).** 42 subjects. Verbal cueing increased peak glute force by 13.5% (p=0.000). Tactile cueing (self-administered tap) did not significantly increase peak force ([*Int J Sports Phys Ther* 19(3):284–289](https://pmc.ncbi.nlm.nih.gov/articles/PMC10909302/)).

Read those two alone and the conclusion is obvious. Verbal is doing the work, tactile is a rounding error, don't waste money on hardware haptics.

**The "tactile does something verbal doesn't" camp:**

- **Lehecka et al. (2024), same paper.** While tactile didn't beat verbal for peak glute force, it *did* significantly improve broad jump distance by 3.0% (p=0.000). Different task, different motor output, tactile won where verbal didn't. That's the footnote that would normally get buried, and it's exactly the signal we're chasing.
- **De Mey et al. (2019).** Combined tactile and verbal cueing improved 9 out of 10 exercise-guidance combinations for scapulothoracic EMG or kinematics, beating verbal alone ([*J Electromyogr Kinesiol* 2019](https://www.sciencedirect.com/science/article/abs/pii/S105064611830453X)).
- **Mixed-reality visual plus verbal for deep core.** Combined MR-visual and verbal cueing outperformed verbal alone for core muscle EMG activation during deep core exercises ([*Virtual Reality* 2022](https://link.springer.com/article/10.1007/s10055-022-00726-3)).

The honest reading: **any feedback beats no feedback**, and the *modality that wins depends on the exercise, the load, the muscle, and the motor output being measured*. Tactile sometimes wins on one metric and not another in the same study. The optimal system is almost certainly multimodal, not "pick one channel."

There's one more thing about this literature that I find hard to get past. **Almost every tactile-cueing study used a human hand as the cue.** Lehecka: self-administered tap. De Mey: therapist manual contact. Huang: clinician-led touch. The only device-based comparison I could find is Muscle Minder, a twisted-string-actuator squeeze shirt out of UBC's SPIN Lab that ran a bicep-curl-only pilot at n=6 ([FORCE Technology case study](https://forcetechnology.com/en/cases/haptic-interfaces-mind-muscle-connections-electronics), [project portfolio](https://vanessacarpenter.com/portfolio/muscle-minder/)). One pilot, one exercise, six subjects. That's the entire device-delivered record.

So the state of the evidence is this. The hand-based studies are inconsistent, the device-based studies don't really exist, and anyone claiming they *know* which cueing modality works best during resistance exercise is making it up.

---

## What the practitioner evidence says

When published evidence is this thin, the next best source is people who have been running the experiment in their own practice for decades.

I've been working through the cueing problem with **Lawson Harris**, a Pilates educator with 38+ years of in-practice experience and an advisor on this project ([bio at Millennium Performance](https://www.mlpwellness.com/lawson-harris)). She's been my reference point on what skilled, real-time cueing actually looks like once you strip the research protocols away and watch a practitioner work.

Picture a woman bench pressing. Her bar path is textbook. Her serratus anterior has been quietly dormant for 12 weeks, and she'll find out about it when her shoulder starts clicking. A good Pilates-trained eye catches that on rep two. Lawson's does. And then she does something about it.

Two things she told me that sharpened the product in ways the literature couldn't.

**1. Tactile and visual aren't in competition. The practitioner picks based on what the rep is asking for.** Her read on the mixed evidence, unprompted: *"Both are terrific. Touch cues are a little bit more effective in certain situations when spatial relations are less prominent."* That's a working clinician's reconciliation of Huang and Lehecka and De Mey in one sentence. It's exactly the framing our agent needs to make in real time. Not "pick a modality" but "pick the right cue for what this rep is missing." On vibration versus pressure as the tactile modality, Lawson's position is that the difference is subjective enough that the user should probably get to choose.

**2. Her highest-value cueing is mid-rep, and it's graduated pressure.** Lawson's most differentiated move isn't the pre-rep setup. It's her eye mid-rep, catching a stabilizer that's under-recruited, and applying a precise graduated squeeze on the muscle that needs more drive. She is, in effect, a biological closed-loop controller. Perception, reasoning, graduated pressure, re-observation, adjustment. That is the loop we're trying to approximate in hardware, and it's why mid-rep graduated pressure sits at the center of our cueing design. Not because a paper told us to, but because one of the sharpest practitioners I've encountered does it that way.

Here's the honest counterweight, and I want to state it explicitly because it matters for scope. **Some of what Lawson does is hardware-unreachable.** When she's cueing the pelvic floor, she does it with a precise, professional fingertip two inches above the pubic bone. When she's checking whether the transverse abdominis or internal obliques are actually firing (muscles that hide behind the external obliques and rectus abdominis), she does it with a deep, deliberate jab through the outer layer that no sEMG electrode and no haptic band is going to replicate trustworthily. The skilled-hand parts of her practice are the skilled-hand parts for a reason. Our product does not replace them. It extends perceptual judgment into the larger surface-accessible muscle groups (erector spinae, lats, pecs, external obliques) and leaves the deep-cavity and precision-contact work where it belongs, with the practitioner.

I'll pick this thread up in tomorrow's post on trainer-market de-bundling. For now, the one-line version. Perceptual judgment on accessible tissue is software's problem to solve. Perceptual judgment on tissue a sensor can't reach is still, and should still be, the practitioner's.

---

## Sense, reason, cue, **verify**

Here's the loop, with the part nobody else has emphasized in bold.

1. **Sense.** Multi-channel sEMG on the target muscle group, phone CV for kinematics. Activation *and* movement, at the same time.
2. **Reason.** An agentic LLM over a curated knowledge base:
    - **Fascial-chain force transmission.** [Wilke et al., *Arch Phys Med Rehabil* 2016](https://pubmed.ncbi.nlm.nih.gov/26281953/), the cadaveric review (62 dissection studies, 6,589 screened) that found strong evidence for the Superficial Back Line, Back Functional Line, and Front Functional Line. [Kalichman, *J Bodyw Mov Ther* 45:569–575, 2025](https://pubmed.ncbi.nlm.nih.gov/41316622/), a more recent systematic review reporting that **in vitro** studies show fascia transmits up to ~30% of mechanical force between adjacent muscles, with in vivo evidence described as partial and limited. Worth citing. Worth not overclaiming.
    - **Load-dependent cueing boundaries.** [Calatayud et al., *Eur J Appl Physiol* 2016](https://pubmed.ncbi.nlm.nih.gov/26700744/). Trained lifters can voluntarily redistribute activation between pec and triceps at 20 to 60% of 1RM, but not at 80%. Cueing works in the submaximal zone and breaks down when all motor units are already firing.
    - **Attentional focus for hypertrophy.** [Schoenfeld et al., *Eur J Sport Sci* 2018](https://pubmed.ncbi.nlm.nih.gov/29533715/). Internal focus produced biceps growth of 12.4% versus 6.9% external over 8 weeks of matched training in untrained subjects.
3. **Cue.** Haptic feedback on the muscle. Timing and modality are hypotheses, not settled.
4. **Verify.** *The same sEMG sensor that fired the cue now reads whether the activation actually changed.* Every session produces per-rep evidence on whether the cue worked for this user, this exercise, this load, this rep. That evidence flows back into the model.

Consider an eight-count set. Reps one through four, her glutes are driving. Reps five through eight, her lower back has quietly taken over. She hits her rep target and calls it a glute day, except she just trained her lumbar erectors. This is exactly the failure mode verify is built to catch. Not one measurement at the start and a dashboard at the end, but continuous per-rep evidence that the muscle you intended to train is still the one doing the work.

That last step is where this stops being a wearable and starts being an AI product. Every session produces an observed activation change the model can learn from, not a user self-report on a 1–5 scale. Every user's model sharpens with use.

Nobody has built this before. Not because the pieces are hard individually, but because no previous team had all four pieces on the same device at the same time.

---

## What we're actually building at Gauntlet

I'm in the Gauntlet AI fellowship, and the window to prove this out is short. A few honest things about scope.

**We are testing feasibility across the full loop**, not shipping a production device. The goal for this capstone is to show we can sense cleanly, reason over the signal, deliver a cue, and verify the change, even at low channel count, even on a single lift, even on a single muscle group.

**We are testing multiple cueing modalities**, not committing to one. The hardware prototype carries both vibrotactile and graduated-pressure (twisted string actuator) channels. The load-bearing hypothesis, grounded in Lawson's practice pattern and in the mechanoreceptor science below, is that **mid-rep graduated pressure on an under-recruited muscle** is the highest-value cue a wearable can deliver during a set. Vibrotactile is tested alongside it, both as a standalone modality and as a complementary pre-rep attentional cue. Lawson's position on pressure versus vibration is that the difference is subjective enough that the user should probably get to choose, so "pick your tactile" is on the table as a product surface too. Whichever configuration wins on sEMG-verified activation change, we ship.

**There's real mechanoreceptor science motivating the pressure channel**, and I want to cite it without overclaiming. Merkel and Ruffini mechanoreceptors encode sustained pressure and are slow-adapting. Pacinian corpuscles encode vibration and are fast-adapting, habituating within seconds ([Johansson & Flanagan, *Nat Rev Neurosci* 10:345–359, 2009](https://www.nature.com/articles/nrn2621)). Vibrotactile perception declines with sustained stimulation in a body-location- and activity-dependent way ([Wentink et al., IEEE EMBC 2011, PubMed 22254645](https://pubmed.ncbi.nlm.nih.gov/22254645/)). The caveat I owe the reader is that this science is from fingertip manipulation and prosthetic-feedback contexts, not from limb-worn bands during resistance exercise. The extrapolation is reasonable but has never been tested in the context that matters, which is exactly why someone has to go build the instrument and run the test.

---

## The counter I take most seriously

Not "pressure isn't better than vibration." That's a comparison I'm genuinely happy to run and lose.

The counter I find hardest to wave off is this. **What if verbal and visual cueing is already enough, and the whole tactile hardware layer is effort the category shouldn't be spending?** The Huang and Lehecka results above point in this direction. A good voice prompt through an earbud plus a live skeleton overlay on the phone might already be most of the way there. If that's true, the haptic stack is a solution in search of a problem.

I don't think it's true, but I can't dismiss it either. Here's how we plan to find out. Our product is going to ship verbal and visual feedback as a baseline regardless of any haptic layer. The honest question is whether **layering tactile cueing on top of verbal and visual** produces an additional, sEMG-verified change in muscle activation worth the hardware cost. Same user, same exercise, with and without the tactile layer. If the tactile layer doesn't meaningfully move the activation needle on top of a good verbal-plus-visual baseline, we should know that early, say it out loud, and rescope. I'd rather kill the haptic thesis cleanly than drag an unjustified hardware bet into demo day.

That's the actual spiky claim of this post. Not "pressure is the answer." It's that **the answer is knowable**, and everyone before us was equipped to guess.

---

## What the rest of the series looks like

The team is writing over the next few days. Previews, based on the work we've actually been doing this week.

- **Rajiv on the de-bundling of personal training** (tomorrow). The personal training industry sells perceptual judgment, programming knowledge, accountability, and human connection under one hourly rate. Three of those come apart with sensors and LLMs. One doesn't. A respectful account of which is which, and a pitch to elite trainers on how Bioliminal multiplies their reach instead of replacing them.
- **Rajat on injury prevention and the signal chain.** How do you get usable sEMG out of a $79 sensor signal chain (INA128 instrumentation amplifiers, Ag/AgCl electrodes, a bandpass filter tuned to 20 to 500 Hz) when commercial reference hardware costs several times more? Wave 1 ships at 4 channels on ESP32 ADC to validate placements. The upgrade path to 10+ channels with a 24-bit ADC is the Wave 2 story.
- **Aaron on the biomech ML pipeline.** Why the server-side pipeline switched from MediaPipe → MotionBERT → HSMR to **MediaPipe → WHAM → OpenCap Monocular**. The rules we want to flag (Hewett knee abduction moment, Harris-Hayes hip adduction angle) are defined on *forces and moments*, not raw pose angles. OpenCap Monocular (Gilon et al. 2026) gives us joint moments, ground reaction forces, and muscle forces from a single phone video. And why the phone stays deliberately dumb.
- **Kelsi on the mobile and CV side.** Live pose overlay, the capture UX, and how the whole loop feels when it's running in your pocket.

Later posts in the series may cover the market we call "replaces nothing with something" (the solo optimizer who would never hire a trainer), the user archetypes we're designing for (hypertrophy, strength, longevity, rehab, movement-quality diagnostic), and the research-platform angle (every session produces a data point on a literature question that's been open for a decade).

---

## Close

The EMG wearable category spent ten years proving that data isn't a product. Coaching is. We're building what should have existed ten years ago, and we're going to show the work cue by cue, set by set.

Our edge is that we are an AI-native team building this in the AI-first era. Every previous attempt in this category was a hardware company that tried to bolt intelligence on top. We are building the coaching brain first, with current-generation tools: frontier-model agents reasoning over a curated biomechanics and fascial-chain knowledge base, modern on-device pose estimation and markerless kinetics (MediaPipe, WHAM, OpenCap Monocular), multi-channel sEMG fused with CV at the model layer, and a deterministic rule layer over the LLM so that safety-critical decisions (load, fatigue thresholds, compensation flags) don't rely on an LLM alone guessing right. The closed-loop verify step is what turns the whole thing from a plausible AI product into a learning one. Every session produces ground-truth evidence on whether the cue worked, and that evidence trains the next cue.

If any of this resonates, whether you're a builder in hardware, haptics, biomech ML, or sports science, or a PT or trainer who wants tools that match how you already think, reach out. We'll respond.

**Subscribe** for the rest of the series.

*— Rajiv, for the Bioliminal team*
