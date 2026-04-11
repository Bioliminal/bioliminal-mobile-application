# IMPLEMENTATION: AuraLink App Stabilization & Premium Overhaul

This plan outlines the steps to resolve state errors, optimize camera performance, and deliver a premium UI/UX.

## Journal
- Phase 1 Complete: Refactored cloud providers to be nullable, added null checks in `LoginView`, and updated related unit tests. App should no longer crash on launch when cloud sync is disabled.
- Phase 2 Complete: Optimized `AppCameraController` with a "busy flag" pattern and a persistent stream, significantly reducing the overhead of ML processing per frame.
- Phase 3 Complete: Isolated high-frequency UI updates in `ScreeningView`. Header and Footer now use `.select` to avoid unnecessary rebuilds during pose estimation. Added `RepaintBoundary` to the camera and skeleton layers to further reduce GPU load.

## Phase 1: Foundation & State Stabilization
Goal: Eliminate app crashes caused by cloud provider errors and ensure a clean starting point.

- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Refactor `authServiceProvider` and `firestoreServiceProvider` in `lib/core/providers.dart` to return `null` instead of throwing `StateError`.
- [x] Update `lib/core/services/auth_service.dart` and `firestore_service.dart` if necessary to support nullable initialization.
- [x] Add null-checks to any widgets currently watching these providers (e.g., `SettingsView`, `LoginView`).
- [x] **Validation & Commit:**
    - [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
    - [x] Run the `dart_fix` tool to clean up the code.
    - [x] Run the `analyze_files` tool one more time and fix any issues.
    - [x] Run any tests to make sure they all pass.
    - [x] Run `dart_format` to make sure that the formatting is correct.
    - [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
    - [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state in the Journal section. Check off completed items.
    - [x] Use `git diff` to verify changes and prepare a commit message.
    - [x] Wait for user approval before committing.
    - [x] After committing, use `hot_reload` if the app is running.

## Phase 2: Camera Pipeline Optimization
Goal: Achieve 30+ FPS by optimizing frame processing and avoiding redundant stream subscriptions.

- [x] Refactor `AppCameraController` in `lib/features/camera/controllers/camera_controller.dart` to use a persistent `_handleFrame` loop with a `_isProcessing` flag.
- [x] Remove the frame-by-frame subscription cancellation logic.
- [x] Optimize `ResolutionPreset` to `medium` (or `low` if needed) for better performance on older devices.
- [x] Ensure `_landmarkSubscription` is correctly managed across the app lifecycle (resumed/paused).
- [x] **Validation & Commit:**
    - [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
    - [x] Run the `dart_fix` tool to clean up the code.
    - [x] Run the `analyze_files` tool one more time and fix any issues.
    - [x] Run any tests to make sure they all pass.
    - [x] Run `dart_format` to make sure that the formatting is correct.
    - [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
    - [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state in the Journal section. Check off completed items.
    - [x] Use `git diff` to verify changes and prepare a commit message.
    - [x] Wait for user approval before committing.
    - [x] After committing, use `hot_reload` if the app is running.

## Phase 3: UI Rebuild Optimization
Goal: Isolate heavy UI elements from high-frequency AI updates.

- [x] Refactor `ScreeningView` in `lib/features/screening/views/screening_view.dart` to separate the "Skeleton Layer" from the "Control UI Layer".
- [x] Use Riverpod's `.select` in `_ActiveMovementScreen` to ensure the header, footer, and progress indicators only rebuild when their specific data changes (e.g., `repsCompleted`).
- [x] Wrap `SkeletonOverlay` and `CameraPreview` in `RepaintBoundary` widgets to isolate their rendering.
- [x] Replace or optimize expensive `BackdropFilter` usage in the active screening screen.
- [x] **Validation & Commit:**
    - [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
    - [x] Run the `dart_fix` tool to clean up the code.
    - [x] Run the `analyze_files` tool one more time and fix any issues.
    - [x] Run any tests to make sure they all pass.
    - [x] Run `dart_format` to make sure that the formatting is correct.
    - [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
    - [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state in the Journal section. Check off completed items.
    - [x] Use `git diff` to verify changes and prepare a commit message.
    - [x] Wait for user approval before committing.
    - [x] After committing, use `hot_reload` if the app is running.

## Phase 4: Premium UI Polish & Cleanup
Goal: Deliver a sophisticated look and remove technical debt.

- [ ] Remove unused components and "dead code" in `lib/features/report/views/report_view.dart` and `lib/features/history/views/history_view.dart`.
- [ ] Fully wire the `PDFGenerator` and `SharePlus` integration in `ReportView`.
- [ ] Refine `StickFigureAnimation` with smoother transitions and improved stroke/joint aesthetics.
- [ ] Apply a consistent "Glassmorphism" theme (using optimized containers) across all secondary screens.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 5: Final Validation & Documentation
Goal: Ensure everything works as intended and the codebase is well-documented.

- [ ] Update `README.md` with relevant information from the modification.
- [ ] Update `GEMINI.md` to reflect the new architecture and file layout.
- [ ] Perform a final full-app walkthrough to verify all navigation and data persistence flows.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
