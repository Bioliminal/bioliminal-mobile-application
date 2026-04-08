# AuraLink — Technical Briefing

## Problem Statement
**What problem?** Movement screening costs $150–2,000 and requires a trained professional. Current AI movement tools detect *what's* happening (knee collapses inward) but can't explain *why* (ankle restriction forcing compensation up the chain). Zero cross-citations exist between computer vision and fascial chain research across 4,071 papers — the fields needed to build this tool have never talked to each other.

**Why fix it?** Most athletes — especially youth and recreational — never get screened. They find out something's wrong when they get hurt. The clinical reasoning that connects symptoms to upstream drivers lives entirely in practitioners' heads and takes 3–4 visits to surface. Upstream reasoning reduces recurrence from 50–72% to 6–8% (SFMA, lateral elbow data).

**Why integral?** This tool is the first to bridge computer vision, biomechanics, and fascial chain science. It encodes practitioner-level pattern matching into computable rules that run on a phone, for free. The integration has zero precedent — it can only exist if someone builds the bridge.

**End goal:** A working Flutter app (mobile + web demo) that runs a 5-minute, 4-movement screen from a phone camera, detects compensation patterns, maps them along 3 validated fascial chains (SBL/BFL/FFL), and generates a personalized triage report with cited evidence. Validated against 2–3 clinicians on 10 test subjects across 3 layers (measurement accuracy, chain mapping agreement, recommendation usefulness).

## Overview

AuraLink is a Flutter-based AI movement screening app. Users perform 4 movements in front of their phone camera (~60 sec each). MediaPipe BlazePose extracts 33 body landmarks, which feed into a logic engine that calculates joint angles, detects compensation patterns against published thresholds, and maps co-occurring findings along three validated fascial chains (SBL/BFL/FFL) to identify upstream root causes. The output is a personalized triage report with body-path language, per-finding confidence scoring, inline evidence citations, and specific practitioner discussion points.

The app shell and ML pipeline are developed in parallel by separate team members. The Flutter app (Kelsi) defines clean service interfaces; the ML developer implements the pose estimation, angle calculation, and chain mapping logic behind those interfaces. Mock implementations allow app development to proceed independently.

## Summary

AuraLink is a Flutter movement screening app that bridges computer vision and fascial chain science — two fields with zero academic cross-citation. Users perform 4 movements on their phone camera. MediaPipe BlazePose tracks 33 landmarks; a rule-based logic engine detects compensation patterns and maps them along 3 validated chains (SBL/BFL/FFL) to find upstream root causes. Output is a personalized triage report with confidence scoring, evidence citations, and practitioner discussion points. Architecture: feature-first Flutter with Riverpod, clean service interfaces for ML pipeline (separate developer), Firebase/Firestore for persistence. Mobile-first; web demo uses pre-recorded data. 3-week capstone, team of 4.

## Features

### MVP
0. **Bootstrap** — `flutter create --org com.auralink --platforms ios,android auralink` + Firebase setup + install all dependencies + create shared interfaces + `.env` config + `flutter_test` setup + `go_router` routing + Riverpod DI + theme
   - `lib/core/` (router, theme, DI)
   - `lib/domain/` (all shared interfaces + models)
   - `pubspec.yaml`, `firebase.json`, analysis_options.yaml

1. **Camera Pipeline + Setup** — Camera access, BlazePose integration point, skeleton overlay via CustomPainter, progressive setup checklist (angle, distance, lighting, clothing), per-joint confidence colors
   - `lib/features/camera/views/camera_view.dart`
   - `lib/features/camera/controllers/camera_controller.dart`
   - `lib/features/camera/widgets/skeleton_overlay.dart`
   - `lib/features/camera/widgets/setup_checklist.dart`

2. **Movement Assessment Flow** — 4 movements (overhead squat → single-leg balance → overhead reach → forward fold), ~60 sec each, instructions, rep counter, progress indicator, between-movement preliminary findings
   - `lib/features/screening/views/screening_view.dart`
   - `lib/features/screening/controllers/screening_controller.dart`
   - `lib/features/screening/widgets/movement_instructions.dart`
   - `lib/features/screening/widgets/preliminary_findings.dart`
   - `lib/features/screening/models/movement.dart`

