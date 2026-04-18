import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/services/compensation_detector.dart';
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';

void main() {
  group('CompensationDetector', () {
    test('buildReference averages shoulder Y and torso pitch', () {
      final f1 = _frameWithRightShoulder(0.3);
      final f2 = _frameWithRightShoulder(0.4);
      final f3 = _frameWithRightShoulder(0.5);
      final ref = CompensationDetector.buildReference(
        [f1, f2, f3],
        ArmSide.right,
      );
      expect(ref.shoulderYRef, closeTo(0.4, 1e-9));
      expect(ref.armSide, ArmSide.right);
    });

    test('computeDelta produces shoulder drift in degrees', () {
      const ref = CompensationReference(
        shoulderYRef: 0.4,
        torsoPitchDegRef: 0.0,
        armSide: ArmSide.right,
      );
      // Shoulder rose 0.04 normalized units → ~7° at the conversion factor.
      final frame = _frameWithRightShoulder(0.36);
      final delta = CompensationDetector.computeDelta(frame, ref);
      expect(delta.shoulderDriftDeg, closeTo(-7.0, 0.01));
    });

    test('exceedsThresholds true when drift past intermediate threshold', () {
      final delta = const PoseDelta(
        shoulderDriftDeg: 9.0,
        torsoPitchDeltaDeg: 0.0,
      );
      final intermediate = const CompensationThresholds(
        shoulderDriftDeg: 7.0,
        torsoPitchDeltaDeg: 10.0,
      );
      expect(delta.exceedsThresholds(intermediate), isTrue);
    });

    test('exceedsThresholds false when within band', () {
      final delta = const PoseDelta(
        shoulderDriftDeg: 5.0,
        torsoPitchDeltaDeg: 8.0,
      );
      final intermediate = const CompensationThresholds(
        shoulderDriftDeg: 7.0,
        torsoPitchDeltaDeg: 10.0,
      );
      expect(delta.exceedsThresholds(intermediate), isFalse);
    });
  });
}

List<PoseLandmark> _frameWithRightShoulder(double y) {
  final landmarks = List.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  landmarks[kRightShoulder] =
      PoseLandmark(x: 0.6, y: y, z: 0, visibility: 1, presence: 1);
  landmarks[kLeftShoulder] = const PoseLandmark(
      x: 0.4, y: 0.3, z: 0, visibility: 1, presence: 1);
  landmarks[kLeftHip] = const PoseLandmark(
      x: 0.4, y: 0.7, z: 0, visibility: 1, presence: 1);
  landmarks[kRightHip] = const PoseLandmark(
      x: 0.6, y: 0.7, z: 0, visibility: 1, presence: 1);
  return landmarks;
}
