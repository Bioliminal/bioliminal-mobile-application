# Screening Fixes: Disposal Leak, Null-as-Dynamic, Movement Type, Double Nav, Duration
Story: story-1304
Agent: architect

## Context
Five bugs in the screening flow introduced or exposed during story-1295 implementation. The mock pose service leaks on recreation, the abstract interface rejects null camera frames, the mock always generates overhead-squat data regardless of active movement, the complete screen can double-navigate on rebuild, and movement duration was left at 15s for dev convenience.

Files:
- lib/features/screening/controllers/screening_controller.dart
- lib/features/screening/views/screening_view.dart
- lib/domain/services/pose_estimation_service.dart
- lib/domain/mocks/mock_pose_estimation.dart
- lib/features/screening/models/movement.dart

## What changes
| File | Change |
|---|---|
| screening_controller.dart | Dispose previous `MockPoseEstimationService` before creating a new one; track the instance as `_mockPoseService`. Restart mock feed with correct `movementType` when advancing movements. |
| pose_estimation_service.dart | Make `CameraImage` parameter nullable: `CameraImage? frame` |
| mock_pose_estimation.dart | Match interface: `CameraImage? frame`. No behavioral change. |
| screening_view.dart | Add `_hasNavigated` flag to `_CompleteScreenState` so `Future.delayed` callback is a no-op after first fire. |
| movement.dart | Change default duration from `Duration(seconds: 15)` to `Duration(seconds: 60)` and remove the TODO comment. |

## Architecture (Claude)

### Disposal Leak
`_startMockLandmarkFeed` currently creates a new `MockPoseEstimationService` as a local variable. The old instance (timer + stream controller) is never disposed. Fix: store as `MockPoseEstimationService? _mockPoseService` on the controller. Dispose before recreating. Also dispose in `ScreeningController.dispose()`.

### Movement Type Advancement
`_startMockLandmarkFeed` hardcodes `screeningMovements.first.type`. Fix: accept an index parameter, look up `screeningMovements[index].type`. Call `_startMockLandmarkFeed(index)` from both `startScreening()` (index 0) and `_startMovement(index)` (for subsequent movements, to get the right mock data).

### Null-as-Dynamic
`processFrame(null as dynamic)` works at runtime but produces analyzer warnings and is fragile. Making the parameter `CameraImage?` in the abstract interface is the minimal correct fix -- the mock ignores the image anyway, and real implementations will receive non-null frames from the camera.

### Double Navigation
`_CompleteScreenState.initState` schedules a `Future.delayed` that calls `context.go(...)`. If the widget rebuilds before the delay fires (e.g., Riverpod state emission), `initState` runs again on the new instance, scheduling a second navigation. Fix: a `bool _hasNavigated = false` flag checked and set inside the callback.

<!-- CODER_ONLY -->
## Read-only context
- lib/core/providers.dart (provider wiring, may need updating if story-1301 renames land first)
- lib/domain/models.dart (MovementType enum, Landmark, Compensation, Assessment)
- plans/screening-flow.md (original architecture)

## Tasks
1. **movement.dart line 8**: Change `Duration(seconds: 15)` to `Duration(seconds: 60)`. Remove the `// TODO: restore to 60 for production` comment.

2. **pose_estimation_service.dart line 11**: Change `Stream<List<Landmark>> processFrame(CameraImage frame)` to `Stream<List<Landmark>> processFrame(CameraImage? frame)`. Update the doc comment on line 6 to note the parameter is nullable for mock usage.

3. **mock_pose_estimation.dart line 19**: Change `Stream<List<Landmark>> processFrame(CameraImage frame)` to `Stream<List<Landmark>> processFrame(CameraImage? frame)` to match the updated interface.

