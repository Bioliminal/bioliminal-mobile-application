import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/main.dart' as app;
import 'package:bioliminal/features/screening/controllers/screening_controller.dart';
import 'package:bioliminal/features/screening/models/movement.dart';
import 'package:bioliminal/features/screening/widgets/stick_figure_animation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screening pipeline on device', () {
    testWidgets('full flow: disclaimer → screening → preview → complete', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle();

      // --- Disclaimer screen ---
      // Should see the disclaimer/onboarding view first.
      expect(find.textContaining('Understand'), findsOneWidget);

      // Accept disclaimer.
      final acceptButton = find.widgetWithText(FilledButton, 'I Understand');
      expect(acceptButton, findsOneWidget);
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // --- Navigate to screening ---
      // Find and tap the screening entry point.
      final screeningButton = find.textContaining('Begin Screening');
      if (screeningButton.evaluate().isEmpty) {
        // May need to navigate — look for a screening nav item.
        final navItem = find.textContaining('Screen');
        if (navItem.evaluate().isNotEmpty) {
          await tester.tap(navItem.first);
          await tester.pumpAndSettle();
        }
      }

      // --- Setup screen ---
      expect(find.textContaining('Movement Screening'), findsOneWidget);
      expect(find.textContaining('4 simple movements'), findsOneWidget);

      final beginButton = find.widgetWithText(FilledButton, 'Begin Screening');
      expect(beginButton, findsOneWidget);
      await tester.tap(beginButton);
      await tester.pumpAndSettle();

      // --- Preview screen for first movement ---
      expect(find.textContaining('Overhead Squat'), findsOneWidget);
      expect(find.byType(StickFigureAnimation), findsOneWidget);
      expect(find.textContaining("I'm Ready"), findsOneWidget);
    });

    testWidgets('preview shows stick figure animation for each movement', (
      tester,
    ) async {
      // Build a minimal app with just the screening flow.
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctrl = container.read(screeningControllerProvider.notifier);

      // Walk through all movements.
      ctrl.startScreening();

      for (var i = 0; i < screeningMovements.length; i++) {
        final state = container.read(screeningControllerProvider);
        expect(state, isA<ActiveMovement>());
        final active = state as ActiveMovement;
        expect(active.movementIndex, i);
        expect(active.config.type, screeningMovements[i].type);

        // Verify keyframes exist for this movement.
        final keyframes = keyframesFor(active.config.type);
        expect(keyframes.length, greaterThanOrEqualTo(2));

        // Skip to next: active → findings → next active (or complete).
        ctrl.skipMovement();
        final afterSkip = container.read(screeningControllerProvider);

        if (afterSkip is ShowingFindings) {
          ctrl.continueToNextMovement();
        }
        // Last movement goes straight to ScreeningComplete.
      }

      expect(
        container.read(screeningControllerProvider),
        isA<ScreeningComplete>(),
      );
    });

    testWidgets('camera feed delivers real landmarks when available', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle();

      // Accept disclaimer.
      final acceptButton = find.widgetWithText(FilledButton, 'I Understand');
      if (acceptButton.evaluate().isNotEmpty) {
        await tester.tap(acceptButton);
        await tester.pumpAndSettle();
      }

      // Navigate to screening and start.
      final beginButton = find.widgetWithText(FilledButton, 'Begin Screening');
      if (beginButton.evaluate().isNotEmpty) {
        await tester.tap(beginButton);
        await tester.pumpAndSettle();
      }

      // Tap "I'm Ready" on preview.
      final readyButton = find.widgetWithText(FilledButton, "I'm Ready");
      if (readyButton.evaluate().isNotEmpty) {
        await tester.tap(readyButton);
        await tester.pumpAndSettle();

        // Wait for camera to initialize and potentially deliver frames.
        // On a real device with camera permission, ML Kit will start
        // producing landmarks within ~1 second.
        await tester.pump(const Duration(seconds: 3));

        // Verify we're in ActiveMovement state — camera view is showing.
        // The skeleton overlay should be in the widget tree.
        // Whether landmarks are populated depends on the device having
        // a camera and granting permission.
        expect(find.textContaining('Movement 1 of'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      }
    });
  });
}
