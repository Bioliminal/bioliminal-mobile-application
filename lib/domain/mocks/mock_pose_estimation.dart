import 'dart:async';

import 'package:camera/camera.dart';

import '../models.dart';
import '../services/pose_estimation_service.dart';

/// Streams pre-built landmark sequences for each of the clinical movements
/// with realistic visibility scores.
class MockPoseEstimationService implements PoseEstimationService {
  MockPoseEstimationService({this.movementType = MovementType.overheadSquat});

  final MovementType movementType;
  StreamController<List<PoseLandmark>>? _controller;
  Timer? _timer;

  bool _disposed = false;

  @override
  Stream<List<PoseLandmark>> processFrame(CameraImage? frame) {
    // Dispose previous timer/controller to prevent leaks on repeated calls.
    _timer?.cancel();
    _timer = null;
    _controller?.close();

    _disposed = false;
    _controller = StreamController<List<PoseLandmark>>();
    final frames = _framesForMovement(movementType);
    var frameIndex = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_disposed || (_controller?.isClosed ?? true)) {
        _timer?.cancel();
        return;
      }
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
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
  }

  List<List<PoseLandmark>> _framesForMovement(MovementType type) {
    switch (type) {
      case MovementType.overheadSquat:
        return _overheadSquatFrames();
      case MovementType.singleLegSquat:
        return _singleLegSquatFrames();
      case MovementType.pushUp:
        return _pushUpFrames();
      case MovementType.rollup:
        return _rollupFrames();
    }
  }

  List<List<PoseLandmark>> _overheadSquatFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0;
      final depth = progress * 0.3;
      final kneeMedialDrift = progress * 0.04;
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

  List<List<PoseLandmark>> _singleLegSquatFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0;
      final depth = progress * 0.2;
      return _buildLandmarks(
        hipY: 0.5 + depth,
        kneeMedialOffset: 0.02 + (progress * 0.03),
        ankleVisibility: 0.75,
        hipVisibility: 0.93,
        kneeVisibility: 0.91,
        shoulderVisibility: 0.92,
        trunkLateralOffset: 0.03,
        hipDropOffset: 0.025 * progress,
      );
    });
  }

  List<List<PoseLandmark>> _pushUpFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0;
      final depth = progress * 0.15;
      return _buildLandmarks(
        hipY: 0.7,
        kneeMedialOffset: 0.0,
        ankleVisibility: 0.88,
        hipVisibility: 0.94,
        kneeVisibility: 0.93,
        shoulderVisibility: 0.96,
        trunkLateralOffset: 0.0,
        leftShoulderDepression: depth,
      );
    });
  }

  List<List<PoseLandmark>> _rollupFrames() {
    return List.generate(30, (i) {
      final progress = i / 29.0;
      final lift = progress * 0.4;
      return _buildLandmarks(
        hipY: 0.8 - (lift * 0.2),
        kneeMedialOffset: 0.005,
        ankleVisibility: 0.5,
        hipVisibility: 0.80,
        kneeVisibility: 0.85,
        shoulderVisibility: 0.82,
        trunkLateralOffset: 0.0,
      );
    });
  }

  List<PoseLandmark> _buildLandmarks({
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
    return List.generate(33, (idx) {
      switch (idx) {
        case 0: // nose
          return PoseLandmark(
            x: 0.5 + trunkLateralOffset,
            y: 0.15,
            z: 0.0,
            visibility: 0.98,
            presence: 0.99,
          );
        case 11: // left shoulder
          return PoseLandmark(
            x: 0.4 + trunkLateralOffset,
            y: 0.25 + leftShoulderDepression,
            z: 0.0,
            visibility: shoulderVisibility,
            presence: 0.95,
          );
        case 12: // right shoulder
          return PoseLandmark(
            x: 0.6 + trunkLateralOffset,
            y: 0.25,
            z: 0.0,
            visibility: shoulderVisibility,
            presence: 0.95,
          );
        case 23: // left hip
          return PoseLandmark(
            x: 0.45,
            y: hipY + hipDropOffset,
            z: 0.0,
            visibility: hipVisibility,
            presence: 0.95,
          );
        case 24: // right hip
          return PoseLandmark(
            x: 0.55,
            y: hipY,
            z: 0.0,
            visibility: hipVisibility,
            presence: 0.95,
          );
        case 25: // left knee
          return PoseLandmark(
            x: 0.45 + kneeMedialOffset,
            y: hipY + 0.2,
            z: 0.0,
            visibility: kneeVisibility,
            presence: 0.95,
          );
        case 26: // right knee
          return PoseLandmark(
            x: 0.55 - kneeMedialOffset,
            y: hipY + 0.2,
            z: 0.0,
            visibility: kneeVisibility,
            presence: 0.95,
          );
        case 27: // left ankle
          return PoseLandmark(
            x: 0.45,
            y: hipY + 0.4,
            z: 0.0,
            visibility: ankleVisibility,
            presence: 0.95,
          );
        case 28: // right ankle
          return PoseLandmark(
            x: 0.55,
            y: hipY + 0.4,
            z: 0.0,
            visibility: ankleVisibility,
            presence: 0.95,
          );
        default:
          return const PoseLandmark(
            x: 0.5,
            y: 0.5,
            z: 0.0,
            visibility: 0.90,
            presence: 0.90,
          );
      }
    });
  }
}
