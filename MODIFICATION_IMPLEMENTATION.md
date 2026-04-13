# IMPLEMENTATION: Bioliminal Sensor Placement & Sync

This plan implements the hardware setup flow, ghost skeleton placement guide, signal verification LEDs, and the "Sync Stomp" timestamp alignment.

## Journal
- (Empty)

## Phase 1: Routing & Setup State
Goal: Establish the navigation and state foundation for the hardware setup flow.

- [ ] Run all tests to ensure the project is in a good state before starting modifications.
- [ ] Add `HardwareSetupView` route to `lib/core/router.dart`.
- [ ] Implement `HardwareSetupState` (e.g., `scanning`, `placing`, `syncing`, `ready`) in a new Riverpod provider.
- [ ] Add `useHardwareModeProvider` to track if the user opted for sensors or camera-only mode.
- [ ] **Validation & Commit:**
    - [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
    - [ ] Run the `dart_fix` tool to clean up the code.
    - [ ] Run the `analyze_files` tool one more time and fix any issues.
    - [ ] Run any tests to make sure they all pass.
    - [ ] Run `dart_format` to make sure that the formatting is correct.
    - [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
    - [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state in the Journal section. Check off completed items.
    - [ ] Use `git diff` to verify changes and prepare a commit message.
    - [ ] Wait for user approval before committing.
    - [ ] After committing, use `hot_reload` if the app is running.

## Phase 2: Placement Guide & Signal LEDs
Goal: Build the visual interface for electrode placement and lead verification.

- [ ] Create `lib/features/camera/widgets/placement_ghost_skeleton.dart` using a semi-transparent `SkeletonPainter`.
- [ ] Implement the `SignalLED` widget with 3 states: `disconnected` (Grey), `clean` (Aqua), `saturated` (Orange).
- [ ] Update `HardwareController` to expose a `Map<int, SignalStatus>` based on voltage thresholds (0V-5V).
- [ ] Build the layout for `HardwareSetupView` showing the Ghost Skeleton and LED stack.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 3: The "Sync Stomp" Mechanism
Goal: Precisely align BLE and Camera data streams.

- [ ] Implement `VerticalAccelerationDetector` for vision (monitoring foot landmarks).
- [ ] Implement `EMGSpikeDetector` for sensing (monitoring calf channels).
- [ ] Create the `SyncCalibrationService` to calculate the time delta between vision/sensing peaks.
- [ ] Add the "STOMP NOW" UI phase to `HardwareSetupView`.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 4: Full Integration & Optionality
Goal: Wire the setup flow into the app and handle "Camera-Only" mode.

- [ ] Update `DisclaimerView` to navigate to `/hardware-setup` instead of `/screening`.
- [ ] Implement the "SKIP / CAMERA-ONLY" button in `HardwareSetupView`.
- [ ] Refactor `ScreeningController` to apply the `sync_offset` to all captured `PoseFrame`s when in hardware mode.
- [ ] Update `MuscleActivationSidebar` to only appear if `useHardwareMode` is true.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 5: Final Validation & Documentation
Goal: Verify the clinical sync precision and finalize docs.

- [ ] Update `README.md` and `GEMINI.md` with the new Hardware Setup & Sync protocols.
- [ ] Perform a full smoke-test: Onboarding -> Setup -> Sync -> Screening.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
