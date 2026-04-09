import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/domain/services/pose_estimation_service.dart'
    as pose_service;
import 'package:auralink/domain/services/angle_calculator.dart'
    as angle_service;
import 'package:auralink/domain/services/chain_mapper.dart' as chain_service;
import 'package:auralink/domain/mocks/mock_pose_estimation.dart';
import 'package:auralink/domain/services/rule_based_angle_calculator.dart';
import 'package:auralink/domain/services/rule_based_chain_mapper.dart';
import 'package:auralink/core/services/auth_service.dart';
import 'package:auralink/core/services/firestore_service.dart'
    as firestore_impl;
import 'package:auralink/core/services/local_storage_service.dart'
    as local_impl;

// Re-export camera providers so screening can import from one place.
export 'package:auralink/features/camera/controllers/camera_controller.dart'
    show currentLandmarksProvider, appCameraControllerProvider;

// ---------------------------------------------------------------------------
// Cloud sync opt-in toggle — false by default (offline-first).
// ---------------------------------------------------------------------------

class CloudSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void enable() => state = true;
  void disable() => state = false;
}

final cloudSyncEnabledProvider =
    NotifierProvider<CloudSyncNotifier, bool>(CloudSyncNotifier.new);

// ---------------------------------------------------------------------------
// Core providers — always available, offline-first.
// ---------------------------------------------------------------------------

final poseEstimationServiceProvider =
    Provider<pose_service.PoseEstimationService>(
  (ref) => MockPoseEstimationService(),
);

final angleCalculatorProvider = Provider<angle_service.AngleCalculator>(
  (ref) => RuleBasedAngleCalculator(),
);

final chainMapperProvider = Provider<chain_service.ChainMapper>(
  (ref) => RuleBasedChainMapper(),
);

final localStorageServiceProvider = Provider<local_impl.LocalStorageService>(
  (ref) => local_impl.LocalStorageService(),
);

// ---------------------------------------------------------------------------
// Cloud-only providers — throw when cloud sync is disabled.
// Only instantiated when the user explicitly opts into cloud backup.
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>(
  (ref) {
    if (!ref.watch(cloudSyncEnabledProvider)) {
      throw StateError(
        'AuthService is unavailable — cloud sync is disabled. '
        'Enable cloud sync in settings before accessing auth.',
      );
    }
    return AuthService.withFirebase();
  },
);

final firestoreServiceProvider = Provider<firestore_impl.FirestoreService>(
  (ref) {
    if (!ref.watch(cloudSyncEnabledProvider)) {
      throw StateError(
        'FirestoreService is unavailable — cloud sync is disabled. '
        'Enable cloud sync in settings before accessing Firestore.',
      );
    }
    return firestore_impl.FirestoreService.withFirebase(
      ref.read(authServiceProvider),
    );
  },
);
