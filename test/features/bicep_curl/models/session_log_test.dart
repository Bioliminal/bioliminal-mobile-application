import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/models/rep_record.dart';
import 'package:bioliminal/features/bicep_curl/models/session_log.dart';

void main() {
  group('SessionLog', () {
    test('baselineTrajectory tracks rolling-max over the last N peaks', () {
      // Window of 5 peaks; rising then falling sequence.
      final log = _logWithPeaks([100, 120, 140, 160, 180, 170, 150, 130, 110, 100]);
      final baseline = log.baselineTrajectory(5);
      expect(baseline, equals([100, 120, 140, 160, 180, 180, 180, 180, 180, 170]));
    });

    test('formScore is 100 when no rep has compensation', () {
      final log = _logWithPeaks([100, 100, 100], poseDeltas: [
        const PoseDelta(shoulderDriftDeg: 0, torsoPitchDeltaDeg: 0),
        const PoseDelta(shoulderDriftDeg: 3, torsoPitchDeltaDeg: 5),
        null,
      ]);
      expect(log.formScore, 100.0);
    });

    test('formScore drops with compensation events past thresholds', () {
      final log = _logWithPeaks([100, 100, 100, 100], poseDeltas: [
        const PoseDelta(shoulderDriftDeg: 0, torsoPitchDeltaDeg: 0),
        const PoseDelta(shoulderDriftDeg: 9, torsoPitchDeltaDeg: 5),  // compensating
        const PoseDelta(shoulderDriftDeg: 0, torsoPitchDeltaDeg: 12), // compensating
        const PoseDelta(shoulderDriftDeg: 3, torsoPitchDeltaDeg: 4),
      ]);
      expect(log.formScore, 50.0);
    });

    test('formScore returns 100 for an empty set', () {
      final log = _logWithPeaks([]);
      expect(log.formScore, 100.0);
    });
  });
}

SessionLog _logWithPeaks(List<double> peaks, {List<PoseDelta?>? poseDeltas}) {
  final reps = <RepRecord>[];
  for (var i = 0; i < peaks.length; i++) {
    reps.add(RepRecord(
      repNum: i + 1,
      tStartUs: i * 1000000,
      tPeakUs: i * 1000000 + 500000,
      tEndUs: (i + 1) * 1000000,
      peakEnv: peaks[i],
      poseDelta: poseDeltas != null && i < poseDeltas.length
          ? poseDeltas[i]
          : null,
    ));
  }
  return SessionLog(
    reps: reps,
    cueEvents: const [],
    ref: null,
    startedAt: DateTime(2026, 4, 18),
    duration: Duration(seconds: peaks.length),
    profile: CueProfile.intermediate(),
    armSide: ArmSide.right,
    bleDroppedDuringSet: false,
  );
}
