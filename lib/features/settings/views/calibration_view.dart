import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../camera/widgets/skeleton_overlay.dart';

// ---------------------------------------------------------------------------
// Critical BlazePose landmarks the server needs to see for bicep curl analysis.
// Indices per the canonical 33-point BlazePose table.
// ---------------------------------------------------------------------------

const int _kNose = 0;
const int _kLeftShoulder = 11;
const int _kRightShoulder = 12;
const int _kLeftHip = 23;
const int _kRightHip = 24;
const int _kLeftKnee = 25;
const int _kRightKnee = 26;
const int _kLeftAnkle = 27;
const int _kRightAnkle = 28;

const List<int> _criticalLandmarks = [
  _kNose,
  _kLeftShoulder,
  _kRightShoulder,
  _kLeftHip,
  _kRightHip,
  _kLeftKnee,
  _kRightKnee,
  _kLeftAnkle,
  _kRightAnkle,
];

// Thresholds
const double _minVisibility = 0.7;
const double _frameMarginX = 0.02;
const double _frameMarginY = 0.05;
const Duration _readyHoldDuration = Duration(milliseconds: 1000);

/// Sealed classification of the current pose-visibility check result.
sealed class _CalibrationCheck {
  const _CalibrationCheck();
}

class _NoPerson extends _CalibrationCheck {
  const _NoPerson();
}

class _Issues extends _CalibrationCheck {
  const _Issues(this.messages);
  final List<String> messages;
}

class _Ready extends _CalibrationCheck {
  const _Ready();
}

/// Real pre-flight calibration. Streams MediaPipe pose, checks that all
/// critical landmarks are in-frame and visible, and holds for 1 second
/// before enabling the continue button.
class CalibrationView extends ConsumerStatefulWidget {
  const CalibrationView({super.key});

