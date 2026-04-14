import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/domain/models.dart';

// ---------------------------------------------------------------------------
// CameraState — sealed class covering the full permission + lifecycle surface
// ---------------------------------------------------------------------------

sealed class CameraState {
  const CameraState();
}

class CameraUninitialized extends CameraState {
  const CameraUninitialized();
}

class CameraPermissionDenied extends CameraState {
  const CameraPermissionDenied({this.permanent = false});
  final bool permanent;
}

class CameraReady extends CameraState {
  const CameraReady({required this.controller});
  final CameraController controller;
}

class CameraStreaming extends CameraState {
  const CameraStreaming({required this.controller, this.landmarks = const []});
  final CameraController controller;
  final List<PoseLandmark> landmarks;
}

class CameraError extends CameraState {
  const CameraError({required this.message});
  final String message;
}

// ---------------------------------------------------------------------------
// AppCameraController — Riverpod AsyncNotifier
// ---------------------------------------------------------------------------

class AppCameraController extends AsyncNotifier<CameraState> {
  CameraController? _cameraController;
  bool _isProcessing = false;

  @override
  FutureOr<CameraState> build() {
    return const CameraUninitialized();
  }

  /// Release all internal camera resources without touching provider state.
  Future<void> _releaseCamera() async {
    _cameraController?.dispose();
    _cameraController = null;
  }

  /// Toggle between front and back cameras.
  Future<void> toggleCamera() async {
    final current = state.value;
    if (current is! CameraReady && current is! CameraStreaming) return;

    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    final currentDesc = ref.read(cameraDescriptionProvider);
    final newDesc = cameras.firstWhere(
      (c) => c.lensDirection != currentDesc?.lensDirection,
      orElse: () => cameras.first,
    );

    final wasStreaming = current is CameraStreaming;

    await requestPermission(specificCamera: newDesc);

    if (wasStreaming) {
      await startStreaming();
    }
  }

  /// Request camera permission by attempting to list + initialize.
  Future<void> requestPermission({CameraDescription? specificCamera}) async {
    state = const AsyncValue.loading();
    await _releaseCamera();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = const AsyncData(
          CameraError(message: 'No cameras available on this device.'),
        );
        return;
      }

      final selected =
          specificCamera ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      ref.read(cameraDescriptionProvider.notifier).set(selected);

      _cameraController = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      state = AsyncData(CameraReady(controller: _cameraController!));
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraPermissionDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt') {
        final permanent = e.code == 'CameraAccessDeniedWithoutPrompt';
        state = AsyncData(CameraPermissionDenied(permanent: permanent));
      } else {
        state = AsyncData(CameraError(message: e.description ?? e.code));
      }
    } catch (e) {
      state = AsyncData(CameraError(message: e.toString()));
    }
  }

  /// Begin streaming frames to the pose detection service.
  Future<void> startStreaming() async {
    final current = state.value;
    if (current is! CameraReady && current is! CameraStreaming) return;

    final controller = current is CameraReady
        ? current.controller
        : (current as CameraStreaming).controller;

    try {
      _isProcessing = false;

      // Start the camera image stream.
      await controller.startImageStream((CameraImage image) {
        _handleFrame(image);
      });

      state = AsyncData(CameraStreaming(controller: controller));
    } catch (e) {
      state = AsyncData(CameraError(message: 'Failed to start streaming: $e'));
    }
  }

  void _handleFrame(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    final poseDetector = ref.read(poseDetectorProvider);
    final description = ref.read(cameraDescriptionProvider);
    final sensorOrientation = description?.sensorOrientation ?? 0;
    final lensDirection =
        description?.lensDirection ?? CameraLensDirection.back;

    // Calculate rotation based on sensor orientation and lens.
    final rotationDegrees = (lensDirection == CameraLensDirection.front)
        ? (360 - sensorOrientation) % 360
        : sensorOrientation;

    poseDetector
        .processFrame(image, rotationDegrees: rotationDegrees)
        .then(
          (landmarks) {
            updateLandmarks(landmarks);
            _isProcessing = false;
          },
          onError: (e) {
            developer.log(
              'Pose detection error',
              error: e,
              name: 'CameraController',
            );
            _isProcessing = false;
          },
        );
  }

  /// Stop streaming but keep camera initialized.
  Future<void> stopStreaming() async {
    final current = state.value;
    if (current is! CameraStreaming) return;

    try {
      await current.controller.stopImageStream();
      state = AsyncData(CameraReady(controller: current.controller));
    } catch (e) {
      state = AsyncData(CameraError(message: 'Failed to stop streaming: $e'));
    }
  }

  /// Release all camera resources.
  Future<void> disposeCamera() async {
    await _releaseCamera();
    state = const AsyncData(CameraUninitialized());
  }

  /// Update landmarks from pose estimation.
  void updateLandmarks(List<PoseLandmark> landmarks) {
    final current = state.value;
    if (current is CameraStreaming) {
      state = AsyncData(
        CameraStreaming(controller: current.controller, landmarks: landmarks),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final appCameraControllerProvider =
    AsyncNotifierProvider<AppCameraController, CameraState>(
      AppCameraController.new,
    );

/// Derived provider exposing only the current landmarks.
final currentLandmarksProvider = Provider<List<PoseLandmark>>((ref) {
  final cameraState = ref.watch(appCameraControllerProvider).value;
  if (cameraState is CameraStreaming) {
    return cameraState.landmarks;
  }
  return const [];
});
