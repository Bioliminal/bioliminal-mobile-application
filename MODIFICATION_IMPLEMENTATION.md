# IMPLEMENTATION: AuraLink Mobile Hand-off Integration

This plan transitions the AuraLink mobile app to a high-fidelity capture tool for server-side clinical analysis.

## Journal
- Phase 1 Complete: Refactored core data models to align with server Pydantic schemas. Renamed `Landmark` to `PoseLandmark` (adding `presence` field) and introduced `PoseFrame`, `SessionMetadata`, and `SessionPayload`. Updated `MovementType` and `screeningMovements` to match the clinical priority list (Overhead Squat, Single-Leg Squat, Push-up, Rollup). Updated all services and tests to match new models. Verified zero static analysis errors.
- Phase 2 Complete: Implemented the `PoseDetector` interface and `MediaPipePoseDetector` using `google_mlkit_pose_detection`. Overhauled the ML pipeline to capture exactly 33 BlazePose landmarks. Refactored `AppCameraController` to use the new `poseDetectorProvider` for better testability. Implemented background JSON serialization for large `SessionPayload` data using `compute` (Isolate). Resolved test environment issues by adding `MockPoseDetector` and binding initialization to unit tests.
- Phase 3 Complete: Implemented `AuraLinkClient` for server communication. Added `Report.fromJson` and related factories to support clinical-grade report retrieval. Wired `POST /sessions` to the end of the screening flow in `ScreeningController` for automatic, asynchronous session submission. Integrated the `http` package and established the foundation for server-side clinical analysis.
- Phase 4 Complete: Updated `DisclaimerView` to reflect the new privacy policy (landmarks transmitted, raw video stays local). Refactored `ReportView` to handle server-side processing states with an automated polling mechanism. Added a "CLINICAL ANALYSIS IN PROGRESS" state and maintained local triage as a fallback. Resolved test timeout issues by introducing a `localOnly` mode for `ReportView` unit tests.

## Phase 1: Data Model & Clinical Movement Update
Goal: Align core models and movement configurations with the clinical priority list.

- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Copy and refactor `PoseLandmark`, `PoseFrame`, and `SessionPayload` from the handover package into `lib/domain/models.dart`.
- [x] Update `MovementType` enum to match clinical list: `overhead_squat`, `single_leg_squat`, `push_up`, `rollup`.
- [x] Update `MovementConfig` and `screeningMovements` in `lib/features/screening/models/movement.dart` to match the new set.
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

## Phase 2: ML Pipeline & Capture Overhaul
Goal: Implement the 33-landmark high-fidelity capture pipeline.

- [x] Implement the `PoseDetector` interface in `lib/features/camera/services/pose_detector.dart`.
- [x] Create the `MediaPipePoseDetector` implementation using `google_mlkit_pose_detection`.
- [x] Refactor `AppCameraController` to use the new `PoseDetector` and buffer `PoseFrame`s during active capture.
- [x] Implement `Isolate.run()` for `SessionPayload` JSON serialization.
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

## Phase 3: Server Integration & Session Management
Goal: Establish communication with the AuraLink clinical server.

- [x] Implement `AuraLinkClient` in `lib/core/services/auralink_client.dart` using the `http` package.
- [x] Wire the `POST /sessions` endpoint to the end of the screening flow.
- [x] Implement local caching/retry logic for failed uploads.
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

## Phase 4: UI/UX Alignment & Report Fetching
Goal: Update the user flow to handle server-side analysis states.

- [x] Simplify `DisclaimerView` to reflect the updated privacy policy (landmarks transmitted, video stays local).
- [x] Add a "Processing..." / "Pending Analysis" state to the `ReportView`.
- [x] Implement `GET /reports/{id}` in `AuraLinkClient` and wire it to the final report screen.
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
Goal: Verify the full capture-to-report loop and finalize documentation.

- [ ] Update `README.md` to reflect the new Server-Centric architecture and Clinical Priority list.
- [ ] Update `GEMINI.md` to document the new data pipeline.
- [ ] Perform a full smoke-test of the capture and upload flow.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
