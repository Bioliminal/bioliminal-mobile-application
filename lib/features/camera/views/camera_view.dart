import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/camera_controller.dart';
import '../widgets/setup_checklist.dart';
import '../widgets/skeleton_overlay.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key});

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> with WidgetsBindingObserver {
  bool _setupComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick off permission request on first build.
    Future.microtask(() {
      ref.read(appCameraControllerProvider.notifier).requestPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(appCameraControllerProvider.notifier).disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appCameraControllerProvider.notifier);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.stopStreaming();
    } else if (state == AppLifecycleState.resumed) {
      // Re-request to reinitialize after background.
      controller.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraAsync = ref.watch(appCameraControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.read(appCameraControllerProvider.notifier).requestPermission();
          },
        ),
        data: (cameraState) => switch (cameraState) {
          CameraUninitialized() => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          CameraPermissionDenied(:final permanent) => _PermissionDeniedView(
              permanent: permanent,
              onRetry: () {
                ref
                    .read(appCameraControllerProvider.notifier)
                    .requestPermission();
              },
            ),
          CameraReady(:final controller) => CameraBody(
              controller: controller,
              setupComplete: _setupComplete,
              onSetupComplete: () => setState(() => _setupComplete = true),
              onStartStreaming: () {
                ref
                    .read(appCameraControllerProvider.notifier)
                    .startStreaming();
              },
            ),
          CameraStreaming(:final controller) => CameraBody(
              controller: controller,
              setupComplete: _setupComplete,
              onSetupComplete: () => setState(() => _setupComplete = true),
              onStartStreaming: null,
            ),
          CameraError(:final message) => _ErrorView(
              message: message,
              onRetry: () {
                ref
                    .read(appCameraControllerProvider.notifier)
                    .requestPermission();
              },
            ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera body — preview + overlays
// ---------------------------------------------------------------------------

class CameraBody extends StatefulWidget {
  const CameraBody({
    super.key,
    required this.controller,
    required this.setupComplete,
    required this.onSetupComplete,
    required this.onStartStreaming,
  });

  final CameraController controller;
  final bool setupComplete;
  final VoidCallback onSetupComplete;
  final VoidCallback? onStartStreaming;

  @override
  State<CameraBody> createState() => _CameraBodyState();
}

class _CameraBodyState extends State<CameraBody> {
  bool _streamingStarted = false;

  @override
  void initState() {
    super.initState();
    _maybeStartStreaming();
  }

  @override
  void didUpdateWidget(CameraBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStartStreaming();
  }

  void _maybeStartStreaming() {
    if (!_streamingStarted && widget.onStartStreaming != null) {
      _streamingStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStartStreaming?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFront =
        widget.controller.description.lensDirection == CameraLensDirection.front;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Camera preview.
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: CameraPreview(widget.controller),
          ),
        ),

        // Layer 2: Skeleton overlay.
        Positioned.fill(
          child: SkeletonOverlay(isFrontCamera: isFront),
        ),

        // Layer 3: Setup checklist (shown until all checks pass).
        if (!widget.setupComplete)
          Positioned.fill(
            child: SetupChecklist(onAllPassed: widget.onSetupComplete),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Permission denied fallback
// ---------------------------------------------------------------------------

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.permanent,
    required this.onRetry,
  });

  final bool permanent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Camera Access Required',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              permanent
                  ? 'Camera permission was permanently denied. Please enable it in your device settings.'
                  : 'AuraLink needs camera access to perform the movement screening.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(permanent ? Icons.settings : Icons.videocam),
              label: Text(permanent ? 'Open Settings' : 'Grant Access'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error fallback
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
