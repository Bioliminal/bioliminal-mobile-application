# IMPLEMENTATION: AuraLink Mobile Hand-off Integration

This plan transitions the AuraLink mobile app to a high-fidelity capture tool for server-side clinical analysis.

## Journal
- Phase 1 Complete: Refactored core data models to align with server Pydantic schemas. Renamed `Landmark` to `PoseLandmark` (adding `presence` field) and introduced `PoseFrame`, `SessionMetadata`, and `SessionPayload`. Updated `MovementType` and `screeningMovements` to match the clinical priority list (Overhead Squat, Single-Leg Squat, Push-up, Rollup). Updated all services and tests to match new models. Verified zero static analysis errors.

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

- [ ] Implement the `PoseDetector` interface in `lib/features/camera/services/pose_detector.dart`.
- [ ] Create the `MediaPipePoseDetector` implementation using `google_mlkit_pose_detection`.
- [ ] Refactor `AppCameraController` to use the new `PoseDetector` and buffer `PoseFrame`s during active capture.
- [ ] Implement `Isolate.run()` for `SessionPayload` JSON serialization.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 3: Server Integration & Session Management
Goal: Establish communication with the AuraLink clinical server.

- [ ] Implement `AuraLinkClient` in `lib/core/services/auralink_client.dart` using the `http` package.
- [ ] Wire the `POST /sessions` endpoint to the end of the screening flow.
- [ ] Implement local caching/retry logic for failed uploads.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 4: UI/UX Alignment & Report Fetching
Goal: Update the user flow to handle server-side analysis states.

- [ ] Simplify `DisclaimerView` to reflect the updated privacy policy (landmarks transmitted, video stays local).
- [ ] Add a "Processing..." / "Pending Analysis" state to the `ReportView`.
- [ ] Implement `GET /reports/{id}` in `AuraLinkClient` and wire it to the final report screen.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 5: Final Validation & Documentation
Goal: Verify the full capture-to-report loop and finalize documentation.

- [ ] Update `README.md` to reflect the new Server-Centric architecture and Clinical Priority list.
- [ ] Update `GEMINI.md` to document the new data pipeline.
- [ ] Perform a full smoke-test of the capture and upload flow.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
