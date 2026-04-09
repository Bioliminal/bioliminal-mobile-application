import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../../../domain/mocks/mock_pose_estimation.dart';
import '../../../domain/services/angle_calculator.dart';
import '../../../domain/services/chain_mapper.dart';
import '../../../core/providers.dart' as core_providers;
import '../models/movement.dart';

// ---------------------------------------------------------------------------
// ScreeningState — sealed class covering the full screening lifecycle
// ---------------------------------------------------------------------------

sealed class ScreeningState {
  const ScreeningState();
}

class ScreeningSetup extends ScreeningState {
  const ScreeningSetup();
}

class ActiveMovement extends ScreeningState {
  const ActiveMovement({
    required this.movementIndex,
    required this.config,
    required this.repsCompleted,
    required this.remaining,
    required this.capturedFrames,
    required this.movementCompensations,
  });

  final int movementIndex;
  final MovementConfig config;
  final int repsCompleted;
  final Duration remaining;
  final List<List<Landmark>> capturedFrames;
  final List<Compensation> movementCompensations;
}

class ShowingFindings extends ScreeningState {
  const ShowingFindings({
    required this.completedMovementIndex,
    required this.findings,
    required this.feedbackMessage,
  });

  final int completedMovementIndex;
  final List<Compensation> findings;
  final String feedbackMessage;
}

class ScreeningComplete extends ScreeningState {
  const ScreeningComplete({required this.assessment});

  final Assessment assessment;
}

// ---------------------------------------------------------------------------
// ScreeningController
// ---------------------------------------------------------------------------

class ScreeningController extends StateNotifier<ScreeningState> {
  ScreeningController({
    required AngleCalculator angleCalculator,
    required ChainMapper chainMapper,
  })  : _angleCalculator = angleCalculator,
        _chainMapper = chainMapper,
        super(const ScreeningSetup());

  final AngleCalculator _angleCalculator;
  final ChainMapper _chainMapper;

  // Internal tracking state
  final List<double> _angleHistory = [];
  final List<List<Landmark>> _frameBuffer = [];
  final List<Movement> _completedMovements = [];
  final List<Compensation> _allCompensations = [];
  List<Compensation> _currentMovementCompensations = [];
  List<List<Landmark>> _currentCapturedFrames = [];
  Timer? _countdownTimer;
  StreamSubscription<List<Landmark>>? _mockLandmarkSub;
  MockPoseEstimationService? _mockPoseService;
  int _currentReps = 0;

  static const int _frameBufferSize = 5;
  static const int _derivativeWindow = 3;

  // -- Public API --

  void startScreening() {
    if (state is! ScreeningSetup) return;
    _startMovement(0);
  }

  void _startMockLandmarkFeed(int movementIndex) {
    _mockLandmarkSub?.cancel();
    _mockPoseService?.dispose();
    _mockPoseService = MockPoseEstimationService(
      movementType: screeningMovements[movementIndex].type,
    );
    _mockLandmarkSub = _mockPoseService!.processFrame(null).listen((landmarks) {
      onLandmarkFrame(landmarks);
    });
  }

  void continueToNextMovement() {
    final current = state;
    if (current is! ShowingFindings) return;
    _startMovement(current.completedMovementIndex + 1);
  }

  void skipMovement() {
    final current = state;
    if (current is! ActiveMovement) return;
    _completeMovement();
  }

  void onLandmarkFrame(List<Landmark> landmarks) {
    final current = state;
    if (current is! ActiveMovement) return;

    // Update rolling frame buffer.
    _frameBuffer.add(landmarks);
    if (_frameBuffer.length > _frameBufferSize) {
      _frameBuffer.removeAt(0);
    }

    // Calculate angles and track the primary joint.
    final angles = _angleCalculator.calculateAngles(landmarks);
    final primaryAngle = _extractPrimaryAngle(angles, current.config);
    if (primaryAngle == null) return;

    _angleHistory.add(primaryAngle);
    if (_angleHistory.length > _derivativeWindow + 1) {
      _angleHistory.removeAt(0);
    }

    _detectPeak(current.config);
  }

