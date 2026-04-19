import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';

void main() {
  group('angleDeg', () {
    test('right angle = 90°', () {
      const a = PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1);
      const b = PoseLandmark(x: 1, y: 0, z: 0, visibility: 1, presence: 1);
      const c = PoseLandmark(x: 1, y: 1, z: 0, visibility: 1, presence: 1);
      expect(angleDeg(a, b, c), closeTo(90.0, 0.01));
    });

    test('straight line = 180°', () {
      const a = PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1);
      const b = PoseLandmark(x: 1, y: 0, z: 0, visibility: 1, presence: 1);
      const c = PoseLandmark(x: 2, y: 0, z: 0, visibility: 1, presence: 1);
      expect(angleDeg(a, b, c), closeTo(180.0, 0.01));
    });

    test('returns 0 for coincident points', () {
      const a = PoseLandmark(x: 1, y: 1, z: 0, visibility: 1, presence: 1);
      const b = PoseLandmark(x: 1, y: 1, z: 0, visibility: 1, presence: 1);
      const c = PoseLandmark(x: 2, y: 0, z: 0, visibility: 1, presence: 1);
      expect(angleDeg(a, b, c), 0.0);
    });
  });

  group('elbowAngleDeg', () {
    test('extended right arm ~180°', () {
      final landmarks = _placeholders();
      // Right shoulder at (0, 0), elbow at (0.5, 0), wrist at (1, 0).
      landmarks[kRightShoulder] = const PoseLandmark(
          x: 0, y: 0, z: 0, visibility: 1, presence: 1);
      landmarks[kRightElbow] = const PoseLandmark(
          x: 0.5, y: 0, z: 0, visibility: 1, presence: 1);
      landmarks[kRightWrist] = const PoseLandmark(
          x: 1.0, y: 0, z: 0, visibility: 1, presence: 1);
      expect(elbowAngleDeg(landmarks, ArmSide.right), closeTo(180.0, 0.01));
    });

    test('contracted right arm ~0°', () {
      final landmarks = _placeholders();
      // Wrist folded back to shoulder.
      landmarks[kRightShoulder] = const PoseLandmark(
          x: 0, y: 0, z: 0, visibility: 1, presence: 1);
      landmarks[kRightElbow] = const PoseLandmark(
          x: 0.5, y: 0, z: 0, visibility: 1, presence: 1);
      landmarks[kRightWrist] = const PoseLandmark(
          x: 0, y: 0, z: 0, visibility: 1, presence: 1);
      expect(elbowAngleDeg(landmarks, ArmSide.right), closeTo(0.0, 0.01));
    });
  });

  group('torsoPitchDeg', () {
    test('upright posture is ~0°', () {
      final landmarks = _placeholders();
      landmarks[kLeftShoulder] = const PoseLandmark(
          x: 0.4, y: 0.3, z: 0, visibility: 1, presence: 1);
      landmarks[kRightShoulder] = const PoseLandmark(
          x: 0.6, y: 0.3, z: 0, visibility: 1, presence: 1);
      landmarks[kLeftHip] = const PoseLandmark(
          x: 0.4, y: 0.7, z: 0, visibility: 1, presence: 1);
      landmarks[kRightHip] = const PoseLandmark(
          x: 0.6, y: 0.7, z: 0, visibility: 1, presence: 1);
      expect(torsoPitchDeg(landmarks).abs(), closeTo(0.0, 0.01));
    });
  });
}

List<PoseLandmark> _placeholders() => List.filled(
      33,
      const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
    );
