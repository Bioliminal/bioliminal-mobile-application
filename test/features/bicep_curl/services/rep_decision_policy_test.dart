import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart'
    show ArmSide;
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';
import 'package:bioliminal/features/bicep_curl/services/rep_decision_policy.dart';

void main() {
  group('ExtremaAmplitudeGatePolicy', () {
    test('emits one RepComplete on a clean 170° → 60° → 170° sweep', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      void feed(double angle, int tUs) {
        final e = policy.feedFrame(
          tUs: tUs,
          landmarks: _armAtAngle(angle),
          side: ArmSide.right,
        );
        if (e != null) events.add(e);
      }
      int t = 0;
      for (var i = 0; i < 3; i++) { feed(170, t); t += 33333; }
      for (var i = 0; i < 11; i++) { feed(170 - i * 11.0, t); t += 33333; }
      for (var i = 0; i < 11; i++) { feed(60 + i * 11.0, t); t += 33333; }
      for (var i = 0; i < 3; i++) { feed(170, t); t += 33333; }
      final completes = events.whereType<RepCompleteEvent>().toList();
      expect(completes.length, 1);
      expect(completes[0].bottomAngle, lessThan(70));
    });

    test('emits ZERO RepComplete on 10s of stationary 170° with ±5° jitter', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final rnd = math.Random(7);
      final events = <RepDecisionEvent>[];
      var t = 0;
      for (var i = 0; i < 300; i++) {
        final angle = 170.0 + (rnd.nextDouble() - 0.5) * 10.0;
        final e = policy.feedFrame(
          tUs: t,
          landmarks: _armAtAngle(angle),
          side: ArmSide.right,
        );
        if (e != null) events.add(e);
        t += 33333;
      }
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);
    });

    test('emits exactly two RepComplete for two clean cycles', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      for (var rep = 0; rep < 2; rep++) {
        for (var i = 0; i < 3; i++) {
          final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right);
          if (e != null) events.add(e);
          t += 33333;
        }
        for (var i = 0; i < 11; i++) {
          final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170 - i * 11.0), side: ArmSide.right);
          if (e != null) events.add(e);
          t += 33333;
        }
        for (var i = 0; i < 11; i++) {
          final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 11.0), side: ArmSide.right);
          if (e != null) events.add(e);
          t += 33333;
        }
      }
      for (var i = 0; i < 3; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right);
        if (e != null) events.add(e);
        t += 33333;
      }
      expect(events.whereType<RepCompleteEvent>().length, 2);
    });

    test('rejects a shallow partial (amplitude < 30°) as not-a-rep', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += 33333; }
      for (var i = 0; i < 5; i++) { _maybeAdd(events, policy, 170 - i * 5.0, t); t += 33333; }
      for (var i = 0; i < 5; i++) { _maybeAdd(events, policy, 150 + i * 5.0, t); t += 33333; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += 33333; }
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);
    });

    test('RepCompleteEvent.startAngle reflects the actual angle observed just before armed→descending (not a constant)', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      int t = 0;
      RepCompleteEvent? done;
      // Pre-rep idle below the top (e.g. 165°) — still armed because 165° > 130° threshold.
      for (var i = 0; i < 5; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(165), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += 33333;
      }
      // Clean curl from 165° down to 60° and back to 170°.
      for (var i = 0; i < 11; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(165 - i * 9.5), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += 33333;
      }
      for (var i = 0; i < 12; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 9.5), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += 33333;
      }
      expect(done, isNotNull);
      // 165° was the last-observed angle at armed→descending transition.
      expect(done!.startAngle, closeTo(165, 1.0));
    });

    test('reset() clears state so a subsequent sweep counts from 1', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      int t = 0;
      for (var i = 0; i < 3; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right); t += 33333; }
      for (var i = 0; i < 11; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170 - i * 11.0), side: ArmSide.right); t += 33333; }
      for (var i = 0; i < 11; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 11.0), side: ArmSide.right); t += 33333; }
      for (var i = 0; i < 3; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right); t += 33333; }
      policy.reset();
      final events = <RepDecisionEvent>[];
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += 33333; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 170 - i * 11.0, t); t += 33333; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 60 + i * 11.0, t); t += 33333; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += 33333; }
      final completes = events.whereType<RepCompleteEvent>().toList();
      expect(completes.length, 1);
      expect(completes[0].repNum, 1);
    });
  });
}

void _maybeAdd(List<RepDecisionEvent> events, ExtremaAmplitudeGatePolicy p, double a, int t) {
  final e = p.feedFrame(tUs: t, landmarks: _armAtAngle(a), side: ArmSide.right);
  if (e != null) events.add(e);
}

List<PoseLandmark> _armAtAngle(double angleDeg) {
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final landmarks = List.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  landmarks[kRightShoulder] = const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1);
  landmarks[kRightElbow] = const PoseLandmark(x: 1, y: 0, z: 0, visibility: 1, presence: 1);
  landmarks[kRightWrist] = PoseLandmark(
    x: 1.0 + math.cos(theta),
    y: math.sin(theta),
    z: 0,
    visibility: 1,
    presence: 1,
  );
  return landmarks;
}
