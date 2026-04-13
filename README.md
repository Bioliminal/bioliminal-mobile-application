# Bioliminal

**Clinical-grade movement screening and real-time sEMG biofeedback.**

> Most movement apps tell you *what* happened. Bioliminal tells you *why* — and uses real-time muscle sensing to help you fix it.

## The Bioliminal Edge

Bioliminal merges advanced computer vision with real-time biometric sensing to bridge the gap between screening and correction:
- **High-Fidelity Capture:** Captures 33 BlazePose landmarks at 30+ FPS for precise kinetic analysis.
- **Server-Side Reasoning:** Biomechanical modeling, joint moments, and muscle force analysis performed via WHAM + OpenCap Monocular.
- **10-Channel sEMG Hub:** Real-time muscle activation tracking via BLE (ESP32-S3).
- **Biofeedback Loop (Premium):** Real-time physical corrective cues (vibrotactile/TSA) based on clinical coordination ratios (e.g., Gastrocnemius:Soleus).

## Clinical Priority Set

1. **Overhead Squat:** Evaluation of deep-chain mobility.
2. **Single-Leg Squat:** Assessment of frontal-plane knee and hip stability.
3. **Push-up:** Analysis of core and scapular coordination.
4. **Rollup:** Segmental spinal articulation tracking.

## How It Works

```
[Vision] Phone Camera → MediaPipe BlazePose Full (33 landmarks)
[Sensing] ESP32-S3 Hub → 10-Channel sEMG (250Hz - 2kHz)
  → Data Fusion (Bioliminal Mobile App)
  → Clinical Server (Kinetics + Muscle Force Analysis)
  → Real-time Biofeedback & Clinical-Grade Report
```

**Four movements. Five minutes. No account.**

## The Core Problem
1. **Capture** — Computer vision landmarks + sEMG biopotentials.
2. **Detect** — 33 high-fidelity landmarks analyzed via server-side kinetics.
3. **Map** — Joint moments and muscle forces traced along fascial chains.
4. **Correct** — Real-time physical cues to retrain movement patterns mid-rep.

### Clinical Validation

Bioliminal is built on established biomechanical research:
- **MSI Framework:** Van Dillen et al. 2016 (Movement System Impairment patterns).
- **Kinematic Correlation:** Harris-Hayes 2018 (Hip adduction vs. clinical outcomes).
- **Biofeedback Research:** Uhlrich et al. 2023 (Real-time EMG retraining for knee contact force reduction).

---

## Technical Setup

### Requirements
- **Flutter:** Stable channel (^3.11.0)
- **Hardware:** Bioliminal ESP32-S3 Sensor Hub (10-channel AD8232)
- **Connection:** Bluetooth Low Energy (BLE)

### Installation
```bash
git clone https://github.com/YOUR_ORG/bioliminal
cd bioliminal
flutter pub get
flutter run
```

---

## License

MIT

## Citation

If you use Bioliminal in research:

```bibtex
@software{bioliminal2026,
  title={Bioliminal: Clinical-Grade Movement Screening with Real-time sEMG Biofeedback},
  year={2026},
  url={https://github.com/YOUR_ORG/bioliminal}
}
```
