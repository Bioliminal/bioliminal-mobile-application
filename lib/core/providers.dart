import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/core/services/auth_service.dart';
import 'package:bioliminal/core/services/capability_tier.dart';
import 'package:bioliminal/core/services/local_storage_service.dart'
    as local_impl;
import 'package:bioliminal/core/services/bioliminal_client.dart';
import 'package:bioliminal/features/camera/services/landmark_smoother.dart';
import 'package:bioliminal/features/camera/services/pose_detector.dart';

// Re-export camera providers so screening can import from one place.
export 'package:bioliminal/features/camera/controllers/camera_controller.dart'
    show
        currentLandmarksProvider,
        appCameraControllerProvider,
        CameraState,
        CameraReady,
        CameraStreaming,
        CameraPermissionDenied,
        CameraError,
        CameraUninitialized;

// Re-export capability/config types so consumers import from one place.
export 'package:bioliminal/core/services/capability_tier.dart'
    show CapabilityTier, PoseConfig, PoseDelegate, PosePlatform,
         deviceCapabilityProvider, poseConfigProvider;

// ---------------------------------------------------------------------------
// Cloud sync opt-in toggle — false by default (offline-first).
// ---------------------------------------------------------------------------

class CloudSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void enable() => state = true;
  void disable() => state = false;
}

final cloudSyncEnabledProvider = NotifierProvider<CloudSyncNotifier, bool>(
  CloudSyncNotifier.new,
);

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final isPremiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

// ---------------------------------------------------------------------------
// User Profile — derived from FirebaseAuth. Null when guest / anonymous.
// ---------------------------------------------------------------------------

class UserProfile {
  final String name;
  final String email;
  final DateTime memberSince;

  const UserProfile({
    required this.name,
    required this.email,
    required this.memberSince,
  });
}

// ---------------------------------------------------------------------------
// Core providers — always available, offline-first.
// ---------------------------------------------------------------------------

class CameraDescriptionNotifier extends Notifier<CameraDescription?> {
  @override
  CameraDescription? build() => null;
  void set(CameraDescription description) => state = description;
}

final cameraDescriptionProvider =
    NotifierProvider<CameraDescriptionNotifier, CameraDescription?>(
      CameraDescriptionNotifier.new,
    );

final poseDetectorProvider = Provider<PoseDetector>((ref) {
  final config = ref.watch(poseConfigProvider);
  final detector = MediaPipePoseDetector(config: config);
  ref.onDispose(() => detector.dispose());
  return detector;
});

final landmarkSmootherProvider = Provider<LandmarkSmoother>((ref) {
  final smoother = OneEuroLandmarkSmoother();
  ref.onDispose(smoother.reset);
  return smoother;
});

final localStorageServiceProvider = Provider<local_impl.LocalStorageService>(
  (ref) => local_impl.LocalStorageService(),
);

final bioliminalClientProvider = Provider<BioliminalClient>((ref) {
  final client = BioliminalClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// ---------------------------------------------------------------------------
// Hardware Setup State (EMG — out of scope for the analysis-server
// integration; kept so the existing hardware pairing flow continues to build).
// ---------------------------------------------------------------------------

class UseHardwareModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  set value(bool v) => state = v;
}

final useHardwareModeProvider = NotifierProvider<UseHardwareModeNotifier, bool>(
  UseHardwareModeNotifier.new,
);

enum HardwareSetupStep { scanning, placing, syncing, ready }

class HardwareSetupStepNotifier extends Notifier<HardwareSetupStep> {
  @override
  HardwareSetupStep build() => HardwareSetupStep.scanning;
  set value(HardwareSetupStep v) => state = v;
}

final hardwareSetupStepProvider =
    NotifierProvider<HardwareSetupStepNotifier, HardwareSetupStep>(
      HardwareSetupStepNotifier.new,
    );

class HardwareSyncOffsetNotifier extends Notifier<int> {
  @override
  int build() => 0;
  set value(int v) => state = v;
}

final hardwareSyncOffsetProvider =
    NotifierProvider<HardwareSyncOffsetNotifier, int>(
      HardwareSyncOffsetNotifier.new,
    );

// ---------------------------------------------------------------------------
// Cloud-only providers — throw when cloud sync is disabled.
// Only instantiated when the user explicitly opts into cloud backup.
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService?>((ref) {
  if (!ref.watch(cloudSyncEnabledProvider)) {
    return null;
  }
  return AuthService.withFirebase();
});

/// Streams the current user profile, rebuilding on sign-in, sign-out, or
/// profile updates (displayName, email). Null when the user is a guest or
/// signed in anonymously.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(authServiceProvider);
  if (auth == null) return Stream.value(null);

  return auth.userChanges.map((user) {
    if (user == null || user.isAnonymous) return null;
    return UserProfile(
      name: user.displayName ?? user.email ?? 'User',
      email: user.email ?? '',
      memberSince: user.metadata.creationTime ?? DateTime.now(),
    );
  });
});

/// True when the user has a real (non-anonymous) account.
final isSignedInProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.asData?.value != null;
});

/// Count of session records for display on the profile view.
final sessionCountProvider = FutureProvider<int>((ref) async {
  final records = await ref
      .watch(localStorageServiceProvider)
      .listSessionRecords();
  return records.length;
});
