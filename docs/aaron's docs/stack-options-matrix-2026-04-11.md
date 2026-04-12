# Stack Options Matrix — 2026-04-11 (rewrite)

**Scope.** This matrix evaluates pose-estimation and biomechanics-backend options for the AuraLink capstone **prototype**. Every row is scored against four things: (a) does it run on-device on a phone for inference, (b) can the team realistically integrate it in one capstone semester, (c) does it plug into the planned ESP32-S3 + 10-channel AD8232 sEMG fusion, and (d) can it be used under an **academic** license. Commercial licensing is captured for reference only and is explicitly **not a decision factor** for the prototype — the team will retrain or replace components downstream if the project pivots commercial. On-device *training* is out of scope (the team will train downstream classifiers once, on a laptop, not on phones). **Federated learning is out of scope** and is addressed only in the short "Deferred" section at the bottom.

HIPAA concern for user video is handled architecturally by keeping inference local: raw phone-camera frames → pose landmarks happens on-device, raw video never leaves the device. That is the only privacy claim this matrix relies on.

No row contains a recommendation. Every cell is either a metric with a source or "unknown". Unknown cells are enumerated in the "Data gaps" section at the bottom. For full licensing detail see `docs/research/license-audit-2026-04-11-v2.md`.

**Sources abbreviated in footnotes:**
- `[v2]` = `docs/research/license-audit-2026-04-11-v2.md`
- `[DRS]` = `docs/research/deep-read-sensing-2026-04-10.md`
- `[MFR]` = `docs/research/model-framework-recommendations-2026-04-10.md`
- `[CAT]` = `docs/research/sensing/catalog.md`
- `[Gilon26]` = Gilon et al. 2026, OpenCap Monocular (`sensing/Gilon et al. - 2026 - OpenCap Monocular*.pdf`)
- `[Shin24]` = Shin et al. 2024, WHAM (CVPR 2024)
- `[Xu22]` = Xu et al. 2022, ViTPose (NeurIPS)
- `[Liu25]` = Liu et al. 2025, TCPFormer (arXiv 2501.01770)
- `[Uhlrich23]` = Uhlrich et al. 2023, OpenCap (PLOS Comp Bio)
- `[HSMR]` = Xia et al., HSMR / SKEL paper (`sensing/biomechanically-accurate-skeleton.pdf`)
- `[Sabo26]` = Sabo et al. 2026, video Beighton tool
- `[MP-task]` = Direct file-size inspection of `.task` files on `storage.googleapis.com/mediapipe-models/pose_landmarker/...` 2026-04-11
- `[MP-doc]` = `ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker`
- `[Rajagopal16]` = Rajagopal 2016 full-body MSK model on simtk.org
- `[OpenSim-repo]` = `github.com/opensim-org/opensim-core` metadata fetched 2026-04-11
- `[gh-*]` = GitHub API metadata (`pushed_at`, `stargazers_count`, `open_issues_count`) fetched via `gh api` on 2026-04-11

---

## Table 1 — Capability (what the model does)

| Name | Input | Output | Keypoints / DoF | Coordinate frame | Real-time capable (on what HW) | Source |
|---|---|---|---|---|---|---|
| MediaPipe Pose Landmarker — Lite | Single frame (RGB, 256×256 landmarker input) | 2D + relative-depth landmarks with (x,y,z,visibility,presence) | 33 landmarks | Image frame (x,y normalized ∈[0,1], z relative depth) | Yes, on mobile CPU; Google's smallest variant for resource-constrained devices | [MP-doc], [MFR §2.1] |
| MediaPipe Pose Landmarker — Full | Single frame (RGB 256×256) | Same schema | 33 landmarks | Image frame | Yes on mid-range / flagship phones; MFR cites "~30–50 ms/frame" (team-note estimate, not a Google benchmark) | [MP-doc], [MFR §2.1], [DRS §Phone-viable] |
| MediaPipe Pose Landmarker — Heavy | Single frame (RGB 256×256) | Same schema | 33 landmarks | Image frame | Yes on flagship / GPU delegate per Google positioning; exact phone FPS unknown | [MP-doc] |
| WHAM | Video sequence (supports moving camera) | SMPL-family body parameters + global translation | SMPL skeleton (24 joints / 72 rotation params + 10 shape params) | World-grounded | Server GPU only; paper emphasizes "efficient vs optimization baselines" but does not quote mobile FPS | [Shin24], [DRS §4] |
| OpenCap Monocular (full pipeline) | Single smartphone video + subject height | 3D kinematics + joint moments + GRFs + muscle forces | OpenSim lower-limb + trunk (Rajagopal-derived) | World-grounded | No — optimization is "seconds to minutes per capture" on server GPU | [Gilon26], [DRS §2] |
| OpenCap (dual-camera, Uhlrich 2023) | 2+ synchronized smartphone videos (~90° apart, ≥30 fps) | 3D kinematics + muscle/force simulation via OpenSim | 37 DoF, 80 muscle-tendon units (Rajagopal 2016 derivative) | World frame via multi-view triangulation | No — cloud processing ~10–30 min per recording | [Uhlrich23], [DRS §1] |
| HSMR (SKEL body model) | Single image | SKEL biomechanical skeleton (pose + shape) | 46 DoF (SKEL model) | Camera frame / root-relative | GPU server per [MFR §2.2]; per-frame FPS not quoted in catalog notes | [HSMR], [CAT], [MFR §2.2] |
| MotionBERT | Video (2D keypoint sequence → 3D lift) | 3D root-relative joint positions | Human3.6M 17-joint | Root-relative 3D | Not mobile; transformer temporal model on GPU | [CAT §Gap 1] |
| ViTPose-S (small) | Single frame | 2D keypoints (heatmap regression) | COCO 17 | Image frame | A100 benchmarks only; no mobile demonstration | [Xu22], [DRS §6] |
| ViTPose-B (base) | Single frame | 2D keypoints | 17 | Image frame | ~158 fps on A100 (paper); not benchmarked on phones | [Xu22], [DRS §6] |
| ViTPose-L (large) | Single frame | 2D keypoints | 17 | Image frame | A100; per-variant FPS figure not quoted for L | [Xu22] |
| ViTPose-H (huge) | Single frame | 2D keypoints | 17 | Image frame | A100; 80.9 AP on COCO test-dev | [Xu22], [DRS §6] |
| TCPFormer | Video (2D→3D temporal lift) | 3D joint positions | Human3.6M 17-joint | Root-relative | Not mobile; transformer sequence model on GPU | [Liu25], [DRS §5] |
| MoveNet Lightning (TF Lite) | Single frame | 2D keypoints | 17 (COCO) | Image frame | Yes on mobile; Google's smaller MoveNet variant | [MFR §2.1] |
| MoveNet Thunder (TF Lite) | Single frame | 2D keypoints | 17 (COCO) | Image frame | Yes on mobile; larger/slower MoveNet variant | [MFR §2.1] |
| HRNet-W48 (reference implementation) | Single frame | 2D keypoints | 17 (COCO) | Image frame | Server / desktop GPU; large model | [CAT], [Uhlrich23] (used inside OpenCap) |
| HRPose / HRNet-small (mobile ports) | Single frame | 2D keypoints | 17 (COCO) | Image frame | Mobile-capable per [MFR §2.1] (TFLite / ONNX RT Mobile); better occlusion/fast-motion handling | [MFR §2.1], [CAT] |
| Sabo 2026 Beighton scorer | Video | Beighton-style hypermobility score | MediaPipe / MobileNet backbone → downstream classifier | Image frame | "Phone-viable by design" per paper | [Sabo26], [DRS §7] |

