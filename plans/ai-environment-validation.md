# AI-Driven Environment Validation + Mock Leak Fix
Story: story-1318
Agent: architect

## Context
The manual SetupChecklist requires users to tap through 4 steps (angle, distance, lighting, clothing) with no actual validation. A premium experience should use the pose estimation service to automatically detect whether conditions are met. Additionally, MockPoseEstimationService has timer/stream leaks when processFrame() is called multiple times without disposing the previous controller.

DATA_FLOW_TRACE segment:
[Camera streaming] → currentLandmarksProvider (List<Landmark>, 33 per frame)
→ [SetupChecklistNotifier watches landmarks] → auto-validates:
  - Distance: all 33 landmarks present with visibility > 0.5 (full skeleton visible)
  - Lighting: average visibility across key joints (11,12,23,24,25,26,27,28) > 0.7
  - Camera angle: hip landmarks (23,24) y-position in 0.4-0.6 range (waist height)
→ [SetupChecklistState.allPassed = true] → onAllPassed callback fires

## What changes
| File | Change |
|---|---|
| `lib/features/camera/widgets/setup_checklist.dart` | Rewrite SetupChecklistNotifier to watch currentLandmarksProvider instead of manual taps. Auto-validate distance (landmark count + visibility), lighting (average key joint visibility), and camera angle (hip y-position range). Keep clothing as the only manual step. Remove confirmCurrentStep() tap-through logic. Add real-time status indicators that transition from red → yellow → green as conditions improve. Keep the progressive UI but make steps auto-complete when the AI confirms each condition. |
| `lib/domain/mocks/mock_pose_estimation.dart` | Fix leak: dispose previous _controller and _timer before creating new ones in processFrame(). Guard against calling add() on a closed controller. |

## Acceptance criteria
- User opens camera → landmarks stream begins → distance/lighting/angle steps auto-complete as conditions are met without any taps
- Only "Clothing" step requires a manual confirmation tap
- If user moves too close (landmarks leave frame), distance step reverts to incomplete
- MockPoseEstimationService: calling processFrame() twice does not leak the first timer/controller
- MockPoseEstimationService: calling dispose() after stream completes does not throw

## Architecture notes
- SetupChecklistNotifier becomes a Notifier that takes a ref and watches currentLandmarksProvider
- Thresholds should be constants at the top of the file for easy tuning
- The clothing step remains manual because AI can't assess clothing fit from landmarks alone
- Keep the same visual stepper UI (progress dots, step cards) but replace the "Done" button with a real-time status indicator for AI-validated steps
