import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/domain/services/rule_based_angle_calculator.dart';
import 'package:auralink/domain/services/rule_based_chain_mapper.dart';
import 'package:auralink/features/screening/controllers/screening_controller.dart';
import 'package:auralink/features/screening/models/movement.dart';

void main() {
  late ScreeningController controller;

  setUp(() {
    controller = ScreeningController(
      angleCalculator: RuleBasedAngleCalculator(),
      chainMapper: RuleBasedChainMapper(),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('initial state is ScreeningSetup', () {
    expect(controller.state, isA<ScreeningSetup>());
  });

  test('startScreening transitions to ActiveMovement', () {
    controller.startScreening();
    expect(controller.state, isA<ActiveMovement>());
    final state = controller.state as ActiveMovement;
    expect(state.movementIndex, 0);
    expect(state.repsCompleted, 0);
    expect(state.config.type, MovementType.overheadSquat);
  });

  test('startScreening only works from ScreeningSetup', () {
    controller.startScreening();
    final firstState = controller.state;
    // Calling startScreening again should be a no-op.
    controller.startScreening();
    expect(controller.state, firstState);
  });

  test('skipMovement advances from ActiveMovement', () {
    controller.startScreening();
    expect(controller.state, isA<ActiveMovement>());

    controller.skipMovement();
    // After skipping the first movement, should show findings or advance.
    expect(
      controller.state,
      anyOf(isA<ShowingFindings>(), isA<ActiveMovement>()),
    );
  });

  test('skipMovement is no-op from non-ActiveMovement states', () {
    // From ScreeningSetup — should be no-op.
    final initial = controller.state;
    controller.skipMovement();
    expect(controller.state, initial);
  });

  test('full screening flow reaches ScreeningComplete', () {
    controller.startScreening();

    // Skip through all 4 movements.
    for (var i = 0; i < screeningMovements.length; i++) {
      if (controller.state is ActiveMovement) {
        controller.skipMovement();
      }
      if (controller.state is ShowingFindings) {
        controller.continueToNextMovement();
      }
    }

    expect(controller.state, isA<ScreeningComplete>());
  });

  test('ScreeningComplete contains Assessment with correct structure', () {
    controller.startScreening();

    for (var i = 0; i < screeningMovements.length; i++) {
      if (controller.state is ActiveMovement) {
        controller.skipMovement();
      }
      if (controller.state is ShowingFindings) {
        controller.continueToNextMovement();
      }
    }

    final state = controller.state as ScreeningComplete;
    expect(state.assessment.id, isNotEmpty);
    expect(state.assessment.createdAt, isA<DateTime>());
    expect(state.assessment.movements, isNotEmpty);
  });

  test('movement duration is 60 seconds', () {
    expect(screeningMovements.first.duration, const Duration(seconds: 60));
    for (final config in screeningMovements) {
      expect(config.duration, const Duration(seconds: 60));
    }
  });

  test('continueToNextMovement only works from ShowingFindings', () {
    controller.startScreening();
    // From ActiveMovement — should be no-op.
    final state = controller.state;
    controller.continueToNextMovement();
    expect(controller.state, state);
  });
}