---

## Table 2 — Deployment footprint (can it run on a phone)

| Name | Model file size | Min RAM estimate | Inference framework(s) | Official mobile runtime exists? | Desktop GPU required? | Reported inference latency | Source |
|---|---|---|---|---|---|---|---|
| MediaPipe Pose Landmarker — Lite | `.task` ~5.5 MB (direct file fetch 2026-04-11) | unknown | MediaPipe Tasks (Android / iOS / Web / Python); TFLite underneath | Yes — official Android + iOS + Web builds | No | unknown from Google's public model card | [MP-task], [MP-doc] |
| MediaPipe Pose Landmarker — Full | `.task` ~9 MB (direct fetch 2026-04-11) | unknown | Same as Lite | Yes | No | ~30–50 ms/frame per [MFR §2.1] team-note (not Google-published) | [MP-task], [DRS §Phone-viable], [MFR §2.1] |
| MediaPipe Pose Landmarker — Heavy | `.task` >10 MB (direct fetch aborted at 10 MB cap) | unknown | Same as Lite | Yes (official) | No | unknown | [MP-task], [MP-doc] |
| WHAM | unknown (paper does not quote parameter count or file size) | unknown | PyTorch (official); no ONNX / TFLite / Core ML export | No | Yes (GPU-only per [DRS §4]) | unknown (paper: "efficient vs optimization baselines", no ms/frame figure) | [Shin24], [DRS §4] |
| OpenCap Monocular (pipeline) | n/a (pipeline, not a single weight file) | unknown | Python + PyTorch (WHAM stage) + OpenSim + optimization | No | Yes | "Seconds to minutes per capture" per [Gilon26] | [Gilon26] |
| OpenCap (dual-camera) | n/a (pipeline) | unknown | Python (`opencap-core`) + HRNet-W48 / OpenPose + OpenSim | No | Cloud GPU | 10–30 min per recording | [Uhlrich23] |
| HSMR (SKEL) | unknown (not quoted in [CAT] / [MFR]) | unknown | PyTorch | No | Yes (GPU server) | unknown | [HSMR], [CAT], [MFR §2.2] |
| MotionBERT | unknown | unknown | PyTorch (Apache 2.0 repo) | No | Yes | unknown | [CAT §Gap 1] |
| ViTPose-S | ~15M params (scaling family estimate per [DRS §6]) | unknown | PyTorch; no official mobile build | No | Yes (stock) | unknown on phone | [Xu22], [DRS §6] |
| ViTPose-B | ~86M params ([Xu22]) | unknown | PyTorch | No | Yes | ~158 fps on A100 | [Xu22], [DRS §6] |
| ViTPose-L | unknown exact (100M–1B family range) | unknown | PyTorch | No | Yes | unknown | [Xu22] |
| ViTPose-H | ~1B params (top of family range) | unknown | PyTorch | No | Yes | accuracy 80.9 AP; FPS for H not quoted | [Xu22], [DRS §6] |
| TCPFormer | unknown | unknown | PyTorch (third-party mirrors; official release status unclear — see Table 3) | No | Yes | unknown | [Liu25], [DRS §5] |
| MoveNet Lightning | unknown exact size | unknown | TF Lite (official Google release on TF Hub) | Yes | No | Google's "single-person, real-time" target; exact ms unknown | [MFR §2.1] |
| MoveNet Thunder | unknown exact size (listed as "~13M params" in [MFR §2.1] citing Google docs) | unknown | TF Lite | Yes | No | ~25–50 ms per [MFR §2.1] team notes | [MFR §2.1] |
| HRNet-W48 (reference) | unknown exact; "large" per reference | unknown | PyTorch | No | Yes | Desktop / server timings only in paper | [CAT], [Uhlrich23] |
| HRPose / HRNet-small | unknown exact (~9–13M params per [MFR §2.1]) | unknown | TF Lite or ONNX Runtime Mobile | Yes (medium-effort integration per [MFR §2.1]) | No | ~80–150 ms per [MFR §2.1] team notes | [MFR §2.1] |
| Sabo 2026 Beighton scorer | unknown (MobileNet-class backbone per paper description) | unknown | Inherits MediaPipe / MobileNet runtime | Yes (phone-viable by design) | No | unknown | [Sabo26], [DRS §7] |

---

## Table 3 — Out-of-box usability and tooling maturity (can the team actually integrate it in one semester)

Last-commit window reference: 2026-04-11. "Within 90 days" means `pushed_at ≥ 2026-01-11`. All GitHub metadata fetched via `gh api repos/<owner>/<repo>` on 2026-04-11.

