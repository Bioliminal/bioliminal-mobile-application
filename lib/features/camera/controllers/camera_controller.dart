import 'dart:async';

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
  const CameraStreaming({
    required this.controller,
    this.landmarks = const [],
  });
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

  /// Request camera permission by attempting to list + initialize.
  /// The camera package triggers the native permission dialog on first access.
  Future<void> requestPermission() async {
    await _releaseCamera();
    state = const AsyncValue.loading();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = const AsyncData(
          CameraError(message: 'No cameras available on this device.'),
        );
        return;
      }

      // Prefer back camera (user faces phone propped up at distance).
      final selected = cameras.firstWhere(
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

    final controller =
        current is CameraReady ? current.controller : (current as CameraStreaming).controller;

    try {
      final poseService = ref.read(poseEstimationServiceProvider);

      // Cancel any previous subscription.
      await _landmarkSubscription?.cancel();

      await controller.startImageStream((CameraImage image) {
        _handleFrame(image, poseService);
      });

      state = AsyncData(CameraStreaming(controller: controller));
    } catch (e) {
      state = AsyncData(CameraError(message: 'Failed to start streaming: $e'));
    }
  }

  void _handleFrame(CameraImage image, PoseEstimationService poseService) {
    if (_isProcessing) return;
    _isProcessing = true;

    _landmarkSubscription?.cancel();
    _landmarkSubscription = poseService.processFrame(image).listen(
      (landmarks) {
        updateLandmarks(landmarks);
        _isProcessing = false;
      },
      onError: (_) {
        _isProcessing = false;
      },
      onDone: () {
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