3. **Logic Engine Interfaces + Mocks** — PoseEstimationService, AngleCalculator, ChainMapper interfaces with mock implementations returning realistic test data. ML developer replaces mocks with real implementations.
   - `lib/domain/services/pose_estimation_service.dart`
   - `lib/domain/services/angle_calculator.dart`
   - `lib/domain/services/chain_mapper.dart`
   - `lib/domain/mocks/mock_pose_estimation.dart`
   - `lib/domain/mocks/mock_angle_calculator.dart`
   - `lib/domain/mocks/mock_chain_mapper.dart`

4. **Report Generation** — Personalized compensation patterns as body-path connections, layered display (summary → expand), inline evidence citations, practitioner discussion points, confidence colors per finding, PDF export, one-tap share
   - `lib/features/report/views/report_view.dart`
   - `lib/features/report/widgets/finding_card.dart`
   - `lib/features/report/widgets/citation_expandable.dart`
   - `lib/features/report/services/pdf_generator.dart`

5. **Data Persistence** — Local assessment storage + Firestore sync. Anonymous auth. Save/load assessments, store generated reports/PDFs.
   - `lib/core/services/local_storage_service.dart`
   - `lib/core/services/firestore_service.dart`
   - `lib/core/services/auth_service.dart`

6. **Confidence Visualization** — Real-time skeleton overlay with per-joint confidence colors (green >0.9, yellow 0.7–0.9, red <0.7). Specific feedback for low-confidence joints. Report-level confidence annotations.
   - Modifies: `lib/features/camera/widgets/skeleton_overlay.dart`
   - Modifies: `lib/features/report/widgets/finding_card.dart`

### Phase 2 (post-capstone)
7. **Live Web ML** — MediaPipe Tasks Vision JS SDK integration for live web pose estimation. Capstone web demo uses pre-recorded landmark data.
8. **sEMG Hardware** — BLE pairing, sensor placement guide, real-time muscle activation overlay, haptic cueing
9. **Longitudinal Tracking** — Dashboard showing pattern changes over time, return-visit comparisons
10. **User Accounts** — Profile persistence, assessment history, practitioner sharing

## Technical Research

### APIs & Services

- **MediaPipe BlazePose**: 33 landmark pose estimation. Native: `google_mlkit_pose_detection` (ML Kit). Web (Phase 2): `@mediapipe/tasks-vision` JS SDK. Returns landmarks with x, y, z coordinates and visibility confidence scores.
- **Firebase/Firestore**: Anonymous auth via `firebase_auth`. Document storage via `cloud_firestore`. Collections: `assessments/{id}`, `assessments/{id}/movements/{id}`, `reports/{id}`.
- **No external APIs** — all ML processing on-device.

### Architecture

**Feature-first with Riverpod + clean service interfaces.**

```
lib/
├── core/
│   ├── router.dart              — GoRouter config
│   ├── theme.dart               — App theme + confidence colors
│   ├── providers.dart           — Riverpod providers (DI)
│   └── services/
│       ├── local_storage_service.dart
│       ├── firestore_service.dart
│       └── auth_service.dart
├── domain/
│   ├── models/
│   │   ├── landmark.dart        — x, y, z, visibility
│   │   ├── joint_angle.dart     — joint, angle_degrees, confidence
│   │   ├── compensation.dart    — type, joint, chain, confidence, citation
│   │   ├── assessment.dart      — movements[], compensations[], report
│   │   ├── movement.dart        — type, landmarks[], angles[], duration
│   │   └── report.dart          — findings[], recommendations[], citations[]
│   ├── services/
│   │   ├── pose_estimation_service.dart   — abstract interface
│   │   ├── angle_calculator.dart          — abstract interface
│   │   └── chain_mapper.dart              — abstract interface
│   └── mocks/
│       ├── mock_pose_estimation.dart
│       ├── mock_angle_calculator.dart
│       └── mock_chain_mapper.dart
├── features/
│   ├── onboarding/
│   │   ├── views/disclaimer_view.dart     — non-skippable legal disclaimer
│   │   └── views/welcome_view.dart
│   ├── camera/
│   │   ├── views/camera_view.dart
│   │   ├── controllers/camera_controller.dart
│   │   ├── widgets/skeleton_overlay.dart
│   │   └── widgets/setup_checklist.dart
│   ├── screening/
│   │   ├── views/screening_view.dart
│   │   ├── controllers/screening_controller.dart
│   │   ├── widgets/movement_instructions.dart
│   │   └── widgets/preliminary_findings.dart
│   └── report/
│       ├── views/report_view.dart
│       ├── widgets/finding_card.dart
│       ├── widgets/citation_expandable.dart
│       └── services/pdf_generator.dart
└── main.dart
```

