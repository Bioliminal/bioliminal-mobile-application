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
      detector.addPoseFrame(t, _armAtAngle(angle));
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

  test('RepDetector emits a rep-start signal on ExtremaAmplitudeGate armed→descending', () async {
    final detector = RepDetector();
    final starts = <int>[];
    final sub = detector.onRepStart.listen((tUs) => starts.add(tUs));

    int t = 0;
    void feed(double angle) {
      detector.addPoseFrame(t, _armAtAngle(angle));
      t += 33333;
    }
    // Stationary pre-rep.
    for (var i = 0; i < 5; i++) {
      feed(170);
    }
    // Begin curl — at some frame angle drops below 130, should fire rep-start.
    for (var i = 0; i < 8; i++) {
      feed(170 - i * 11.0);
    }
    await Future<void>.delayed(Duration.zero);

    expect(starts, isNotEmpty);
    expect(starts.length, 1); // exactly one rep-start per descent
    await sub.cancel();
    await detector.dispose();
  });

  test('RepDetector surfaces suppressed events on the suppressed stream', () async {
    final detector = RepDetector();
    final suppressed = <RepSuppressedEvent>[];
    final boundaries = <RepBoundary>[];
    final subS = detector.suppressed.listen(suppressed.add);
    final subB = detector.boundaries.listen(boundaries.add);

    int t = 0;
    // 200 ms/frame so the rep's total duration clears the 1.0 s
    // min-duration gate — we want the ROM gate (not the duration gate)
    // to be the one that suppresses this rep.
    void feed(double angle) {
      detector.addPoseFrame(t, _armAtAngle(angle));
      t += 200000;
    }
    // Short-ROM rep: 170° → 120° → 170° (50° amplitude — clears jitter floor,
    // fails ROM gate).
    for (var i = 0; i < 3; i++) {
      feed(170);
    }
    for (var i = 0; i < 11; i++) {
      feed(170 - i * 5.0);
    }
    for (var i = 0; i < 11; i++) {
      feed(120 + i * 5.0);
    }
    await Future<void>.delayed(Duration.zero);

    expect(boundaries, isEmpty);
    expect(suppressed.length, 1);
    expect(suppressed[0].reason, RepInvalidReason.shortRom);

    await subS.cancel();
    await subB.cancel();
    await detector.dispose();
  });

  test('RepDetector counts two reps when the cycle repeats', () async {
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    int t = 0;
    void feed(double angle) {
      detector.addPoseFrame(t, _armAtAngle(angle));
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
}

/// Build a pose frame with the right arm at `angleDeg` and the left arm
/// parked at a resting 170°. Left is set explicitly because the dual-arm
/// [RepDetector] runs a policy per side — leaving left at (0,0,0) would
/// degenerate `elbowAngleDeg` to 0° and trip the left policy into
/// descending on frame 0.
List<PoseLandmark> _armAtAngle(double angleDeg) {
  final landmarks = List.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  _placeArm(landmarks, side: ArmSide.right, angleDeg: angleDeg, baseX: 1.0);
  _placeArm(landmarks, side: ArmSide.left, angleDeg: 170.0, baseX: -1.0);
  return landmarks;
}

void _placeArm(
  List<PoseLandmark> landmarks, {
  required ArmSide side,
  required double angleDeg,
  required double baseX,
}) {
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final sIdx = side == ArmSide.left ? kLeftShoulder : kRightShoulder;
  final eIdx = side == ArmSide.left ? kLeftElbow : kRightElbow;
  final wIdx = side == ArmSide.left ? kLeftWrist : kRightWrist;
  landmarks[sIdx] = PoseLandmark(
      x: baseX - 1.0, y: 0, z: 0, visibility: 1, presence: 1);
  landmarks[eIdx] =
      PoseLandmark(x: baseX, y: 0, z: 0, visibility: 1, presence: 1);
  landmarks[wIdx] = PoseLandmark(
    x: baseX + math.cos(theta),
    y: math.sin(theta),
    z: 0,
    visibility: 1,
    presence: 1,
  );
}