  @override
  ConsumerState<CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends ConsumerState<CalibrationView> {
  bool _initializing = true;
  String? _errorMessage;
  _CalibrationCheck _check = const _NoPerson();
  DateTime? _readySince;
  Timer? _holdTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _holdTicker?.cancel();
    ref.read(appCameraControllerProvider.notifier).stopStreaming();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final notifier = ref.read(appCameraControllerProvider.notifier);
    await notifier.requestPermission();
    if (!mounted) return;

    final state = ref.read(appCameraControllerProvider).value;
    if (state is CameraPermissionDenied) {
      setState(() {
        _initializing = false;
        _errorMessage = state.permanent
            ? 'Camera permission is permanently denied. Enable it in system settings.'
            : 'Camera permission is required to calibrate.';
      });
      return;
    }
    if (state is CameraError) {
      setState(() {
        _initializing = false;
        _errorMessage = state.message;
      });
      return;
    }

    await notifier.startStreaming();
    if (!mounted) return;
    setState(() => _initializing = false);

    _holdTicker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _refreshReadyHold(),
    );
  }

  void _refreshReadyHold() {
    if (!mounted) return;
    if (_check is _Ready) {
      _readySince ??= DateTime.now();
      setState(() {});
    } else {
      _readySince = null;
    }
  }

  _CalibrationCheck _classify(List<PoseLandmark> landmarks) {
    if (landmarks.length != 33) return const _NoPerson();

    // If no critical landmark has any visibility, treat as "no person".
    final anyVisible = _criticalLandmarks.any(
      (i) => landmarks[i].visibility > 0.2,
    );
    if (!anyVisible) return const _NoPerson();

    final messages = <String>[];

    // Low-visibility joints first — per critical group.
    final lowVisHead = landmarks[_kNose].visibility < _minVisibility;
    final lowVisShoulders =
        math.min(
          landmarks[_kLeftShoulder].visibility,
          landmarks[_kRightShoulder].visibility,
        ) <
        _minVisibility;
    final lowVisHips =
        math.min(
          landmarks[_kLeftHip].visibility,
          landmarks[_kRightHip].visibility,
        ) <
        _minVisibility;
    final lowVisKnees =
        math.min(
          landmarks[_kLeftKnee].visibility,
          landmarks[_kRightKnee].visibility,
        ) <
        _minVisibility;
    final lowVisAnkles =
        math.min(
          landmarks[_kLeftAnkle].visibility,
          landmarks[_kRightAnkle].visibility,
        ) <
        _minVisibility;

    // Out-of-frame checks (top / bottom / sides) — use the relevant landmark.
    final headTooHigh = landmarks[_kNose].y < _frameMarginY;
    final anklesTooLow =
        math.max(landmarks[_kLeftAnkle].y, landmarks[_kRightAnkle].y) >
        1 - _frameMarginY;
    final leftCut =
        math.min(landmarks[_kLeftShoulder].x, landmarks[_kLeftHip].x) <
        _frameMarginX;
    final rightCut =
        math.max(landmarks[_kRightShoulder].x, landmarks[_kRightHip].x) >
        1 - _frameMarginX;

    if (headTooHigh) messages.add('Tilt the camera down — head is cut off.');
    if (anklesTooLow || lowVisAnkles) {
      messages.add('Step back — ankles need to be fully visible.');
    }
    if (leftCut || rightCut) {
      messages.add('Center yourself in the frame.');
    }
    if (lowVisHead && !headTooHigh) {
      messages.add('Face the camera.');
    }
    if (lowVisShoulders || lowVisHips) {
      messages.add('Improve lighting — torso landmarks are uncertain.');
    }
    if (lowVisKnees && !(leftCut || rightCut)) {
      messages.add('Knees are unclear — check clothing and lighting.');
    }

    if (messages.isEmpty) return const _Ready();
    return _Issues(messages);
  }

  bool get _holdComplete {
    final since = _readySince;
    if (since == null) return false;
    return DateTime.now().difference(since) >= _readyHoldDuration;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<PoseLandmark>>(currentLandmarksProvider, (_, next) {
      final result = _classify(next);
      if (result.runtimeType != _check.runtimeType ||
          (result is _Issues && _check is _Issues &&
              !_sameMessages((_check as _Issues).messages, result.messages))) {
        setState(() => _check = result);
      } else {
        _check = result;
      }
    });

    final cameraState = ref.watch(appCameraControllerProvider).value;
    final isFrontCamera =
        ref.watch(cameraDescriptionProvider)?.lensDirection ==
        CameraLensDirection.front;

    if (_errorMessage != null) {
      return _CalibrationError(message: _errorMessage!);
    }

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
                  _TopBar(onClose: () => context.go('/history')),
                  const Spacer(),
                  _CalibrationStatus(
                    initializing: _initializing,
                    check: _check,
                    holdComplete: _holdComplete,
                    onContinue: () => context.go('/history'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameMessages(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// UI pieces
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Text(
            'FRAMING CHECK',
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

class _CalibrationStatus extends StatelessWidget {
  const _CalibrationStatus({
    required this.initializing,
    required this.check,
    required this.holdComplete,
    required this.onContinue,
  });

  final bool initializing;
  final _CalibrationCheck check;
  final bool holdComplete;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (initializing) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'INITIALIZING CAMERA',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      );
    }

    final (color, title, detail, showContinue) = switch (check) {
      _NoPerson() => (
        Colors.white38,
        'NO PERSON DETECTED',
        'Stand in frame so the camera can see your full body.',
        false,
      ),
      _Issues(messages: final msgs) => (
        Colors.orange,
        'ADJUST YOUR FRAMING',
        msgs.join('  •  '),
        false,
      ),
      _Ready() => (
        theme.colorScheme.secondary,
        holdComplete ? 'READY TO CAPTURE' : 'HOLD STILL…',
        holdComplete
            ? 'Camera and pose model look good. Tap continue when ready.'
            : 'Keep your full body visible for a moment.',
        holdComplete,
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: showContinue ? onContinue : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                'CONTINUE TO CAPTURE',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationError extends StatelessWidget {
  const _CalibrationError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('FRAMING CHECK'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
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
