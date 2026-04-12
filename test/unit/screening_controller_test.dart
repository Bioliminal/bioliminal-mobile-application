import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/core/providers.dart';
import 'package:auralink/features/camera/services/pose_detector.dart';
import 'package:auralink/features/screening/controllers/screening_controller.dart';
import 'package:auralink/features/screening/models/movement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        poseDetectorProvider.overrideWithValue(MockPoseDetector()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ScreeningController getController() =>
      container.read(screeningControllerProvider.notifier);

  ScreeningState getState() => container.read(screeningControllerProvider);

  test('initial state is ScreeningSetup', () {
    expect(getState(), isA<ScreeningSetup>());
  });

  test('startScreening transitions to EnvironmentSetup', () {
    getController().startScreening();
    expect(getState(), isA<EnvironmentSetup>());
  });

  test('full setup flow reaches ActiveMovement', () {
    getController().startScreening();
    getController().completeEnvironmentSetup();
    expect(getState(), isA<MovementPreparation>());
    
    getController().startMovement();
    expect(getState(), isA<ActiveMovement>());
    final s = getState() as ActiveMovement;
    expect(s.movementIndex, 0);
    expect(s.repsCompleted, 0);
    expect(s.config.type, MovementType.overheadSquat);
  });

  test('startScreening only works from ScreeningSetup', () {
    getController().startScreening();
    final firstState = getState();
    // Calling startScreening again should be a no-op.
    getController().startScreening();
    expect(getState(), firstState);
  });

  test('skipMovement advances from ActiveMovement', () {
    getController().startScreening();
    getController().completeEnvironmentSetup();
    getController().startMovement();
    expect(getState(), isA<ActiveMovement>());

    getController().skipMovement();
    // After skipping the first movement, should show findings or advance.
    expect(getState(), anyOf(isA<ShowingFindings>(), isA<ActiveMovement>()));
  });

  test('skipMovement is no-op from non-ActiveMovement states', () {
    // From ScreeningSetup — should be no-op.
    final initial = getState();
    getController().skipMovement();
    expect(getState(), initial);
  });

  test('full screening flow reaches ScreeningComplete', () {
    getController().startScreening();
    getController().completeEnvironmentSetup();

    // Skip through all 4 movements.
    for (var i = 0; i < screeningMovements.length; i++) {
      if (getState() is MovementPreparation) {
        getController().startMovement();
      }
      if (getState() is ActiveMovement) {
        getController().skipMovement();
      }
      if (getState() is ShowingFindings) {
        getController().continueToNextMovement();
      }
    }

    expect(getState(), isA<ScreeningComplete>());
  });

  test('ScreeningComplete contains Assessment with correct structure', () {
    getController().startScreening();
    getController().completeEnvironmentSetup();

    for (var i = 0; i < screeningMovements.length; i++) {
      if (getState() is MovementPreparation) {
        getController().startMovement();
      }
      if (getState() is ActiveMovement) {
        getController().skipMovement();
      }
      if (getState() is ShowingFindings) {
        getController().continueToNextMovement();
      }
    }

    final s = getState() as ScreeningComplete;
    expect(s.assessment.id, isNotEmpty);
    expect(s.assessment.createdAt, isA<DateTime>());
    expect(s.assessment.movements, isNotEmpty);
  });

  test('continueToNextMovement only works from ShowingFindings', () {
    getController().startScreening();
    getController().completeEnvironmentSetup();
    getController().startMovement();
    // From ActiveMovement — should be no-op.
    final s = getState();
    getController().continueToNextMovement();
    expect(getState(), s);
  });
}
