import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;

import '../models.dart' as domain;
import 'pose_estimation_service.dart';

class MlKitPoseEstimationService implements PoseEstimationService {
  MlKitPoseEstimationService({
    this.sensorOrientation = 0,
    this.lensDirection = CameraLensDirection.back,
  });

  final int sensorOrientation;
  final CameraLensDirection lensDirection;

  final mlkit.PoseDetector _poseDetector = mlkit.PoseDetector(
    options: mlkit.PoseDetectorOptions(mode: mlkit.PoseDetectionMode.stream),
  );

  StreamController<List<domain.PoseLandmark>>? _controller;

  @override
  Stream<List<domain.PoseLandmark>> processFrame(CameraImage? frame) {
    _controller?.close();
    _controller = StreamController<List<domain.PoseLandmark>>();

    if (frame != null) {
      _detect(frame);
    }

    return _controller!.stream;
  }

  Future<void> _detect(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);
      if (_controller == null || _controller!.isClosed) return;

      if (poses.isEmpty) {
        _controller!.add(const []);
        return;
      }

      final pose = poses.first;
      final width = image.width.toDouble();
      final height = image.height.toDouble();

      // Ensure exactly 33 landmarks in canonical BlazePose order.
      final landmarks = mlkit.PoseLandmarkType.values.map((type) {
        final lm = pose.landmarks[type];
        if (lm == null) {
          return const domain.PoseLandmark(
            x: 0,
            y: 0,
            z: 0,
            visibility: 0,
            presence: 0,
          );
        }
        return domain.PoseLandmark(
          x: lm.x / width,
          y: lm.y / height,
          z: lm.z,
          visibility: lm.likelihood,
          presence: lm.likelihood, // Consolidate likelihood for ML Kit
        );
      }).toList();

      if (!_controller!.isClosed) {
        _controller!.add(landmarks);
      }
    } catch (_) {
      // Frame dropped — next frame will retry.
    }
  }

  static mlkit.InputImageRotation _rotationFromSensor(
    int sensorOrientation,
    CameraLensDirection lens,
  ) {
    final rotationDegrees = (lens == CameraLensDirection.front)
        ? (360 - sensorOrientation) % 360
        : sensorOrientation;
    switch (rotationDegrees) {
      case 0:
        return mlkit.InputImageRotation.rotation0deg;
      case 90:
        return mlkit.InputImageRotation.rotation90deg;
      case 180:
        return mlkit.InputImageRotation.rotation180deg;
      case 270:
        return mlkit.InputImageRotation.rotation270deg;
      default:
        return mlkit.InputImageRotation.rotation0deg;
    }
  }

  mlkit.InputImage? _convertCameraImage(CameraImage image) {
    final planes = image.planes;
    if (planes.isEmpty) return null;

    final mlkit.InputImageFormat format;
    if (Platform.isAndroid) {
      format = mlkit.InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = mlkit.InputImageFormat.bgra8888;
    } else {
      return null;
    }

    final bytes = planes.first.bytes;

    return mlkit.InputImage.fromBytes(
      bytes: bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromSensor(sensorOrientation, lensDirection),
        format: format,
        bytesPerRow: planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _poseDetector.close();
    _controller?.close();
    _controller = null;
  }
}
