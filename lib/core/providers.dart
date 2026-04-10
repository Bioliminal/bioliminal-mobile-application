import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/domain/services/pose_estimation_service.dart'
    as pose_service;
import 'package:auralink/domain/services/angle_calculator.dart'
    as angle_service;
import 'package:auralink/domain/services/chain_mapper.dart' as chain_service;
import 'package:auralink/domain/mocks/mock_pose_estimation.dart';
import 'package:auralink/domain/services/mlkit_pose_estimation_service.dart';
import 'package:auralink/domain/services/rule_based_angle_calculator.dart';
import 'package:auralink/domain/services/rule_based_chain_mapper.dart';
import 'package:auralink/core/services/auth_service.dart';
import 'package:auralink/core/services/firestore_service.dart'
    as firestore_impl;
import 'package:auralink/core/services/local_storage_service.dart'
    as local_impl;

// Re-export camera providers so screening can import from one place.
export 'package:auralink/features/camera/controllers/camera_controller.dart'
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

final cloudSyncEnabledProvider =
    NotifierProvider<CloudSyncNotifier, bool>(CloudSyncNotifier.new);

// ---------------------------------------------------------------------------
// AI Engine Selection — persist in-memory for this session (can extend to local storage).
// ---------------------------------------------------------------------------

class AIModelNotifier extends Notifier<String> {
  @override
  String build() => 'Pose Detection v2';
  void set(String model) => state = model;
}

final selectedAIModelProvider =
    NotifierProvider<AIModelNotifier, String>(AIModelNotifier.new);

// ---------------------------------------------------------------------------
// User Profile — In-memory for now, could link to auth/firestore.
// ---------------------------------------------------------------------------

class UserProfile {
  final String name;
  final String email;
  final DateTime memberSince;
  final int totalScans;

  UserProfile({
    required this.name,
    required this.email,
    required this.memberSince,
    required this.totalScans,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    int? totalScans,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      memberSince: memberSince,
      totalScans: totalScans ?? this.totalScans,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return UserProfile(
      name: 'Guest User',
      email: 'guest.user@example.com',
      memberSince: DateTime(2026, 4, 1),
      totalScans: 12,
    );
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void updateEmail(String email) => state = state.copyWith(email: email);
  void incrementScans() => state = state.copyWith(totalScans: state.totalScans + 1);
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

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
    Provider<pose_service.PoseEstimationService>(
  (ref) {
    if (ref.watch(useMockPoseServiceProvider)) {
      return MockPoseEstimationService();
    }
    final cam = ref.watch(cameraDescriptionProvider);
    return MlKitPoseEstimationService(
      sensorOrientation: cam?.sensorOrientation ?? 0,
      lensDirection: cam?.lensDirection ?? CameraLensDirection.back,
    );
  },
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
