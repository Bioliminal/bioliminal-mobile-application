import 'dart:async';

import 'package:camera/camera.dart';

import '../models.dart';
import '../services/pose_estimation_service.dart';

/// Streams pre-built landmark sequences for each of 4 movements
/// with realistic visibility scores. Ankle visibility degrades in
/// forward fold and mid-squat, matching known MediaPipe weaknesses.
class MockPoseEstimationService implements PoseEstimationService {
  MockPoseEstimationService({this.movementType = MovementType.overheadSquat});

  final MovementType movementType;
  StreamController<List<Landmark>>? _controller;
  Timer? _timer;

  @override
  Stream<List<Landmark>> processFrame(CameraImage frame) {
    _controller = StreamController<List<Landmark>>();
    final frames = _framesForMovement(movementType);
    var frameIndex = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (frameIndex >= frames.length) {
        _controller?.close();
        _timer?.cancel();
        return;
      }
      _controller?.add(frames[frameIndex]);
      frameIndex++;
    });

    return _controller!.stream;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }

  List<List<Landmark>> _framesForMovement(MovementType type) {
    switch (type) {
      case MovementType.overheadSquat:
        return _overheadSquatFrames();
      case MovementType.singleLegBalance:
        return _singleLegBalanceFrames();
      case MovementType.overheadReach:
        return _overheadReachFrames();
      case MovementType.forwardFold:
        return _forwardFoldFrames();
    }
  }

  /// 30 frames simulating descent to parallel. Knee landmarks drift
  /// medially (valgus). Ankle visibility degrades mid-squat (0.6-0.7).
  List<List<Landmark>> _overheadSquatFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0; // 0.0 at top, 1.0 at bottom
      final depth = progress * 0.3; // hip drops 0.3 in y
      // Knee drifts medially as squat deepens (valgus)
      final kneeMedialDrift = progress * 0.04;
      // Ankle visibility degrades mid-squat
      final ankleVisibility = (progress > 0.3 && progress < 0.7)
          ? 0.6 + (0.1 * (1.0 - progress))
          : 0.85;

      return _buildLandmarks(
        hipY: 0.5 + depth,
        kneeMedialOffset: kneeMedialDrift,
        ankleVisibility: ankleVisibility,
        hipVisibility: 0.95,
        kneeVisibility: 0.92,
        shoulderVisibility: 0.93,
        trunkLateralOffset: 0.0,
      );
    });
  }

  /// Standing leg stable. Non-stance leg elevated. Hip drop via pelvis
  /// asymmetry. Trunk lean ~7 degrees lateral. Ankle visibility medium.
  List<List<Landmark>> _singleLegBalanceFrames() {
    return List.generate(30, (i) {
      final sway = 0.01 * (i % 5 - 2); // small balance sway
      return _buildLandmarks(
        hipY: 0.5,
        kneeMedialOffset: 0.01 + sway,
        ankleVisibility: 0.75,
        hipVisibility: 0.93,
        kneeVisibility: 0.91,
        shoulderVisibility: 0.92,
        trunkLateralOffset: 0.03, // ~7 deg lean
        hipDropOffset: 0.025, // pelvis asymmetry
      );
    });
  }

  /// Arms overhead. Shoulder landmarks show slight asymmetry (left
  /// depression). Thoracic landmarks show limited rotation. All upper
  /// body visibility high.
  List<List<Landmark>> _overheadReachFrames() {
    return List.generate(30, (i) {
      return _buildLandmarks(
        hipY: 0.55,
        kneeMedialOffset: 0.0,
        ankleVisibility: 0.88,
        hipVisibility: 0.94,
        kneeVisibility: 0.93,
        shoulderVisibility: 0.96,
        trunkLateralOffset: 0.0,
        leftShoulderDepression: 0.02, // asymmetry
      );
    });
  }

  /// Forward bend. Ankle landmarks often occluded (visibility 0.4-0.5).
  /// Hip/spine visibility medium.
  List<List<Landmark>> _forwardFoldFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0;
      final bendDepth = progress * 0.4;
      // Ankle visibility severely degrades during fold
      final ankleVis = 0.5 - (progress * 0.1);

      return _buildLandmarks(
        hipY: 0.5 + bendDepth * 0.3,
        kneeMedialOffset: 0.005,
        ankleVisibility: ankleVis.clamp(0.35, 0.55),
        hipVisibility: 0.80,
        kneeVisibility: 0.85,
        shoulderVisibility: 0.82,
        trunkLateralOffset: 0.0,
      );
    });
  }

  /// Build 33 landmarks in MediaPipe BlazePose order. Only the
  /// clinically relevant landmarks (hips, knees, ankles, shoulders,
  /// spine proxies) vary per movement; others get stable defaults.
  List<Landmark> _buildLandmarks({
    required double hipY,
    required double kneeMedialOffset,
    required double ankleVisibility,
    required double hipVisibility,
    required double kneeVisibility,
    required double shoulderVisibility,
    required double trunkLateralOffset,
    double hipDropOffset = 0.0,
    double leftShoulderDepression = 0.0,
  }) {
    // MediaPipe BlazePose indices:
    // 0: nose, 11: left shoulder, 12: right shoulder,
    // 23: left hip, 24: right hip, 25: left knee, 26: right knee,
    // 27: left ankle, 28: right ankle
    return List.generate(33, (idx) {
      switch (idx) {
        case 0: // nose
          return Landmark(
            x: 0.5 + trunkLateralOffset,
            y: 0.15,
            z: 0.0,
            visibility: 0.98,
          );
        case 11: // left shoulder
          return Landmark(
            x: 0.4 + trunkLateralOffset,
            y: 0.25 + leftShoulderDepression,
            z: 0.0,
            visibility: shoulderVisibility,
          );
        case 12: // right shoulder
          return Landmark(
            x: 0.6 + trunkLateralOffset,
            y: 0.25,
            z: 0.0,
            visibility: shoulderVisibility,
          );
        case 23: // left hip
          return Landmark(
            x: 0.45,
            y: hipY + hipDropOffset,
            z: 0.0,
            visibility: hipVisibility,
          );
        case 24: // right hip
          return Landmark(
            x: 0.55,
            y: hipY,
            z: 0.0,
            visibility: hipVisibility,
          );
        case 25: // left knee
          return Landmark(
            x: 0.45 + kneeMedialOffset,
            y: hipY + 0.2,
            z: 0.0,
            visibility: kneeVisibility,
          );
        case 26: // right knee
          return Landmark(
            x: 0.55 - kneeMedialOffset,
            y: hipY + 0.2,
            z: 0.0,
            visibility: kneeVisibility,
          );
        case 27: // left ankle
          return Landmark(
            x: 0.45,
            y: hipY + 0.4,
            z: 0.0,
            visibility: ankleVisibility,
          );
        case 28: // right ankle
          return Landmark(
            x: 0.55,
            y: hipY + 0.4,
            z: 0.0,
            visibility: ankleVisibility,
          );
        default:
          return const Landmark(
            x: 0.5,
            y: 0.5,
            z: 0.0,
            visibility: 0.90,
          );
      }
    });
  }
}
