# Practitioner Notes — Lawson Harris (Pilates Instructor)

Source: conversation between Rajiv Nelakanti (Bioliminal team) and Lawson Harris, transcribed 2026-04-18.

---

## The conversation

> **Rajiv:** Hey Lawson — wanted to get your thoughts on pre-rep vs mid-rep cueing. Some of our research says that mid-rep cueing may cause too much cognitive load while repping, but I know from personal experience training with you that graduated pressure mid-rep is high value in making sure I'm recruiting the target muscle and the stabilizers.

> **Lawson:** I think the issue is who's on the table. Do you have a big brain and can handle cues mid-rep. Intelligent, focused, dedicated clients can handle a mid-rep cue. Beginners or people who don't have a good brain–body connection — not so much. Sometimes I'll even wait until the exercise is over to correct things, then have them do the exercise again.

## The core insight

**Cue timing is not a universal design choice — it's user-skill-dependent.**

The right cadence for a cue depends on the user's cognitive bandwidth and mind–body connection:

| User profile | Tolerated cue timing | Lawson's practice |
|---|---|---|
| **Advanced** (focused, good proprioception, mind–muscle connection trained) | pre-rep AND mid-rep | graduated pressure mid-rep to reinforce target-muscle recruitment and stabilizer firing |
| **Intermediate** | pre-rep; sparing mid-rep | fewer mid-rep cues, timed carefully |
| **Beginner** (weak mind–body connection, high cognitive load just to move correctly) | post-rep or even post-set | "wait until the exercise is over to correct things, then have them do the exercise again" |

## Why this matters for the product

Our algorithm currently fires cues at rep-completion (effectively pre-rep for rep N+1). That's correct **for a single vibrotactile motor on the agonist**, where the modality itself competes with execution attention. But it assumes a single user profile.

To actually deliver coach-level cueing, the product needs a **user-level dimension** built into the cue strategy:

- **Beginner mode:** fewer cues, later timing, simpler semantics. Possibly: suppress cues within-set entirely, deliver a debrief at set-end with specific corrections ("rep 6 was where you started to lose form"). Or: only fire on severe form breaks, never on moderate fatigue.
- **Intermediate mode:** current v0 behavior — pre-rep cue on fatigue, silent on compensation.
- **Advanced mode:** mid-rep cue capability unlocked, finer-grained (per-phase of rep), and graduated pressure (TSA) as a separate channel from vibration.

## Aligns with the motor-learning literature

This doesn't contradict the Wulf external-vs-internal focus research (Chua et al. 2021, meta-analysis); those studies are about **where attention is directed** (body part vs. movement outcome), not **when a cue arrives**. The two axes are independent:

- WHERE: external focus > internal focus — true for everyone regardless of skill level
- WHEN: cue timing tolerance — scales with user expertise

Also aligns with Sigrist et al. 2013 haptic-guidance fading principle: haptic cues must be *faded* to avoid dependency. Lawson's approach is essentially the fading principle in practice — beginners get denser, later, simpler feedback; advanced users get sparser, earlier, richer feedback.

## Actionable design principles from Lawson

1. **Cue density scales inversely with skill.** A beginner needs fewer, simpler cues; an advanced user can absorb more, richer ones.
2. **Cue timing scales later → earlier with skill.** Beginners benefit from post-rep or post-set reflection. Advanced users benefit from mid-rep reinforcement.
3. **Modality matters:** vibrotactile is best as a discrete attention-tap (pre-rep); graduated pressure is best as sustained reinforcement (capable of mid-rep delivery because it doesn't habituate or compete for attentional bandwidth the same way).
4. **"Intelligent, focused, dedicated" ≈ the target market for a premium coaching product.** If this is the anchor user, mid-rep TSA pressure is genuinely high-value — we shouldn't design the system to preclude it.

## User-level × channel matrix

Extending Lawson's principle: cues live in **channels** (haptic, visual, verbal, post-set debrief) that are independently enabled per user profile. The same `CueDecision` from the algorithm fans out across whichever channels the active profile has turned on.

|  | Live haptic | Live visual | Live verbal | Post-set debrief |
|---|---|---|---|---|
| **Beginner** | minimal / off | minimal / off | minimal / off | **rich debrief** — the primary feedback mechanism |
| **Intermediate** | fatigue cues (current v0 defaults) | compensation badge + fatigue bar | light targeted prompts | summary + fatigue curve |
| **Advanced** | fatigue + stabilizer warnings | live per-muscle activation meter | stabilizer-recruitment prompts | deep analytics + trends |

**Key design rule that falls out of this:** every algorithm decision always writes to the session log regardless of which channels fire in real time. The post-set debrief therefore has the full story even for a beginner profile where no live channel triggered — the user still sees "here's where your form started drifting, here's where your biceps started fading" at the end, in a low-cognitive-load moment.

## Demo day strategy

The matrix suggests the **beginner path is the simplest-to-demo**: silent set, dashboard opens at End Set, everything is in the post-set debrief. That's visually impressive and doesn't rely on haptic/verbal delivery landing reliably on stage. The user-level selector then lets us flip to **advanced** for 30 seconds to demonstrate the full capability (live haptic + visual meter + verbal prompt on the same movement).

Lead with simplest, showcase capability with a toggle, never need to apologize for a haptic that the audience can't feel.

## Roadmap implications

**v0 (current):** single-motor vibrotactile, pre-rep timing, single universal user profile. OK for first demo.

**v1:** user-level selector on first-run onboarding (self-reported: beginner / intermediate / advanced). Cue density, threshold aggressiveness, and timing scale with level. Still vibration-only but adaptive.

**v2:** TSA (Twisted String Actuator) as second haptic channel for graduated pressure. BLE protocol needs a `PRESSURE_RAMP` / `PRESSURE_HOLD` / `PRESSURE_RELEASE` opcode family, independent of the existing `PULSE_BURST` opcode that serves vibration. Advanced-mode unlocks mid-rep pressure cueing.

**v3:** closed-loop coaching — detect user's mind–body connection quality automatically (e.g., form consistency across reps, response-to-cue improvement rate) and auto-tune the cue profile over time. Matches Lawson's instinct that the right cadence is what the user can absorb.

## What this does NOT change

- Current Phase 2 algorithm (first-5-reps calibration, rolling baseline, 15% drop threshold) is still correct for v0 single-user defaults.
- Vibration at rep-completion timing is still the right modality-specific choice.
- Compensation-gate silent-suppression in v0 stands.

## What this DOES change

- Our product narrative: "single algorithm, fires when fatigue detected" → "adaptive cueing system tuned to user skill and intent." Richer, more defensible product story.
- The fitness-expert consult agenda grows: beyond "which muscles to instrument," we also ask "how does cue density/timing scale for your clientele across skill levels?"
- Extensibility requirement on the BLE protocol: must accommodate sustained-pressure cueing, not just discrete bursts.

---

**File purpose:** capture practitioner wisdom that informs product strategy but isn't a firmware or app spec. Lives alongside the handshake docs as context, not as an implementation target.
