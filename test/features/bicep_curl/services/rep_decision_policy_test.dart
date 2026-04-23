import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart'
    show ArmSide;
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';
import 'package:bioliminal/features/bicep_curl/services/rep_decision_policy.dart';

// Test frame cadence: 100 ms (10 Hz). Kept above the 1.0 s minRepDurationUs
// gate so a 25-frame sweep (~2.5 s) counts as a valid rep.
const int _dtUs = 100000;

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
      for (var i = 0; i < 3; i++) { feed(170, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { feed(170 - i * 11.0, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { feed(60 + i * 11.0, t); t += _dtUs; }
      for (var i = 0; i < 3; i++) { feed(170, t); t += _dtUs; }
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
          t += _dtUs;
        }
        for (var i = 0; i < 11; i++) {
          final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170 - i * 11.0), side: ArmSide.right);
          if (e != null) events.add(e);
          t += _dtUs;
        }
        for (var i = 0; i < 11; i++) {
          final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 11.0), side: ArmSide.right);
          if (e != null) events.add(e);
          t += _dtUs;
        }
      }
      for (var i = 0; i < 3; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right);
        if (e != null) events.add(e);
        t += _dtUs;
      }
      expect(events.whereType<RepCompleteEvent>().length, 2);
    });

    test('rejects a shallow partial (amplitude < 30°) as not-a-rep (silent drop)', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += _dtUs; }
      for (var i = 0; i < 5; i++) { _maybeAdd(events, policy, 170 - i * 5.0, t); t += _dtUs; }
      for (var i = 0; i < 5; i++) { _maybeAdd(events, policy, 150 + i * 5.0, t); t += _dtUs; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += _dtUs; }
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);
      // Below the 30° jitter floor — silent drop, no RepSuppressedEvent either.
      expect(events.whereType<RepSuppressedEvent>().toList(), isEmpty);
    });

    test('RepCompleteEvent.startAngle reflects the actual angle observed just before armed→descending (not a constant)', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      int t = 0;
      RepCompleteEvent? done;
      // Pre-rep idle below the top (e.g. 165°) — still armed because 165° > 130° threshold.
      for (var i = 0; i < 5; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(165), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += _dtUs;
      }
      // Clean curl from 165° down to 60° and back to 170°.
      for (var i = 0; i < 11; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(165 - i * 9.5), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += _dtUs;
      }
      for (var i = 0; i < 12; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 9.5), side: ArmSide.right);
        if (e is RepCompleteEvent) done = e;
        t += _dtUs;
      }
      expect(done, isNotNull);
      // 165° was the last-observed angle at armed→descending transition.
      expect(done!.startAngle, closeTo(165, 1.0));
    });

    test('reset() clears state so a subsequent sweep counts from 1', () {
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      int t = 0;
      for (var i = 0; i < 3; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right); t += _dtUs; }
      for (var i = 0; i < 11; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170 - i * 11.0), side: ArmSide.right); t += _dtUs; }
      for (var i = 0; i < 11; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(60 + i * 11.0), side: ArmSide.right); t += _dtUs; }
      for (var i = 0; i < 3; i++) { policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right); t += _dtUs; }
      policy.reset();
      final events = <RepDecisionEvent>[];
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 170 - i * 11.0, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 60 + i * 11.0, t); t += _dtUs; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += _dtUs; }
      final completes = events.whereType<RepCompleteEvent>().toList();
      expect(completes.length, 1);
      expect(completes[0].repNum, 1);
    });

    // -----------------------------------------------------------------------
    // New gate tests (§1 of 2026-04-21-mobile-rep-cue-tts.md).
    // -----------------------------------------------------------------------

    test('ROM gate: rep with 50° amplitude emits shortRom (not RepComplete)', () {
      // 170° → 120° → 170° sweep. Clears the 30° jitter floor but fails the
      // 80° ROM gate. Slower cadence (200 ms/frame) so total rep duration
      // clears the 1.0 s min-duration gate — otherwise the duration gate
      // (checked before ROM) would fire first.
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      const slowDt = 200000;
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += slowDt; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 170 - i * 5.0, t); t += slowDt; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 120 + i * 5.0, t); t += slowDt; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += slowDt; }
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);
      final suppressed = events.whereType<RepSuppressedEvent>().toList();
      expect(suppressed.length, 1);
      expect(suppressed[0].reason, RepInvalidReason.shortRom);
      expect(suppressed[0].amplitudeDeg, inInclusiveRange(45.0, 60.0));
    });

    test('min-duration gate: sub-1s rep emits tooFast', () {
      // Full 110° sweep at 20 ms/frame → ~0.5 s — fails min-duration gate.
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      const fastDt = 20000; // 50 fps
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += fastDt; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 170 - i * 11.0, t); t += fastDt; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 60 + i * 11.0, t); t += fastDt; }
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += fastDt; }
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);
      final suppressed = events.whereType<RepSuppressedEvent>().toList();
      expect(suppressed.length, 1);
      expect(suppressed[0].reason, RepInvalidReason.tooFast);
      expect(suppressed[0].durationUs, lessThan(1000000));
    });

    test('visibility gate: low-visibility frames are skipped without advancing state', () {
      // Arm starts extended, drops to 60°, but every frame during the curl
      // has elbow visibility 0.3 < minVisibility=0.5 → state machine freezes
      // in armed. No rep-start, no rep-complete.
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      for (var i = 0; i < 3; i++) {
        final e = policy.feedFrame(tUs: t, landmarks: _armAtAngle(170), side: ArmSide.right);
        if (e != null) events.add(e);
        t += _dtUs;
      }
      for (var i = 0; i < 11; i++) {
        final e = policy.feedFrame(
          tUs: t,
          landmarks: _armAtAngle(170 - i * 11.0, elbowVisibility: 0.3),
          side: ArmSide.right,
        );
        if (e != null) events.add(e);
        t += _dtUs;
      }
      expect(events, isEmpty);
    });

    test('max-duration gate: stuck mid-rep for >10s resets and emits stalled', () {
      // Drop to mid-range and stay there for >10 s of frames.
      final policy = ExtremaAmplitudeGatePolicy.bicepCurl();
      final events = <RepDecisionEvent>[];
      int t = 0;
      for (var i = 0; i < 3; i++) {
        _maybeAdd(events, policy, 170, t); t += _dtUs;
      }
      // Trigger armed→descending.
      _maybeAdd(events, policy, 100, t); t += _dtUs;
      // Hold at 100° for 110 frames × 0.1 s = 11 s.
      for (var i = 0; i < 110; i++) {
        _maybeAdd(events, policy, 100.0, t); t += _dtUs;
      }
      final suppressed = events.whereType<RepSuppressedEvent>().toList();
      expect(suppressed.length, 1);
      expect(suppressed[0].reason, RepInvalidReason.stalled);
      expect(suppressed[0].durationUs, greaterThan(10000000));
      expect(events.whereType<RepCompleteEvent>().toList(), isEmpty);

      // State reset — a fresh clean sweep after the stall should count as rep 1.
      for (var i = 0; i < 3; i++) { _maybeAdd(events, policy, 170, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 170 - i * 11.0, t); t += _dtUs; }
      for (var i = 0; i < 11; i++) { _maybeAdd(events, policy, 60 + i * 11.0, t); t += _dtUs; }
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

List<PoseLandmark> _armAtAngle(double angleDeg, {double elbowVisibility = 1.0}) {
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final landmarks = List.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  landmarks[kRightShoulder] = const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1);
  landmarks[kRightElbow] = PoseLandmark(
      x: 1, y: 0, z: 0, visibility: elbowVisibility, presence: 1);
  landmarks[kRightWrist] = PoseLandmark(
    x: 1.0 + math.cos(theta),
    y: math.sin(theta),
    z: 0,
    visibility: 1,
    presence: 1,
  );
  return landmarks;
}
