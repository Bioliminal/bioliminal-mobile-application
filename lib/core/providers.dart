import 'package:flutter_riverpod/flutter_riverpod.dart';

// Service interfaces — downstream stories provide concrete implementations.

abstract class PoseEstimationService {}

abstract class AngleCalculator {}

abstract class ChainMapper {}

abstract class FirestoreService {}

abstract class AuthService {}

abstract class LocalStorageService {}

// Providers — each throws until the owning story overrides it.

final poseEstimationServiceProvider = Provider<PoseEstimationService>(
  (ref) => throw UnimplementedError('Provided by camera pipeline story'),
);

final angleCalculatorProvider = Provider<AngleCalculator>(
  (ref) => throw UnimplementedError('Provided by logic engine story'),
);

final chainMapperProvider = Provider<ChainMapper>(
  (ref) => throw UnimplementedError('Provided by logic engine story'),
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => throw UnimplementedError('Provided by data persistence story'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('Provided by data persistence story'),
);

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => throw UnimplementedError('Provided by data persistence story'),
);
