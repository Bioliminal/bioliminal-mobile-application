import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../camera/widgets/skeleton_overlay.dart';
import '../controllers/bicep_curl_controller.dart';
import '../models/compensation_reference.dart';
import '../services/pose_math.dart';
import 'bicep_curl_overlays.dart';

/// Live bicep curl session view.
///
/// Lifecycle:
/// 1. On enter: ensure camera permission + streaming.
/// 2. While BLE not connected: show "Connect Bioliminal Garment" CTA.
/// 3. Once camera streaming + BLE connected: call [BicepCurlController.startSession].
/// 4. Pre-flight framing check (curling-arm landmarks visible for 1 s) →
///    auto-call [BicepCurlController.markFramingComplete].
/// 5. Calibration: silent rep counter "CALIBRATING N/5".
/// 6. Active: rep counter + fatigue bar + compensation badge + cue flashes.
/// 7. Idle 10 s after a rep → controller auto-ends, navigate back to /history
///    (commit 8 routes to /bicep-curl/debrief instead).
class BicepCurlView extends ConsumerStatefulWidget {
  const BicepCurlView({super.key, this.armSide = ArmSide.right});

  final ArmSide armSide;

  @override
  ConsumerState<BicepCurlView> createState() => _BicepCurlViewState();
}

class _BicepCurlViewState extends ConsumerState<BicepCurlView> {
  bool _cameraInitializing = true;
  String? _cameraError;
  bool _attemptedSessionStart = false;
  DateTime? _framingReadySince;
  Timer? _framingTicker;

