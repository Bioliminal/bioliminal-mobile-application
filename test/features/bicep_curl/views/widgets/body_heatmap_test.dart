import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/models/rep_record.dart';
import 'package:bioliminal/features/bicep_curl/models/session_log.dart';
import 'package:bioliminal/features/bicep_curl/views/widgets/body_heatmap.dart';

/// Guards the pure activation math inside the body-heatmap widget —
/// the mapping that powers the MEASURED + INFERRED panels. Rendering
/// itself (a CustomPainter) is validated on-device; here we lock in:
/// - rep window decoding from an absolute sample index
/// - per-sample lookup vs half-sine fallback for legacy reps
/// - bicep stays dark when EMG was never present (no visibility floor)
/// - signed pose-delta → [0,1] normalization tied to profile thresholds
///   (negative slump / back-lean clamps to zero, not flipped positive)
/// - trap = 0.85 × shoulder (synergist coupling)
void main() {
  group('MuscleActivations.fromLog', () {
    test('empty log returns zero activations', () {
      final log = _makeLog([]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 1.0,
      );
      expect(a.bicep, 0);
      expect(a.shoulder, 0);
      expect(a.trap, 0);
      expect(a.erector, 0);
    });

    test('measured panel reads per-sample envelope when available', () {
      final rep = _rep(peakEnv: 100, envelopeSamples: _ramp(50, peak: 100));
      final log = _makeLog([rep]);

      // Sample 25 is the peak of the ramp (100); bicep saturates at 1.0.
      final atPeak = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 25,
        maxSampleValue: 100,
      );
      expect(atPeak.bicep, closeTo(1.0, 1e-9));

      // Sample 0 is bottom of the ramp (0). No visibility floor anymore —
      // quiet EMG reads as a dark bicep, not a fake 40 % glow.
      final atBottom = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(atBottom.bicep, 0);
    });

    test('falls back to half-sine for legacy reps with no envelopeSamples',
        () {
      final rep = _rep(peakEnv: 100, envelopeSamples: null);
      final log = _makeLog([rep]);

      // Half-sine peaks at the middle sample, so sample 25 of 50 ~= 1.0.
      final mid = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 25,
        maxSampleValue: 100,
      );
      expect(mid.bicep, closeTo(1.0, 1e-3));

      // Edges of the half-sine are near zero → bicep dark (no floor).
      final edge = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(edge.bicep, 0);
    });

    test('bicep stays dark when session produced no EMG signal', () {
      // CV-only session: rep boundaries fired but armband was off, so
      // envelopeSamples are all zeros and session-wide max is 0. The
      // panel must not fake engagement with a floor glow.
      final rep = _rep(peakEnv: 0, envelopeSamples: _flat(50, 0));
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 10,
        maxSampleValue: 0,
      );
      expect(a.bicep, 0);
    });

    test('inferred shoulder scales drift against profile threshold', () {
      // Intermediate profile: shoulderDriftDeg threshold = 14°. Saturation
      // hits at 1.5 × threshold = 21°. A mid-range 10.5° reads as 0.5.
      final rep = _rep(
        peakEnv: 0,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: 10.5,
          torsoPitchDeltaDeg: 0,
        ),
      );
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(a.shoulder, closeTo(0.5, 1e-9));
      expect(a.trap, closeTo(0.5 * 0.85, 1e-9));
    });

    test('inferred erector saturates past 1.5x torso-pitch threshold', () {
      // Intermediate profile: torsoPitchDeltaDeg threshold = 20°.
      // Saturation at 30°. 40° is well past and clamps to 1.0.
      final rep = _rep(
        peakEnv: 0,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: 0,
          torsoPitchDeltaDeg: 40,
        ),
      );
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(a.erector, 1.0);
    });

    test('negative shoulder drift (slump) does not glow', () {
      // Signed peak: user's shoulder went DOWN relative to resting ref.
      // That's posture, not compensation — must clamp to zero, not flip.
      final rep = _rep(
        peakEnv: 0,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: -12,
          torsoPitchDeltaDeg: 0,
        ),
      );
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(a.shoulder, 0);
      expect(a.trap, 0);
    });

    test('negative torso pitch (back-lean) does not glow', () {
      final rep = _rep(
        peakEnv: 0,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: 0,
          torsoPitchDeltaDeg: -18,
        ),
      );
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(a.erector, 0);
    });

    test('null poseDelta (calibration rep) zeroes synergists', () {
      final rep = _rep(peakEnv: 100, poseDelta: null);
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(a.shoulder, 0);
      expect(a.trap, 0);
      expect(a.erector, 0);
    });

    test('absoluteSample decodes into the correct rep window', () {
      final rep1 = _rep(
        peakEnv: 50,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: 0,
          torsoPitchDeltaDeg: 0,
        ),
      );
      final rep2 = _rep(
        peakEnv: 50,
        poseDelta: const PoseDelta(
          // 21° = 1.5 × intermediate threshold (14°) → saturated, makes
          // the rep-boundary transition obvious.
          shoulderDriftDeg: 21,
          torsoPitchDeltaDeg: 0,
        ),
      );
      final log = _makeLog([rep1, rep2]);

      // Sample 49 is the final frame of rep 1.
      final endOfRep1 = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 49,
        maxSampleValue: 100,
      );
      expect(endOfRep1.shoulder, 0);

      // Sample 50 is the first frame of rep 2.
      final startOfRep2 = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 50,
        maxSampleValue: 100,
      );
      expect(startOfRep2.shoulder, 1.0);
    });

    test('absoluteSample past the end clamps to the last rep', () {
      final rep = _rep(
        peakEnv: 50,
        poseDelta: const PoseDelta(
          shoulderDriftDeg: 21, // saturated per intermediate profile
          torsoPitchDeltaDeg: 0,
        ),
      );
      final log = _makeLog([rep]);
      final a = MuscleActivations.fromLog(
        log: log,
        absoluteSample: 500,
        maxSampleValue: 100,
      );
      expect(a.shoulder, 1.0);
    });
  });
}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

RepRecord _rep({
  required double peakEnv,
  List<double>? envelopeSamples,
  PoseDelta? poseDelta,
}) {
  return RepRecord(
    repNum: 1,
    tStartUs: 0,
    tPeakUs: 500000,
    tEndUs: 1000000,
    peakEnv: peakEnv,
    poseDelta: poseDelta,
    envelopeSamples: envelopeSamples,
  );
}

SessionLog _makeLog(List<RepRecord> reps) {
  return SessionLog(
    reps: reps,
    cueEvents: const [],
    ref: null,
    startedAt: DateTime(2026, 4, 18),
    duration: const Duration(seconds: 30),
    profile: CueProfile.intermediate(),
    armSide: ArmSide.right,
    bleDroppedDuringSet: false,
  );
}

/// Linear 0 → peak → 0 ramp over `count` samples, peak at the middle.
List<double> _ramp(int count, {required double peak}) {
  final mid = count ~/ 2;
  return List<double>.generate(count, (i) {
    final d = (i - mid).abs();
    return peak * (1 - d / mid).clamp(0.0, 1.0);
  });
}

List<double> _flat(int count, double v) =>
    List<double>.filled(count, v);
