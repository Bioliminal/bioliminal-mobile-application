import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
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

class EnvironmentSetup extends ScreeningState {
  const EnvironmentSetup();
}

class MovementPreparation extends ScreeningState {
  const MovementPreparation({
    required this.movementIndex,
    required this.config,
  });

  final int movementIndex;
  final MovementConfig config;
}

class ActiveMovement extends ScreeningState {
  const ActiveMovement({
    required this.movementIndex,
    required this.config,
    required this.repsCompleted,
    required this.capturedFrames,
    required this.movementCompensations,
  });

  final int movementIndex;
  final MovementConfig config;
  final int repsCompleted;
  final List<PoseFrame> capturedFrames;
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

class ScreeningController extends Notifier<ScreeningState> {
  late final AngleCalculator _angleCalculator;
  late final ChainMapper _chainMapper;

  @override
  ScreeningState build() {
    _angleCalculator = ref.read(core_providers.angleCalculatorProvider);
    _chainMapper = ref.read(core_providers.chainMapperProvider);

    // Listen to landmarks and forward to controller.
    ref.listen<List<PoseLandmark>>(core_providers.currentLandmarksProvider, (
      previous,
      next,
    ) {
      onLandmarkFrame(next);
    });

    return const ScreeningSetup();
  }

  // Internal tracking state
  final List<double> _angleHistory = [];
  final List<List<PoseLandmark>> _frameBuffer = [];
  final List<Movement> _completedMovements = [];
  final List<Compensation> _allCompensations = [];
  final List<PoseFrame> _allCapturedFrames = [];
  List<Compensation> _currentMovementCompensations = [];
  List<PoseFrame> _currentMovementFrames = [];
  DateTime? _movementStartTime;
  int _currentReps = 0;

  static const int _frameBufferSize = 5;
  static const int _derivativeWindow = 3;

  // -- Public API --

  void startScreening() {
    if (state is! ScreeningSetup) return;
    state = const EnvironmentSetup();
  }

  void completeEnvironmentSetup() {
    if (state is! EnvironmentSetup) return;
    _prepareMovement(0);
  }

  void startMovement() {
    final current = state;
    if (current is! MovementPreparation) return;
    _startMovement(current.movementIndex);
  }

  void continueToNextMovement() {
    final current = state;
    if (current is! ShowingFindings) return;
    _prepareMovement(current.completedMovementIndex + 1);
  }

  void skipMovement() {
    final current = state;
    if (current is! ActiveMovement) return;
    _completeMovement();
  }

