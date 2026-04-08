# AuraLink — Product Spec

## Objective

AuraLink is a Flutter-based AI movement screening app that uses phone camera pose estimation to detect biomechanical compensation patterns, maps them along three validated fascial chains (SBL/BFL/FFL) to identify upstream root causes, and generates personalized triage reports with cited evidence — making clinical-grade movement reasoning accessible to anyone with a phone.

## User Stories

- As an **athlete or recreational fitness user**, I want to complete a 5-minute movement screen on my phone so that I can understand what's driving my movement compensations before they become injuries.
- As a **user with a completed screen**, I want a personalized report in plain language with cited evidence so that I can have an informed conversation with a practitioner.
- As a **practitioner** (PT/Rolfer/Pilates instructor), I want to receive a client's screening report with chain-level findings so that I can skip the 3-4 visit discovery cycle and start targeted treatment immediately.

## Requirements

**Camera Pipeline**
- Access phone camera, run MediaPipe BlazePose, extract 33 landmarks in real-time
- Skeleton overlay rendered on Flutter Canvas (mobile) / HTML5 Canvas (web)
- Progressive camera setup checklist: angle, distance, lighting, fitted clothing — one requirement at a time with green checkmarks
- Specific setup feedback ("try removing your jacket", "move back 2 feet")
- Real-time per-joint confidence colors (green/yellow/red) from MediaPipe visibility scores

**Movement Assessment**
- 4 movements: overhead squat, single-leg balance, overhead reach, forward fold
- ~60 sec per movement with instructions and rep counter
- Progress indicator ("2 of 4")
- Preliminary findings surfaced between movements ("We noticed something in your left hip — let's check it in the next movement")

**Logic Engine**
- Joint angle calculation from landmark triplets (hip, knee, ankle, shoulder)
- Threshold-based compensation detection against published values (knee valgus >10°, asymmetry >10°, trunk lean, hip drop)
- SBL/BFL/FFL chain mapping: co-occurring flags → upstream driver identification via rule-based decision trees
- Per-finding confidence scoring based on joint tracking quality

**Report**
- Personalized compensation patterns as body-path connections ("your knee → hip → lower back compensate together")
- Layered display: summary first, details on expand
- Inline evidence citations (expandable) for every finding
- Specific practitioner discussion points ("Ask about your hip mobility and how it affects your knee")
- Recommendations adapted to individual pattern (mobility vs. stability based on findings)
- One-tap share + PDF export

**Platform**
- Flutter targeting iOS, Android, and web from one codebase
- All processing on-device — no backend, no data leaves the phone
- No user accounts required

## Acceptance Criteria

- Given a user grants camera permission, when BlazePose initializes, then 33 landmarks are tracked in real-time with skeleton overlay visible
- Given camera setup, when lighting/angle/distance are inadequate, then specific corrective feedback is shown before proceeding
- Given the skeleton overlay is active, when a joint has low MediaPipe visibility, then it renders in yellow/red (not green)
- Given a user performs an overhead squat, when knee valgus exceeds 10°, then the system flags it with the appropriate confidence level
- Given Person A has knee valgus + ankle restriction + no hypermobility, when report generates, then it recommends ankle mobility work (compensation pattern)
- Given Person B has knee valgus + full ankle ROM + hypermobility markers, when report generates, then it recommends neuromuscular control training (stability issue)
- Given co-occurring flags match an SBL pattern (e.g., knee + hip + lower back), when the chain map runs, then the report identifies the upstream driver — not just individual symptoms
- Given a movement with high ankle occlusion, when confidence is low, then ankle-dependent findings carry explicit reduced confidence
- Given a completed screening, when the report renders, then every finding includes an expandable evidence citation linking to its source
- Given the user taps share, when report export runs, then a PDF is generated with all findings, confidence levels, and citations
- Given no internet connection, when the user runs a full screening, then all features work offline

## Constraints

**What NOT to build (capstone scope):**
- sEMG hardware integration (Phase 2 — hardware arriving in 1-2 weeks, not in capstone deliverable)
- Haptic cueing (requires hardware)
- Longitudinal tracking / return-visit dashboard (Phase 2)
- User accounts or authentication
- Backend, API, or cloud database
- Injury prediction claims
- Diagnostic or clinical language
- Static posture assessment (debunked — Swain 2020)
- Spiral Line, Lateral Line, or Superficial Front Line mapping (insufficient evidence per Wilke 2016)

**Non-functional:**
- 3-week delivery timeline
- Team of 4: app (Flutter/Kelsi), ML (MediaPipe + joint angle math + chain logic), hardware (sEMG prep), marketing
- Must run on mobile (iOS/Android native) and web (Flutter web build)
- All processing on-device — zero data transmission
- Educational framing only — aligned with FDA wellness/CDS guidance (Jan 2026)

## Integration Points

- **MediaPipe BlazePose**: `google_mlkit_pose_detection` (native iOS/Android) or MediaPipe Tasks Vision SDK via platform channels; `@mediapipe/tasks-vision` JS SDK for web
- **Flutter Camera**: `camera` package for camera access and permissions
- **Flutter Canvas**: `CustomPainter` for skeleton overlay and confidence visualization
- **PDF Generation**: `pdf` or `printing` package for report export
- **Share**: `share_plus` package for one-tap share

## Out of Scope

- sEMG hardware, haptic cueing, BLE pairing
- User accounts, persistent profiles, login
- Backend services, APIs, cloud storage
- Practitioner SaaS dashboard
- Find-a-practitioner directory
- Payment or subscription flows
- Injury prediction or diagnostic output
- Multi-language / i18n
- Spiral Line, Lateral Line, SFL chain mapping

## Boundaries

- **Always**: use body-path language in user-facing output ("your knee and hip compensate together"), never chain names
- **Always**: cite evidence inline for every finding
- **Always**: show per-joint confidence — never present a low-confidence finding as certain
- **Always**: frame output as educational triage, not diagnosis
- **Ask first**: any language that could be interpreted as clinical/diagnostic
- **Ask first**: adding movements beyond the 4 specified
- **Ask first**: changing threshold values (sourced from published research)
- **Never**: store or transmit user video/data off-device
- **Never**: use injury prediction language
- **Never**: present fascial chain names to end users
- **Never**: include chains with insufficient evidence
