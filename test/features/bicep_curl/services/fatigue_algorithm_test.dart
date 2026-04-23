import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/services/fatigue_algorithm.dart';

void main() {
  final intermediate = CueProfile.intermediate();

  group('FatigueAlgorithm.evaluate', () {
    test('silent through calibration window regardless of drop', () {
      // A pathological calibration where peak dropped 90% rep 1 → rep 2
      // should still be silent during reps 1..5.
      for (var n = 1; n <= 5; n++) {
        final peaks = [1000.0, 100.0, 100.0, 100.0, 100.0].sublist(0, n);
        final decision = FatigueAlgorithm.evaluate(
          peaks: peaks,
          currentRepNum: n,
          lastCueRep: -999,
          profile: intermediate,
          compensationActive: false,
        );
        expect(decision, isNull, reason: 'rep $n should be silent');
      }
    });

    test('no cue when peaks are still rising (rolling baseline ratchets)', () {
      final peaks = [100.0, 120.0, 140.0, 160.0, 180.0, 200.0, 220.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 7,
        lastCueRep: -999,
        profile: intermediate,
        compensationActive: false,
      );
      expect(decision, isNull);
    });

    test('FADE fires at first rep ≥15% below rolling-max baseline', () {
      // Baseline = max of last 5 = 1000. Drop = 16% → FADE.
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 840.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 7,
        lastCueRep: -999,
        profile: intermediate,
        compensationActive: false,
      );
      expect(decision, isNotNull);
      expect(decision!.content, CueContent.fatigueFade);
    });

    test('URGENT supersedes FADE past the 25% threshold', () {
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 740.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 7,
        lastCueRep: -999,
        profile: intermediate,
        compensationActive: false,
      );
      expect(decision!.content, CueContent.fatigueUrgent);
    });

    test('STOP supersedes everything past 50% drop', () {
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 400.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 7,
        lastCueRep: -999,
        profile: intermediate,
        compensationActive: true, // even with compensation
      );
      expect(decision!.content, CueContent.fatigueStop);
    });

    test('cooldown suppresses fatigue cues after a recent fire', () {
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 800.0, 750.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 8,
        lastCueRep: 7,
        profile: intermediate,
        compensationActive: false,
      );
      expect(decision, isNull);
    });

    test('compensationActive suppresses fatigue cue (form cue dispatches '
        'independently from the pose path)', () {
      // Rep 7 would otherwise fire FADE (16% drop from rolling-max
      // baseline). With compensationActive=true, the controller will
      // dispatch shoulderHike/torsoSwing on its own; the fatigue
      // algorithm stays quiet so the form cue isn't crowded out.
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 840.0];
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 7,
        lastCueRep: -999,
        profile: intermediate,
        compensationActive: true,
      );
      expect(decision, isNull);
    });

    test('beginner profile suppresses cues that would fire on intermediate', () {
      final peaks = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0,
                     1000.0, 840.0]; // 16% drop
      // beginner has calibration=8, so rep 9 is the first eligible rep.
      // beginner FADE threshold is 0.20, so 16% drop should NOT fire.
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: 9,
        lastCueRep: -999,
        profile: CueProfile.beginner(),
        compensationActive: false,
      );
      expect(decision, isNull);
    });
  });
}
