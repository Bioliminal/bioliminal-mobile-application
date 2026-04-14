# Implementation Plan: Rename AuraLink to Bioliminal

This plan outlines the steps to replace all remaining occurrences of "AuraLink" with "Bioliminal" across the project's configuration, scripts, and documentation.

## Journal
- Phase 1: Pre-implementation Validation completed. All tests passed (+190 ~4). `analyze_files` returned no errors. `dart_format` formatted 34 files.
- Phase 2: Platform Configuration Updates completed. Updated `ios/Runner/Info.plist` to change `CFBundleDisplayName` to "Bioliminal". Fixed a unrelated lint issue in `lib/features/camera/widgets/skeleton_overlay.dart` found during validation. All tests pass and analysis is clean.
- Phase 3: Script and Tooling Updates completed. Updated `mobile-handover/tools/export_schemas.py` and `mobile-handover/tools/post_sample.sh` to replace `auralink` with `bioliminal` in comments and imports.

## Phase 1: Pre-implementation Validation
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.

## Phase 2: Platform Configuration Updates
- [x] Update `ios/Runner/Info.plist`: Change `<string>Auralink</string>` to `<string>Bioliminal</string>`.
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [x] After committing the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 3: Script and Tooling Updates
- [x] Update `mobile-handover/tools/export_schemas.py`: Replace `auralink` with `bioliminal` in comments and imports.
- [x] Update `mobile-handover/tools/post_sample.sh`: Replace `auralink` with `bioliminal` in comments.
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.

## Phase 4: Documentation Updates
- [ ] Update `docs/rajat's docs/wave1-lean-final.html`: Replace `AuraLink` with `Bioliminal`.
- [ ] Update `docs/rajat's docs/final-buy-list-with-local.md`: Replace `AuraLink` with `Bioliminal`.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run the `dart_fix` tool to clean up the code.
- [ ] Run the `analyze_files` tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run `dart_format` to make sure that the formatting is correct.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.

## Phase 5: Project Finalization
- [ ] Update any `README.md` file for the package with relevant information from the modification (if any).
- [ ] Update any `GEMINI.md` file in the project directory so that it still correctly describes the app, its purpose, and implementation details and the layout of the files.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
- [ ] Final verification of all changes.
- [ ] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes.
- [ ] Wait for approval. Don't commit the changes.

---
*Note: After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.*
