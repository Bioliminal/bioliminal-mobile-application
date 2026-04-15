# Movement Assessment Flow
Story: story-1295
Agent: architect

## Context
The core user journey: guide the user through 4 movements, capture peak-movement keyframes, detect compensations in real time, surface preliminary findings between movements, and produce a final Assessment object for report generation. This is the orchestration layer between the camera pipeline (story-1294) and the logic engine interfaces (story-1296). The controller owns the state machine that drives the entire screening experience.

Files:
- lib/features/screening/views/screening_view.dart
- lib/features/screening/controllers/screening_controller.dart
- lib/features/screening/widgets/movement_instructions.dart
- lib/features/screening/widgets/preliminary_findings.dart
- lib/features/screening/models/movement.dart

## What changes
| File | Change |
|---|---|
| lib/features/screening/models/movement.dart | Movement configuration — per-movement metadata (name, instructions, duration, target reps, peak detection joint), `MovementConfig` for each of the 4 movements, ordered list |
| lib/features/screening/controllers/screening_controller.dart | `ScreeningController` (StateNotifier) — state machine managing setup → movement → findings → complete transitions, landmark stream subscription, 5-frame keyframe buffer, peak detection via angle rate-of-change, rep counting, countdown timer, preliminary findings generation, final Assessment aggregation |
| lib/features/screening/views/screening_view.dart | `ScreeningView` — top-level screen that renders the correct UI phase based on controller state: movement instructions overlay, camera feed (from story-1294), progress indicator ("2 of 4"), rep counter, countdown timer, preliminary findings interstitial, completion redirect to report |
| lib/features/screening/widgets/movement_instructions.dart | `MovementInstructions` widget — per-movement instruction text, animated countdown before movement starts, "get ready" → "go" transition |
| lib/features/screening/widgets/preliminary_findings.dart | `PreliminaryFindings` widget — between-movement interstitial showing 1-2 key observations from the just-completed movement, "continue" button to advance to next movement |

## Architecture (Claude)

### State Machine

```
           ┌─────────┐
           │  setup   │  — initial state, waiting for user to start
           └────┬─────┘
                │ user taps "Begin"
                ▼
        ┌───────────────┐
        │  movement(0)  │  — overhead squat, 60s countdown, landmark capture
        └───────┬───────┘
                │ timer expires or user completes reps
                ▼
        ┌───────────────┐
        │  findings(0)  │  — "We noticed X in your Y" interstitial
        └───────┬───────┘
                │ user taps "Continue"
                ▼
        ┌───────────────┐
        │  movement(1)  │  — single-leg balance
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │  findings(1)  │
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │  movement(2)  │  — overhead reach
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │  findings(2)  │
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │  movement(3)  │  — forward fold
        └───────┬───────┘
                │ timer expires or user completes reps
                ▼
        ┌───────────────┐
        │   complete    │  — aggregate all compensations → Assessment, navigate to report
        └───────────────┘
```

State is a sealed class `ScreeningState` with variants: `setup`, `activeMovement(int index, MovementConfig config, int repsCompleted, Duration remaining, List<List<Landmark>> capturedFrames)`, `showingFindings(int completedIndex, List<Compensation> findings)`, `complete(Assessment assessment)`.

### Keyframe Capture Strategy

1. Controller subscribes to `Stream<List<Landmark>>` from `PoseEstimationService` during each movement phase.
2. Every frame: calculate angles via `AngleCalculator`, track the primary joint angle for this movement (e.g., knee flexion for squat).
3. Maintain a rolling 5-frame buffer of landmarks.
4. Peak detection: monitor the rate of change of the primary angle. When the angle derivative crosses zero (movement reversal), snapshot the current 5-frame buffer.
5. Average the 5 frames' landmarks element-wise to produce one smoothed `List<Landmark>`.
6. Run averaged landmarks through `AngleCalculator` → `List<JointAngle>`, then through `ChainMapper` → `List<Compensation>`.
7. Increment rep counter on each detected peak.

### Peak Detection Detail

For each movement, one "primary angle" is monitored:
- Overhead squat: knee flexion angle (decreases as user squats, minimum = peak)
- Single-leg balance: hip abduction/adduction angle (maximum deviation = peak)
- Overhead reach: shoulder flexion angle (maximum elevation = peak)
- Forward fold: hip flexion angle (minimum = peak, i.e., most folded)

Rate of change monitored over 3-frame sliding window. Peak = sign change in derivative (positive → negative for maxima, negative → positive for minima, depending on movement).

### Preliminary Findings

After each movement completes, the controller:
1. Collects all `Compensation` objects detected across that movement's reps.
2. Picks the top 1-2 by confidence (highest confidence = most reliable observation).
3. Generates body-path language: "We noticed something in your [joint area] — we'll check it from another angle in the next movement."
4. No chain names exposed to user (constraint from briefing).

### Data Flow

