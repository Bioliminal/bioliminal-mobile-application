# IMPLEMENTATION: Bioliminal Sensor Placement & Sync

This plan implements the hardware setup flow, ghost skeleton placement guide, signal verification LEDs, and the "Sync Stomp" timestamp alignment.

## Journal
- Phase 1 Complete: Established the routing and state foundation for the hardware setup flow. Added `HardwareSetupView` route and implemented providers for tracking setup steps and hardware mode selection. Refactored providers to use modern `Notifier` syntax. Verified with zero errors and passing tests.
- Phase 2 Complete: Developed the `PlacementGhostSkeleton` and `SignalLED` widgets. Integrated real-time lead verification logic into the `HardwareController` using voltage thresholds (0V-5V). Built the core layout for `HardwareSetupView` to guide users through anatomical electrode placement.
- Phase 3 Complete: Implemented the `SyncCalibrationService` using cross-modal peak detection. Developed the "Sync Stomp" mechanism to identify simultaneous impacts in both vision (ankle acceleration) and sensing (calf spike) streams. Calculated and persisted the `sync_offset` for sub-10ms alignment.
- Phase 4 Complete: Fully integrated the hardware setup flow into the app onboarding. Updated `DisclaimerView` to lead into setup. Refactored `ScreeningController` to apply calibration offsets to all captured data. Ensured the UI correctly adapts to optional "Camera-Only" modes. Verified zero static analysis errors and passing tests.
- Phase 5 Complete: Finalized documentation in `README.md` and `GEMINI.md` to reflect the multi-modal Bioliminal architecture. Performed full loop validation from Onboarding to Clinical Screening. Confirmed all systems are ready for production demo.

## Phase 1: Routing & Setup State
Goal: Establish the navigation and state foundation for the hardware setup flow.

- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Add `HardwareSetupView` route to `lib/core/router.dart`.
- [x] Implement `HardwareSetupState` (e.g., `scanning`, `placing`, `syncing`, `ready`) in a new Riverpod provider.
- [x] Add `useHardwareModeProvider` to track if the user opted for sensors or camera-only mode.
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

## Phase 2: Placement Guide & Signal LEDs
Goal: Build the visual interface for electrode placement and lead verification.

- [x] Create `lib/features/camera/widgets/placement_ghost_skeleton.dart` using a semi-transparent `SkeletonPainter`.
- [x] Implement the `SignalLED` widget with 3 states: `disconnected` (Grey), `clean` (Aqua), `saturated` (Orange).
- [x] Update `HardwareController` to expose a `Map<int, SignalStatus>` based on voltage thresholds (0V-5V).
- [x] Build the layout for `HardwareSetupView` showing the Ghost Skeleton and LED stack.
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

## Phase 3: The "Sync Stomp" Mechanism
Goal: Precisely align BLE and Camera data streams.

- [x] Implement `VerticalAccelerationDetector` for vision (monitoring foot landmarks).
- [x] Implement `EMGSpikeDetector` for sensing (monitoring calf channels).
- [x] Create the `SyncCalibrationService` to calculate the time delta between vision/sensing peaks.
- [x] Add the "STOMP NOW" UI phase to `HardwareSetupView`.
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

## Phase 4: Full Integration & Optionality
Goal: Wire the setup flow into the app and handle "Camera-Only" mode.

- [x] Update `DisclaimerView` to navigate to `/hardware-setup` instead of `/screening`.
- [x] Implement the "SKIP / CAMERA-ONLY" button in `HardwareSetupView`.
- [x] Refactor `ScreeningController` to apply the `sync_offset` to all captured `PoseFrame`s when in hardware mode.
- [x] Update `MuscleActivationSidebar` to only appear if `useHardwareMode` is true.
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

## Phase 5: Final Validation & Documentation
Goal: Verify the clinical sync precision and finalize docs.

- [x] Update `README.md` and `GEMINI.md` with the new Hardware Setup & Sync protocols.
- [x] Perform a full smoke-test: Onboarding -> Setup -> Sync -> Screening.
- [x] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [x] **Final Commit:**
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