  static const Duration _framingHoldDuration = Duration(seconds: 1);
  static const double _minVisibility = 0.6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapCamera());
  }

  @override
  void dispose() {
    _framingTicker?.cancel();
    ref.read(appCameraControllerProvider.notifier).stopStreaming();
    unawaited(ref.read(bicepCurlControllerProvider.notifier).cancel());
    super.dispose();
  }

  Future<void> _bootstrapCamera() async {
    final notifier = ref.read(appCameraControllerProvider.notifier);
    await notifier.requestPermission();
    if (!mounted) return;

    final state = ref.read(appCameraControllerProvider).value;
    if (state is CameraPermissionDenied) {
      setState(() {
        _cameraInitializing = false;
        _cameraError = state.permanent
            ? 'Camera permission is permanently denied. Enable it in system settings.'
            : 'Camera permission is required.';
      });
      return;
    }
    if (state is CameraError) {
      setState(() {
        _cameraInitializing = false;
        _cameraError = state.message;
      });
      return;
    }

    await notifier.startStreaming();
    if (!mounted) return;
    setState(() => _cameraInitializing = false);

    _framingTicker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _maybeAdvanceFraming(),
    );
  }

  /// Tries to advance Setup → Calibrating once the curling arm landmarks
  /// are visible for [_framingHoldDuration].
  void _maybeAdvanceFraming() {
    if (!mounted) return;
    final controllerState = ref.read(bicepCurlControllerProvider);
    if (controllerState is! BicepCurlSetup) return;

    final landmarks = ref.read(currentLandmarksProvider);
    if (!_armVisible(landmarks)) {
      _framingReadySince = null;
      return;
    }

    _framingReadySince ??= DateTime.now();
    final held = DateTime.now().difference(_framingReadySince!);
    if (held >= _framingHoldDuration) {
      ref.read(bicepCurlControllerProvider.notifier).markFramingComplete();
    } else {
      setState(() {}); // refresh hold progress UI
    }
  }

  Future<void> _persistAndExit(BicepCurlComplete complete) async {
    // Skip empty sessions (user cancelled before any reps landed).
    if (complete.log.reps.isNotEmpty) {
      final record = SessionRecord(
        sessionId: 'bicep_${complete.log.startedAt.millisecondsSinceEpoch}',
        movement: 'bicep_curl',
        capturedAt: complete.log.startedAt,
        bicepCurl: complete.log.toJson(),
      );
      await ref.read(localStorageServiceProvider).saveSessionRecord(record);
    }
    if (!mounted) return;
    context.go('/history');
  }

  bool _armVisible(List<PoseLandmark> landmarks) {
    if (landmarks.length != 33) return false;
    final shoulder =
        widget.armSide == ArmSide.left ? kLeftShoulder : kRightShoulder;
    final elbow = widget.armSide == ArmSide.left ? kLeftElbow : kRightElbow;
    final wrist = widget.armSide == ArmSide.left ? kLeftWrist : kRightWrist;
    return landmarks[shoulder].visibility > _minVisibility &&
        landmarks[elbow].visibility > _minVisibility &&
        landmarks[wrist].visibility > _minVisibility;
  }

  double get _framingHoldProgress {
    final since = _framingReadySince;
    if (since == null) return 0;
    final ms = DateTime.now().difference(since).inMilliseconds;
    return (ms / _framingHoldDuration.inMilliseconds).clamp(0, 1);
  }

  /// Called by ref.listen when the BLE connection comes up. Kicks off
  /// the session if we're idle and the camera is streaming.
  void _maybeStartSession() {
    if (_attemptedSessionStart) return;
    final hardware = ref.read(hardwareControllerProvider);
    if (hardware != HardwareConnectionState.connected) return;
    final cam = ref.read(appCameraControllerProvider).value;
    if (cam is! CameraStreaming) return;

    _attemptedSessionStart = true;
    ref
        .read(bicepCurlControllerProvider.notifier)
        .startSession(side: widget.armSide);
  }

  @override
  Widget build(BuildContext context) {
    // Watchers — drive rebuilds.
    final controllerState = ref.watch(bicepCurlControllerProvider);
    final hardwareState = ref.watch(hardwareControllerProvider);
    final cameraAsync = ref.watch(appCameraControllerProvider);

    // Side-effect: persist + navigate on Complete (commit 8 routes to debrief).
    ref.listen<BicepCurlState>(bicepCurlControllerProvider, (_, next) {
      if (next is BicepCurlComplete && mounted) {
        unawaited(_persistAndExit(next));
      }
    });

    // Side-effect: try starting session when BLE connects + camera streams.
    ref.listen<HardwareConnectionState>(hardwareControllerProvider,
        (_, _) => _maybeStartSession());
    ref.listen(appCameraControllerProvider, (_, _) => _maybeStartSession());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraInitializing)
            const Center(child: CircularProgressIndicator())
          else if (_cameraError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _cameraError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _cameraStack(cameraAsync.value),

          // Cue flash overlay (no-op until visualBus emits).
          Positioned.fill(
            child: CueFlashIndicator(
              bus: ref
                  .read(bicepCurlControllerProvider.notifier)
                  .visualBus,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _topBar(controllerState),
                const Spacer(),
                _hudCenter(controllerState, hardwareState),
                _hudBottom(controllerState),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraStack(CameraState? cameraState) {
    final isStreaming = cameraState is CameraStreaming;
    if (!isStreaming) {
      return const SizedBox.shrink();
    }
    final desc = ref.read(cameraDescriptionProvider);
    final isFront = desc?.lensDirection == CameraLensDirection.front;
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(cameraState.controller),
        SkeletonOverlay(isFrontCamera: isFront),
      ],
    );
  }

  Widget _topBar(BicepCurlState s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'End set',
            onPressed: () async {
              if (s is BicepCurlActive || s is BicepCurlCalibrating) {
                await ref
                    .read(bicepCurlControllerProvider.notifier)
                    .endSession();
              } else {
                if (mounted) context.go('/history');
              }
            },
          ),
          const Spacer(),
          if (s is BicepCurlCalibrating)
            StatusBadge(
              text: 'CALIBRATING ${s.repsCompleted}/5',
            ),
          if (s is BicepCurlActive)
            const StatusBadge(text: 'ACTIVE'),
        ],
      ),
    );
  }

  Widget _hudCenter(BicepCurlState s, HardwareConnectionState hw) {
    if (hw != HardwareConnectionState.connected) {
      return _ConnectGarmentCta(onConnect: () {
        ref.read(hardwareControllerProvider.notifier).startScan();
      });
    }
    if (s is BicepCurlSetup) {
      return FramingCheckOverlay(
        holdProgress: _framingHoldProgress,
        message: _framingHoldProgress > 0
            ? 'Hold steady…'
            : 'Step into frame so your curling arm is fully visible',
      );
    }
    if (s is BicepCurlError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          s.message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _hudBottom(BicepCurlState s) {
    if (s is BicepCurlActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.currentCompensating) ...[
              const CompensationBadge(),
              const SizedBox(height: 12),
            ],
            FatigueBar(
              dropFraction: s.currentDropFraction,
              emgOnline: s.emgOnline,
            ),
            const SizedBox(height: 14),
            RepCounter(repCount: s.reps.length, label: 'REPS'),
          ],
        ),
      );
    }
    if (s is BicepCurlCalibrating) {
      return RepCounter(repCount: s.repsCompleted, label: 'CALIBRATION');
    }
    return const SizedBox.shrink();
  }
}

class _ConnectGarmentCta extends StatelessWidget {
  const _ConnectGarmentCta({required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_searching,
              color: Colors.white, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Connect Bioliminal Garment',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: BioliminalTheme.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('SCAN'),
          ),
        ],
      ),
    );
  }
}
