import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bioliminal/core/providers.dart'
    show currentLandmarksProvider, landmarkSmootherProvider;
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart'
    show ArmSide;
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';
import 'package:bioliminal/features/camera/services/landmark_smoother.dart';
import 'package:bioliminal/features/bicep_curl/services/rep_detector.dart';

void main() {
  test('10s of stationary arm with ±5° landmark jitter yields ZERO false reps '
      'when smoother + ExtremaAmplitudeGate are in place', () async {
    final smoother = OneEuroLandmarkSmoother();
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    final rnd = math.Random(1234);
    for (var i = 0; i < 300; i++) {
      final angleJitter = (rnd.nextDouble() - 0.5) * 10.0;
      final frame = _armAtAngle(170.0 + angleJitter);
      final tUs = i * 33333;
      final smoothed = smoother.smooth(frame, tUs: tUs);
      detector.addPoseFrame(tUs, smoothed, ArmSide.right);
    }
    await Future<void>.delayed(Duration.zero);
    expect(boundaries, isEmpty);
    await sub.cancel();
    await detector.dispose();
  });

  test('three clean rep cycles on top of continuous jitter yield exactly three reps', () async {
    final smoother = OneEuroLandmarkSmoother();
    final detector = RepDetector();
    final boundaries = <RepBoundary>[];
    final sub = detector.boundaries.listen(boundaries.add);

    final rnd = math.Random(99);
    int t = 0;
    // 100 ms/frame cadence keeps the full 27-frame rep cycle (~2.7 s) above
    // the 1.0 s minRepDurationUs gate. Jitter semantics are independent of
    // cadence.
    void feed(double angle) {
      final jittered = angle + (rnd.nextDouble() - 0.5) * 4.0;
      final smoothed = smoother.smooth(_armAtAngle(jittered), tUs: t);
      detector.addPoseFrame(t, smoothed, ArmSide.right);
      t += 100000;
    }
    for (var rep = 0; rep < 3; rep++) {
      for (var i = 0; i < 5; i++) {
        feed(170);
      }
      for (var i = 0; i < 11; i++) {
        feed(170 - i * 11.0);
      }
      for (var i = 0; i < 11; i++) {
        feed(60 + i * 11.0);
      }
    }
    for (var i = 0; i < 5; i++) {
      feed(170);
    }
    await Future<void>.delayed(Duration.zero);
    expect(boundaries.length, 3);
    await sub.cancel();
    await detector.dispose();
  });

  test('provider graph: smoother applied to currentLandmarksProvider output', () async {
    final rawInput = <PoseLandmark>[];
    for (var i = 0; i < 33; i++) {
      rawInput.add(PoseLandmark(
        x: i == kRightShoulder ? 0.0 : (i == kRightElbow ? 1.0 : 2.0),
        y: 0, z: 0, visibility: 1, presence: 1,
      ));
    }

    final container = ProviderContainer(
      overrides: [
        currentLandmarksProvider.overrideWithValue(rawInput),
      ],
    );
    addTearDown(container.dispose);

    final smoother = container.read(landmarkSmootherProvider);
    expect(smoother, isA<OneEuroLandmarkSmoother>());

    smoother.reset();
    final out = smoother.smooth(rawInput, tUs: 0);
    expect(out.length, 33);
    expect(out[kRightElbow].x, closeTo(1.0, 1e-9));
  });

  test('smoother state does NOT leak across a reset (session restart safety)', () {
    final smoother = OneEuroLandmarkSmoother();
    for (var i = 0; i < 30; i++) {
      smoother.smooth(
        List<PoseLandmark>.filled(
          33,
          const PoseLandmark(x: 0.9, y: 0.9, z: 0.9, visibility: 1, presence: 1),
        ),
        tUs: i * 33333,
      );
    }
    smoother.reset();
    final fresh = smoother.smooth(
      List<PoseLandmark>.filled(
        33,
        const PoseLandmark(x: 0.1, y: 0.1, z: 0.1, visibility: 1, presence: 1),
      ),
      tUs: 0,
    );
    expect(fresh[0].x, closeTo(0.1, 1e-9));
  });
}

List<PoseLandmark> _armAtAngle(double angleDeg) {
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final landmarks = List.filled(33, const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1));
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
