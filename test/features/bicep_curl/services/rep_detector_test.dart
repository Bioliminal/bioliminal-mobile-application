import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';
import 'package:bioliminal/features/bicep_curl/services/rep_detector.dart';

void main() {
  test('RepDetector counts a single concentric → eccentric → reset cycle', () async {
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    int t = 0;
    void feed(double angle) {
      detector.addPoseFrame(t, _armAtAngle(angle), ArmSide.right);
      t += 100000;
    }

    for (var i = 0; i < 5; i++) {
      feed(170);
    }
    for (var i = 0; i < 11; i++) {
      feed(170 - i * 11.0);
    }
    for (var i = 0; i < 11; i++) {
      feed(60 + i * 11.0);
    }

    await Future<void>.delayed(Duration.zero);
    expect(boundaries.length, 1);
    expect(boundaries[0].repNum, 1);

    await sub.cancel();
    await detector.dispose();
  });

  test('RepDetector counts two reps when the cycle repeats', () async {
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    int t = 0;
    void feed(double angle) {
      detector.addPoseFrame(t, _armAtAngle(angle), ArmSide.right);
      t += 100000;
    }

    for (var rep = 0; rep < 2; rep++) {
      for (var i = 0; i < 3; i++) {
        feed(170);
      }
      for (var i = 0; i < 11; i++) {
        feed(170 - i * 11.0);
      }
      for (var i = 0; i < 11; i++) {
        feed(60 + i * 11.0);
      }
    }

    await Future<void>.delayed(Duration.zero);
    expect(boundaries.length, 2);
    expect(boundaries.map((b) => b.repNum).toList(), [1, 2]);

    await sub.cancel();
    await detector.dispose();
  });

  test('RepDetector drops frames below the visibility gate', () async {
    // Full ROM cycle but with every frame at visibility 0.3. State machine
    // should never advance out of armed → no boundary.
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    int t = 0;
    for (var i = 0; i < 30; i++) {
      final angle = i < 15 ? 170 - i * 7.0 : 60 + (i - 15) * 7.0;
      detector.addPoseFrame(
        t,
        _armAtAngle(angle.toDouble(), visibility: 0.3),
        ArmSide.right,
      );
      t += 100000;
    }

    await Future<void>.delayed(Duration.zero);
    expect(boundaries, isEmpty);

    await sub.cancel();
    await detector.dispose();
  });
}

/// Build a pose frame with the right shoulder/elbow/wrist arranged so the
/// elbow's interior angle equals `angleDeg`. Shoulder fixed at (0,0),
/// elbow at (1,0), wrist swings around the elbow.
List<PoseLandmark> _armAtAngle(double angleDeg, {double visibility = 1}) {
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final landmarks = List.filled(
    33,
    PoseLandmark(x: 0, y: 0, z: 0, visibility: visibility, presence: 1),
  );
  landmarks[kRightShoulder] = PoseLandmark(
      x: 0, y: 0, z: 0, visibility: visibility, presence: 1);
  landmarks[kRightElbow] = PoseLandmark(
      x: 1, y: 0, z: 0, visibility: visibility, presence: 1);
  landmarks[kRightWrist] = PoseLandmark(
    x: 1.0 + math.cos(theta),
    y: math.sin(theta),
    z: 0,
    visibility: visibility,
    presence: 1,
  );
  return landmarks;
}