**Key architectural decisions:**
- **Riverpod** for state management — unidirectional data flow, testable, supports async streams from pose estimation
- **Abstract service interfaces** in `domain/services/` — ML developer implements these, app shell uses mocks until real implementations arrive
- **Feature-first directories** — each feature owns its views, controllers, and widgets
- **Local-first writes** with background Firestore sync — handles offline scenarios gracefully
- **Anonymous auth** via Firebase — secures Firestore rules without requiring user accounts

### Patterns

- **State management**: Riverpod 2.x with `StateNotifier` or `AsyncNotifier` for controllers. Unidirectional data flow. Pose estimation streams via `StreamProvider`.
- **Error handling**: Results pattern (sealed class `Result<T>` with `Success<T>` and `Failure`) for service calls. Camera/permission errors surface via UI snackbars. No silent swallowing.
- **Service pattern**: All external interactions behind abstract interfaces in `domain/services/`. Concrete implementations registered via Riverpod providers. Swap mocks ↔ real via provider overrides in tests and during development.
- **Naming**: `snake_case` files, `PascalCase` classes, `camelCase` methods/variables. Service interfaces suffixed with `Service`. Controllers suffixed with `Controller`.
- **Confidence colors**: Defined in `theme.dart` as semantic colors — `confidenceHigh` (green), `confidenceMedium` (yellow), `confidenceLow` (red). Used consistently across skeleton overlay and report findings.

### Shared Interfaces

- `lib/domain/services/pose_estimation_service.dart`: `PoseEstimationService` — `Stream<List<Landmark>> processFrame(CameraImage frame)` (used by features: 1, 2, 6)
- `lib/domain/services/angle_calculator.dart`: `AngleCalculator` — `List<JointAngle> calculateAngles(List<Landmark> landmarks)` (used by features: 2, 3)
- `lib/domain/services/chain_mapper.dart`: `ChainMapper` — `List<Compensation> mapCompensations(List<JointAngle> angles)` (used by features: 2, 4)
- `lib/domain/models/*.dart`: Shared data models (used by all features)

### Data Model

```
Assessment
├── id: String
├── createdAt: DateTime
├── movements: List<Movement>
│   ├── type: MovementType (overheadSquat | singleLegBalance | overheadReach | forwardFold)
│   ├── landmarks: List<List<Landmark>>  // frames of landmarks
│   ├── keyframeAngles: List<JointAngle>  // from 5-frame buffer at peak
│   └── duration: Duration
├── compensations: List<Compensation>
│   ├── type: CompensationType (kneeValgus | hipDrop | ankleRestriction | trunkLean | etc.)
│   ├── joint: String
│   ├── chain: ChainType? (sbl | bfl | ffl | null)
│   ├── confidence: ConfidenceLevel (high | medium | low)
│   ├── value: double  // measured angle
│   ├── threshold: double  // published threshold
│   └── citation: Citation
└── report: Report
    ├── findings: List<Finding>
    │   ├── bodyPathDescription: String  // "your knee and hip compensate together"
    │   ├── compensations: List<Compensation>
    │   ├── upstreamDriver: String?  // CC identification
    │   ├── recommendation: String
    │   └── citations: List<Citation>
    ├── practitionerPoints: List<String>
    └── pdfUrl: String?  // Firestore Storage URL
```

