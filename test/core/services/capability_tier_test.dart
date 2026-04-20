import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/core/services/capability_tier.dart';

void main() {
  group('tierConfig', () {
    test('iOS high → Heavy model + CoreML delegate', () {
      final c = tierConfig(tier: CapabilityTier.high, platform: PosePlatform.iOS);
      expect(c.modelAssetPath, 'assets/models/pose_landmarker_heavy.task');
      expect(c.delegate, PoseDelegate.coreml);
    });

    test('iOS mid → Full model + CPU delegate', () {
      final c = tierConfig(tier: CapabilityTier.mid, platform: PosePlatform.iOS);
      expect(c.modelAssetPath, 'assets/models/pose_landmarker_full.task');
      expect(c.delegate, PoseDelegate.cpu);
    });

    test('iOS low → Lite model + CPU delegate', () {
      final c = tierConfig(tier: CapabilityTier.low, platform: PosePlatform.iOS);
      expect(c.modelAssetPath, 'assets/models/pose_landmarker_lite.task');
      expect(c.delegate, PoseDelegate.cpu);
    });

    test('Android mid → Full model + CPU delegate', () {
      final c = tierConfig(tier: CapabilityTier.mid, platform: PosePlatform.android);
      expect(c.modelAssetPath, 'assets/models/pose_landmarker_full.task');
      expect(c.delegate, PoseDelegate.cpu);
    });

    test('Android high → Full model + GPU delegate (Heavy not vetted on Android)', () {
      final c = tierConfig(tier: CapabilityTier.high, platform: PosePlatform.android);
      expect(c.modelAssetPath, 'assets/models/pose_landmarker_full.task');
      expect(c.delegate, PoseDelegate.gpu);
    });

    test('delegate enum serializes to the exact string the native plugins expect', () {
      expect(PoseDelegate.cpu.wireName, 'cpu');
      expect(PoseDelegate.gpu.wireName, 'gpu');
      expect(PoseDelegate.coreml.wireName, 'coreml');
    });
  });
}
