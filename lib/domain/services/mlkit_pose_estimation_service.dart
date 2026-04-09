import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models.dart';
import 'pose_estimation_service.dart';

class MlKitPoseEstimationService implements PoseEstimationService {
  MlKitPoseEstimationService({
    this.sensorOrientation = 0,
    this.lensDirection = CameraLensDirection.back,
  });

  final int sensorOrientation;
  final CameraLensDirection lensDirection;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  StreamController<List<Landmark>>? _controller;

  @override
  Stream<List<Landmark>> processFrame(CameraImage? frame) {
    _controller?.close();
    _controller = StreamController<List<Landmark>>();

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

      final landmarks = PoseLandmarkType.values.map((type) {
        final lm = pose.landmarks[type];
        if (lm == null) {
          return const Landmark(x: 0, y: 0, z: 0, visibility: 0);
        }
        return Landmark(
          x: lm.x / width,
          y: lm.y / height,
          z: lm.z,
          visibility: lm.likelihood,
        );
      }).toList();

      if (!_controller!.isClosed) {
        _controller!.add(landmarks);
      }
    } catch (_) {
      // Frame dropped — next frame will retry.
    }
  }

  static InputImageRotation _rotationFromSensor(
    int sensorOrientation,
    CameraLensDirection lens,
  ) {
    final rotationDegrees = (lens == CameraLensDirection.front)
        ? (360 - sensorOrientation) % 360
        : sensorOrientation;
    switch (rotationDegrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final planes = image.planes;
    if (planes.isEmpty) return null;

    final InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = InputImageFormat.bgra8888;
    } else {
      return null;
    }

    final bytes = planes.first.bytes;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
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