```
CameraImage (story-1294)
  → PoseEstimationService.processFrame() (story-1296)
  → Stream<List<Landmark>>
  → ScreeningController receives each frame
  → AngleCalculator.calculateAngles() (story-1296)
  → Track primary angle, detect peak
  → On peak: average 5-frame buffer → AngleCalculator → ChainMapper
  → List<Compensation> per rep
  → Accumulate across reps → movement-level compensations
  → Between movements: surface preliminary findings
  → After movement 4: aggregate all → Assessment object
  → Navigate to Report (story-1297)
```

<!-- CODER_ONLY -->
## Read-only context
- presearch/bioliminal-product.md
- lib/domain/models.dart (from story-1293)
- lib/features/camera/ (from story-1294)
- lib/domain/services/ (from story-1296)
- lib/domain/mocks/ (from story-1296)

## Tasks
1. Create `lib/features/screening/models/movement.dart`:
   - Define `MovementConfig` class with fields: `MovementType type`, `String name`, `String instruction` (user-facing text), `Duration duration` (default 60s), `int targetReps`, `String primaryJoint` (joint name to monitor for peak detection), `bool peakIsMinimum` (true = peak is angle minimum like squat/fold, false = peak is angle maximum like reach/balance).
   - Define the 4 movement configs as a `const List<MovementConfig> screeningMovements`:
     - Overhead squat: "Stand with feet shoulder-width apart. Raise arms overhead. Squat as deep as comfortable.", 60s, 5 reps, primaryJoint: 'leftKnee', peakIsMinimum: true
     - Single-leg balance: "Stand on your right leg. Hold for as long as comfortable. We'll check both sides.", 60s, 3 reps, primaryJoint: 'leftHip', peakIsMinimum: false
     - Overhead reach: "Stand tall. Reach both arms as high as you can, then lower.", 60s, 5 reps, primaryJoint: 'leftShoulder', peakIsMinimum: false
     - Forward fold: "Stand with feet together. Bend forward at the hips, reaching toward the floor.", 60s, 3 reps, primaryJoint: 'leftHip', peakIsMinimum: true
   - Import `MovementType` from `lib/domain/models.dart`.

2. Create `lib/features/screening/controllers/screening_controller.dart`:
   - Define sealed class `ScreeningState` with variants:
     - `ScreeningSetup` — initial state
     - `ActiveMovement` — fields: `int movementIndex`, `MovementConfig config`, `int repsCompleted`, `Duration remaining`, `List<List<Landmark>> capturedFrames`, `List<Compensation> movementCompensations`
     - `ShowingFindings` — fields: `int completedMovementIndex`, `List<Compensation> findings`, `String feedbackMessage`
     - `ScreeningComplete` — fields: `Assessment assessment`
   - Define `ScreeningController extends StateNotifier<ScreeningState>`:
     - Constructor takes `PoseEstimationService`, `AngleCalculator`, `ChainMapper` as required dependencies.
     - `void startScreening()` — transitions from setup to first movement, starts timer and landmark subscription.
     - `void _onLandmarkFrame(List<Landmark> landmarks)` — processes each frame: calculates angles, updates rolling 5-frame buffer, runs peak detection, on peak: averages buffer, runs through AngleCalculator + ChainMapper, increments rep counter, stores compensations.
     - `void _detectPeak(double currentAngle)` — maintains 3-frame derivative window, detects sign change based on `peakIsMinimum` flag.
     - `void _onPeakDetected()` — averages 5-frame buffer element-wise, runs averaged landmarks through full pipeline, appends compensations to movement list, increments reps.
     - `void _onTimerTick()` — decrements remaining time, when 0 calls `_completeMovement()`.
     - `void _completeMovement()` — cancels landmark subscription and timer, picks top 1-2 compensations, generates feedback message using body-path language, transitions to `ShowingFindings`. If this was movement index 3 (final), skip findings and go to `_finishScreening()`.
     - `void continueToNextMovement()` — transitions from findings to next movement, restarts timer and subscription.
     - `void _finishScreening()` — aggregates all compensations across 4 movements into a single `Assessment` object (id = UUID, createdAt = now, movements = collected Movement objects, compensations = all compensations, report = null). Transitions to `ScreeningComplete`.
     - `void skipMovement()` — allows user to skip current movement (proceeds as if timer expired with whatever data collected so far).
     - Internal state: `List<double> _angleHistory` (for derivative), `List<List<Landmark>> _frameBuffer` (5-frame rolling), `List<Movement> _completedMovements`, `List<Compensation> _allCompensations`, `StreamSubscription? _landmarkSubscription`, `Timer? _countdownTimer`.
     - `@override void dispose()` — cancel subscription and timer.
   - Define Riverpod provider `screeningControllerProvider` as `StateNotifierProvider<ScreeningController, ScreeningState>` that reads `poseEstimationServiceProvider`, `angleCalculatorProvider`, `chainMapperProvider` from `lib/core/providers.dart`.