| Name | Official example app (platform) | Demo-quality on ordinary phone video | Active community | Documentation quality | Last repo commit within 90 days? | Notes / repo metadata |
|---|---|---|---|---|---|---|
| MediaPipe Pose Landmarker (Lite / Full / Heavy) | Yes — official Android, iOS, and Web Pose Landmarker examples distributed by Google via `ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker` and the `google-ai-edge/mediapipe-samples` repo | Good — runs on ordinary phone video as Google's public demo | Active | Good (official Google dev site with tutorials, code, and API reference) | Yes — `google-ai-edge/mediapipe` pushed 2026-03-06, 34,667 stars; `google-ai-edge/mediapipe-samples` pushed 2026-04-09, 2,635 stars | [gh-google-ai-edge/mediapipe], [gh-google-ai-edge/mediapipe-samples], [MP-doc] |
| WHAM | No mobile example — reference code is a server-side Python/PyTorch repo; authors publish an installation + inference CLI, not a demo app | Untested on phones (server GPU pipeline) | Active | Fair — research-paper README, installation scripts, Colab-style demo | Yes — pushed 2026-03-14, 1,363 stars, 44 open issues | [gh-yohanshin/WHAM], [Shin24] |
| OpenCap Core | Yes — but the "app" is the opencap.ai iPhone capture app bound to the cloud service, not a local inference demo. Local `opencap-core` is a Python pipeline. | Fair for the intended multi-camera capture workflow; not applicable for single-camera casual use | Active | Good (paper + README + project site) | No — `opencap-org/opencap-core` pushed 2025-12-25 (outside 90-day window), 2,007 stars, 109 open issues | [gh-opencap-org/opencap-core], [Uhlrich23] |
| OpenCap Monocular | No official mobile demo — Python research pipeline | Untested on phones (server GPU pipeline) | Active | Fair (research paper + README) | Yes — `utahmobl/opencap-monocular` pushed 2026-04-10, 116 stars, 0 open issues | [gh-utahmobl/opencap-monocular], [Gilon26] |
| HSMR | No mobile example — PyTorch research repo | Untested | Dormant / abandoned | Fair (paper + README) | **No** — `IsshikiHugh/HSMR` last pushed 2024-04-18 (~2 years stale), 1,035 stars, 81 open issues | [gh-IsshikiHugh/HSMR], [HSMR] |
| MotionBERT | No mobile example — PyTorch research repo with training/eval scripts | Untested on phones | Active | Fair (research paper + README) | Yes — `Walter0807/MotionBERT` pushed 2026-03-10, 291 stars, 50 open issues | [gh-Walter0807/MotionBERT] |
| ViTPose (S / B / L / H) | No mobile example; reference implementation is PyTorch research code | Untested on phones | Active | Fair (paper + README) | Yes — `ViTAE-Transformer/ViTPose` pushed 2026-04-11, 609 stars, 1 open issue | [gh-ViTAE-Transformer/ViTPose], [Xu22] |
| TCPFormer | No official repo from the paper authors fetched in this pass. Third-party mirrors exist; `AsukaCamellia/TCPFormer` is the top-starred mirror with 110 stars, last pushed 2025-05-13. Queried repo `hbing-l/TCPFormer` returned 404 on 2026-04-11. | Not applicable (no mobile) | Dormant (mirror only) | Poor (mirror without authoritative docs) | **No** — best available mirror pushed 2025-05-13 | [gh-AsukaCamellia/TCPFormer], [Liu25] |
| MoveNet Lightning / Thunder | Yes — `tensorflow/tfjs-models` hosts the official MoveNet JS demo; TF Lite Android / iOS samples distributed through the TensorFlow examples ecosystem | Good — Google's "real-time single-person" demo runs on ordinary phone video | Active (TF ecosystem) | Good (TF Hub model card + example apps) | Yes — `tensorflow/tfjs-models` pushed 2026-04-08, 14,764 stars | [gh-tensorflow/tfjs-models], [MFR §2.1] |
| HRNet-W48 (reference) | No mobile example | Untested on phones | Dormant / abandoned | Fair (paper + README) | **No** — `HRNet/HRNet-Human-Pose-Estimation` pushed 2021-10-12, 311 stars; `leoxiaobin/deep-high-resolution-net.pytorch` pushed 2024-08-30, 4,472 stars | [gh-HRNet/HRNet-Human-Pose-Estimation], [gh-leoxiaobin/deep-high-resolution-net.pytorch] |
| HRPose / HRNet-small (mobile ports) | Varies per third-party port; no single canonical example app | Untested | Fragmented | Poor (per-port, no single authoritative source) | Varies per port | [MFR §2.1] notes the mobile-port route; individual port licenses and commit cadence were not audited in this pass |
| Sabo 2026 Beighton scorer | No public example app; research-only release per [MFR §2.2] | Untested outside paper's own study cohort | Unknown | Poor (paper-only) | unknown | [Sabo26], [MFR §2.2] |
| OpenSim core (as a biomechanics backend — for reference) | Desktop GUI + CLI; no mobile | n/a (not a pose estimator) | Active | Good (long-standing OpenSim community, simtk.org, `opensim-org` org) | Yes — `opensim-org/opensim-core` pushed 2026-04-11, 1,013 stars | [gh-opensim-org/opensim-core] |

---

## Table 4 — Academic-use licensing (reference only — not a decision factor for the prototype)

For the AuraLink capstone, commercial usability does **not** drive model selection. If the project later pivots commercial, the front-end pose estimator will be swapped and the downstream classifiers retrained from scratch. Read this table only as "is it legal to use in a university capstone?"

