import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/domain/services/pose_estimation_service.dart'
    as pose_service;
import 'package:bioliminal/domain/services/angle_calculator.dart'
    as angle_service;
import 'package:bioliminal/domain/services/chain_mapper.dart' as chain_service;
import 'package:bioliminal/domain/mocks/mock_pose_estimation.dart';
import 'package:bioliminal/domain/services/mlkit_pose_estimation_service.dart';
import 'package:bioliminal/domain/services/rule_based_angle_calculator.dart';
import 'package:bioliminal/domain/services/rule_based_chain_mapper.dart';
import 'package:bioliminal/core/services/auth_service.dart';
import 'package:bioliminal/core/services/firestore_service.dart'
    as firestore_impl;
import 'package:bioliminal/core/services/local_storage_service.dart'
    as local_impl;
import 'package:bioliminal/core/services/bioliminal_client.dart';
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
// AI Engine Selection — persist in-memory for this session (can extend to local storage).
// ---------------------------------------------------------------------------

class AIModelNotifier extends Notifier<String> {
  @override
  String build() => 'Pose Detection v2';
  void set(String model) => state = model;
}

final selectedAIModelProvider = NotifierProvider<AIModelNotifier, String>(
  AIModelNotifier.new,
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

final useMockPoseServiceProvider = Provider<bool>((ref) => false);

class CameraDescriptionNotifier extends Notifier<CameraDescription?> {
  @override
  CameraDescription? build() => null;
  void set(CameraDescription description) => state = description;
}

final cameraDescriptionProvider =
    NotifierProvider<CameraDescriptionNotifier, CameraDescription?>(
      CameraDescriptionNotifier.new,
    );

final poseEstimationServiceProvider =
    Provider<pose_service.PoseEstimationService>((ref) {
      if (ref.watch(useMockPoseServiceProvider)) {
        return MockPoseEstimationService();
      }
      final cam = ref.watch(cameraDescriptionProvider);
      return MlKitPoseEstimationService(
        sensorOrientation: cam?.sensorOrientation ?? 0,
        lensDirection: cam?.lensDirection ?? CameraLensDirection.back,
      );
    });

final poseDetectorProvider = Provider<PoseDetector>((ref) {
  final detector = MediaPipePoseDetector();
  ref.onDispose(() => detector.dispose());
  return detector;
});

final angleCalculatorProvider = Provider<angle_service.AngleCalculator>(
  (ref) => RuleBasedAngleCalculator(),
);

final chainMapperProvider = Provider<chain_service.ChainMapper>(
  (ref) => RuleBasedChainMapper(),
);

final localStorageServiceProvider = Provider<local_impl.LocalStorageService>(
  (ref) => local_impl.LocalStorageService(),
);

final bioliminalClientProvider = Provider<BioliminalClient>((ref) {
  final client = BioliminalClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// ---------------------------------------------------------------------------
// Hardware Setup State
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

final firestoreServiceProvider = Provider<firestore_impl.FirestoreService?>((
  ref,
) {
  if (!ref.watch(cloudSyncEnabledProvider)) {
    return null;
  }
  final auth = ref.watch(authServiceProvider);
  if (auth == null) return null;
  return firestore_impl.FirestoreService.withFirebase(auth);
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

/// Count of assessments for display on the profile view.
final assessmentCountProvider = FutureProvider<int>((ref) async {
  final assessments = await ref
      .watch(localStorageServiceProvider)
      .listAssessments();
  return assessments.length;
});