### Dependencies

- `flutter_riverpod: ^2.5.0` — state management + DI
- `go_router: ^14.0.0` — declarative routing
- `camera: ^0.11.0` — camera access + stream
- `google_mlkit_pose_detection: ^0.11.0` — BlazePose on native (ML dev integrates)
- `firebase_core: ^3.0.0` — Firebase initialization
- `firebase_auth: ^5.0.0` — anonymous authentication
- `cloud_firestore: ^5.0.0` — document storage
- `firebase_storage: ^12.0.0` — PDF/report file storage
- `pdf: ^3.10.0` — declarative PDF generation
- `share_plus: ^9.0.0` — native share sheet
- `path_provider: ^2.1.0` — local file paths
- `freezed_annotation: ^2.4.0` + `freezed: ^2.5.0` — immutable data classes (dev dependency)
- `json_annotation: ^4.9.0` + `json_serializable: ^6.8.0` — JSON serialization (dev dependency)
- `build_runner: ^2.4.0` — code generation (dev dependency)

### Gotchas

- **Ankle tracking unreliable** — MediaPipe ankle visibility degrades significantly with occlusion (r=0.45 in forward fold). All ankle-dependent findings MUST carry reduced confidence. Never make ankle-only recommendations.
- **5-frame smoothing buffer latency** — The keyframe snapshotting approach introduces a brief delay. UI must provide immediate visual feedback (skeleton overlay) even while buffer processes.
- **Camera permission timing** — iOS requires `NSCameraUsageDescription` in `Info.plist`. Android requires runtime permission. Handle denial gracefully with re-prompt.
- **Flutter web + camera** — `camera` package has limited web support. Web demo should use pre-recorded landmark data, not live camera.
- **Firestore offline behavior** — Firestore SDK caches locally by default. With anonymous auth, if the user reinstalls the app, their anonymous UID changes and they lose access to prior data. Acceptable for capstone; solve with real accounts in Phase 2.
- **Hypermobility false negatives** — Fixed >10° valgus threshold misclassifies hypermobile individuals (3.5° lower baseline). Threshold adjustment logic needed in ChainMapper.
- **PDF size** — Embedding body diagrams as vectors keeps PDFs small (~100KB). Raster images would balloon to 2–5MB.

### Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| ML interface contract mismatch | High | High | Finalize interfaces day 1. Build app against mocks. Integration test when ML dev delivers. |
| MediaPipe performance on older devices | Medium | Medium | Test on iPhone 11 and a 5-year-old Android early. Define fallback (reduce frame rate, skip overlay). ML dev's scope but app must handle gracefully. |
| Firestore security with anonymous auth | Medium | Low | Write strict security rules: users can only read/write their own anonymous UID's documents. |
| 3-week timeline overrun | High | Medium | Prioritize: camera + screening flow + mock logic + report. Firestore sync and PDF are stretch. Demo can use local-only. |
| Chain mapping validation disagreement | Medium | Medium | This is a research finding, not a bug. Document clinician feedback. Adjust thresholds if consensus emerges. |

### Cost Estimate

**Development complexity:**

| Feature | Size | Notes |
|---------|------|-------|
| 0. Bootstrap | S | Scaffold, Firebase config, shared types |
| 1. Camera Pipeline | M | Camera access, overlay, setup checklist |
| 2. Movement Flow | M | 4 movement screens, state machine, preliminary findings |
| 3. Logic Interfaces + Mocks | S | Abstract classes + mock data |
| 4. Report Generation | L | PDF layout, citations, share, layered UI |
| 5. Data Persistence | M | Firestore + local + anonymous auth |
| 6. Confidence Viz | S | Colors on existing overlay + report cards |

**Monthly operational costs:**

