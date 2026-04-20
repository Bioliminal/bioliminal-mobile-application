import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CapabilityTier { low, mid, high }

enum PosePlatform { android, iOS }

enum PoseDelegate {
  cpu('cpu'),
  gpu('gpu'),
  coreml('coreml');

  const PoseDelegate(this.wireName);
  final String wireName;
}

class PoseConfig {
  const PoseConfig({required this.modelAssetPath, required this.delegate});
  final String modelAssetPath;
  final PoseDelegate delegate;
}

PoseConfig tierConfig({required CapabilityTier tier, required PosePlatform platform}) {
  if (platform == PosePlatform.iOS) {
    switch (tier) {
      case CapabilityTier.high:
        return const PoseConfig(
          modelAssetPath: 'assets/models/pose_landmarker_heavy.task',
          delegate: PoseDelegate.coreml,
        );
      case CapabilityTier.mid:
        return const PoseConfig(
          modelAssetPath: 'assets/models/pose_landmarker_full.task',
          delegate: PoseDelegate.cpu,
        );
      case CapabilityTier.low:
        return const PoseConfig(
          modelAssetPath: 'assets/models/pose_landmarker_lite.task',
          delegate: PoseDelegate.cpu,
        );
    }
  }
  switch (tier) {
    case CapabilityTier.high:
      return const PoseConfig(
        modelAssetPath: 'assets/models/pose_landmarker_full.task',
        delegate: PoseDelegate.gpu,
      );
    case CapabilityTier.mid:
      return const PoseConfig(
        modelAssetPath: 'assets/models/pose_landmarker_full.task',
        delegate: PoseDelegate.cpu,
      );
    case CapabilityTier.low:
      return const PoseConfig(
        modelAssetPath: 'assets/models/pose_landmarker_lite.task',
        delegate: PoseDelegate.cpu,
      );
  }
}

PosePlatform currentPosePlatform() {
  try {
    if (Platform.isIOS) return PosePlatform.iOS;
  } catch (_) {
    // Platform not available in pure-Dart test host.
  }
  return PosePlatform.android;
}

final deviceCapabilityProvider = Provider<CapabilityTier>((ref) {
  return currentPosePlatform() == PosePlatform.iOS
      ? CapabilityTier.high
      : CapabilityTier.mid;
});

final poseConfigProvider = Provider<PoseConfig>((ref) {
  final tier = ref.watch(deviceCapabilityProvider);
  return tierConfig(tier: tier, platform: currentPosePlatform());
});
