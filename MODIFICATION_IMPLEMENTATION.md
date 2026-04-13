# IMPLEMENTATION: Bioliminal Rebrand & Hardware Integration

This plan transforms the AuraLink app into Bioliminal and integrates the 10-channel sEMG hardware and premium features.

## Journal
- Phase 1 Complete: Successfully rebranded the entire project to Bioliminal. This included updating `pubspec.yaml`, performing a global search and replace of all `package:auralink/` imports with `package:bioliminal/`, and renaming all UI strings, class names (e.g., `BioliminalApp`), and providers. Updated Android `applicationId` and iOS `bundleId` to `com.bioliminal.app`. Verified with zero static analysis errors and passing tests.

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

- [ ] Add `flutter_blue_plus: ^1.34.5` to `pubspec.yaml`.
- [ ] Implement `HardwareController` in `lib/core/services/hardware_controller.dart`.
- [ ] Map the 10 sEMG channels based on the clinical priority list (Gastroc, Soleus, VM, Glute Med, Erector Spinae).
- [ ] Implement real-time data smoothing (EMA) for the EMG stream.
- [ ] Add a "Hardware Status" indicator to the Main Scaffold.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 3: Premium Tier & Biofeedback Engine
Goal: Implement the "Premium" logic and demo toggle.

- [ ] Add `isPremiumProvider` to `lib/core/providers.dart`.
- [ ] Add a "Premium Demo" toggle in `lib/features/settings/views/settings_view.dart`.
- [ ] Implement the `BiofeedbackEngine` to calculate the Gastrocnemius:Soleus ratio in real-time.
- [ ] Wire the "Corrective Cue" (Vibe/Squeeze) commands back to the `HardwareController`.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 4: Data Visualization Overhaul
Goal: Deliver high-fidelity muscle activation feedback.

- [ ] Implement the `MuscleActivationSidebar` (Free) for real-time 10-channel bar graphs.
- [ ] Refactor `SkeletonPainter` to support `AnatomicalHeatmapping` (Premium) using Aqua (`#00D4AA`) glows.
- [ ] Update the `ReportView` to include sEMG activation summaries.
- [ ] **Validation & Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)

## Phase 5: Final Validation & Clinical Alignment
Goal: Ensure the clinical research is fully reflected in the final Bioliminal product.

- [ ] Update `README.md` and `GEMINI.md` to reflect the Bioliminal name and Hardware architecture.
- [ ] Perform a full smoke-test of the BLE connection and Biofeedback loop.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it.
- [ ] **Final Commit:**
    - [ ] (Include all standard validation/commit steps from Phase 1)
