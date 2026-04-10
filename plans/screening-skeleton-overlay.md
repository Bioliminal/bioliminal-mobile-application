# Screening Skeleton Overlay
Story: story-1319
Agent: quick-fixer

## Context
The SkeletonOverlay widget exists and works (watches currentLandmarksProvider, renders via SkeletonPainter CustomPainter). But the _ActiveMovementScreen in screening_view.dart shows a blank camera placeholder with just a countdown timer. The skeleton overlay needs to be wired into the screening view's Stack so users see the AI tracking their movements in real time.

DATA_FLOW_TRACE segment:
[ScreeningController starts mock feed] → MockPoseEstimationService.processFrame()
→ Stream<List<Landmark>> → ScreeningController.onLandmarkFrame()
→ currentLandmarksProvider updates → [SkeletonOverlay in _ActiveMovementScreen renders landmarks on canvas]

## What changes
| File | Change |
|---|---|
| `lib/features/screening/views/screening_view.dart` | In _ActiveMovementScreen.build(), add SkeletonOverlay as a Positioned.fill child in the Stack, layered between the camera placeholder background and the UI overlays (movement instructions, progress indicator, timer). Import skeleton_overlay.dart. |

## Acceptance criteria
- During ActiveMovement state, the skeletal overlay renders on screen showing landmark dots and connections
- The overlay updates in real time as mock landmarks stream in (30fps)
- UI overlays (movement label, rep counter, timer, skip button) remain visible on top of the skeleton
- The skeleton disappears when transitioning to ShowingFindings state (no landmarks streaming)