| Name | Usable for academic capstone? | Code license | Weights license | Training-data license | Commercial status (post-capstone only) | Reference |
|---|---|---|---|---|---|---|
| MediaPipe Pose Landmarker (Lite / Full / Heavy) | Yes | Apache 2.0 (framework) + CC BY 4.0 (docs) | BlazePose GHUM 3D Model Card (PDF not text-extractable in v2) | unknown (training set not disclosed on `ai.google.dev` page) | Likely commercial-OK (consensus — High framework / Medium-High weights per [v2]); human should confirm the model card PDF before ship | [v2] Models row 9; [v2] Critical Q4 |
| WHAM (code) | Yes | MIT | n/a | n/a | Code commercial-OK; **weights are not** | [v2] Models row 1 |
| WHAM (released weights) | Yes (research use) | — | MPI non-commercial research license (strongly implied; TUE project page is a JS shell, template matches other verified TUE projects) | AMASS (MPI non-commercial, verified directly v2), 3DPW, BEDLAM, EMDB (all non-commercial verified directly) | **No** | [v2] Models row 2; [v2] AMASS/3DPW/BEDLAM/EMDB rows |
| OpenCap Core | Yes | Apache 2.0 | n/a | n/a | Yes | [v2] Models row 3 |
| OpenCap Monocular (pipeline code repo) | Yes | **PolyForm Noncommercial 1.0.0** | n/a | n/a | **No** | [v2] Models row 4 |
| opencap.ai hosted service | Yes (research use per opencap-core README) | — | — | — | No (research-only per README; formal ToS still JS-shell-unreachable) | [v2] Models row 5; [v2] Critical Q3 |
| HSMR | Yes | MIT (code) | — | SMPL dependency | No — SMPL chain blocks commercial | [v2] Models row 6 + SMPL row |
| MotionBERT | Yes | Apache 2.0 (code) | Released checkpoints trained on Human3.6M (academic non-commercial) | Human3.6M | No for released checkpoints; Yes for code-only retrained on commercial-clean data | [v2] Models row 7 |
| ViTPose (S / B / L / H) | Yes | Apache 2.0 (code) | Released checkpoints trained on COCO + MPII | COCO annotations CC BY 4.0; MPII unclear on current MPI page | Medium — code yes, released weights Medium-risk | [v2] Models row 12; [v2] COCO + MPII rows |
| TCPFormer | Yes (for reading the paper) | unknown (no authoritative release) | unknown | Human3.6M + MPI-INF-3DHP (both academic) | unknown — not shippable | [DRS §5], [Liu25] |
| MoveNet Lightning / Thunder | Yes | Apache 2.0 (TF Hub consensus) | Apache 2.0 model on TF Hub (not explicitly v2-verified) | unknown | Yes (consensus; not v2-verified) | Not in v2 |
| HRNet-W48 / HRPose / HRNet-small | Yes | Original HRNet research code; mobile ports vary per port | Per port | unknown | unknown (depends on port) | Not in v2 |
| Sabo 2026 Beighton scorer | Yes (research) | Research | Research-only | Private EDS-clinic cohort (n=125) | No | [MFR §2.2] |
| OpenSim core (C++) | Yes | Apache 2.0 | n/a | n/a | Yes | [v2] Models row 13 |
| OpenSim Python bindings | Yes | Apache 2.0 | n/a | n/a | Yes | [v2] Models row 14 |
| Rajagopal 2016 full-body MSK model | Yes | MIT Use Agreement (verified directly v2) | n/a (MSK model, not ML weights) | n/a | Yes (High confidence; flipped from v1) | [v2] Models row 15 |
| SMPL / SMPL-X body models | Yes (research) | MPI Non-Commercial Research License (verified directly v2) | Non-commercial | n/a | **No** | [v2] SMPL row |

Every pose model and every biomechanics backend listed in this file is usable in the capstone. The "Commercial status" column is reference-only and **does not score**.

---

## Table 5 — sEMG fusion with ESP32-S3 + 10-channel AD8232 (expanded)

AuraLink's sEMG source is an ESP32-S3 MCU driving 10 AD8232 channels and streaming to the phone over BLE (per `CLAUDE.md`). The specific per-channel sample rate target is not fixed in the research corpus reviewed — the AD8232 supports rates typical of surface EMG (250 Hz–2 kHz per channel) and the exact AuraLink rate is an open hardware spec question. This table lists, per pose framework, what the framework natively exposes for timestamps and external-data ingestion — i.e. what the fusion layer has to work around.

