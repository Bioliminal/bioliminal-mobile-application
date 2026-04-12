# Plan Changes — Plain English Summary

**Date:** 2026-04-11
**For:** AuraLink team + anyone catching up on the project.
**Source documents (if you want the long versions):**
- `docs/research/model-framework-recommendations-2026-04-10.md`
- `docs/research/deep-read-sensing-2026-04-10.md`
- `docs/research/deep-read-biomech-2026-04-10.md`
- `software/mobile-handover/README.md`

---

## What changed in plain English

We added 16 new research papers to the project on 2026-04-10, then read every
one of them in full. The result: a meaningful course correction on three things,
and a confirmation of one team decision. None of this is a rewrite. The 4-movement
screening protocol, the fascial-chain framing (SBL/BFL/FFL), the wellness
positioning, and the overall architecture all stay the same. What changed is
*which models we use server-side*, *what we put on the phone*, *how we talk about
the Sahrmann movement-system framework in our reports*, and *how we handle body
type at onboarding*.

### Change 1 — Server pipeline backbone

**Before:** plan was MediaPipe → MotionBERT → HSMR → chain reasoning.

**After:** MediaPipe → WHAM → OpenCap Monocular → chain reasoning, with HSMR
kept as a side branch only for the rollup movement.

**Why this matters in plain English:** there's a brand-new tool called OpenCap
Monocular (Gilon et al. 2026) that takes a single phone video and produces not
just 3D pose but also *joint moments, ground reaction forces, and muscle
forces*. That last part is huge — the rules we want to flag (the Hewett knee
abduction moment, the Harris-Hayes hip adduction angle) are actually defined on
forces and moments, not on raw pose angles. The old plan would have stopped at
pose and we'd have been left rolling our own kinetics layer. OpenCap Monocular
gives us all of that out of the box, it's open source, and Stanford/Utah even
host a free cloud endpoint. We keep HSMR for one specific job — the rollup
movement, where we need detailed per-segment spine information that OpenCap
Monocular doesn't focus on.

**What you do:** nothing immediately. The current code already keeps these
models behind protocols (`Lifter`, `SkeletonFitter`), so the swap is a future
implementation detail, not a refactor today. The L2 plans stand.

### Change 2 — Phone app stays simple, model is locked in

**Decision:** the phone ships **MediaPipe BlazePose Full** and only that. No
3D models, no biomechanical models, no chain reasoning on the phone. Everything
else lives on the server.

**Why this matters in plain English:** the deep read confirmed that none of the
fancier models (WHAM, OpenCap Monocular, HSMR, MotionBERT, ViTPose) are realistic
to run on a phone today. They're all GPU server models. The phone's job is to
capture good video, run BlazePose for live skeleton overlay, and upload. That's
it. This is actually good news — it makes the phone teammate's scope crisp.

**What you do:**
- Hand the phone teammate the package at `software/mobile-handover/`. It contains
  the Dart interface contract, a JSON schema, a sample valid payload, the model
  download instructions, and a smoke-test script. He can start integrating today.
- Keep the model behind a small Dart interface (`PoseDetector`) so we can swap
  in MoveNet Thunder or HRPose-small later without an app release if we want to
  experiment.

### Change 3 — Sahrmann Movement System framework: cherry-pick, don't adopt

**Decision:** we use the *kinematic patterns* from the Sahrmann/Movement System
literature, but we do **not** put MSI diagnostic labels in our reports.

**Why this matters in plain English:** the deep read found a 2016 RCT (Van
Dillen, n=101) that tested MSI classification-specific treatment for chronic low
back pain against generic movement training and found **no difference**. There's
also a 2023 critique (Joyce et al.) arguing that movement-pattern diagnoses
haven't been shown to predict pain, disability, or future injury. So labeling
someone with "Lumbar Flexion Bias" in our report isn't defensible. But — and
this is important — we *did* find one paper (Harris-Hayes 2018, hip adduction
during single-leg squat) that does link a specific kinematic pattern to a real
clinical outcome (r = -0.67, p < .01). That's exactly the kind of rule we *can*
defend.

**What you do:** when we get to writing the rule YAML files and the report
narrative templates, every rule needs an evidence block (level of evidence,
citation, mechanism). The report shows people *what we saw* in their movement
and what the literature says it correlates with — not a diagnostic label.

### Change 4 — No onboarding questionnaire (team decision)

**Decision (already taken by team):** we don't ask users to self-report their
hypermobility status or fill out a Beighton questionnaire at onboarding. Body
type gets auto-derived from the SKEL shape parameters (β vector) that the
server-side models produce.

**Why this matters in plain English:** the team's instinct was right —
onboarding cognitive load is already high, adding questions makes it worse. The
research-integration-report assumed we'd have to ship a questionnaire. The new
research papers (specifically OpenCap Monocular and HSMR) extract enough body
shape information automatically that we don't need to. It costs us one extra
server inference at first session; the result is cached forever after.

**What you do:** L2 Plan 2 currently has a "questionnaire intake" task. That
needs to be downgraded to "auto-populate body type from server-side analysis."
I'll update the plan in a separate pass.

### Change 5 — Free tier *will* use the server

**Decision (already taken by team):** the free tier is allowed to call the
server. Free vs premium is about **feature depth**, not about where compute
happens.

**Why this matters in plain English:** this corrects a confusion in the original
research-integration-report. The team's framing — "free is the funnel, premium
is what we want people to upgrade to" — only works if free actually delivers a
useful result. So free-tier users still get a server-processed report; it just
shows fewer things (top-line score, biggest finding, no full chain narrative,
no temporal trends, no body-type adjustment). Compute cost is a small operational
worry, not a tier-defining constraint. We control it with caching, rate limiting,
and quality-gate rejection of obvious junk uploads.

