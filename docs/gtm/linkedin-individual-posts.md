# LinkedIn Individual Posts — Bioliminal Launch

> **HISTORICAL — 4/15 launch artifact.** Drafted for the 4/15 social-media launch ahead of the 4/20 demo, which has since shipped. Current focus is the showcase **Thu 2026-04-23 16:40** (live, 10 min + 3 Q&A, 4 ppl). Authoritative scope: `bioliminal-ops/decisions/2026-04-22-showcase-scope.md`.

---

Tag all 4 members. One primary CTA: waitlist.

LinkedIn handles:
- Kelsi Andrews: https://www.linkedin.com/in/kelsi-andrews/
- Aaron Carney: https://www.linkedin.com/in/aaron-carney/
- Rajat Arora: https://www.linkedin.com/in/rajat-arora-613b4b130/
- Rajiv Nelakanti: https://www.linkedin.com/in/rajiv-nelakanti/

---

## Kelsi Andrews

**Attach:** Screen recording of BlazePose overlay running in the app.

---

Pro athletes spend thousands on movement analysis and muscle activation
coaching. We're putting it in a free app.

I build the mobile side of Bioliminal. Flutter app running BlazePose at
30 fps, synced over BLE to a wearable sEMG sensor. Your phone captures
movement. The sensor captures what your muscles actually do. Both fuse on a
server and the result comes back as a cue you feel mid-rep.

Every other app in this space tries to run everything on-device. We don't.
Phone stays simple. Server does the science.

My job: make all of that feel like opening an app and training. No setup. No
complexity. Just train.

Built by four of Gauntlet AI's most cracked members — Rajat Arora, Aaron
Carney, Rajiv Nelakanti, and me.

Join the waitlist: https://bioliminal.web.app
⭐ https://github.com/bioliminal
🎥 Live demo Monday 4/20

#buildinpublic #wearables #AI #Flutter #BLE

---

## Rajat Arora

**Attach:** Photo of prototype hardware.

---

Pro athletes spend thousands on muscle activation coaching. We built the
hardware to deliver it for $121.

I build the physical layer of Bioliminal. 4-channel sEMG, bandpass-filtered
20–500 Hz, ESP32-S3, streamed over BLE to a phone running CV at 30 fps.
Vibration motors and a twisted-string actuator on the output side — the system
cues the muscle that needs more drive, mid-rep.

Then it reads back whether the cue worked. Same sensor. Same rep. That's the
closed loop nobody else has.

Two people doing the same squat can look identical on camera while their
muscles do completely different things. The only way to see it is to measure
it. The only way to make it useful is to close the loop.

Built with three of the most cracked people I've met at Gauntlet AI — Kelsi
Andrews, Aaron Carney, Rajiv Nelakanti.

Join the waitlist: https://bioliminal.web.app
⭐ https://github.com/bioliminal
🎥 Live demo Monday 4/20

#buildinpublic #wearables #AI #EMG #ESP32 #embedded

---

## Aaron Carney

**Attach:** Architecture diagram or pipeline visualization.

---

What pro athletes get from a biomechanics lab — joint moments, ground reaction
forces, muscle forces — we're producing from a single phone video.

I train the CV models and build the server pipeline behind Bioliminal.
MediaPipe → WHAM → OpenCap Monocular for full musculoskeletal simulation.
That output meets a live sEMG stream, and a chain reasoner flags when the
muscle you intended to train isn't the one doing the work.

Nobody else runs this server-side. Other apps cram everything on the phone
and hit a ceiling. We keep the phone simple. The server does the real science.

The same sensor that triggers a cue reads whether the muscle responded. Every
rep is a labeled data point. The system learns.

Built with three of the most cracked people I've met at Gauntlet AI — Kelsi
Andrews, Rajat Arora, Rajiv Nelakanti.

Join the waitlist: https://bioliminal.web.app
⭐ https://github.com/bioliminal
🎥 Live demo Monday 4/20

#buildinpublic #wearables #AI #machinelearning #biomechanics

---

## Rajiv Nelakanti

**Attach:** Sense → Reason → Cue → Verify diagram.

---

Every EMG wearable in the last ten years built a dashboard. None built a coach.

I lead product for Bioliminal. The cueing thesis is mine: sense the muscle,
reason over the signal, cue the muscle that needs more drive, then verify
whether the cue actually changed the activation. Every rep produces evidence.
The system learns whether its coaching is working.

Nobody else closes this loop. Nobody else runs the heavy biomechanics ML
server-side instead of cramming it on a phone.

The free tier is a real product — AI movement feedback from camera alone.
Premium adds the layer cameras can't see: muscle activation, haptic cueing,
the full closed loop. When you've felt what free does, premium is irresistible.

Built by four of Gauntlet AI's most cracked members — Kelsi Andrews, Rajat
Arora, Aaron Carney, and me.

Join the waitlist: https://bioliminal.web.app
⭐ https://github.com/bioliminal
📝 Cueing thesis: https://substack.com/home/post/p-194145623
🎥 Live demo Monday 4/20

#buildinpublic #wearables #AI #startups #sportsscience

---

## Compliance reminder

Safe: training, coaching-quality feedback, muscle activation, skill
acquisition, movement quality.

Never: "prevents injury," "diagnoses," "treats," "clinical," "prescription,"
"before they become injuries," "medical-grade."
