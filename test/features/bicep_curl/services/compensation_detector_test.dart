import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/services/compensation_detector.dart';
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';

/// Tests for the rebuilt pose-compensation pipeline.
///
/// The algorithm changed from "mean pose delta across all calibration
/// frames and all rep frames, OR on absolute value" to "mean across stable
/// resting frames for the reference, SIGNED PEAK across rep frames for the
/// per-rep signal." These tests exercise each shift.
void main() {
  group('CompensationDetector.buildReference', () {
    test('averages shoulder Y and torso pitch over stable resting frames',
        () {
      // Three frames where the elbow is fully extended (~180°) and
      // angular velocity is zero — all qualify as stable resting frames.
      final frames = [
        _frame(shoulderY: 0.3),
        _frame(shoulderY: 0.4),
        _frame(shoulderY: 0.5),
      ];
      final ref = CompensationDetector.buildReference(frames, ArmSide.right);
      expect(ref.shoulderYRef, closeTo(0.4, 1e-9));
      expect(ref.armSide, ArmSide.right);
      expect(ref.armSegmentLen, isNotNull);
      // Shoulder (0.6, yRef) → elbow (0.6, yRef + 0.2). Segment length = 0.2.
      expect(ref.armSegmentLen!, closeTo(0.2, 1e-9));
    });

    test('rejects frames captured mid-rep (elbow below extension gate)', () {
      // Three frames where the user was actively curling (elbow at 90°).
      // None qualify, so the reference falls back to zero with no
      // armSegmentLen — peak deltas will measure against zero and the
      // detector degrades quietly.
      final frames = [
        _frame(shoulderY: 0.3, elbowAngleDeg: 90),
        _frame(shoulderY: 0.4, elbowAngleDeg: 90),
        _frame(shoulderY: 0.5, elbowAngleDeg: 90),
      ];
      final ref = CompensationDetector.buildReference(frames, ArmSide.right);
      expect(ref.shoulderYRef, 0.0);
      expect(ref.torsoPitchDegRef, 0.0);
      expect(ref.armSegmentLen, isNull);
    });

    test('rejects frames where the arm is moving (angular velocity gate)', () {
      // Extended-elbow frames but angles differ by 5°/frame — far above
      // the 2°/frame stationary threshold. No qualifying run.
      final frames = [
        _frame(shoulderY: 0.3, elbowAngleDeg: 170),
        _frame(shoulderY: 0.4, elbowAngleDeg: 175),
        _frame(shoulderY: 0.5, elbowAngleDeg: 180),
      ];
      final ref = CompensationDetector.buildReference(frames, ArmSide.right);
      expect(ref.armSegmentLen, isNull);
    });

    test('accepts mid-calibration extended+stationary frames only', () {
      // Simulated calibration rep: 3 stable frames at the top, a dip
      // through a concentric (elbow bends), then 3 more stable frames.
      // The 6 stable frames should land in the reference; the 3 concentric
      // frames should be filtered out.
      final frames = <List<PoseLandmark>>[
        _frame(shoulderY: 0.30, elbowAngleDeg: 178),
        _frame(shoulderY: 0.30, elbowAngleDeg: 178),
        _frame(shoulderY: 0.30, elbowAngleDeg: 178),
        _frame(shoulderY: 0.30, elbowAngleDeg: 60), // mid-rep
        _frame(shoulderY: 0.30, elbowAngleDeg: 60),
        _frame(shoulderY: 0.30, elbowAngleDeg: 60),
        _frame(shoulderY: 0.40, elbowAngleDeg: 178),
        _frame(shoulderY: 0.40, elbowAngleDeg: 178),
        _frame(shoulderY: 0.40, elbowAngleDeg: 178),
      ];
      final ref = CompensationDetector.buildReference(frames, ArmSide.right);
      // Mean over the 6 stable frames (3 at 0.30, 3 at 0.40) = 0.35.
      expect(ref.shoulderYRef, closeTo(0.35, 1e-9));
    });

    test('degrades to zero-drift reference when no frames qualify', () {
      final ref = CompensationDetector.buildReference(
        const <List<PoseLandmark>>[],
        ArmSide.right,
      );
      expect(ref.shoulderYRef, 0.0);
      expect(ref.torsoPitchDegRef, 0.0);
      expect(ref.armSegmentLen, isNull);
    });
  });

  group('CompensationDetector.computePerRepDeltas', () {
    test('peakShoulderRiseDeg is signed — shoulder hike is positive', () {
      final ref = _referenceWith(shoulderYRef: 0.30, armSegmentLen: 0.20);
      // Rep frames: shoulder dips to 0.22 mid-rep (Y DECREASED, i.e. moved
      // UP in image coordinates). Rise = 0.30 - 0.22 = 0.08, normalized
      // over 0.20 segment = 0.4 → asin(0.4) * 180/pi ≈ 23.6°.
      final frames = [
        _frame(shoulderY: 0.30),
        _frame(shoulderY: 0.22),
        _frame(shoulderY: 0.30),
      ];
      final result = CompensationDetector.computePerRepDeltas(
        frames,
        ArmSide.right,
        ref,
      );
      expect(result.peakShoulderRiseDeg,
          closeTo(math.asin(0.4) * 180 / math.pi, 1e-6));
      expect(result.peakShoulderRiseDeg, greaterThan(0));
    });

    test('peakShoulderRiseDeg is negative when the user SLUMPS', () {
      final ref = _referenceWith(shoulderYRef: 0.30, armSegmentLen: 0.20);
      // Shoulder drops to 0.38 — shoulder moved DOWN in image coordinates.
      // Peak "rise" is the most positive value across the rep; with every
      // frame lower than reference, the peak is still the LEAST NEGATIVE
      // delta (frame 0.30 → rise = 0°; frame 0.38 → rise < 0°), so peak = 0°.
      final frames = [
        _frame(shoulderY: 0.38),
        _frame(shoulderY: 0.36),
        _frame(shoulderY: 0.38),
      ];
      final result = CompensationDetector.computePerRepDeltas(
        frames,
        ArmSide.right,
        ref,
      );
      // Signed peak is computed off MIN shoulderY (0.36). refY - min = -0.06
      // → asin(-0.3) ≈ -17.5°. Negative = user slumped; detector won't fire.
      expect(result.peakShoulderRiseDeg,
          closeTo(math.asin(-0.3) * 180 / math.pi, 1e-6));
      expect(result.peakShoulderRiseDeg, lessThan(0));
    });

    test('peakForwardLeanDeg is the MAX pitch across the rep minus ref', () {
      final ref = _referenceWith(
        shoulderYRef: 0.30,
        armSegmentLen: 0.20,
        torsoPitchDegRef: 2.0,
      );
      // Three frames with different torso pitches. Peak forward lean
      // should be max(pitch) - refPitch = 18 - 2 = 16°.
      final frames = [
        _frame(shoulderY: 0.30, torsoPitchDeg: 3.0),
        _frame(shoulderY: 0.30, torsoPitchDeg: 18.0),
        _frame(shoulderY: 0.30, torsoPitchDeg: 5.0),
      ];
      final result = CompensationDetector.computePerRepDeltas(
        frames,
        ArmSide.right,
        ref,
      );
      expect(result.peakForwardLeanDeg, closeTo(16.0, 1e-6));
      expect(result.series.length, 3);
    });

    test('zero scale when reference has no armSegmentLen', () {
      final ref = _referenceWith(shoulderYRef: 0.30, armSegmentLen: null);
      final frames = [_frame(shoulderY: 0.22)];
      final result = CompensationDetector.computePerRepDeltas(
        frames,
        ArmSide.right,
        ref,
      );
      // No scale means we can't convert y-delta to degrees honestly — the
      // detector fails quiet (0°) rather than fabricating a spurious peak.
      expect(result.peakShoulderRiseDeg, 0.0);
    });

    test('empty frame list returns zero peaks', () {
      final ref = _referenceWith(shoulderYRef: 0.30, armSegmentLen: 0.20);
      final result = CompensationDetector.computePerRepDeltas(
        const <List<PoseLandmark>>[],
        ArmSide.right,
        ref,
      );
      expect(result.series, isEmpty);
      expect(result.peakShoulderRiseDeg, 0.0);
      expect(result.peakForwardLeanDeg, 0.0);
    });
  });

  group('PoseDelta.exceedsThresholds', () {
    const intermediate = CompensationThresholds(
      shoulderDriftDeg: 14.0,
      torsoPitchDeltaDeg: 20.0,
    );

    test('fires when shoulder rise crosses the threshold (positive)', () {
      const delta = PoseDelta(
        shoulderDriftDeg: 15.0,
        torsoPitchDeltaDeg: 0.0,
      );
      expect(delta.exceedsThresholds(intermediate), isTrue);
    });

    test('does NOT fire on a large negative shoulder delta (slump)', () {
      // A user slumping is not mid-curl compensation. The signed threshold
      // keeps this off even though the magnitude would have fired the old
      // abs()-based gate.
      const delta = PoseDelta(
        shoulderDriftDeg: -30.0,
        torsoPitchDeltaDeg: 0.0,
      );
      expect(delta.exceedsThresholds(intermediate), isFalse);
    });

    test('does NOT fire on a large negative torso delta (back lean)', () {
      const delta = PoseDelta(
        shoulderDriftDeg: 0.0,
        torsoPitchDeltaDeg: -25.0,
      );
      expect(delta.exceedsThresholds(intermediate), isFalse);
    });

    test('fires when EITHER signal exceeds independently', () {
      const shoulderOnly = PoseDelta(
        shoulderDriftDeg: 16.0,
        torsoPitchDeltaDeg: -5.0,
      );
      const torsoOnly = PoseDelta(
        shoulderDriftDeg: -5.0,
        torsoPitchDeltaDeg: 25.0,
      );
      expect(shoulderOnly.exceedsThresholds(intermediate), isTrue);
      expect(torsoOnly.exceedsThresholds(intermediate), isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Fixture builders
// ---------------------------------------------------------------------------

CompensationReference _referenceWith({
  required double shoulderYRef,
  required double? armSegmentLen,
  double torsoPitchDegRef = 0.0,
}) =>
    CompensationReference(
      shoulderYRef: shoulderYRef,
      torsoPitchDegRef: torsoPitchDegRef,
      armSide: ArmSide.right,
      armSegmentLen: armSegmentLen,
    );

/// Builds a pose frame where the right shoulder is at (0.6, `shoulderY`)
/// and the right elbow is placed so the resulting elbow angle approximates
/// `elbowAngleDeg`. Left shoulder/hip are placed to produce `torsoPitchDeg`
/// for the trunk. Z/visibility fixed at 1 for the full frame.
List<PoseLandmark> _frame({
  required double shoulderY,
  double elbowAngleDeg = 180.0,
  double torsoPitchDeg = 0.0,
}) {
  final landmarks = List<PoseLandmark>.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  const armLen = 0.2;

  // Right shoulder.
  landmarks[kRightShoulder] = PoseLandmark(
    x: 0.6,
    y: shoulderY,
    z: 0,
    visibility: 1,
    presence: 1,
  );

  // Right elbow: anchored directly below the shoulder (arm hanging down) at
  // elbowAngleDeg = 180 (straight). For angles < 180, bend the forearm
  // toward the body so the interior angle at the elbow matches. Tests
  // primarily exercise the stable-extended case; the bent case just needs
  // to flunk the stable-frame gate, so the exact geometry at < 150° isn't
  // load-bearing.
  if (elbowAngleDeg >= 179.9) {
    landmarks[kRightElbow] = PoseLandmark(
      x: 0.6,
      y: shoulderY + armLen,
      z: 0,
      visibility: 1,
      presence: 1,
    );
    landmarks[kRightWrist] = PoseLandmark(
      x: 0.6,
      y: shoulderY + armLen * 2,
      z: 0,
      visibility: 1,
      presence: 1,
    );
  } else {
    // Bent elbow: wrist rotated inward so the elbow's interior angle is
    // roughly elbowAngleDeg. Cheap approximation — we only need the gate
    // check `angle < 150` to evaluate correctly.
    final theta = elbowAngleDeg * math.pi / 180.0;
    landmarks[kRightElbow] = PoseLandmark(
      x: 0.6,
      y: shoulderY + armLen,
      z: 0,
      visibility: 1,
      presence: 1,
    );
    landmarks[kRightWrist] = PoseLandmark(
      x: 0.6 - armLen * math.sin(math.pi - theta),
      y: shoulderY + armLen + armLen * math.cos(math.pi - theta),
      z: 0,
      visibility: 1,
      presence: 1,
    );
  }

  // Torso — mid-shoulder at x=0.5, mid-hip offset by torso pitch.
  landmarks[kLeftShoulder] = PoseLandmark(
    x: 0.4,
    y: shoulderY,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  // For a small pitch angle, hips sit at (0.5 + tan(pitch)*trunkLen,
  // shoulderY + trunkLen). Using trunkLen=0.4.
  const trunkLen = 0.4;
  final dx = math.tan(torsoPitchDeg * math.pi / 180.0) * trunkLen;
  landmarks[kLeftHip] = PoseLandmark(
    x: 0.4 + dx,
    y: shoulderY + trunkLen,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  landmarks[kRightHip] = PoseLandmark(
    x: 0.6 + dx,
    y: shoulderY + trunkLen,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  return landmarks;
}
