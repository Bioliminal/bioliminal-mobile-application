import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_event.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/models/rep_record.dart';
import 'package:bioliminal/features/bicep_curl/models/session_log.dart';

void main() {
  test('SessionLog roundtrips through JSON without losing data', () {
    final original = SessionLog(
      reps: const [
        RepRecord(
          repNum: 1,
          tStartUs: 0,
          tPeakUs: 1500000,
          tEndUs: 3000000,
          peakEnv: 1234.5,
        ),
        RepRecord(
          repNum: 2,
          tStartUs: 3000000,
          tPeakUs: 4500000,
          tEndUs: 6000000,
          peakEnv: 1450.0,
          poseDelta:
              PoseDelta(shoulderDriftDeg: 8.2, torsoPitchDeltaDeg: -3.1),
        ),
      ],
      cueEvents: [
        CueEvent(
          repNum: 7,
          content: CueContent.fatigueFade,
          firedAt: DateTime.utc(2026, 4, 18, 21, 13, 21),
          channelsFired: const {'haptic', 'visual'},
        ),
      ],
      ref: const CompensationReference(
        shoulderYRef: 0.42,
        torsoPitchDegRef: 1.5,
        armSide: ArmSide.right,
      ),
      startedAt: DateTime.utc(2026, 4, 18, 21, 12, 0),
      duration: const Duration(seconds: 90, milliseconds: 250),
      profile: CueProfile.intermediate(),
      armSide: ArmSide.right,
      bleDroppedDuringSet: false,
    );

    // Round-trip through real JSON encoding to catch any serialization
    // bugs that String-keyed maps would mask.
    final encoded = jsonEncode(original.toJson());
    final decoded = SessionLog.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(decoded.reps.length, 2);
    expect(decoded.reps[0].peakEnv, 1234.5);
    expect(decoded.reps[1].poseDelta!.shoulderDriftDeg, closeTo(8.2, 1e-9));
    expect(decoded.cueEvents.length, 1);
    expect(decoded.cueEvents[0].content, CueContent.fatigueFade);
    expect(decoded.cueEvents[0].channelsFired,
        equals({'haptic', 'visual'}));
    expect(decoded.ref!.armSide, ArmSide.right);
    expect(decoded.duration, const Duration(seconds: 90, milliseconds: 250));
    expect(decoded.profile.label, 'intermediate');
    expect(decoded.armSide, ArmSide.right);
    expect(decoded.bleDroppedDuringSet, isFalse);
  });

  test('SessionLog with no compensation ref roundtrips cleanly', () {
    final original = SessionLog(
      reps: const [],
      cueEvents: const [],
      ref: null,
      startedAt: DateTime.utc(2026, 4, 18),
      duration: Duration.zero,
      profile: CueProfile.beginner(),
      armSide: ArmSide.left,
      bleDroppedDuringSet: true,
    );
    final decoded = SessionLog.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.ref, isNull);
    expect(decoded.profile.label, 'beginner');
    expect(decoded.armSide, ArmSide.left);
    expect(decoded.bleDroppedDuringSet, isTrue);
  });
}