  void onLandmarkFrame(List<PoseLandmark> landmarks) {
    final current = state;
    if (current is! ActiveMovement || landmarks.isEmpty) return;

    // Update rolling frame buffer for rep counting / peak detection.
    _frameBuffer.add(landmarks);
    if (_frameBuffer.length > _frameBufferSize) {
      _frameBuffer.removeAt(0);
    }

    // Capture the frame for the server payload.
    final timestamp = _movementStartTime != null
        ? DateTime.now().difference(_movementStartTime!).inMilliseconds
        : 0;
    
    // BlazePose expects exactly 33 landmarks. 
    // Ensure we have exactly 33 before creating PoseFrame.
    if (landmarks.length == 33) {
      _currentMovementFrames.add(
        PoseFrame(timestampMs: timestamp, landmarks: landmarks),
      );
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

  void _prepareMovement(int index) {
    if (index >= screeningMovements.length) {
      _finishScreening();
      return;
    }

    final config = screeningMovements[index];
    state = MovementPreparation(movementIndex: index, config: config);
  }

  void _startMovement(int index) {
    _angleHistory.clear();
    _frameBuffer.clear();
    _currentMovementCompensations = [];
    _currentMovementFrames = [];
    _currentReps = 0;
    _movementStartTime = DateTime.now();

    final config = screeningMovements[index];
    state = ActiveMovement(
      movementIndex: index,
      config: config,
      repsCompleted: 0,
      capturedFrames: const [],
      movementCompensations: const [],
    );
  }

  double? _extractPrimaryAngle(List<JointAngle> angles, MovementConfig config) {
    // Map MovementConfig.primaryJoint to angle joint names.
    final jointMapping = {
      'leftKnee': 'left_knee_valgus',
      'leftHip': 'left_hip_flexion',
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

    // Average the frame buffer element-wise for a "stable" keyframe.
    final averaged = _averageFrameBuffer();

    // Run averaged landmarks through the local triage pipeline.
    final angles = _angleCalculator.calculateAngles(averaged);
    final compensations = _chainMapper.mapCompensations(angles);
    _currentMovementCompensations.addAll(compensations);

    _currentReps++;

    state = ActiveMovement(
      movementIndex: current.movementIndex,
      config: current.config,
      repsCompleted: _currentReps,
      capturedFrames: List.unmodifiable(_currentMovementFrames),
      movementCompensations: List.unmodifiable(_currentMovementCompensations),
    );

    // Check if target reps reached.
    if (_currentReps >= current.config.targetReps) {
      _completeMovement();
    }
  }

  List<PoseLandmark> _averageFrameBuffer() {
    if (_frameBuffer.length == 1) return _frameBuffer.first;

    final landmarkCount = _frameBuffer.first.length;

    return List.generate(landmarkCount, (i) {
      var sumX = 0.0;
      var sumY = 0.0;
      var sumZ = 0.0;
      var sumVis = 0.0;
      var sumPres = 0.0;
      var count = 0;

      for (final frame in _frameBuffer) {
        if (i < frame.length) {
          sumX += frame[i].x;
          sumY += frame[i].y;
          sumZ += frame[i].z;
          sumVis += frame[i].visibility;
          sumPres += frame[i].presence;
          count++;
        }
      }

      if (count == 0) {
        return const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0, presence: 0);
      }

      return PoseLandmark(
        x: sumX / count,
        y: sumY / count,
        z: sumZ / count,
        visibility: sumVis / count,
        presence: sumPres / count,
      );
    });
  }

  void _completeMovement() {
    final current = state;
    if (current is! ActiveMovement) return;

    // Build the completed Movement record.
    // Use the frames captured during this movement.
    final allAngles = <JointAngle>[];
    if (_currentMovementFrames.isNotEmpty) {
      allAngles.addAll(_angleCalculator.calculateAngles(_currentMovementFrames.last.landmarks));
    }

    final duration = _movementStartTime != null
        ? DateTime.now().difference(_movementStartTime!)
        : Duration.zero;

    _completedMovements.add(
      Movement(
        type: current.config.type,
        frames: List.unmodifiable(_currentMovementFrames),
        keyframeAngles: List.unmodifiable(allAngles),
        duration: duration,
      ),
    );
    _allCompensations.addAll(_currentMovementCompensations);
    _allCapturedFrames.addAll(_currentMovementFrames);

    // If this was the final movement, skip findings and finish.
    if (current.movementIndex == screeningMovements.length - 1) {
      _finishScreening();
      return;
    }

    // Pick top findings for intermediate feedback.
    final findings = _topFindings(_currentMovementCompensations);
    final message = _buildFeedbackMessage(findings);

    state = ShowingFindings(
      completedMovementIndex: current.movementIndex,
      findings: findings,
      feedbackMessage: message,
    );
  }

  void _finishScreening() async {
    final now = DateTime.now();
    
    final payload = SessionPayload(
      metadata: SessionMetadata(
        movement: _completedMovements.firstOrNull?.type ?? MovementType.overheadSquat,
        device: 'iPhone 11', // TODO: use real device info
        model: 'mediapipe_blazepose_full',
        frameRate: 30.0, // TODO: measure real FPS
      ),
      frames: List.unmodifiable(_allCapturedFrames),
    );

    final assessment = Assessment(
      id: '${now.millisecondsSinceEpoch}-${now.microsecond}',
      createdAt: now,
      movements: List.unmodifiable(_completedMovements),
      compensations: List.unmodifiable(_allCompensations),
      report: null,
      payload: payload,
    );

    state = ScreeningComplete(assessment: assessment);

    // Async upload to server.
    try {
      final client = ref.read(core_providers.auraLinkClientProvider);
      await client.submitSession(payload);
    } catch (e) {
      developer.log('Auto-upload failed', error: e, name: 'ScreeningController');
    }
  }

  List<Compensation> _topFindings(List<Compensation> compensations) {
    if (compensations.isEmpty) return const [];
    final sorted = List<Compensation>.from(compensations)
      ..sort((a, b) => a.confidence.index.compareTo(b.confidence.index));
    return sorted.take(2).toList();
  }

  String _buildFeedbackMessage(List<Compensation> findings) {
    if (findings.isEmpty) {
      return 'Everything looked good on that one. Let\'s keep going!';
    }
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
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final screeningControllerProvider =
    NotifierProvider<ScreeningController, ScreeningState>(
      ScreeningController.new,
    );
