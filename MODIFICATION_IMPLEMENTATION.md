# Implementation Plan: Initial Flow Realignment & Hardware Discovery

This plan outlines the steps to realign the Bioliminal application flow, focusing on a new authentication options screen and a low-friction, auto-detecting hardware setup process.

## Phase 1: Preparation & Baseline
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Perform a project-wide search for any remaining "AuraLink" strings (case-insensitive) in comments, strings, or configs and update to "Bioliminal".
- [x] Ensure all existing tests pass on the current branch.

### Phase 1 Completion Checklist
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [x] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 2: Authentication Options & Navigation
- [x] Create `lib/features/onboarding/views/auth_options_view.dart`.
  - [x] Implement UI with "CREATE ACCOUNT", "LOG IN", and "CONTINUE WITHOUT ACCOUNT".
  - [x] Link "CONTINUE WITHOUT ACCOUNT" to navigate to `/history`.
- [x] Update `lib/core/router.dart`:
  - [x] Add `/auth-options` route.
  - [x] Update `DisclaimerView` to navigate to `/auth-options` instead of `/hardware-setup`.
  - [x] Update initial redirect logic if necessary to handle the new onboarding flow.
- [x] Update `LoginView` to support both "Sign In" and "Create Account" modes (or add a separate Account creation view).

### Phase 2 Completion Checklist
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [x] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 3: Hardware Discovery Refactor
- [x] Update `HardwareSetupView`:
  - [x] Replace "SKIP" with "CONTINUE WITHOUT SENSORS".
  - [x] Trigger `hardwareController.startScan()` automatically on entry.
  - [x] Implement a ~5-second timer to highlight the "CONTINUE WITHOUT SENSORS" option if no device is found.
  - [x] Simplify the "Scanning" UI to be more approachable (minimalist animation).
- [x] Update `HistoryView`:
  - [x] Ensure "NEW SCAN" button routes to `/hardware-setup`.

### Phase 3 Completion Checklist
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [x] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 4: Finalization
- [x] Update `README.md` with the new flow description.
- [x] Update `GEMINI.md` to reflect the updated architecture and flow.
- [x] Run a final `analyze_files` and `run_tests` to ensure project integrity.
- [x] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.

### Journal
- **2026-04-14**: 
  - Created `AuthOptionsView` and updated navigation from `DisclaimerView` -> `AuthOptionsView`.
  - Integrated `/auth-options` into `goRouter`.
  - Refactored `HardwareSetupView` to support auto-scanning and a 5-second timer for highlighting the "CONTINUE WITHOUT SENSORS" option.
  - Updated `HistoryView` to route "NEW SCAN" through `HardwareSetupView`.
  - Rebranded remaining references to Bioliminal.
  - Verified with analyzer and tests (fixing routing and history view test regressions).

---
*Note: After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.*
