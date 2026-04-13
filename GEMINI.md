# AuraLink Project Documentation

AuraLink is a clinical-grade movement screening application that uses computer vision to detect biomechanical compensations and trace them to upstream fascial drivers.

## Project Architecture

The project follows a feature-first structure with a clear separation of concerns between on-device capture, data modeling, and server-side clinical analysis.

### Directory Structure

- `lib/core/`: Global configurations, theme definitions, and Riverpod providers.
  - `services/auralink_client.dart`: HTTP client for clinical server communication (Session upload/Report fetch).
- `lib/domain/`: Core business logic and data models aligned with server schemas.
  - `models.dart`: Server-Ready schemas including `PoseLandmark`, `PoseFrame`, and `SessionPayload`.
- `lib/features/`: UI and state management grouped by feature.
  - `camera/`: 33-landmark ML Kit integration and high-fidelity skeleton overlays.
  - `screening/`: Clinical movement screening flow (Overhead Squat, Single-Leg Squat, Push-up, Rollup).
  - `report/`: Server-processed analysis, body map visualization, and report polling.

## Key Implementation Details

### High-Fidelity Capture Pipeline
The `PoseDetector` interface abstracts the ML backend, currently implemented using **MediaPipe BlazePose Full** (via Google ML Kit).
- Exactly 33 landmarks are captured per frame.
- The `AppCameraController` uses a "busy flag" pattern to maintain 30+ FPS.
- Captured frames are buffered and bundled into a `SessionPayload` for clinical analysis.

### Performance & Memory
To maintain UI responsiveness during heavy data processing:
- `SessionPayload.serializeAsync` uses `compute` (Background Isolate) for JSON encoding of large multi-frame sessions.
- UI components use Riverpod's `.select` to watch only specific fields (e.g., `repsCompleted`), preventing full-page rebuilds on every frame.

### Server-Centric Analysis
Clinical reasoning is offloaded to the AuraLink server to leverage advanced kinetics (WHAM + OpenCap Monocular):
- Joint moments and ground reaction forces (impossible on-device) are calculated server-side.
- The app polls the `AuraLinkClient` for report completion with an automated back-off/retry mechanism.
- Local rule-based triage is maintained as a fallback for the prototype environment.
