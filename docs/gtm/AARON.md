# Aaron Carney

## Role

Biomechanics ML, Computer Vision, Server Pipeline

## What I build

The CV models and server-side intelligence. I train the computer vision models
and build the ML pipeline that takes a single phone video and produces joint
moments, ground reaction forces, and muscle forces — outputs that used to
require a motion-capture lab and force plates.

The pipeline: MediaPipe landmarks from the phone feed into WHAM for
world-grounded 3D pose, then into OpenCap Monocular (Gilon et al. 2026) for
full musculoskeletal simulation. That output meets the sEMG stream from the
wearable sensor, and a rule-based chain reasoner flags when the muscle you
intended to train isn't the one doing the work.

Key architecture decision: keeping the phone deliberately simple. BlazePose
runs on-device for live overlay. Everything heavy — WHAM, OpenCap, chain
reasoning — lives on the server. The phone captures. The server thinks.

## Why it matters

The rules we want to evaluate — activation patterns, chain involvement,
compensation — are defined on forces and moments, not raw pose angles. You
can't get there with a pose estimator alone. You need the full biomechanical
pipeline, and it needs to be grounded in peer-reviewed science, not prompt
engineering.

Every rep produces evidence on whether the cue actually changed what the muscle
did. That's a labeled training sample. Over time, the system doesn't just
reason — it learns.

## What I bring

Published researcher (federated learning). The machine learning behind
Bioliminal isn't guesswork bolted onto a sensor — it's backed by real research,
built by someone who publishes. Trains the CV models, builds the server
pipeline: pose estimation, 3D reconstruction, musculoskeletal simulation, chain
reasoning.

The science under the hood is actually science.

## Links

- LinkedIn: https://www.linkedin.com/in/aaron-carney/
- Bioliminal: https://bioliminal.web.app
- GitLab (architecture + repos): https://gitlab.com/bioliminal/gitlab-profile
