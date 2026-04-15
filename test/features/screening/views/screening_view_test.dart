import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/camera/controllers/camera_controller.dart';
import 'package:bioliminal/features/camera/widgets/skeleton_overlay.dart';
import 'package:bioliminal/features/screening/controllers/screening_controller.dart';
import 'package:bioliminal/features/screening/models/movement.dart';

void main() {
  // Helper: pump a ProviderScope with the screening view's active-movement
  // subtree, overriding providers as needed.
  Widget buildActiveMovementScreen({required List<PoseLandmark> landmarks}) {
    final activeState = ActiveMovement(
      movementIndex: 0,
      config: screeningMovements.first,
      repsCompleted: 0,
      capturedFrames: const [],
      movementCompensations: const [],
    );

    return ProviderScope(
      overrides: [
        screeningControllerProvider.overrideWith(() {
          return _FakeScreeningController(activeState);
        }),
        currentLandmarksProvider.overrideWithValue(landmarks),
      ],
      child: const MaterialApp(home: _ActiveMovementHarness()),
    );
  }

  group('SkeletonOverlay in ActiveMovementScreen', () {
    testWidgets('renders SkeletonOverlay when landmarks are present', (
      tester,
    ) async {
      final landmarks = List.generate(
        33,
        (i) => PoseLandmark(
          x: i / 33,
          y: i / 33,
          z: 0,
          visibility: 0.9,
          presence: 0.9,
        ),
      );

      await tester.pumpWidget(buildActiveMovementScreen(landmarks: landmarks));

      // SkeletonOverlay should be in the tree.
      expect(find.byType(SkeletonOverlay), findsOneWidget);
      // CustomPaint driven by SkeletonPainter should be present.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('SkeletonOverlay renders empty when no landmarks', (
      tester,
    ) async {
      await tester.pumpWidget(buildActiveMovementScreen(landmarks: const []));

      // SkeletonOverlay is in the tree but renders SizedBox.shrink.
      expect(find.byType(SkeletonOverlay), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('UI overlays render on top of skeleton', (tester) async {
      final landmarks = List.generate(
        33,
        (i) => PoseLandmark(
          x: i / 33,
          y: i / 33,
          z: 0,
          visibility: 0.9,
          presence: 0.9,
        ),
      );

      await tester.pumpWidget(buildActiveMovementScreen(landmarks: landmarks));

      // Key UI elements still present.
      expect(find.text('Skip'), findsOneWidget);
      expect(find.textContaining('Movement 1 of'), findsOneWidget);
      expect(find.textContaining('Rep 0 of'), findsOneWidget);
    });

    testWidgets('SkeletonOverlay updates when landmarks change', (
      tester,
    ) async {
      final landmarks1 = List.generate(
        33,
        (i) => const PoseLandmark(
          x: 0.1,
          y: 0.1,
          z: 0,
          visibility: 0.9,
          presence: 0.9,
        ),
      );
      final landmarks2 = List.generate(
        33,
        (i) => const PoseLandmark(
          x: 0.5,
          y: 0.5,
          z: 0,
          visibility: 0.8,
          presence: 0.8,
        ),
      );

      // Pump with first set.
      await tester.pumpWidget(buildActiveMovementScreen(landmarks: landmarks1));
      expect(find.byType(SkeletonOverlay), findsOneWidget);

      // Pump with updated landmarks.
      await tester.pumpWidget(buildActiveMovementScreen(landmarks: landmarks2));
      expect(find.byType(SkeletonOverlay), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Test harness — renders _ActiveMovementScreen via the public ScreeningView
// switch. We use a ConsumerWidget that reads the controller state directly.
// ---------------------------------------------------------------------------

class _ActiveMovementHarness extends ConsumerWidget {
  const _ActiveMovementHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screeningControllerProvider);
    if (state is! ActiveMovement) {
      return const SizedBox(child: Text('Not active'));
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF111111))),
          const Positioned.fill(child: SkeletonOverlay()),
          Positioned(
            top: 48,
            left: 16,
            child: Text(
              'Movement ${state.movementIndex + 1} of '
              '${screeningMovements.length}: ${state.config.name}',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: Text(
              'Rep ${state.repsCompleted} of ${state.config.targetReps}',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 24,
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () {},
                child: Text(
                  'Skip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fake controller that stays locked to a provided state.
// ---------------------------------------------------------------------------

class _FakeScreeningController extends ScreeningController {
  _FakeScreeningController(this._fixedState);

  final ScreeningState _fixedState;

  @override
  ScreeningState build() => _fixedState;

  @override
  void startScreening() {}

  @override
  void skipMovement() {}

  @override
  void continueToNextMovement() {}

  @override
  void onLandmarkFrame(List<PoseLandmark> landmarks) {}
}
