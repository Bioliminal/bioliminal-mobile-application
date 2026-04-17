# Rajat Arora

## Role

Hardware, Firmware, Signal Chain

## What I build

The physical layer. Everything the software touches starts with hardware that
works: 4-channel surface EMG sensors (BioAmp EXG Pill), bandpass-filtered at
20–500 Hz, sampled by an ESP32-S3, streamed over BLE to the phone in real time.
On the output side: coin vibration motors and a twisted-string actuator for
graduated pressure — so the system doesn't just detect what your muscles are
doing, it physically cues the one that needs more drive.

Prototype BOM: $121.

## Why it matters

Muscle activation is invisible. Two people doing the same squat can look
identical on camera, but their muscles are doing completely different things.
The only way to see it is to measure it. And the only way to make it useful
is to close the loop fast enough that the feedback arrives while the rep is
still happening.

The signal chain is the foundation. If the hardware is noisy, late, or
unreliable, nothing downstream — no ML, no reasoning, no UX — can save it.

## What I bring

Embedded systems engineer with hands-on experience designing chips from scratch.
PCB design, signal conditioning, firmware, BLE protocol, power management,
actuator control. If it has a pulse and a PCB, I've built one.

The sEMG signal chain at consumer price points is an unsolved problem in this
category. Previous products spent $400–700 on hardware and still shipped noisy
data. We're shipping clean signal at $121 because the analog front end is
designed right.

## Links

- LinkedIn: https://www.linkedin.com/in/rajat-arora-613b4b130/
- Bioliminal: https://bioliminal.web.app