| Component | 1K users | 10K users | 100K users |
|-----------|----------|-----------|------------|
| Firebase Auth | $0 (free tier) | $0 (free tier) | $0 (free tier) |
| Firestore | $0 (free tier) | $1–5/mo | $25–75/mo |
| Firebase Storage | $0 (free tier) | $2–8/mo | $20–50/mo |
| Hosting (web demo) | $0 (Firebase Hosting free) | $0 | $5–15/mo |
| **Total** | **$0** | **$3–13/mo** | **$50–140/mo** |

Primary cost driver: Firestore document reads at scale (each assessment = ~10 document writes).

### Deployment

- **Platform**: Firebase (hosting + auth + Firestore + storage — single ecosystem)
- **Build (mobile)**: `flutter build ios` / `flutter build apk`
- **Build (web)**: `flutter build web`
- **Deploy (web)**: `firebase deploy --only hosting`
- **Beta distribution**: TestFlight (iOS), Firebase App Distribution (Android)
- **URL**: `auralink.web.app` (Firebase Hosting default) or custom domain
- **Config**: `firebase.json` (hosting config), `firestore.rules` (security rules), `storage.rules`
- **Secrets**: Firebase config via `google-services.json` (Android) + `GoogleService-Info.plist` (iOS). No additional secrets — all Firebase, no third-party API keys.

## Test Strategy

### Critical paths
- Camera permission flow: grant → stream starts → landmarks render on overlay
- Movement assessment state machine: 4 movements in order, ~60 sec each, correct progress indicator
- Mock logic engine: landmarks in → angles out → compensations out → chain mapping out
- Report generation: compensations → body-path language findings → expandable citations → PDF export
- Assessment persistence: save locally → sync to Firestore → retrieve on reload
- Person A vs Person B: same symptom (knee valgus) + different context (ankle restriction vs hypermobility) → different recommendation

### Edge cases
- Camera permission denied → graceful error with re-prompt
- Ankle occlusion during forward fold → confidence degrades to red, finding flagged
- All joints high confidence → no yellow/red degradation in report
- Zero compensations detected → "No significant findings" report (not an error)
- Firestore offline → local save succeeds, sync when reconnected
- App backgrounded mid-movement → resume or restart movement (not crash)

### Integration boundaries
- PoseEstimationService contract: mock returns consistent data shapes that match what ML dev will deliver
- AngleCalculator contract: verify 2D angle math against known landmark positions
- ChainMapper contract: given known compensation patterns, correct chain identified
- Firestore serialization: Assessment model serializes/deserializes without data loss

