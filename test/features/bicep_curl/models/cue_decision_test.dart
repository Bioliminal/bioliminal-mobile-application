import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';

void main() {
  group('VibrationPulseBurst.encode', () {
    test('matches the FADE payload from the handshake', () {
      // From haptic-cueing-handshake.md §"Pre-defined cue payloads".
      const fade = Cue.fadeBurst as VibrationPulseBurst;
      expect(
        fade.encode(),
        equals([0x10, 0x00, 0xB4, 0x02, 0xC8, 0x00, 0x96, 0x00]),
      );
    });

    test('matches the URGENT payload from the handshake', () {
      const urgent = Cue.urgentBurst as VibrationPulseBurst;
      expect(
        urgent.encode(),
        equals([0x10, 0x00, 0xE6, 0x02, 0xC8, 0x00, 0x96, 0x00]),
      );
    });

    test('matches the FORM staccato payload from the handshake', () {
      const form = Cue.formStaccato as VibrationPulseBurst;
      expect(
        form.encode(),
        equals([0x10, 0x00, 0xE6, 0x03, 0x64, 0x00, 0x50, 0x00]),
      );
    });

    test('encodes onMs / offMs little-endian', () {
      const burst = VibrationPulseBurst(
        motorIdx: 1,
        duty: 0xAA,
        pulseCount: 5,
        onMs: 0x0123,
        offMs: 0x4567,
      );
      expect(
        burst.encode(),
        equals([0x10, 0x01, 0xAA, 0x05, 0x23, 0x01, 0x67, 0x45]),
      );
    });
  });
}
