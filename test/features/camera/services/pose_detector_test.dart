import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/core/services/capability_tier.dart';
import 'package:bioliminal/features/camera/services/pose_detector.dart';

void main() {
  test('MediaPipePoseDetector exposes the configured assetPath and delegate', () {
    final d = MediaPipePoseDetector(
      config: const PoseConfig(
        modelAssetPath: 'assets/models/pose_landmarker_heavy.task',
        delegate: PoseDelegate.coreml,
      ),
    );
    expect(d.assetPath, 'assets/models/pose_landmarker_heavy.task');
    expect(d.delegate, PoseDelegate.coreml);
  });
}
