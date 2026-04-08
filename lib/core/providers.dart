import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/domain/services/pose_estimation_service.dart'
    as pose_service;
import 'package:auralink/domain/services/angle_calculator.dart'
    as angle_service;
import 'package:auralink/domain/services/chain_mapper.dart' as chain_service;
import 'package:auralink/domain/mocks/mock_pose_estimation.dart';
import 'package:auralink/domain/mocks/mock_angle_calculator.dart';
import 'package:auralink/domain/mocks/mock_chain_mapper.dart';
import 'package:auralink/core/services/auth_service.dart';
import 'package:auralink/core/services/firestore_service.dart'
    as firestore_impl;
import 'package:auralink/core/services/local_storage_service.dart'
    as local_impl;

// Providers — mock implementations wired by default, swap for real ones.

final poseEstimationServiceProvider =
    Provider<pose_service.PoseEstimationService>(
  (ref) => MockPoseEstimationService(),
);

final angleCalculatorProvider = Provider<angle_service.AngleCalculator>(
  (ref) => MockAngleCalculator(),
);

final chainMapperProvider = Provider<chain_service.ChainMapper>(
  (ref) => MockChainMapper(),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(FirebaseAuth.instance),
);

final firestoreServiceProvider = Provider<firestore_impl.FirestoreService>(
  (ref) => firestore_impl.FirestoreService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    ref.read(authServiceProvider),
  ),
);

final localStorageServiceProvider = Provider<local_impl.LocalStorageService>(
  (ref) => local_impl.LocalStorageService(),
);
