import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/camera/services/landmark_smoother.dart';

void main() {
  group('OneEuroLandmarkSmoother', () {
    test('passes first frame through unchanged', () {
      final s = OneEuroLandmarkSmoother();
      final frame = List<PoseLandmark>.filled(
        33,
        const PoseLandmark(x: 0.5, y: 0.5, z: 0.1, visibility: 0.9, presence: 0.9),
      );
      final out = s.smooth(frame, tUs: 0);
      expect(out.length, 33);
      expect(out[0].x, closeTo(0.5, 1e-9));
      expect(out[0].y, closeTo(0.5, 1e-9));
      expect(out[0].z, closeTo(0.1, 1e-9));
    });

    test('preserves visibility and presence unchanged (confidence, not position)', () {
      final s = OneEuroLandmarkSmoother();
      final frame = List<PoseLandmark>.filled(
        33,
        const PoseLandmark(x: 0.1, y: 0.1, z: 0.1, visibility: 0.77, presence: 0.88),
      );
      s.smooth(frame, tUs: 0);
      final jittery = List<PoseLandmark>.filled(
        33,
        const PoseLandmark(x: 0.9, y: 0.9, z: 0.9, visibility: 0.42, presence: 0.15),
      );
      final out = s.smooth(jittery, tUs: 33333);
      expect(out[0].visibility, closeTo(0.42, 1e-9));
      expect(out[0].presence, closeTo(0.15, 1e-9));
    });

    test('reduces variance of a stationary-but-jittery landmark below input variance', () {
      final s = OneEuroLandmarkSmoother();
      final rnd = math.Random(42);
      const frameUs = 33333;
      final inXs = <double>[];
      final outXs = <double>[];
      for (var i = 0; i < 120; i++) {
        final jitterX = 0.5 + (rnd.nextDouble() - 0.5) * 0.04;
        inXs.add(jitterX);
        final frame = List<PoseLandmark>.filled(
          33,
          PoseLandmark(x: jitterX, y: 0.5, z: 0.0, visibility: 1, presence: 1),
        );
        final out = s.smooth(frame, tUs: i * frameUs);
        outXs.add(out[0].x);
      }
      final inVar = _variance(inXs.skip(10).toList());
      final outVar = _variance(outXs.skip(10).toList());
      expect(outVar, lessThan(inVar * 0.25));
    });

    test('reset() clears per-landmark filter state', () {
      final s = OneEuroLandmarkSmoother();
      s.smooth(
        List<PoseLandmark>.filled(
          33,
          const PoseLandmark(x: 10, y: 10, z: 10, visibility: 1, presence: 1),
        ),
        tUs: 0,
      );
      s.reset();
      final out = s.smooth(
        List<PoseLandmark>.filled(
          33,
          const PoseLandmark(x: 3, y: 3, z: 3, visibility: 1, presence: 1),
        ),
        tUs: 0,
      );
      expect(out[0].x, closeTo(3, 1e-9));
    });
  });
}

double _variance(List<double> xs) {
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  var sum = 0.0;
  for (final x in xs) {
    final d = x - mean;
    sum += d * d;
  }
  return sum / xs.length;
}