### Change 6 — Chain reasoner stays rule-based at launch

**Decision:** v1 ships with rule-based chain reasoning. The Graph Neural Network
chain reasoner is post-launch.

**Why this matters in plain English:** training a GNN needs labeled training
data (PT-reviewed sessions with chain-involvement labels), which we don't have
yet. Joyce 2023 also warns that learned classifiers trained on weak labels
inherit the weakness. Rule-based is auditable, deterministic, doesn't need
training data, and matches the open-source story. We collect labeled data over
the months after launch, then train v2.

**What you do:** L2 Plan 2 is already rule-based-only — no change needed.

---

## What Aaron needs to do (concrete action list)

1. **Hand off the phone package.** Send the phone teammate the contents of
   `software/mobile-handover/`. Tell him to start with the README.
2. **Sync with the server-coding session.** Drop them
   `docs/2026-04-11-server-session-note.md` so they know what the Dart hand-off
   contains and what the contract guarantees about incoming session payloads.
3. **Update L2 Plan 2** for: (a) remove the questionnaire task, replace with
   auto-populate from `SkeletonFitter` output; (b) require an `evidence:`
   block in every rule YAML; (c) document the MSI cherry-pick stance in the
   rule-loader docstrings.
4. **Register for OpenCap SimTK access** (free, but takes a Data Use Agreement
   step). This unlocks the OpenCap public dataset for evaluating our pipeline
   on real clinical-grade ground truth.
5. **Plan calibration data collection.** Target 20–30 subjects × the 4 movements,
   with a PT-annotated subset for evaluation. Capstone-scale feasible. This is
   the dataset that actually matters for tuning rule thresholds — public datasets
   are secondary.
6. **Keep an eye on Rajiv's rollup question.** Until we know if rollup is in the
   protocol, the rollup branch (HSMR + phase segmentation) is interface-only.

---

## What to communicate to teammates

Short version you can paste into Slack/Discord:

> Quick research update from yesterday's deep read of the new papers:
>
> 1. **Server pipeline backbone is changing** from MotionBERT+HSMR to
>    WHAM+OpenCap Monocular. Same overall shape, but OpenCap Monocular gives
>    us joint moments and forces from a single phone video for free, which is
>    what our rules actually need. HSMR is now the rollup-only side branch.
> 2. **Phone app stays simple.** Ships MediaPipe BlazePose Full only.
>    Everything else is server-side. Phone teammate has a hand-off package at
>    `software/mobile-handover/` — start with the README.
> 3. **Sahrmann MSI: cherry-pick.** We use the kinematic patterns and the
>    movement-pattern training literature, but we DON'T put MSI diagnostic
>    labels in reports. Van Dillen 2016 RCT (n=101) showed MSI classification
>    didn't beat generic training for LBP, and Joyce 2023 critiques the
>    validity of the labels. Harris-Hayes 2018 (hip adduction → function
>    correlation) is the kind of rule we *can* defend.
> 4. **Body type:** no questionnaire (per team decision). Auto-derived from
>    server-side body-shape analysis.
> 5. **Free tier:** uses the server, just gets less detail than premium (per
>    team decision).
> 6. **Chain reasoner:** rule-based at launch. GNN is post-launch once we have
>    labeled data.
>
> Long version: `docs/research/model-framework-recommendations-2026-04-10.md`.
> Plain-English version: `docs/2026-04-11-plan-changes-plain-english.md`.
> Full per-paper notes: `docs/research/deep-read-sensing-2026-04-10.md` and
> `docs/research/deep-read-biomech-2026-04-10.md`.

---

## Frequently asked questions (anticipated)

**Q: Are we throwing away the existing scaffold work?**
No. Plan 1 (pipeline framework + core stages) is unchanged. Plans 2, 3, 4, 5
are unchanged in structure — the ML hooks Plan 4 stubs out are still
`Lifter`/`SkeletonFitter`/`PhaseSegmenter`/`ChainReasoner` protocols. The
backbone swap is what gets *plugged into* those hooks, not a replacement for
the hooks themselves.

**Q: What happens to all the MotionBERT references in the existing docs?**
They get a "superseded" note pointing at the new recommendations doc. The
research-integration-report.md already has that pointer at the top. I'm not
deleting the original analysis — it's still useful context.

**Q: Does the WHAM non-commercial license matter for the capstone?**
Not for the academic submission. It would matter if we tried to spin this into
a real product later. Worth knowing but not blocking now.

**Q: Why isn't TCPFormer in the new pipeline if it beats MotionBERT?**
Code wasn't released as of the deep read. Watch-this-space, not ship-this.

**Q: Why isn't ViTPose on the phone if it's better than MediaPipe?**
ViTPose is a server GPU model in the published paper. Mobile quantization is
research effort we'd own. Not worth it for a capstone when MediaPipe meets the
accuracy envelope we need.

**Q: How does this affect the hardware/sEMG team?**
Not much. The Uhlrich coordination retraining paper directly validates the
sEMG biofeedback story we want to tell — gastrocnemius:soleus ratio
retraining via real-time EMG biofeedback reduces knee contact force by 12%.
That's a strong premium-tier feature for when the garment ships. No hardware
spec changes.

---

*Generated 2026-04-11. If anything in this document gets out of date, the
authoritative versions live in `docs/research/`.*
