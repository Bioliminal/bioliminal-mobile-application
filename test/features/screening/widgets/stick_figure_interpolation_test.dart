import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/features/screening/data/movement_keyframes.dart';
import 'package:auralink/features/screening/widgets/stick_figure_animation.dart';

/// Helper: create a uniform PoseFrame with all joints at the same offset.
PoseFrame _uniform(double x, double y) => PoseFrame(
  head: Offset(x, y),
  leftShoulder: Offset(x, y),
  rightShoulder: Offset(x, y),
  leftElbow: Offset(x, y),
  rightElbow: Offset(x, y),
  leftWrist: Offset(x, y),
  rightWrist: Offset(x, y),
  leftHip: Offset(x, y),
  rightHip: Offset(x, y),
  leftKnee: Offset(x, y),
  rightKnee: Offset(x, y),
  leftAnkle: Offset(x, y),
  rightAnkle: Offset(x, y),
);

void main() {
  group('PoseFrame.lerp', () {
    test('t=0 returns first pose', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(1.0, 1.0);
      final result = PoseFrame.lerp(a, b, 0.0);

      for (final joint in result.all) {
        expect(joint.dx, closeTo(0.0, 1e-10));
        expect(joint.dy, closeTo(0.0, 1e-10));
      }
    });

    test('t=1 returns second pose', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(1.0, 1.0);
      final result = PoseFrame.lerp(a, b, 1.0);

      for (final joint in result.all) {
        expect(joint.dx, closeTo(1.0, 1e-10));
        expect(joint.dy, closeTo(1.0, 1e-10));
      }
    });

    test('t=0.5 returns midpoint', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(1.0, 1.0);
      final result = PoseFrame.lerp(a, b, 0.5);

      for (final joint in result.all) {
        expect(joint.dx, closeTo(0.5, 1e-10));
        expect(joint.dy, closeTo(0.5, 1e-10));
      }
    });

    test('lerp is linear across individual joints', () {
      const a = PoseFrame(
        head: Offset(0.0, 0.0),
        leftShoulder: Offset(0.2, 0.0),
        rightShoulder: Offset(0.8, 0.0),
        leftElbow: Offset(0.0, 0.2),
        rightElbow: Offset(0.0, 0.8),
        leftWrist: Offset(0.1, 0.1),
        rightWrist: Offset(0.9, 0.9),
        leftHip: Offset(0.3, 0.3),
        rightHip: Offset(0.7, 0.7),
        leftKnee: Offset(0.4, 0.4),
        rightKnee: Offset(0.6, 0.6),
        leftAnkle: Offset(0.0, 1.0),
        rightAnkle: Offset(1.0, 0.0),
      );
      final b = _uniform(1.0, 1.0);
      final result = PoseFrame.lerp(a, b, 0.25);

      // head: (0,0) -> (1,1) at t=0.25 => (0.25, 0.25)
      expect(result.head.dx, closeTo(0.25, 1e-10));
      expect(result.head.dy, closeTo(0.25, 1e-10));

      // leftShoulder: (0.2, 0) -> (1, 1) at t=0.25 => (0.4, 0.25)
      expect(result.leftShoulder.dx, closeTo(0.4, 1e-10));
      expect(result.leftShoulder.dy, closeTo(0.25, 1e-10));
    });
  });

  group('interpolateKeyframes', () {
    test('single keyframe returns that frame for any t', () {
      final frame = _uniform(0.5, 0.5);
      final result = interpolateKeyframes([frame], 0.7);

      for (final joint in result.all) {
        expect(joint.dx, closeTo(0.5, 1e-10));
        expect(joint.dy, closeTo(0.5, 1e-10));
      }
    });

    test('two keyframes: t=0 returns first, t=1 returns second', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(1.0, 1.0);

      final atZero = interpolateKeyframes([a, b], 0.0);
      final atOne = interpolateKeyframes([a, b], 1.0);

      expect(atZero.head.dx, closeTo(0.0, 1e-10));
      expect(atOne.head.dx, closeTo(1.0, 1e-10));
    });

    test('two keyframes: t=0.5 returns midpoint', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(1.0, 1.0);
      final mid = interpolateKeyframes([a, b], 0.5);

      expect(mid.head.dx, closeTo(0.5, 1e-10));
      expect(mid.head.dy, closeTo(0.5, 1e-10));
    });

    test('three keyframes distributes time evenly across two segments', () {
      final a = _uniform(0.0, 0.0);
      final b = _uniform(0.5, 0.5);
      final c = _uniform(1.0, 1.0);
      final keyframes = [a, b, c];

      // t=0.0 -> start of segment 0 -> frame a
      final at0 = interpolateKeyframes(keyframes, 0.0);
      expect(at0.head.dx, closeTo(0.0, 1e-10));

      // t=0.25 -> halfway through segment 0 -> midpoint(a, b) = 0.25
      final at25 = interpolateKeyframes(keyframes, 0.25);
      expect(at25.head.dx, closeTo(0.25, 1e-10));

      // t=0.5 -> start of segment 1 -> frame b = 0.5
      final at50 = interpolateKeyframes(keyframes, 0.5);
      expect(at50.head.dx, closeTo(0.5, 1e-10));

      // t=0.75 -> halfway through segment 1 -> midpoint(b, c) = 0.75
      final at75 = interpolateKeyframes(keyframes, 0.75);
      expect(at75.head.dx, closeTo(0.75, 1e-10));

      // t=1.0 -> end of segment 1 -> frame c = 1.0
      final at100 = interpolateKeyframes(keyframes, 1.0);
      expect(at100.head.dx, closeTo(1.0, 1e-10));
    });

    test('five keyframes (overhead squat shape) boundary values', () {
      final keyframes = [
        _uniform(0.0, 0.0),
        _uniform(0.25, 0.25),
        _uniform(0.5, 0.5),
        _uniform(0.75, 0.75),
        _uniform(1.0, 1.0),
      ];

      // 4 segments, each gets 25% of t.
      // t=0.0 -> frame 0
      expect(interpolateKeyframes(keyframes, 0.0).head.dx, closeTo(0.0, 1e-10));
      // t=0.25 -> frame 1
      expect(
        interpolateKeyframes(keyframes, 0.25).head.dx,
        closeTo(0.25, 1e-10),
      );
      // t=0.5 -> frame 2
      expect(interpolateKeyframes(keyframes, 0.5).head.dx, closeTo(0.5, 1e-10));
      // t=0.75 -> frame 3
      expect(
        interpolateKeyframes(keyframes, 0.75).head.dx,
        closeTo(0.75, 1e-10),
      );
      // t=1.0 -> frame 4
      expect(interpolateKeyframes(keyframes, 1.0).head.dx, closeTo(1.0, 1e-10));
    });

    test('real keyframe data does not crash at boundaries', () {
      final allKeyframes = [
        overheadSquatKeyframes,
        singleLegBalanceKeyframes,
        overheadReachKeyframes,
        forwardFoldKeyframes,
      ];

      for (final keyframes in allKeyframes) {
        // Sweep t from 0 to 1 in small steps.
        for (var t = 0.0; t <= 1.0; t += 0.01) {
          final pose = interpolateKeyframes(keyframes, t);
          // All joints should be in [0, 1] range.
          for (final joint in pose.all) {
            expect(joint.dx, greaterThanOrEqualTo(0.0));
            expect(joint.dx, lessThanOrEqualTo(1.0));
            expect(joint.dy, greaterThanOrEqualTo(0.0));
            expect(joint.dy, lessThanOrEqualTo(1.0));
          }
        }
      }
    });
  });
}