3. Create `lib/features/screening/views/screening_view.dart`:
   - `ScreeningView` is a `ConsumerWidget` that watches `screeningControllerProvider`.
   - Renders based on state:
     - `ScreeningSetup` → full-screen intro with "Begin Screening" button, brief explanation of what's about to happen.
     - `ActiveMovement` → Stack containing: camera preview (from story-1294's CameraView as a child widget — import and embed it), `MovementInstructions` overlay at top, progress indicator ("Movement 2 of 4: Single-Leg Balance") at top-left, rep counter ("Rep 3 of 5") at top-right, countdown timer (large, semi-transparent) at center-bottom, "Skip" text button at bottom-right.
     - `ShowingFindings` → `PreliminaryFindings` widget (full-screen interstitial).
     - `ScreeningComplete` → brief "Assessment Complete" message, auto-navigates to `/report/:id` via GoRouter after 1 second.
   - Import `CameraView` from story-1294. If not available yet, wrap in a `Container` placeholder with comment `// TODO: Replace with CameraView from story-1294`.

4. Create `lib/features/screening/widgets/movement_instructions.dart`:
   - `MovementInstructions` is a StatelessWidget taking `MovementConfig config` and `Duration remaining`.
   - Displays: movement name as title, instruction text below, remaining time formatted as "0:45".
   - Styled as a semi-transparent dark overlay at the top of the screen (positioned widget).
   - When `remaining > 57 seconds` (first 3 seconds), show large "Get Ready..." text instead of instructions (countdown before movement starts).

5. Create `lib/features/screening/widgets/preliminary_findings.dart`:
   - `PreliminaryFindings` is a StatelessWidget taking `String feedbackMessage`, `int completedMovementIndex`, `VoidCallback onContinue`.
   - Full-screen card with: completed movement name, feedback message in body-path language, progress dots (filled for completed movements, empty for remaining), "Continue to Next Movement" button.
   - If `completedMovementIndex == 2` (third movement, 0-indexed), button says "Continue to Final Movement".
   - Warm, encouraging tone — no clinical language.
<!-- END_CODER_ONLY -->

## Contract
ScreeningController public API consumed by ScreeningView and downstream stories:

```dart
// lib/features/screening/models/movement.dart
class MovementConfig {
  final MovementType type;
  final String name;
  final String instruction;
  final Duration duration;      // default 60s
  final int targetReps;
  final String primaryJoint;    // joint name for peak detection
  final bool peakIsMinimum;     // true = squat/fold, false = reach/balance
}

const List<MovementConfig> screeningMovements; // ordered: squat, balance, reach, fold

// lib/features/screening/controllers/screening_controller.dart
sealed class ScreeningState {}
class ScreeningSetup extends ScreeningState {}
class ActiveMovement extends ScreeningState {
  final int movementIndex;
  final MovementConfig config;
  final int repsCompleted;
  final Duration remaining;
  final List<List<Landmark>> capturedFrames;
  final List<Compensation> movementCompensations;
}
class ShowingFindings extends ScreeningState {
  final int completedMovementIndex;
  final List<Compensation> findings;
  final String feedbackMessage;
}
class ScreeningComplete extends ScreeningState {
  final Assessment assessment;
}

class ScreeningController extends StateNotifier<ScreeningState> {
  ScreeningController(PoseEstimationService, AngleCalculator, ChainMapper);
  void startScreening();
  void continueToNextMovement();
  void skipMovement();
}

// Riverpod provider
final screeningControllerProvider = StateNotifierProvider<ScreeningController, ScreeningState>(...);
```

Output to story-1297 (Report):
```dart
// Assessment object (from lib/domain/models.dart)
Assessment(
  id: String,           // UUID
  createdAt: DateTime,
  movements: List<Movement>,        // 4 movements with keyframeAngles populated
  compensations: List<Compensation>, // all compensations across all movements
  report: null,                      // populated by story-1297
)
```

## Acceptance criteria
- User taps "Begin Screening" and the first movement (overhead squat) starts with a 3-second "Get Ready" countdown before the 60-second timer begins
- Progress indicator displays "Movement 1 of 4: Overhead Squat" and updates correctly as movements advance
- Rep counter increments each time peak detection fires during a movement and displays "Rep 3 of 5"
- When a movement's timer expires (or target reps reached), the between-movement findings screen appears showing 1-2 observations in body-path language (no chain names, no clinical jargon)
- User taps "Continue" on findings screen and the next movement begins with its own countdown and instructions
- After the 4th movement completes, the controller produces an Assessment object containing all 4 Movement records and all detected Compensation objects with report set to null
- User can tap "Skip" during any movement to advance to findings/next movement with whatever data was captured
- State machine never skips a state or allows out-of-order transitions (setup → movement0 → findings0 → movement1 → ... → complete)
- 5-frame keyframe buffer averages landmarks element-wise at each detected peak before running through AngleCalculator and ChainMapper
- Assessment object is structurally valid for consumption by story-1297's report generation

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
<!-- TESTER_ONLY -->
test_files: test/features/screening/controllers/screening_controller_test.dart
<!-- END_TESTER_ONLY -->
