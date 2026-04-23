import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../camera/controllers/camera_controller.dart'
    show AppCameraController;
import '../../camera/widgets/skeleton_overlay.dart';
import '../controllers/bicep_curl_controller.dart';
import '../models/compensation_reference.dart';
import '../services/pose_math.dart';
import 'bicep_curl_overlays.dart';
import 'widgets/muscle_activity_overlay.dart';

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

  // Captured in initState so dispose() can clean up without touching `ref`.
  // Riverpod 3 disallows ref access during dispose.
  late final AppCameraController _cameraNotifier;
  late final BicepCurlController _bicepNotifier;

  static const Duration _framingHoldDuration = Duration(seconds: 1);
  static const double _minVisibility = 0.6;

  @override
  void initState() {
    super.initState();
    _cameraNotifier = ref.read(appCameraControllerProvider.notifier);
    _bicepNotifier = ref.read(bicepCurlControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapCamera());
  }

  @override
  void dispose() {
    _framingTicker?.cancel();
    _cameraNotifier.stopStreaming();
    unawaited(_bicepNotifier.cancel());
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

    // CV is the base capability — start the session as soon as the camera
    // is streaming, without waiting for a listener to observe the state
    // transition. Garment is supplemental; its connection listener remains
    // for the case where hardware connects mid-session.
    _maybeStartSession();
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
    if (complete.log.reps.isEmpty) {
      // User cancelled before any reps — nothing to debrief.
      if (mounted) context.go('/history');
      return;
    }
    final sessionId = 'bicep_${complete.log.startedAt.millisecondsSinceEpoch}';
    final record = SessionRecord(
      sessionId: sessionId,
      movement: 'bicep_curl',
      capturedAt: complete.log.startedAt,
      bicepCurl: complete.log.toJson(),
    );
    await ref.read(localStorageServiceProvider).saveSessionRecord(record);
    // Refresh the shared records provider so HistoryView picks up the new
    // session when the user returns from debrief.
    ref.invalidate(sessionRecordsProvider);
    if (!mounted) return;
    context.go('/bicep-curl/debrief/$sessionId');
  }

  bool _armVisible(List<PoseLandmark> landmarks) {
    if (landmarks.length != 33) return false;
    final shoulder = widget.armSide == ArmSide.left
        ? kLeftShoulder
        : kRightShoulder;
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

  /// Kicks off the session as soon as the camera is streaming. Garment is
  /// optional — if BLE connects later, the controller's hardware listener
  /// clears `_bleDroppedDuringSet` semantics on its own.
  void _maybeStartSession() {
    if (_attemptedSessionStart) return;
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

    // Select only the streaming-state CameraController. The underlying
    // provider emits a new CameraStreaming state on every processed frame
    // (~30fps); watching it directly would rebuild the full Scaffold at
    // that rate. This selector fires only when the controller identity
    // changes (start/stop streaming, toggle camera).
    final streamingController = ref.watch(
      appCameraControllerProvider.select<CameraController?>((v) {
        final s = v.value;
        return s is CameraStreaming ? s.controller : null;
      }),
    );

    // Side-effect: persist + navigate on Complete (commit 8 routes to debrief).
    ref.listen<BicepCurlState>(bicepCurlControllerProvider, (_, next) {
      if (next is BicepCurlComplete && mounted) {
        unawaited(_persistAndExit(next));
      }
    });

    // Side-effect: try starting session when BLE connects + camera streams.
    // Selectors on the listen calls prevent them from firing 30x/sec.
    ref.listen<HardwareConnectionState>(
      hardwareControllerProvider,
      (_, _) => _maybeStartSession(),
    );
    ref.listen<bool>(
      appCameraControllerProvider.select((v) => v.value is CameraStreaming),
      (_, _) => _maybeStartSession(),
    );

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
            _cameraStack(streamingController),

          // Cue flash overlay (no-op until visualBus emits).
          Positioned.fill(
            child: CueFlashIndicator(
              bus: ref.read(bicepCurlControllerProvider.notifier).visualBus,
            ),
          ),

          // Too-fast banner — fires for CueContent.repTooFast only.
          // Complementary to the flash indicator + cue timeline entry.
          Positioned.fill(
            child: RepTooFastBanner(
              bus: ref.read(bicepCurlControllerProvider.notifier).visualBus,
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

  Widget _cameraStack(CameraController? controller) {
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _CoverCameraPreview(controller: controller),
        const SkeletonOverlay(),
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
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            tooltip: 'Flip camera',
            onPressed: () {
              _framingReadySince = null;
              ref.read(appCameraControllerProvider.notifier).toggleCamera();
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final hw = ref.watch(hardwareControllerProvider);
              final connected = hw == HardwareConnectionState.connected;
              return IconButton(
                icon: Icon(
                  connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: connected ? BioliminalTheme.accent : Colors.white54,
                ),
                tooltip: connected
                    ? 'Garment connected — EMG fatigue tracking on'
                    : 'Optional: connect Bioliminal Garment for EMG fatigue tracking',
                onPressed: connected
                    ? null
                    : () => ref
                          .read(hardwareControllerProvider.notifier)
                          .startScan(),
              );
            },
          ),
          const Spacer(),
          if (s is BicepCurlCalibrating)
            StatusBadge(text: 'CALIBRATING ${s.repsCompleted}/5'),
          if (s is BicepCurlActive) const StatusBadge(text: 'ACTIVE'),
        ],
      ),
    );
  }

  Widget _hudCenter(BicepCurlState s, HardwareConnectionState hw) {
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
    // Hybrid rep-counting mode: CV (Aaron's RepDecisionPolicy) is the
    // authoritative rep count shown to the user. Firmware rep count arrives
    // on FF02 as an observational stream — surfaced only via a subtle amber
    // dot next to the counter when it drifts past the reconciliation
    // threshold. Muscle sparkline + compensation badge remain from Rajat's
    // hardware-led UI; fatigue bar stays removed (firmware owns fatigue).
    if (s is BicepCurlActive || s is BicepCurlCalibrating) {
      final cvRepCount = ref.watch(cvRepCountProvider);
      final label = s is BicepCurlCalibrating ? 'CALIBRATING' : 'REPS';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s is BicepCurlActive && s.currentCompensating) ...[
              const CompensationBadge(),
              const SizedBox(height: 12),
            ],
            _RepCounterWithReconciliation(
              repCount: cvRepCount,
              label: label,
            ),
            const SizedBox(height: 12),
            const MuscleActivityOverlay(),
            const SizedBox(height: 16),
            _EndSetButton(onPressed: _endSet),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _endSet() async {
    await ref.read(bicepCurlControllerProvider.notifier).endSession();
  }
}

class _EndSetButton extends StatelessWidget {
  const _EndSetButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('END SET'),
        style: FilledButton.styleFrom(
          backgroundColor: BioliminalTheme.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Wraps the [RepCounter] with a subtle amber dot in the top-right corner
/// that activates when the firmware-reported rep count drifts from the CV
/// count. Inactive/invisible by default — the user never sees it unless the
/// two counters materially disagree.
class _RepCounterWithReconciliation extends ConsumerWidget {
  const _RepCounterWithReconciliation({
    required this.repCount,
    required this.label,
  });

  final int repCount;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciliation = ref.watch(repReconciliationProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepCounter(repCount: repCount, label: label),
        Positioned(
          top: -4,
          right: -4,
          child: ValueListenableBuilder<RepCountReconciliation>(
            valueListenable: reconciliation,
            builder: (_, value, _) {
              if (!value.disagreeing) return const SizedBox.shrink();
              return Tooltip(
                message:
                    'Hardware rep count differs: ${value.hw} vs ${value.cv}',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});
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
