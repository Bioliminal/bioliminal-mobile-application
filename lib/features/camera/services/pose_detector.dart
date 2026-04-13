import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;

import '../../../domain/models.dart' as domain;

/// Abstract pose detection interface for the Bioliminal Flutter app.
///
/// The app should not bind directly to MediaPipe at the UI layer. We ship
/// BlazePose at launch, but the pipeline plan allows for swapping models.
abstract class PoseDetector {
  /// Process a single camera frame.
  /// Implementation must return exactly 33 BlazePose landmarks.
  Future<List<domain.PoseLandmark>> processFrame(CameraImage image, {
    required int rotationDegrees,
  });

  /// Release native resources.
  Future<void> dispose();
}

/// Implementation of PoseDetector using Google ML Kit (BlazePose).
class MediaPipePoseDetector implements PoseDetector {
  MediaPipePoseDetector()
      : _poseDetector = mlkit.PoseDetector(
          options: mlkit.PoseDetectorOptions(
            mode: mlkit.PoseDetectionMode.stream,
            model: mlkit.PoseDetectionModel.base,
          ),
        );

  final mlkit.PoseDetector _poseDetector;

  @override
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  }) async {
    final inputImage = _convertCameraImage(image, rotationDegrees);
    if (inputImage == null) return const [];

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return const [];

    final pose = poses.first;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    // Map to domain model, ensuring 33 landmarks in BlazePose order.
    return mlkit.PoseLandmarkType.values.map((type) {
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
      // Normalize coordinates based on image size.
      // BlazePose coordinates are in image-space pixels.
      return domain.PoseLandmark(
        x: lm.x / width,
        y: lm.y / height,
        z: lm.z / width, // z is relative depth, scaled similar to x
        visibility: lm.likelihood,
        presence: lm.likelihood,
      );
    }).toList();
  }

  @override
  Future<void> dispose() async {
    await _poseDetector.close();
  }

  mlkit.InputImage? _convertCameraImage(CameraImage image, int rotationDegrees) {
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
    final rotation = _degreesToRotation(rotationDegrees);

    return mlkit.InputImage.fromBytes(
      bytes: bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: planes.first.bytesPerRow,
      ),
    );
  }

  mlkit.InputImageRotation _degreesToRotation(int degrees) {
    switch (degrees) {
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
}

/// Mock implementation of PoseDetector for unit tests.
/// Returns static landmarks and avoids native plugin calls.
class MockPoseDetector implements PoseDetector {
  @override
  Future<List<domain.PoseLandmark>> processFrame(
    CameraImage image, {
    required int rotationDegrees,
  }) async {
    return List.generate(
      33,
      (idx) => const domain.PoseLandmark(
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.9,
        presence: 0.9,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    // No-op for mock
  }
}
