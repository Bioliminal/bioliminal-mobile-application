import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/core/providers.dart';
import 'package:auralink/domain/models.dart';
import 'package:auralink/domain/services/pose_estimation_service.dart';

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
  final List<Landmark> landmarks;
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
  StreamSubscription<dynamic>? _landmarkSubscription;
  bool _isProcessing = false;

  @override
  FutureOr<CameraState> build() => const CameraUninitialized();

  /// Release all internal camera resources without touching provider state.
  Future<void> _releaseCamera() async {
    await _landmarkSubscription?.cancel();
    _landmarkSubscription = null;
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

    // If we were streaming, we should restart streaming after switching.
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
      // CameraException code 'CameraAccessDenied' means user denied.
      if (e.code == 'CameraAccessDenied' ||
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

  /// Begin streaming frames to the pose estimation service.
  Future<void> startStreaming() async {
    final current = state.value;
    if (current is! CameraReady && current is! CameraStreaming) return;

    final controller = current is CameraReady
        ? current.controller
        : (current as CameraStreaming).controller;

    try {
      final poseService = ref.read(poseEstimationServiceProvider);

      // Cancel any previous subscription to ensure a clean state.
      await _landmarkSubscription?.cancel();
      _isProcessing = false;

      // Start the camera stream.
      await controller.startImageStream((CameraImage image) {
        _handleFrame(image, poseService);
      });

      // We maintain one long-running subscription to the landmarks stream.
      // The stream itself is handled by the poseService.
      state = AsyncData(CameraStreaming(controller: controller));
    } catch (e) {
      state = AsyncData(CameraError(message: 'Failed to start streaming: $e'));
    }
  }

  void _handleFrame(CameraImage image, PoseEstimationService poseService) {
    if (_isProcessing) return;
    _isProcessing = true;

    // Process the frame. The service handles the heavy lifting.
    // We listen to the first result and then reset the busy flag.
    poseService
        .processFrame(image)
        .first
        .then(
          (landmarks) {
            updateLandmarks(landmarks);
            _isProcessing = false;
          },
          onError: (e) {
            developer.log(
              'Pose estimation error',
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
      await _landmarkSubscription?.cancel();
      _landmarkSubscription = null;
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

  /// Update landmarks from pose estimation (called by the service integration).
  void updateLandmarks(List<Landmark> landmarks) {
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
/// Widgets that only need landmark data watch this instead of the full
/// camera state — avoids rebuilds on camera lifecycle transitions.
final currentLandmarksProvider = Provider<List<Landmark>>((ref) {
  final cameraState = ref.watch(appCameraControllerProvider).value;
  if (cameraState is CameraStreaming) {
    return cameraState.landmarks;
  }
  return const [];
});
