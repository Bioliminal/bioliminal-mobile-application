import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../domain/models.dart';
import '../../camera/widgets/skeleton_overlay.dart';

// ---------------------------------------------------------------------------
// Recording duration for the bicep-curl demo. Long enough to clear the
// server's 1s quality gate with significant headroom and to cover ~5 reps
// at a deliberate tempo.
// ---------------------------------------------------------------------------
const Duration _recordDuration = Duration(seconds: 10);

/// Bicep-curl capture screen. Opens the camera, runs MediaPipe on-device,
/// records pose frames for 10 seconds, then submits the full session to the
/// analysis server and navigates to /report/{session_id}.
class RepCaptureView extends ConsumerStatefulWidget {
  const RepCaptureView({super.key});

  @override
  ConsumerState<RepCaptureView> createState() => _RepCaptureViewState();
}

enum _CapturePhase { initializing, ready, recording, submitting, error }

class _RepCaptureViewState extends ConsumerState<RepCaptureView> {
  _CapturePhase _phase = _CapturePhase.initializing;
  String? _errorMessage;

  final List<PoseFrame> _frames = [];
  DateTime? _recordStart;
  Timer? _uiTicker;
  Duration _elapsed = Duration.zero;
  ProviderSubscription<List<PoseLandmark>>? _landmarkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapCamera());
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _landmarkSub?.close();
    // Stop streaming so we don't keep the camera busy once this view is gone.
    // The controller itself is owned by the provider and will be reused.
    final notifier = ref.read(appCameraControllerProvider.notifier);
    notifier.stopStreaming();
    super.dispose();
  }

  Future<void> _bootstrapCamera() async {
    final notifier = ref.read(appCameraControllerProvider.notifier);
    await notifier.requestPermission();
    if (!mounted) return;

    final state = ref.read(appCameraControllerProvider).value;
    if (state is CameraPermissionDenied) {
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage = state.permanent
            ? 'Camera permission is permanently denied. Enable it in system settings.'
            : 'Camera permission is required to capture a session.';
      });
      return;
    }
    if (state is CameraError) {
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage = state.message;
      });
      return;
    }

    await notifier.startStreaming();
    if (!mounted) return;
    setState(() => _phase = _CapturePhase.ready);
  }

  void _startRecording() {
    _frames.clear();
    _recordStart = DateTime.now();
    _elapsed = Duration.zero;

    setState(() => _phase = _CapturePhase.recording);

    // Accumulate one PoseFrame per landmark emission while recording.
    _landmarkSub = ref.listenManual<List<PoseLandmark>>(currentLandmarksProvider, (
      _,
      next,
    ) {
      if (_phase != _CapturePhase.recording) return;
      if (next.length != 33) return;
      final start = _recordStart;
      if (start == null) return;

      final timestampMs = DateTime.now().difference(start).inMilliseconds;
      _frames.add(PoseFrame(timestampMs: timestampMs, landmarks: next));
    });

    _uiTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final start = _recordStart;
      if (start == null || !mounted) return;
      final elapsed = DateTime.now().difference(start);
      setState(() => _elapsed = elapsed);
      if (elapsed >= _recordDuration) {
        _finishRecording();
      }
    });
  }

  Future<void> _finishRecording() async {
    _uiTicker?.cancel();
    _landmarkSub?.close();
    _landmarkSub = null;

    if (_frames.isEmpty) {
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage =
            'No pose frames captured. Ensure your full body is visible in the camera.';
      });
      return;
    }

    setState(() => _phase = _CapturePhase.submitting);

    final totalMs = _frames.last.timestampMs.clamp(1, 1 << 30);
    final measuredFps = (_frames.length * 1000.0) / totalMs;

    final payload = SessionPayload(
      metadata: SessionMetadata(
        movement: MovementType.bicepCurl,
        device: _deviceLabel(),
        model: 'mediapipe_blazepose_full',
        frameRate: measuredFps,
      ),
      frames: List.unmodifiable(_frames),
    );

    try {
      final client = ref.read(bioliminalClientProvider);
      final sessionId = await client.submitSession(payload);

      final record = SessionRecord(
        sessionId: sessionId,
        movement: MovementType.bicepCurl.wire,
        capturedAt: DateTime.now().toUtc(),
      );
      await ref.read(localStorageServiceProvider).saveSessionRecord(record);

      if (!mounted) return;
      context.go('/report/$sessionId');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _CapturePhase.error;
        _errorMessage = 'Upload failed: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _phase = _CapturePhase.ready;
      _errorMessage = null;
      _frames.clear();
      _elapsed = Duration.zero;
    });
  }

  String _deviceLabel() {
    if (Platform.isIOS) return 'iOS device';
    if (Platform.isAndroid) return 'Android device';
    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(appCameraControllerProvider).value;
    final isFrontCamera =
        ref.watch(cameraDescriptionProvider)?.lensDirection ==
        CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (cameraState is CameraStreaming || cameraState is CameraReady)
            Positioned.fill(
              child: _CameraPreview(
                controller: cameraState is CameraStreaming
                    ? cameraState.controller
                    : (cameraState as CameraReady).controller,
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),
          Positioned.fill(
            child: SkeletonOverlay(isFrontCamera: isFrontCamera),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    phase: _phase,
                    onBack: () => context.go('/history'),
                  ),
                  const Spacer(),
                  _BottomPanel(
                    phase: _phase,
                    elapsed: _elapsed,
                    totalDuration: _recordDuration,
                    frameCount: _frames.length,
                    errorMessage: _errorMessage,
                    onStart: _startRecording,
                    onRetry: _reset,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UI pieces
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.phase, required this.onBack});

  final _CapturePhase phase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: phase == _CapturePhase.recording ? null : onBack,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Text(
            'BICEP CURL',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.phase,
    required this.elapsed,
    required this.totalDuration,
    required this.frameCount,
    required this.errorMessage,
    required this.onStart,
    required this.onRetry,
  });

  final _CapturePhase phase;
  final Duration elapsed;
  final Duration totalDuration;
  final int frameCount;
  final String? errorMessage;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
        ),
      ),
      child: switch (phase) {
        _CapturePhase.initializing => const _StatusMessage(
          label: 'INITIALIZING CAMERA',
          detail: 'Granting permission and warming up the pose model...',
        ),
        _CapturePhase.ready => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Frame yourself so the full body outline is visible. '
              'Recording lasts 10 seconds — perform your bicep curls at a '
              'deliberate tempo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  'START',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.black,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        _CapturePhase.recording => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountdownRing(elapsed: elapsed, total: totalDuration),
            const SizedBox(height: 16),
            Text(
              '$frameCount frames captured',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white60,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        _CapturePhase.submitting => const _StatusMessage(
          label: 'UPLOADING TO SERVER',
          detail:
              'Sending pose data for clinical analysis. This usually takes a few seconds.',
          showSpinner: true,
        ),
        _CapturePhase.error => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      },
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.label,
    required this.detail,
    this.showSpinner = false,
  });

  final String label;
  final String detail;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.secondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.elapsed, required this.total});

  final Duration elapsed;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (elapsed.inMilliseconds / total.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final remainingSeconds = (total - elapsed).inMilliseconds / 1000;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white12,
              color: theme.colorScheme.secondary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remainingSeconds.clamp(0, 99).toStringAsFixed(1),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'RECORDING',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}
