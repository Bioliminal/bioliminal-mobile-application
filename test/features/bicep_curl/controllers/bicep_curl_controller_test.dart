import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/controllers/bicep_curl_controller.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';

void main() {
  group('BicepCurlController', () {
    test('initial state is Idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(bicepCurlControllerProvider);
      expect(state, isA<BicepCurlIdle>());
    });

    test('startSession proceeds vision-only when BLE is not connected',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(bicepCurlControllerProvider.notifier);
      await controller.startSession(side: ArmSide.right);

      // No garment → session enters Setup (framing check). Vision-only
      // rep counting + compensation cues run; fatigue bar greys out once
      // Active begins (emgOnline=false driven by _bleDroppedDuringSet).
      final state = container.read(bicepCurlControllerProvider);
      expect(state, isA<BicepCurlSetup>());
    });

    test('cycleProfile rotates intermediate → advanced → beginner', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(bicepCurlControllerProvider.notifier);
      // No-op behaviorally without an active session, but the rotation
      // updates the controller's internal _profile field used on the
      // next session start. We can't observe _profile directly, but we
      // can verify cycleProfile doesn't throw and doesn't change state.
      controller.cycleProfile();
      controller.cycleProfile();
      controller.cycleProfile();
      expect(container.read(bicepCurlControllerProvider), isA<BicepCurlIdle>());
    });
  });
}