  // -- Private machinery --

  void _startMovement(int index) {
    if (index >= screeningMovements.length) {
      _finishScreening();
      return;
    }

    _angleHistory.clear();
    _frameBuffer.clear();
    _currentMovementCompensations = [];
    _currentCapturedFrames = [];
    _currentReps = 0;

    final config = screeningMovements[index];
    state = ActiveMovement(
      movementIndex: index,
      config: config,
      repsCompleted: 0,
      remaining: config.duration,
      capturedFrames: const [],
      movementCompensations: const [],
    );

    _startMockLandmarkFeed(index);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
    });
  }

  void _onTimerTick() {
    final current = state;
    if (current is! ActiveMovement) {
      _countdownTimer?.cancel();
      return;
    }

    final newRemaining = current.remaining - const Duration(seconds: 1);
    if (newRemaining <= Duration.zero) {
      _completeMovement();
      return;
    }

    state = ActiveMovement(
      movementIndex: current.movementIndex,
      config: current.config,
      repsCompleted: _currentReps,
      remaining: newRemaining,
      capturedFrames: List.unmodifiable(_currentCapturedFrames),
      movementCompensations: List.unmodifiable(_currentMovementCompensations),
    );
  }

  double? _extractPrimaryAngle(List<JointAngle> angles, MovementConfig config) {
    // Map MovementConfig.primaryJoint to angle joint names.
    final jointMapping = {
      'leftKnee': 'left_knee_valgus',
      'leftHip': 'left_hip_abduction',
      'leftShoulder': 'left_shoulder_elevation',
    };
    final jointName = jointMapping[config.primaryJoint];
    if (jointName == null) return null;

    for (final a in angles) {
      if (a.joint == jointName) return a.angleDegrees;
    }
    return null;
  }

  void _detectPeak(MovementConfig config) {
    if (_angleHistory.length < _derivativeWindow) return;

    // Compute derivatives over the window.
    final len = _angleHistory.length;
    final prevDelta = _angleHistory[len - 2] - _angleHistory[len - 3];
    final currDelta = _angleHistory[len - 1] - _angleHistory[len - 2];

    // Peak detection: sign change in derivative.
    // peakIsMinimum: we look for negative→positive (valley).
    // peakIsMaximum: we look for positive→negative (peak).
    final bool peakDetected;
    if (config.peakIsMinimum) {
      peakDetected = prevDelta < 0 && currDelta >= 0;
    } else {
      peakDetected = prevDelta > 0 && currDelta <= 0;
    }

    if (peakDetected) {
      _onPeakDetected();
    }
  }

  void _onPeakDetected() {
    final current = state;
    if (current is! ActiveMovement) return;
    if (_frameBuffer.isEmpty) return;

    // Average the frame buffer element-wise.
    final averaged = _averageFrameBuffer();
    _currentCapturedFrames.add(averaged);

    // Run averaged landmarks through the full pipeline.
    final angles = _angleCalculator.calculateAngles(averaged);
    final compensations = _chainMapper.mapCompensations(angles);
    _currentMovementCompensations.addAll(compensations);

    _currentReps++;

    state = ActiveMovement(
      movementIndex: current.movementIndex,
      config: current.config,
      repsCompleted: _currentReps,
      remaining: current.remaining,
      capturedFrames: List.unmodifiable(_currentCapturedFrames),
      movementCompensations: List.unmodifiable(_currentMovementCompensations),
    );

    // Check if target reps reached.
    if (_currentReps >= current.config.targetReps) {
      _completeMovement();
    }
  }

  List<Landmark> _averageFrameBuffer() {
    if (_frameBuffer.length == 1) return _frameBuffer.first;

    final landmarkCount = _frameBuffer.first.length;

    return List.generate(landmarkCount, (i) {
      var sumX = 0.0;
      var sumY = 0.0;
      var sumZ = 0.0;
      var sumVis = 0.0;
      var count = 0;

      for (final frame in _frameBuffer) {
        if (i < frame.length) {
          sumX += frame[i].x;
          sumY += frame[i].y;
          sumZ += frame[i].z;
          sumVis += frame[i].visibility;
          count++;
        }
      }

      if (count == 0) {
        return const Landmark(x: 0, y: 0, z: 0, visibility: 0);
      }

      return Landmark(
        x: sumX / count,
        y: sumY / count,
        z: sumZ / count,
        visibility: sumVis / count,
      );
    });
  }

  void _completeMovement() {
    _countdownTimer?.cancel();

    final current = state;
    if (current is! ActiveMovement) return;

    // Build the completed Movement record.
    final allAngles = <JointAngle>[];
    for (final frame in _currentCapturedFrames) {
      allAngles.addAll(_angleCalculator.calculateAngles(frame));
    }

    _completedMovements.add(Movement(
      type: current.config.type,
      landmarks: List.unmodifiable(_currentCapturedFrames),
      keyframeAngles: List.unmodifiable(allAngles),
      duration: current.config.duration - current.remaining,
    ));
    _allCompensations.addAll(_currentMovementCompensations);

    // If this was the final movement, skip findings and finish.
    if (current.movementIndex == screeningMovements.length - 1) {
      _finishScreening();
      return;
    }

    // Pick top 1-2 compensations by confidence for findings.
    final findings = _topFindings(_currentMovementCompensations);
    final message = _buildFeedbackMessage(findings);

    state = ShowingFindings(
      completedMovementIndex: current.movementIndex,
      findings: findings,
      feedbackMessage: message,
    );
  }

  void _finishScreening() {
    final now = DateTime.now();
    final assessment = Assessment(
      id: '${now.millisecondsSinceEpoch}-${now.microsecond}',
      createdAt: DateTime.now(),
      movements: List.unmodifiable(_completedMovements),
      compensations: List.unmodifiable(_allCompensations),
      report: null,
    );

    state = ScreeningComplete(assessment: assessment);
  }

  List<Compensation> _topFindings(List<Compensation> compensations) {
    if (compensations.isEmpty) return const [];

    // Sort by confidence: high (index 0) first, then medium, then low.
    final sorted = List<Compensation>.from(compensations)
      ..sort((a, b) => a.confidence.index.compareTo(b.confidence.index));

    return sorted.take(2).toList();
  }

  String _buildFeedbackMessage(List<Compensation> findings) {
    if (findings.isEmpty) {
      return 'Everything looked good on that one. Let\'s keep going!';
    }

    // Body-path language: map joint to user-friendly area names.
    // No chain names, no clinical jargon.
    final areas = findings.map((f) => _jointToBodyArea(f.joint)).toSet();

    if (areas.length == 1) {
      return 'We noticed something in your ${areas.first} area '
          '-- we\'ll check it from another angle in the next movement.';
    }

    final areaList = areas.toList();
    return 'We noticed something in your ${areaList.first} and '
        '${areaList.last} areas -- we\'ll look at these from '
        'another angle next.';
  }

  String _jointToBodyArea(String joint) {
    if (joint.contains('ankle')) return 'ankle';
    if (joint.contains('knee')) return 'knee';
    if (joint.contains('hip')) return 'hip';
    if (joint.contains('shoulder')) return 'shoulder';
    if (joint.contains('trunk')) return 'core';
    return 'movement';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mockLandmarkSub?.cancel();
    _mockPoseService?.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final screeningControllerProvider =
    StateNotifierProvider<ScreeningController, ScreeningState>((ref) {
  final controller = ScreeningController(
    angleCalculator: ref.watch(core_providers.angleCalculatorProvider),
    chainMapper: ref.watch(core_providers.chainMapperProvider),
  );

  // Listen to landmarks and forward to controller.
  ref.listen<List<Landmark>>(core_providers.currentLandmarksProvider,
      (previous, next) {
    controller.onLandmarkFrame(next);
  });

  return controller;
});
