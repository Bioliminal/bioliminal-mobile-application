# Bioliminal Project Documentation

Bioliminal is an AI-powered movement screening application that uses computer vision to detect biomechanical compensations and trace them to upstream fascial drivers.

## Project Architecture

The project follows a feature-first structure with a clear separation of concerns between domain logic, data services, and UI presentation.

### Directory Structure

- `lib/core/`: Global configurations, theme definitions, and Riverpod providers.
  - `providers.dart`: Centralized provider graph. Note: `authServiceProvider` and `firestoreServiceProvider` are nullable and only instantiated when cloud sync is enabled.
- `lib/domain/`: Core business logic, data models, and fascial chain definitions.
  - `models.dart`: Unified data structures for Assessments, Findings, and Reports.
  - `services/`: Rule-based engines for angle calculation and chain mapping.
- `lib/features/`: UI and state management grouped by feature.
  - `camera/`: ML Kit integration, camera lifecycle management, and skeleton overlays.
  - `screening/`: The movement screening flow, including environment setup and rep counting.
  - `report/`: Post-screening analysis, body map visualization, and PDF export.
  - `history/`: Longitudinal progress tracking, archetype classification, and trend detection.
  - `settings/`: User profile and privacy/cloud-sync controls.
  - `onboarding/`: Educational disclaimer and authentication options.
  - `landing/`: High-fidelity Flutter Web landing page for showcasing Bioliminal.

## Key Implementation Details

### Optimized AI Pipeline
The `AppCameraController` uses a "busy flag" pattern to process camera frames at maximum efficiency. It maintains a persistent image stream and only sends a frame to ML Kit if the previous frame has finished processing, preventing bridge congestion.

### UI Performance
High-frequency landmark updates (30-60 FPS) are isolated from the rest of the UI tree.
- `SkeletonOverlay` and `CameraPreview` are wrapped in `RepaintBoundary` to minimize paint overhead.
- UI components like headers and footers use Riverpod's `.select` to watch only specific fields (e.g., `repsCompleted`), preventing full-page rebuilds on every frame.

### Privacy-First Persistence
The app defaults to a local-only mode. Cloud synchronization is strictly opt-in. Services are architected to handle `null` states gracefully, ensuring the app remains fully functional without an internet connection or Firebase account.
