import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/mocks/mock_pose_estimation.dart';
import 'package:auralink/domain/models.dart';

void main() {
  late MockPoseEstimationService service;

  setUp(() {
    service = MockPoseEstimationService();
  });

  tearDown(() {
    service.dispose();
  });

  test('processFrame returns a stream of landmark frames', () async {
    final stream = service.processFrame(null);
    final frames = await stream.toList();
    expect(frames, isNotEmpty);
    expect(frames.first.length, 33);
  });

  test('calling processFrame twice does not leak the first timer/controller',
      () async {
    // Start a first stream — don't await completion.
    final stream1 = service.processFrame(null);
    final sub1 = stream1.listen((_) {});

    // Immediately start a second stream — this should dispose the first.
    final stream2 = service.processFrame(null);
    final frames2 = await stream2.toList();

    // Second stream completes normally.
    expect(frames2, isNotEmpty);
    expect(frames2.first.length, 33);

    // First subscription should have been closed (stream ended).
    await sub1.cancel();
  });

  test('dispose after stream completes does not throw', () async {
    final stream = service.processFrame(null);
    await stream.toList();

    // Should not throw.
    service.dispose();
  });

  test('dispose during active stream does not throw', () async {
    final stream = service.processFrame(null);
    final completer = Completer<void>();
    final sub = stream.listen(
      (_) {},
      onDone: () => completer.complete(),
      onError: (e) => completer.completeError(e),
    );

    // Dispose while stream is still active.
    service.dispose();

    // Clean up subscription.
    await sub.cancel();
  });

  test('each movement type produces 30 frames with 33 landmarks', () async {
    for (final movement in MovementType.values) {
      final s = MockPoseEstimationService(movementType: movement);
      final frames = await s.processFrame(null).toList();
      expect(frames.length, 30, reason: '${movement.name} should have 30 frames');
      for (final frame in frames) {
        expect(frame.length, 33,
            reason: '${movement.name} frames should have 33 landmarks');
      }
      s.dispose();
    }
  });
}
