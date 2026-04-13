# IMPLEMENTATION: Bioliminal Rebrand & Hardware Integration

This plan transforms the AuraLink app into Bioliminal and integrates the 10-channel sEMG hardware and premium features.

## Journal
- Phase 1 Complete: Successfully rebranded the entire project to Bioliminal. This included updating `pubspec.yaml`, performing a global search and replace of all `package:auralink/` imports with `package:bioliminal/`, and renaming all UI strings, class names (e.g., `BioliminalApp`), and providers. Updated Android `applicationId` and iOS `bundleId` to `com.bioliminal.app`. Verified with zero static analysis errors and passing tests.
- Phase 2 Complete: Integrated `flutter_blue_plus` for BLE communication. Implemented `HardwareController` with support for 10-channel sEMG data streaming, real-time EMA smoothing, and anatomical mapping (Gastroc, Soleus, VM, Glute Med, Erector Spinae). Added a mock data mode for demonstrations and a "Hardware Status" indicator to the `MainScaffold`. Resolved several BLE-related compilation issues and verified stability.
- Phase 3 Complete: Implemented the `isPremiumProvider` and updated `SettingsView` with a "Premium Mode" toggle and "Hardware Simulation" switch. Built the `BiofeedbackEngine` to calculate real-time Gastrocnemius:Soleus ratios based on the clinical research (Uhlrich 2023). Established the foundation for physical corrective cues (Vibe/Squeeze) during screening. Verified stability with tests passing.
- Phase 4 Complete: Developed the `MuscleActivationSidebar` for real-time 10-channel sEMG visualization. Refactored `SkeletonOverlay` to support premium "Anatomical Heatmapping," where individual limb segments glow based on corresponding muscle activation. Updated `ScreeningView` to integrate the sidebar and display live biofeedback ratios. Added an "EMG ACTIVATION" summary section to the `ReportView` for post-session analysis. Verified zero static analysis errors and all tests passing.

## Phase 1: Full-Project Rebranding (Bioliminal)
Goal: Rename the package and all UI references to Bioliminal.

- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Update `pubspec.yaml` name to `bioliminal`.
- [x] Perform a global search and replace of `package:auralink/` with `package:bioliminal/` in all `.dart` files.
- [x] Rename `lib/auralink.dart` (if it exists) or any package-level entry points.
- [x] Update `AuraLinkApp` to `BioliminalApp` and `AuraLinkTheme` to `BioliminalTheme`.
- [x] Replace all "AuraLink" strings in UI text, disclaimers, and reports with "Bioliminal".
- [x] Update Android `applicationId` and iOS `bundleId` to `com.bioliminal.app` (where safe).
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

## Phase 2: Hardware Core & BLE Integration
Goal: Establish communication with the ESP32-S3 sensor hub.

- [x] Add `flutter_blue_plus: ^1.34.5` to `pubspec.yaml`.
- [x] Implement `HardwareController` in `lib/core/services/hardware_controller.dart`.
- [x] Map the 10 sEMG channels based on the clinical priority list (Gastroc, Soleus, VM, Glute Med, Erector Spinae).
- [x] Implement real-time data smoothing (EMA) for the EMG stream.
- [x] Add a "Hardware Status" indicator to the Main Scaffold.
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

## Phase 3: Premium Tier & Biofeedback Engine
Goal: Implement the "Premium" logic and demo toggle.

- [x] Add `isPremiumProvider` to `lib/core/providers.dart`.
- [x] Add a "Premium Demo" toggle in `lib/features/settings/views/settings_view.dart`.
- [x] Implement the `BiofeedbackEngine` to calculate the Gastrocnemius:Soleus ratio in real-time.
- [x] Wire the "Corrective Cue" (Vibe/Squeeze) commands back to the `HardwareController`.
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

## Phase 4: Data Visualization Overhaul
Goal: Deliver high-fidelity muscle activation feedback.

- [x] Implement the `MuscleActivationSidebar` (Free) for real-time 10-channel bar graphs.
- [x] Refactor `SkeletonPainter` to support `AnatomicalHeatmapping` (Premium) using Aqua (`#00D4AA`) glows.
- [x] Update the `ReportView` to include sEMG activation summaries.
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

## Phase 5: Final Validation & Clinical Alignment
Goal: Ensure the clinical research is fully reflected in the final Bioliminal product.

- [ ] Update `README.md` and `GEMINI.md` to reflect the Bioliminal name and Hardware architecture.
- [ ] Perform a full smoke-test of the BLE connection and Biofeedback loop.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
