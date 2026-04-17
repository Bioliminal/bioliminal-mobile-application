# Bioliminal — Project Goals

## What we do

Bioliminal is a closed-loop training system for muscle activation. Surface EMG
meets phone-based computer vision, fused live, with haptic cueing and real-time
verification of whether the cue actually changed what the muscle did.

Sense → Reason → Cue → Verify. Every rep produces evidence.

## Why we're here

Coaching-quality feedback shouldn't require a $200/hour trainer. The signal
chain to deliver it already exists — sEMG sensors, phone cameras, haptic
actuators — it just hasn't been closed into a loop before.

Every EMG wearable in the last ten years captured the signal, waited for the
set to end, and showed a chart. The coaching moment came and went and the
product was not in the room for it. Measurement without intervention is the
defining failure of the category.

We're building the first system that runs the coaching loop — watch, cue,
re-watch, adjust — on a phone and a sensor band, every rep, with real evidence
instead of self-report.

---

## Three pillars

### 1. Democratizing elite-level feedback

This is the main point. What pro athletes spend thousands of dollars on and
regular people spend hundreds per session on — movement analysis, muscle
activation assessment, real-time coaching — delivered through a freemium app.

The free tier isn't a trial. It's a real product: AI-powered movement feedback
from phone camera alone. Good enough that people use it. Good enough that when
they see what the premium layer adds — the muscle data cameras can't see — it
becomes irresistible.

Pro-level feedback, consumer-level access. That's the thesis.

### 2. Server-side intelligence, phone-side simplicity

Nobody else is offloading the heavy biomechanics computation to servers. Other
apps and systems try to cram everything on-device and hit a ceiling. We keep
the phone deliberately dumb — capture and overlay only — and run the real ML
(WHAM, OpenCap Monocular, chain reasoning) server-side.

This is a recognized tradeoff: live overlay on the phone (instant, lightweight)
vs. real-time analysis on the server (seconds, heavyweight). We split them
intentionally. The phone gives you the live experience. The server gives you
the science. No one else in this space is making that split.

### 3. Closed-loop verification

Every other system is open-loop: sense → display. We close it:
sense → reason → cue → verify.

The same sensor that triggers a cue reads whether the muscle actually responded.
Every rep produces a labeled data point — did the cue work for this user, this
exercise, this load, this rep? That evidence trains the next cue.

The system doesn't just coach. It learns whether its coaching is working. No
one else is doing this. It's the technical moat, and it's what ties the whole
product together: the reason pros pay thousands is that a skilled coach's
feedback loop is tight and adaptive. We're closing that same loop digitally.

---

## What's happening now

- Four-person team building through the Gauntlet AI fellowship
- Prototype hardware: 4-channel sEMG at $121 BOM
- Flutter app running BlazePose at 30 fps with live BLE sensor fusion
- Server pipeline: MediaPipe → WHAM → OpenCap Monocular for joint moments
  and muscle forces from a single phone video
- Rule-based chain reasoning at launch, learning system post-launch
- Daily build-in-public on Substack
- Live demo: Monday 2026-04-20

## Product architecture

**Free tier:** Phone camera app. AI-powered movement feedback from computer
vision alone. The funnel.

**Premium tier:** Wearable sEMG sensor band paired with the app. Muscle
activation data fused with CV. Haptic cueing. The full closed loop.

Free is the product, not a trial. Premium is for people who've experienced
value from the free tier and want the layer cameras can't see.

## Positioning

Bioliminal is a training and educational tool. It is not a medical device and
does not diagnose, treat, or prevent any condition. Positioned under FDA
General Wellness Policy (2016).

Safe lane: training, coaching-quality feedback, muscle activation, skill
acquisition, movement quality.

## Links

- Site: https://bioliminal.web.app
- Substack: https://substack.com/home/post/p-194145623
- Architecture + repos: https://gitlab.com/bioliminal/gitlab-profile