### What NOT to test
- Flutter widget rendering (framework responsibility)
- Firebase SDK behavior (Google's tests)
- MediaPipe accuracy (ML dev's domain + published papers validate)
- Route configuration (fails obviously)
- Type correctness (Dart's type system catches these)

## Blast Radius

- **`lib/domain/services/`** (interfaces): Every feature depends on these. Changing a service signature breaks camera, screening, and report features. **Freeze these by day 1.**
- **`lib/domain/models/`** (data classes): Serialized to Firestore and used in PDF generation. Schema changes cascade to persistence and export.
- **`lib/core/providers.dart`** (DI): All features resolve dependencies here. Adding/removing a provider affects every screen.
- **`lib/features/screening/controllers/`**: Orchestrates the full assessment flow. Bug here = broken user journey.
- Confidence: **best-effort** — greenfield project, no existing code to break. Risk is in interface contract definitions, not in downstream dependencies.

## Success Criteria

- A user can open the app, complete 4 movements in ~5 minutes, and receive a personalized report — end-to-end on a phone.
- Two users with the same symptom (e.g., knee valgus) but different patterns receive different recommendations.
- Every finding in the report cites its evidence source (expandable).
- Per-joint confidence colors are visible during movement and on the report.
- 2–3 clinicians reviewing 10 test subjects agree with chain attribution ≥70% of the time.
- Report is shareable (PDF or link) with enough detail for a practitioner to act on.

## Environment

- `FIREBASE_PROJECT_ID` — Firebase project identifier (required)
- `FIREBASE_WEB_APP_ID` — Web app config for Flutter web build (required for web demo)
- `FIREBASE_API_KEY` — Firebase API key (required)
- Note: Mobile Firebase config is handled via `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), not environment variables.

## Decisions

- **Platform priority**: Mobile-first (iOS/Android), web for demo only with pre-recorded data — user decision
- **Angle calculation**: 2D screen-space initially; 3D upgrade path via interface — user decision
- **Data persistence**: Local storage + Firestore with anonymous auth — user decision (updates original "no backend" constraint)
- **Device floor**: iPhone 11+ / Android 5–6yr — user decision, optimization is ML dev's scope
- **Frame analysis**: Keyframe snapshotting with 5-frame smoothing buffer — Gemini recommended, user agreed, subject to ML dev's direction
- **MediaPipe integration**: Platform-specific (ML Kit native, JS Tasks Vision web) — Gemini recommended, user agreed
- **PDF generation**: Declarative PDF via `pdf` package, stored to Firestore — user decision
- **Architecture**: Feature-first + Riverpod + abstract service interfaces for ML pipeline — Gemini recommended, aligned with team structure
- **State management**: Riverpod 2.x with unidirectional data flow — Gemini recommended
- **Authentication**: Anonymous Firebase auth (no user accounts, but secures Firestore rules) — Claude added based on Firestore security requirement
- **Web ML**: Pre-recorded/mock landmark data for web demo; live MediaPipe is Phase 2 — Claude recommended based on timeline risk

## Constraints

- Flutter (iOS/Android/Web) — single codebase
- Firebase/Firestore for persistence and report storage
- ML pipeline is a separate developer's product — app defines interfaces only
- 3-week capstone timeline, team of 4
- Educational framing only — FDA wellness/CDS guidance (Jan 2026)
- iPhone 11+ / Android 5–6yr device floor
- 2D angles initially, 3D upgrade path via interface
- SBL/BFL/FFL chains only — Spiral, Lateral, SFL excluded (insufficient evidence)
- 4 movements only — overhead squat, single-leg balance, overhead reach, forward fold
- Body-path language only — no chain names in user-facing output
- Every finding must cite evidence inline
- Ankle findings always carry reduced confidence
- No injury prediction, no diagnostic language, no static posture assessment

## Reference

- Wilke et al. (2016) — SBL/BFL/FFL chain evidence: https://pubmed.ncbi.nlm.nih.gov/26281953/
- Kalichman (2025) — Independent chain hierarchy confirmation: https://pubmed.ncbi.nlm.nih.gov/41316622/
- Hewett et al. (2005) — Knee valgus >10° threshold: https://pubmed.ncbi.nlm.nih.gov/15722287/
- Ferber et al. — Hip-for-knee RCT (n=199): https://pubmed.ncbi.nlm.nih.gov/25102167/
- Gnat 2022 RCT — CC/CP framework validation: https://www.mdpi.com/2075-1729/12/2/222
- RESTORE trial (n=492) — 3-year upstream treatment outcomes: https://pubmed.ncbi.nlm.nih.gov/37060913/
- Swain 2020 — Static posture debunked: https://pubmed.ncbi.nlm.nih.gov/32014781/
- Bahr 2016 — Screening ≠ prediction: https://bjsm.bmj.com/content/50/13/776
- FDA CDS Guidance (Jan 2026): https://www.fda.gov/media/109618/download
- Dorsher 2009 — 91% SBL/Bladder Meridian correspondence: https://www.liebertpub.com/doi/10.1089/acu.2009.0701
- Langevin & Yandow 2002 — 80% acupoint/fascial plane overlap: https://pubmed.ncbi.nlm.nih.gov/12447927/
- PMC8558993 — Hypermobility movement differences: https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/
- PMC 10886083 — MediaPipe joint angle accuracy: https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/
- Nature Sci Rep 2023 — Force transmission counter-evidence: https://www.nature.com/articles/s41598-023-30775-x
- Frontiers 2025 — Zero apps with chain reasoning: https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2025.1531050/full