4. **screening_controller.dart -- disposal leak + movement type**: 
   - Add field `MockPoseEstimationService? _mockPoseService;` alongside the other internal state fields (after line 84).
   - Refactor `_startMockLandmarkFeed()` to accept `int movementIndex`:
     ```dart
     void _startMockLandmarkFeed(int movementIndex) {
       _mockLandmarkSub?.cancel();
       _mockPoseService?.dispose();
       _mockPoseService = MockPoseEstimationService(
         movementType: screeningMovements[movementIndex].type,
       );
       _mockLandmarkSub = _mockPoseService!.processFrame(null).listen((landmarks) {
         onLandmarkFrame(landmarks);
       });
     }
     ```
   - Update `startScreening()` call: `_startMockLandmarkFeed(0)`.
   - Add `_startMockLandmarkFeed(index)` call inside `_startMovement(int index)`, after the state assignment (after line 166), so each movement gets mock data for its own type.
   - In `dispose()`, add `_mockPoseService?.dispose();` before `super.dispose()`.

5. **screening_view.dart -- double navigation in _CompleteScreenState**:
   - Add field: `bool _hasNavigated = false;`
   - Wrap the `Future.delayed` callback body:
     ```dart
     Future.delayed(const Duration(seconds: 1), () {
       if (mounted && !_hasNavigated) {
         _hasNavigated = true;
         context.go(
           '/report/${widget.state.assessment.id}',
           extra: widget.state.assessment,
         );
       }
     });
     ```

6. **Conditional -- imports for story-1301 renames**: If story-1301 has landed when this story is coded, update imports in `screening_controller.dart` lines 7-8 to match renamed service files. If story-1301 has not landed, skip this task.
<!-- END_CODER_ONLY -->

## Contract
```dart
// lib/domain/services/pose_estimation_service.dart
// CHANGED: CameraImage → CameraImage?
abstract class PoseEstimationService {
  Stream<List<Landmark>> processFrame(CameraImage? frame);
  void dispose();
}

// lib/domain/mocks/mock_pose_estimation.dart
// CHANGED: CameraImage → CameraImage?, movementType now used dynamically
class MockPoseEstimationService implements PoseEstimationService {
  MockPoseEstimationService({this.movementType = MovementType.overheadSquat});
  @override
  Stream<List<Landmark>> processFrame(CameraImage? frame);
  @override
  void dispose();
}

// lib/features/screening/controllers/screening_controller.dart
// CHANGED: _startMockLandmarkFeed signature, _mockPoseService field, dispose cleanup
class ScreeningController extends StateNotifier<ScreeningState> {
  // public API unchanged:
  void startScreening();
  void continueToNextMovement();
  void skipMovement();
  void onLandmarkFrame(List<Landmark> landmarks);
  @override void dispose();
}

// lib/features/screening/models/movement.dart
// CHANGED: default duration 15s → 60s
class MovementConfig {
  const MovementConfig({
    // ...
    this.duration = const Duration(seconds: 60), // was 15
    // ...
  });
}
```

## Acceptance criteria
- `MockPoseEstimationService` instances are disposed before replacement: no orphaned timers or stream controllers survive across movement transitions.
- `PoseEstimationService.processFrame` accepts `CameraImage?` — passing `null` produces no analyzer warnings and the mock streams landmarks normally.
- Mock landmark data matches the active movement type: overhead squat data during squat, single-leg balance data during balance, etc.
- Navigating from `_CompleteScreen` to the report route fires exactly once, even if the widget rebuilds during the 1-second delay.
- Each movement's countdown timer starts at 1:00 (60 seconds), not 0:15.
- No public API changes to `ScreeningController` — all fixes are internal or at the interface level.

## Cross-story seams
- **story-1301**: If it renames `angle_calculator.dart` or `chain_mapper.dart`, screening_controller.dart imports must update. Task 6 is conditional on this.
- **story-1309**: Tests the screening state machine. The `PoseEstimationService` interface change (nullable param) will require test mocks to update their `processFrame` signature. No behavioral change needed in tests.

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
<!-- TESTER_ONLY -->
test_files: test/features/screening/controllers/screening_controller_test.dart
focus: disposal lifecycle (no leaked timers), movement-type-specific mock data, double-nav guard, 60s timer
<!-- END_TESTER_ONLY -->