| Component | Timestamp format exposed | Time-sync mechanism available | Sub-ms sync with external streams? | sEMG sampling-rate compatibility (how fusion happens) | Phone-side fusion framework | Latency budget for fusion | Notes / source |
|---|---|---|---|---|---|---|---|
| ESP32-S3 + 10-channel AD8232 (the sEMG source) | MCU-hardware timestamp (microsecond-resolution `esp_timer_get_time()` available on ESP-IDF) | Hardware counter on-MCU; BLE packet tags carry the MCU timestamp | Yes (MCU counter is sub-ms; the question is BLE jitter) | n/a — this is the producer, not a consumer | n/a | n/a | `CLAUDE.md` project hardware; BLE jitter flagged in `research-gaps.md §B4` |
| MediaPipe Pose Landmarker (any variant) | Per-frame timestamp exposed as `Image.timestamp_ms` (MediaPipe Tasks API) | No built-in external-stream sync. Framework is vision-only. | No — sync has to be done in the host app | **Side-by-side in app code.** Fusion happens downstream: pose landmarks at ~30 fps go to a custom pipeline together with the sEMG samples that the app also receives. The pose framework is not in the fusion loop. | Custom app-layer fusion (Kotlin/Java on Android, Swift on iOS) using the landmarker output + BLE samples | Dominated by (a) pose inference ~30–50 ms per [MFR §2.1] estimate + (b) BLE packet latency | [MP-doc] — Tasks API accepts only vision inputs, timestamps are vision-frame timestamps |
| WHAM | Per-frame indices in offline PyTorch inference; no real-time timestamp API | No built-in sync (batch inference model) | No | n/a — not a real-time component; fusion would be post-hoc from saved video + saved sEMG log | Server-side Python pipeline (post-hoc alignment) | Not a real-time target | [Shin24] is a batch / server workflow |
| OpenCap Monocular | Per-frame from the WHAM front end; OpenSim stage ingests `.trc` / `.mot` time-series | `.sto` / `.mot` files can carry arbitrary external time-series including sEMG, user-written timestamps | Yes (arbitrary-resolution timestamps in `.sto` format) | **Upstream.** OpenSim downstream can accept sEMG-derived muscle-activation constraints via `.sto` files in Computed Muscle Control or Static Optimization workflows. The ingestion is manual. | Server-side Python + OpenSim | Not a real-time target (seconds–minutes per capture per [Gilon26]) | [Gilon26], [OpenSim-repo] |
| OpenCap (dual-camera, Uhlrich 2023) | Same as monocular (batch OpenSim downstream) | `.sto` / `.mot` external time-series ingestion | Yes (arbitrary resolution in `.sto`) | **Upstream** (user-written step) | Server-side Python + OpenSim | 10–30 min per recording | [Uhlrich23] |
| OpenSim (standalone, fed from any pose source) | User-supplied timestamps in `.sto` / `.mot` | User-supplied; OpenSim uses whatever the user provides | Yes (arbitrary resolution) | **Upstream.** Computed Muscle Control and Static Optimization accept external muscle-activation constraints as `.sto` channels; the user decides the fusion semantics. | Desktop C++ core or Python bindings | Not real-time; offline analysis workflow | [v2] Models row 13 / 14; [OpenSim-repo] |
| HSMR | Per-image inference; no timestamp API | No built-in sync | No | n/a — single-image model, no streaming | Server-side PyTorch | Not real-time | [HSMR] |
| MotionBERT | Per-frame indices in PyTorch inference | No built-in sync | No | Post-hoc only | Server-side PyTorch | Not real-time | [CAT §Gap 1] |
| ViTPose (S/B/L/H) | Per-frame; no mobile timestamp API | No built-in sync | No | Post-hoc or custom host-app fusion | Server / research-only PyTorch; no official mobile runtime | Not real-time on mobile | [Xu22], [DRS §6] |
| TCPFormer | unknown (code release status unclear) | unknown | unknown | Not applicable (no release) | n/a | n/a | [Liu25] |
| MoveNet Lightning / Thunder | Per-frame timestamp in TFLite inference wrapper (user-managed) | No built-in external-stream sync | No — sync is host-app concern | **Side-by-side in app code** (same as MediaPipe) | Custom app-layer fusion using TFLite output + BLE samples | ~25–50 ms inference (Thunder) per [MFR §2.1] + BLE latency | [MFR §2.1] |
| HRPose / HRNet-small (mobile ports) | Per-frame; per-port | No built-in sync | No | **Side-by-side in app code** | Custom app-layer fusion + TFLite / ONNX RT Mobile | ~80–150 ms inference per [MFR §2.1] + BLE latency | [MFR §2.1] |
| **Generic phone-side data pipeline (user owns the fusion layer entirely)** | Any — user tags pose frames with system clock (`System.nanoTime()` on Android, `mach_absolute_time()` on iOS) and merges with ESP32-tagged BLE packets | User-supplied cross-clock alignment (initial handshake, sliding-window drift correction) | Depends on BLE stack quality; BLE 5.x can deliver ~1–5 ms jitter in practice on modern phones (not cited — requires measurement on the team's specific devices) | Any — user interpolates sEMG samples to the pose-frame timebase or vice versa | Any framework the team chooses (TFLite, Core ML, custom) | Depends on inference stage + BLE jitter | Standard multi-rate sensor-fusion pattern; no single citation |

**Key architectural observation.** None of the pose frameworks reviewed exposes a native API slot for sEMG ingestion. All fusion happens one layer up: either in an OpenSim `.sto` file (downstream of the pose pipeline) or in a user-written phone-side process (side-by-side with the pose framework). From a fusion-design standpoint the pose framework choice only affects (a) the timestamp accuracy the framework lets the host reach and (b) whether fusion can run alongside pose inference on the phone without saturating CPU/GPU. Fusion itself is always AuraLink-owned app code.

---

## Table 6 — Skeleton → Rajagopal 2016 MSK mapping

Rajagopal 2016 is an OpenSim full-body musculoskeletal model with 37 degrees of freedom and ~80 muscle-tendon units, and is the MSK backbone used by OpenCap. Its marker/joint set is OpenSim-convention (anatomical landmarks at pelvis, hip, knee, ankle, subtalar, shoulder, elbow, wrist, lumbar) — not a pose-estimator keypoint convention. This table asks: if the team wants to drive OpenSim IK/ID with phone-estimated joints, which pose models plug in without an intermediate SMPL fit or custom retargeting layer?

| Pose model | Skeleton name / convention | Keypoint count | Maps directly to Rajagopal 2016? | Retargeting required? | Notes on specific joint mismatches | Source |
|---|---|---|---|---|---|---|
| MediaPipe Pose Landmarker (Lite / Full / Heavy) | BlazePose GHUM 33 | 33 landmarks | No | Simple — BlazePose-to-OpenSim marker mapping has been published in the literature and is the path used by `markerless-mediapipe-joint-moments.pdf` | BlazePose provides face/hand/foot landmarks that OpenSim does not consume; OpenSim expects bilateral pelvis/hip markers that BlazePose approximates with a midpoint; spine segments differ (BlazePose has no thoracic/lumbar split) | [MP-doc], [markerless-mediapipe-joint-moments.pdf] in `sensing/` |
| WHAM | SMPL (24 joints, 72 rotation params + 10 shape params) | 24 joints | No | Complex — SMPL-to-OpenSim requires a body-model fit and marker-cloud projection step (this is literally what OpenCap Monocular does internally); no off-the-shelf adapter outside the OpenCap Monocular pipeline | SMPL spine has 3 segments vs OpenSim lumbar 1-DoF joint; SMPL shoulder is a 3-DoF ball, OpenSim shoulder is a constrained 3-DoF joint with clavicle/scapula kinematic coupling; foot/ankle structure differs | [Shin24], [Gilon26] |
| OpenCap Monocular (as a direct kinematics producer) | Rajagopal-derived (lower-limb + trunk, OpenSim marker set) | OpenSim marker set | Yes — this pipeline is OpenSim-native by design | None (it is already in OpenSim coordinates) | n/a — this is the canonical fit | [Gilon26] |
| OpenCap (dual-camera) | Rajagopal 2016 (37 DoF, 80 MTUs — Rajagopal-derived variant) | Rajagopal marker set | Yes — native by design | None | n/a | [Uhlrich23] |
| HSMR (SKEL body model) | SKEL (46 DoF biomechanical skeleton) | 46 DoF | No | Complex — SKEL is itself a biomechanically-motivated skeleton (closer to Rajagopal in spirit than SMPL is), but no published SKEL → Rajagopal `.osim` adapter was found in the sources reviewed | SKEL has "0% joint-limit violations" per [HSMR]; joint-axis conventions differ from Rajagopal; shoulder and spine are the most likely mismatch regions | [HSMR], [CAT] |
| MotionBERT | Human3.6M 17-joint | 17 | No | Simple-to-moderate — Human3.6M skeleton is a standard benchmark skeleton and published mappings to OpenSim exist in the biomechanics literature, but the specific Rajagopal mapping was not verified in the sources reviewed | Human3.6M has no foot keypoints other than heel/toe proxies; no bilateral shoulder clavicle model; no lumbar split | [CAT §Gap 1] |
| ViTPose (S / B / L / H) | COCO 17 | 17 | No | Moderate — COCO 17 is 2D only (image-frame); a 3D lifting step is required before any OpenSim ingestion, and even then COCO's joint set omits foot/toe and has no lumbar/thoracic spine at all | Missing lumbar/thoracic spine entirely; no head/neck beyond nose/ears; shoulder is a single point | [Xu22] |
| TCPFormer | Human3.6M 17-joint (via its 2D→3D lift path) | 17 | No | Same as MotionBERT | Same as MotionBERT | [Liu25] |
| MoveNet Lightning / Thunder | COCO 17 | 17 | No | Same as ViTPose | Same as ViTPose | [MFR §2.1] |
| HRNet-W48 / HRPose / HRNet-small | COCO 17 | 17 | No | Same as ViTPose | Same as ViTPose | [Uhlrich23], [MFR §2.1] |
| Sabo 2026 Beighton scorer | Inherits MediaPipe backbone | 33 (inherited) | Same as MediaPipe | Same as MediaPipe | Same as MediaPipe | [Sabo26] |

**Observation.** Only the OpenCap pipelines (which *are* OpenSim-native) map directly. Everything else requires either a simple marker-convention mapping (BlazePose-class 33-point models, where literature adapters exist) or a complex body-model fit (SMPL-class models, where the adapter is effectively the entirety of OpenCap Monocular's front-end). 2D-only COCO-17 models require a 3D-lifting stage before any OpenSim ingestion is even possible.

---

## Table 7 — Pipeline compatibility grid (pose model × biomechanics backend)

Rows are pose estimators. Columns are biomechanics backends. Cell = ✅ works out-of-box per a cited source / ⚠️ adapter or multi-step work required / ❌ incompatible per the upstream component's design. "Parallel only" means two models produce disjoint outputs runnable side-by-side for cross-check (e.g. HSMR vs WHAM) but not chainable.

| Pose estimator ↓ \\ Backend → | Direct joint-angle (on-phone geometry) | OpenSim + Rajagopal 2016 (desktop) | OpenCap Core (dual-camera, server) | OpenCap Monocular (mono, server) | HSMR / SKEL (parallel) |
|---|---|---|---|---|---|
| MediaPipe Pose Landmarker Lite | ✅ — 33-landmark x,y,z per [MP-doc]; direct math per [CAT]; Hip R=0.94, Knee R=0.95, Ankle R=0.11 per `markerless-mediapipe-joint-moments.pdf` | ⚠️ BlazePose-to-OpenSim marker mapping required (simple, published) | ❌ OpenCap Core expects HRNet-W48 or OpenPose 2D from 2+ cameras per [Uhlrich23] | ❌ OpenCap Monocular's front end is WHAM, not MediaPipe per [Gilon26] | ❌ HSMR is a single-image mesh fitter, not a keypoint consumer |
| MediaPipe Pose Landmarker Full | Same as Lite | Same as Lite | Same as Lite | Same as Lite | Same as Lite |
| MediaPipe Pose Landmarker Heavy | Same as Lite | Same as Lite | Same as Lite | Same as Lite | Same as Lite |
| WHAM | ✅ — WHAM outputs SMPL joint rotations; direct vector math on SMPL skeleton works | ⚠️ SMPL-to-OpenSim body-model fit required (complex — this is effectively what OpenCap Monocular's pipeline does internally) | ❌ OpenCap Core does not accept WHAM as input (uses its own HRNet/OpenPose 2D front end) | ✅ WHAM *is* the front end of OpenCap Monocular per [Gilon26] | ⚠️ SMPL (WHAM) and SKEL (HSMR) are different skeletons — parallel cross-check only, not chainable |
| OpenCap Monocular (as a pose source) | ✅ already outputs kinematics | ✅ OpenSim-native by design | n/a (sibling pipeline) | n/a (this is the pipeline itself) | ⚠️ parallel cross-check only |
| OpenCap (dual-camera) | ✅ outputs kinematics | ✅ OpenSim-native | n/a (this is the pipeline itself) | n/a (sibling pipeline) | ⚠️ parallel cross-check only |
| HSMR | ✅ outputs a biomechanical skeleton | ⚠️ SKEL-to-OpenSim adapter not found in the sources reviewed | ❌ HSMR is a mesh fitter, not a 2D front end | ⚠️ could be run as a parallel branch to WHAM per [DRS §Multi-model] — not a drop-in swap | n/a (this is the model itself) |
| MotionBERT | ✅ outputs 3D joints | ⚠️ Human3.6M-to-OpenSim adapter required | ❌ incompatible | ❌ not used by OpenCap Monocular (WHAM replaced MotionBERT in the pipeline per [MFR §1]) | ⚠️ parallel cross-check only |
| ViTPose (S/B/L/H) | ⚠️ 2D only — direct geometry limited to in-plane angles without a 3D-lift stage | ❌ OpenSim expects 3D; ViTPose alone is 2D | ⚠️ could in principle swap into OpenCap Core's 2D-detector slot (OpenCap Core's detector is pluggable per [Uhlrich23] notes in [DRS §1]), but no upstream support | ❌ incompatible with the monocular pipeline's WHAM front end | ❌ incompatible |
| TCPFormer | ⚠️ — theoretical compatibility as a MotionBERT-replacement in a 2D→3D path; code availability unclear per Table 3 | ⚠️ same as MotionBERT | ❌ | ❌ | ⚠️ parallel only |
| MoveNet Lightning / Thunder | ⚠️ 2D only (17-keypoint COCO) — 2D direct angle calc only, no 3D backend path | ❌ (2D only) | ⚠️ could swap into OpenCap Core's 2D-detector slot (not documented in sources reviewed) | ❌ | ❌ |
| HRNet-W48 (reference) | ⚠️ 2D only | ❌ (2D only) | ✅ native 2D detector used by OpenCap Core per [Uhlrich23] | ❌ (OpenCap Monocular uses WHAM) | ❌ |
| HRPose / HRNet-small (mobile ports) | ⚠️ 2D only | ❌ (2D only) | ⚠️ HRNet-family is OpenCap's native 2D path, but the *mobile* HRPose ports are not the same weights / variant as the reference HRNet-W48 used by OpenCap Core | ❌ | ❌ |
| Sabo 2026 Beighton scorer | n/a — classification head, not a joint-angle producer | n/a | n/a | n/a | n/a |

Legend: ✅ out-of-the-box per a cited source; ⚠️ adapter / skeleton remap / multi-step work required; ❌ incompatible per the upstream component's design.

---

## Table 8 — Biomechanics / MSK backend options

| Name | Desktop or Mobile | Input required | Output produced | License (ref [v2]) | Compatible pose sources | On-device (phone) feasibility |
|---|---|---|---|---|---|---|
| OpenSim core (C++) | Desktop (Windows / macOS / Linux C++ library) | Musculoskeletal model (`.osim`) + motion file (`.mot`) or marker trajectories (`.trc`) | Full inverse dynamics: joint angles, joint moments, muscle forces, reaction forces, moment arms, energetics | Apache 2.0 [v2] | Any 3D marker/joint source that can be written to `.trc` or `.mot` | **No** — desktop only; no mobile port exists in `opensim-core` |
| OpenSim Python bindings (`opensim` pip) | Desktop (Python, via bundled compiled C++ core) | Same as core | Same as core, exposed as Python API | Apache 2.0 [v2] | Same as core | **No** — desktop only; ships a compiled C++ core |
| Rajagopal 2016 full-body MSK model | Desktop (loaded by OpenSim) | `.osim` + motion input | 37 DoF, ~80 muscles in the OpenCap variant | MIT Use Agreement [v2] | Any OpenSim-compatible motion source | **No** — depends on OpenSim runtime |
| OpenCap Core (Python) | Desktop / server (orchestrates OpenSim + HRNet + OpenPose) | 2+ synchronized smartphone videos | Kinematics + muscle/force simulation | Apache 2.0 [v2] | HRNet-W48 or OpenPose 2D (dual-camera) | **No** — server only per [Uhlrich23] |
| OpenCap Monocular (pipeline) | Server (Python + GPU) | One smartphone video + subject height | Kinematics + joint moments + GRFs + muscle forces | PolyForm Noncommercial 1.0.0 [v2] | WHAM (internally) | **No** — server only; optimization is seconds–minutes per capture |
| Direct joint-angle calculation from 3D landmarks (geometry only, no MSK) | **Either — pure math** | Any 3D keypoint stream (BlazePose 33-landmark x,y,z, SMPL joint set, etc.) | Joint angles via vector math (no forces, no muscle data) | n/a — user-written code | Any 2D or 3D pose source | **Yes — trivially mobile.** Used in `markerless-mediapipe-joint-moments.pdf` for Hip/Knee/Ankle correlation (R=0.94/0.95/0.11) |
| HSMR / SKEL (used as a skeleton fitter) | Server | Single image | SKEL 46-DoF skeleton with 0% joint-limit violations; 18.8 mm better on extreme poses than SMPL methods per [HSMR] | MIT (code); SMPL dependency for academic use [v2] | Single image (its own pipeline) | **No** — server only |
| Pose2Sim | Desktop | Multi-camera 2D pose | 3D triangulated keypoints → OpenSim IK | Apache 2.0 [CAT §Gap 1] | Multi-camera only — "not viable for single phone" per [CAT] | **No** — desktop, multi-camera |

**No mobile-native MSK simulator library was found in the research files reviewed.** All OpenSim-family backends are desktop/server only. For any on-device biomechanics processing, the only backend listed above that runs on a phone is "direct joint-angle calculation from 3D landmarks" — i.e. geometry-only, no muscle forces.

---

## Table 9 — Training-data → generalization domain (rescoped from v1 licensing table)

This table answers "what domains does each model generalize to?" — the relevant question for the AuraLink use case is "how well does it handle ordinary phone video of a person performing an overhead squat / single-leg squat / push-up / rollup in a gym, clinic, or home setting?" Licensing of the training data is covered in Table 4 and in [v2].

| Pose model | Training dataset(s) | Domain the model generalizes to | Expected performance on AuraLink's use case (ordinary phone video of a person doing a movement screen) | Notes / source |
|---|---|---|---|---|
| MediaPipe Pose Landmarker (Lite / Full / Heavy) | unknown — BlazePose GHUM 3D model card PDF not text-extractable in [v2] | unknown formally; Google positions BlazePose as a general consumer-video model covering "fitness, yoga, AR effects" | Good candidate for ordinary phone video — it's the only model in this table whose entire product design target is that use case; specific movement-screen accuracy unknown from Google's public materials | [MP-doc], [v2] |
| WHAM | AMASS (synthetic 2D projections), plus 3DPW / BEDLAM / EMDB for benchmarking | Motion-capture-distribution domain (indoor and outdoor, includes BEDLAM-synthetic settings); generalizes better to in-the-wild than Human3.6M-only models | Paper demonstrates improved world-grounding on in-the-wild video; specific fitness/movement-screen performance not in paper | [Shin24], [v2] |
| OpenCap (Uhlrich 2023) | Stanford 100-subject validation cohort (multi-camera + marker mocap). Uses pretrained HRNet-W48 / OpenPose internally (not retrained inside OpenCap) | Lab-captured controlled conditions with multi-camera rig | N/A for single phone; dual-camera requirement disqualifies it from AuraLink's single-phone use case | [Uhlrich23] |
| OpenCap Monocular (Gilon 2026) | Re-validated on Stanford/Utah marker+force-plate datasets; WHAM backbone inherits AMASS/3DPW/BEDLAM/EMDB | Mocap-validated squat / sit-to-stand / walking in a research-gym setting | Validated on walking / squat / STS per [Gilon26]; overhead squat, single-leg squat, push-up, rollup coverage is unproven | [Gilon26], [DRS §2] |
| HSMR | unknown — training set not quoted in `catalog.md` / [MFR §2.2] / [DRS] excerpts reviewed | Unknown (SMPL-based mesh fitter — generalization tied to the training corpus used by the authors) | Unknown for movement-screen settings | [HSMR], [CAT] |
| MotionBERT | Human3.6M (released checkpoints) | Indoor lab with controlled lighting, treadmill / walking corridor settings | Known domain gap: Human3.6M is a small set of staged indoor activities and generalizes poorly to in-the-wild fitness video without fine-tuning | [v2] Human3.6M row; [CAT §Gap 1] |
| ViTPose (S / B / L / H) | COCO + MPII (2D pose); ImageNet-21K (backbone pretraining) | Everyday scenes (COCO) + "people in sports/news images" (MPII); excellent 2D accuracy, zero 3D coverage | Very strong 2D keypoint accuracy on ordinary phone video; still needs a separate 3D-lifting stage before any biomechanics | [Xu22], [v2] COCO + MPII rows |
| TCPFormer | Human3.6M + MPI-INF-3DHP | Indoor lab (Human3.6M) + green-screen multi-camera studio (MPI-INF-3DHP) | Same domain-gap concern as MotionBERT | [Liu25] |
| MoveNet Lightning / Thunder | unknown from sources reviewed (Google-internal) | Positioned by Google for "fitness and yoga" in-the-wild usage, similar to MediaPipe Pose | Good candidate for ordinary phone video, similar to MediaPipe; specific movement-screen accuracy unknown | [MFR §2.1] |
| HRNet-W48 / HRPose / HRNet-small | COCO (original HRNet) | Everyday scenes from COCO (similar to ViTPose) | Strong 2D accuracy on ordinary phone video; 2D only | [CAT] |
| Sabo 2026 Beighton scorer | Private EDS-clinic cohort, n=125, 91.9% sensitivity / 42.4% specificity (for Beighton scoring, not movement screening in general) | Clinical hypermobility screening on controlled in-clinic video | Off-scope — it is a hypermobility scorer, not a movement-screen scorer; listed for completeness | [Sabo26], [MFR §2.2] |

---

## Data gaps

Every "unknown" cell above is listed below, grouped by the action needed to fill it.

### Table 1 (Capability)
- **MediaPipe Heavy** — exact phone FPS unknown. Action: benchmark on the target device.
- **WHAM** — per-frame fps on a named server GPU. Action: run the WHAM reference repo on a test clip.
- **HSMR** — per-frame latency. Action: run the HSMR repo on a test clip.
- **ViTPose-L / H** — per-variant phone feasibility. Action: paper only benchmarks on A100; "could theoretically run quantized on high-end Android" per [DRS §6] is not a measured claim.
- **TCPFormer** — no authoritative code release; nothing to benchmark.

### Table 2 (Deployment footprint)
- **MediaPipe Pose Landmarker (all three variants)** — min RAM and Google-published per-device latency. Action: open BlazePose GHUM 3D Model Card PDF in a real browser (outside this sandbox).
- **MediaPipe Heavy** — `.task` file exact size (fetch aborted at 10 MB cap). Action: `curl -I` or range-headers fetch from outside the sandbox cap.
- **WHAM** — parameter count, file size, measured fps. Action: inspect checkpoint in the cloned repo.
- **HSMR** — file size, parameter count, per-frame latency. Action: read `sensing/biomechanically-accurate-skeleton.pdf` directly or the HSMR GitHub README.
- **MotionBERT** — file size, parameter count, phone/GPU latency. Action: read the MotionBERT GitHub README.
- **ViTPose-L** — exact parameter count (paper quotes family range 100M–1B but not per-variant table). Action: read the ViTPose paper's per-variant table.
- **MoveNet Lightning / Thunder** — exact file sizes and training dataset. Action: read the TF Hub model card.
- **HRPose / HRNet-small mobile ports** — size, license, trainable-signature support — all per third-party port. Action: pick a specific port and audit it.
- **Sabo 2026 Beighton scorer** — exact MobileNet variant. Action: read the Sabo 2026 paper's methods section.

### Table 3 (Out-of-box usability / tooling maturity)
- **MediaPipe Pose Landmarker demo quality** on ordinary user-captured phone video (as opposed to Google's curated demo clips) — not formally benchmarked. Action: capture the team's own demo clips and measure.
- **HRPose / HRNet-small mobile-port tooling maturity** — per-port audit not done in this pass. Action: pick a specific port.
- **Sabo 2026 Beighton scorer community and docs** — research-only release; public community activity unknown. Action: email the paper authors.
- **TCPFormer official release status** — the paper-queried repo `hbing-l/TCPFormer` 404s; `AsukaCamellia/TCPFormer` (110 stars) is the top mirror, stale since 2025-05-13. An authoritative author repo may exist elsewhere. Action: contact the paper authors or check alternative mirrors periodically.

### Table 4 (Academic licensing)
- **WHAM weights license** (`wham.is.tue.mpg.de/license.html`) — JS shell in headless fetchers per [v2]. Template matches verified TUE non-commercial. Action: open in a real browser for verbatim confirmation.
- **opencap.ai formal ToS** — Webflow SPA, JS shell per [v2]. Action: open `opencap.ai/terms` in a real browser.
- **BlazePose GHUM 3D Model Card PDF** — not text-extractable in the v2 sandbox. Action: open in a real browser.
- **MoveNet, HRNet mobile ports** — not covered in [v2]. Action: read TF Hub model card / pick a port.

### Table 5 (sEMG fusion)
- **BLE jitter budget on the team's target phones**, used for end-to-end pose-frame ↔ sEMG-sample sync. Action: measurement on the actual devices the team plans to demo with.
- **ESP32-S3 + AD8232 per-channel sample rate target.** The 10-channel topology is fixed in `CLAUDE.md`; the per-channel Hz is a hardware spec question not answered in the research corpus. Action: read the `hardware/` tree.
- **Core ML / TFLite latency for pose inference running concurrently with the app's BLE data path.** Action: measurement on the actual device.

### Table 6 (Skeleton → Rajagopal mapping)
- **SKEL (HSMR) → Rajagopal mapping** — no published adapter found in the sources reviewed. Action: search `simtk.org` and OpenSim community forums, or contact the HSMR authors.
- **BlazePose-to-OpenSim marker mapping specifics** — `markerless-mediapipe-joint-moments.pdf` reports correlation figures but does not publish the marker-mapping file itself. Action: read that PDF directly or email the authors.
- **Human3.6M → Rajagopal specific mapping** — known to exist in the biomechanics literature; specific citation not pulled in this pass. Action: biomechanics literature search.

### Table 7 (Pipeline compatibility)
- **OpenCap Core's 2D-detector pluggability** — [DRS §1] describes it as pluggable in principle; specific drop-in of ViTPose / MoveNet / HRPose not documented. Action: read `opencap-core` README and source.

### Table 8 (Biomechanics backends)
- No unknown cells (backends are either well-documented or explicitly listed as "not mobile-feasible").

### Table 9 (Generalization domain)
- **MediaPipe Pose Landmarker training dataset** — not disclosed on Google's page. Action: open BlazePose GHUM 3D Model Card PDF in a real browser.
- **HSMR training set** — not quoted in catalog notes. Action: read the HSMR paper / GitHub README.
- **MoveNet training set** — not disclosed in the sources reviewed. Action: read TF Hub model card.
- **Per-movement accuracy** for overhead squat, single-leg squat, push-up, rollup, on any of the pose models listed. This is a research question, not a metrics lookup — filling it in requires running the models on the team's own clips and hand-labeling ground truth.

---

## Deferred: federated learning

FL was researched in depth during the first pass of this matrix (TFF, Google federated-compute, Flower, PySyft, FATE, NVFlare, FedML, OpenFL, Apple `pfl-research`). It is **not in scope** for the capstone: the team is not training any model on real user data this semester. HIPAA is addressed architecturally by keeping pose inference on-device so raw video never leaves the phone, not by FL. FL only becomes relevant if the team later wants to *train* a downstream classifier on real user data across many users without centralizing it — which is explicitly future work, not current scope. The raw framework comparison and on-device-training feasibility notes from the earlier pass live in this file's git history (commit preceding the 2026-04-11 rewrite) for the team's reference if the project ever picks that thread back up.
