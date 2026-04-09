import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/core/providers.dart';
import 'package:auralink/domain/models.dart';
import 'package:auralink/features/camera/widgets/setup_checklist.dart';

/// Builds 33 landmarks where every landmark has the given [visibility],
/// and hip landmarks (23, 24) have the given [hipY].
List<Landmark> _buildLandmarks({
  double visibility = 0.9,
  double hipY = 0.5,
}) {
  return List.generate(33, (idx) {
    final y = (idx == kLeftHipIndex || idx == kRightHipIndex) ? hipY : 0.5;
    return Landmark(x: 0.5, y: y, z: 0.0, visibility: visibility);
  });
}

void main() {
  group('SetupChecklistNotifier auto-validation', () {
    test('empty landmarks leaves all steps incomplete', () {
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(const []),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.distanceOk, false);
      expect(state.lightingOk, false);
      expect(state.angleOk, false);
      expect(state.clothingOk, false);
      expect(state.allPassed, false);
    });

    test('good landmarks auto-validates distance, lighting, and angle', () {
      final landmarks = _buildLandmarks(visibility: 0.9, hipY: 0.5);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.distanceOk, true);
      expect(state.lightingOk, true);
      expect(state.angleOk, true);
      // Clothing is manual — still false.
      expect(state.clothingOk, false);
      expect(state.allPassed, false);
    });

    test('low visibility fails distance check', () {
      final landmarks = _buildLandmarks(visibility: 0.4, hipY: 0.5);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.distanceOk, false);
    });

    test('medium visibility passes distance but fails lighting', () {
      // 0.6 > 0.5 threshold (distance passes), but < 0.7 (lighting fails).
      final landmarks = _buildLandmarks(visibility: 0.6, hipY: 0.5);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.distanceOk, true);
      expect(state.lightingOk, false);
    });

    test('hip out of range fails angle check', () {
      // hipY = 0.8 is outside 0.4-0.6 range.
      final landmarks = _buildLandmarks(visibility: 0.9, hipY: 0.8);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.angleOk, false);
      // Distance and lighting should still pass.
      expect(state.distanceOk, true);
      expect(state.lightingOk, true);
    });

    test('fewer than 33 landmarks fails distance check', () {
      final landmarks = List.generate(
        20,
        (_) => const Landmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.9),
      );
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(setupChecklistProvider);
      expect(state.distanceOk, false);
    });

    test('conditions revert when landmarks degrade', () {
      final good = _buildLandmarks(visibility: 0.9, hipY: 0.5);
      final bad = _buildLandmarks(visibility: 0.3, hipY: 0.9);

      // Good landmarks pass.
      final container1 = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(good),
        ],
      );
      addTearDown(container1.dispose);

      var state = container1.read(setupChecklistProvider);
      expect(state.distanceOk, true);
      expect(state.angleOk, true);

      // Degraded landmarks revert to failing.
      final container2 = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(bad),
        ],
      );
      addTearDown(container2.dispose);

      state = container2.read(setupChecklistProvider);
      expect(state.distanceOk, false);
      expect(state.angleOk, false);
    });
  });

  group('SetupChecklistNotifier manual clothing step', () {
    test('confirmClothing sets clothingOk', () {
      final landmarks = _buildLandmarks(visibility: 0.9, hipY: 0.5);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(setupChecklistProvider.notifier);
      expect(container.read(setupChecklistProvider).clothingOk, false);

      notifier.confirmClothing();

      final state = container.read(setupChecklistProvider);
      expect(state.clothingOk, true);
      expect(state.allPassed, true);
    });

    test('reset clears all state', () {
      final landmarks = _buildLandmarks(visibility: 0.9, hipY: 0.5);
      final container = ProviderContainer(
        overrides: [
          currentLandmarksProvider.overrideWithValue(landmarks),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(setupChecklistProvider.notifier);
      notifier.confirmClothing();
      expect(container.read(setupChecklistProvider).allPassed, true);

      notifier.reset();
      final state = container.read(setupChecklistProvider);
      expect(state.clothingOk, false);
      expect(state.allPassed, false);
    });
  });

  group('SetupChecklistState', () {
    test('completedCount returns number of passed steps', () {
      const none = SetupChecklistState();
      expect(none.completedCount, 0);

      const two = SetupChecklistState(distanceOk: true, lightingOk: true);
      expect(two.completedCount, 2);

      const all = SetupChecklistState(
        angleOk: true,
        distanceOk: true,
        lightingOk: true,
        clothingOk: true,
      );
      expect(all.completedCount, 4);
      expect(all.allPassed, true);
    });
  });
}
