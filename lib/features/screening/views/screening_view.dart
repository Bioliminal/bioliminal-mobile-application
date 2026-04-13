import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bioliminal/core/providers.dart' as core_providers;
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/core/services/biofeedback_engine.dart';
import '../controllers/screening_controller.dart';
import '../../camera/widgets/skeleton_overlay.dart';
import '../../camera/widgets/muscle_activation_sidebar.dart';
import '../widgets/preliminary_findings.dart';
import '../widgets/stick_figure_animation.dart';
import '../../camera/widgets/setup_checklist.dart';
import '../models/movement.dart';

class ScreeningView extends ConsumerStatefulWidget {
  const ScreeningView({super.key});

  @override
  ConsumerState<ScreeningView> createState() => _ScreeningViewState();
}

class _ScreeningViewState extends ConsumerState<ScreeningView>
    with WidgetsBindingObserver {
  late dynamic _cameraControllerNotifier;
  late dynamic _localStorageService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraControllerNotifier = ref.read(
      core_providers.appCameraControllerProvider.notifier,
    );
    _localStorageService = ref.read(core_providers.localStorageServiceProvider);

    // Request camera permission on entry.
    Future.microtask(() {
      _cameraControllerNotifier.requestPermission();
    });

    // Save assessment to local storage when screening completes.
    ref.listenManual(screeningControllerProvider, (previous, next) {
      if (next is ScreeningComplete) {
        _localStorageService.saveAssessment(next.assessment);

        // Stop streaming when finished.
        _cameraControllerNotifier.stopStreaming();
      } else if ((next is ActiveMovement && previous is! ActiveMovement) ||
          (next is EnvironmentSetup && previous is! EnvironmentSetup)) {
        // Start streaming when we move into active state or setup.
        _cameraControllerNotifier.startStreaming();
      } else if (next is ShowingFindings ||
          next is MovementPreparation ||
          next is ScreeningSetup) {
        // Pause streaming while showing findings, prep, or initial setup.
        _cameraControllerNotifier.stopStreaming();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraControllerNotifier.stopStreaming();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraControllerNotifier.stopStreaming();
    } else if (state == AppLifecycleState.resumed) {
      final screeningState = ref.read(screeningControllerProvider);
      if (screeningState is ActiveMovement) {
        _cameraControllerNotifier.startStreaming();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screeningState = ref.watch(screeningControllerProvider);

    return switch (screeningState) {
      ScreeningSetup() => _SetupScreen(
        onBegin: () =>
            ref.read(screeningControllerProvider.notifier).startScreening(),
      ),
      EnvironmentSetup() => const _EnvironmentSetupScreen(),
      MovementPreparation() => _SetupScreen(
        onBegin: () =>
            ref.read(screeningControllerProvider.notifier).startMovement(),
      ),
      ActiveMovement() => _ActiveMovementScreen(state: screeningState),
      ShowingFindings() => PreliminaryFindings(
        feedbackMessage: screeningState.feedbackMessage,
        completedMovementIndex: screeningState.completedMovementIndex,
        onContinue: () => ref
            .read(screeningControllerProvider.notifier)
            .continueToNextMovement(),
      ),
      ScreeningComplete() => _CompleteScreen(state: screeningState),
    };
  }
}

class _SetupScreen extends ConsumerWidget {
  const _SetupScreen({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cameraState = ref
        .watch(core_providers.appCameraControllerProvider)
        .value;

    final screeningState = ref.watch(screeningControllerProvider);

    final MovementConfig? nextMovement;
    if (screeningState is MovementPreparation) {
      nextMovement = screeningState.config;
    } else {
      nextMovement = screeningMovements.first;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BioliminalTheme.screenBackground, BioliminalTheme.surface],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    if (screeningState is MovementPreparation) ...[
                      Text(
                        'NEXT MOVEMENT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextMovement.name.toUpperCase(),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipOval(
                          child: StickFigureAnimation(
                            movementType: nextMovement.type,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        nextMovement.instruction,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Motion Analysis',
                        style: theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We use clinical-grade pose estimation to analyze your movement patterns and identify fascial drivers.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const _MovementStep(
                        icon: Icons.repeat,
                        title: 'Rep-Based Detection',
                        subtitle:
                            'Move naturally; we\'ll track your repetitions automatically.',
                      ),
                      const _MovementStep(
                        icon: Icons.videocam,
                        title: 'Full Body View',
                        subtitle:
                            'Ensure your entire body is visible in the frame.',
                      ),
                    ],

                    if (cameraState is core_providers.CameraPermissionDenied)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Camera permission required to proceed.',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    else if (cameraState is core_providers.CameraError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Camera error: ${cameraState.message}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),

                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            (cameraState is core_providers.CameraReady ||
                                cameraState is core_providers.CameraStreaming)
                            ? onBegin
                            : null,
                        child: const Text('START SCREENING'),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => context.go('/history'),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  tooltip: 'Exit Screening',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementStep extends StatelessWidget {
  const _MovementStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveMovementScreen extends ConsumerWidget {
  const _ActiveMovementScreen({required this.state});

  final ActiveMovement state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref
        .watch(core_providers.appCameraControllerProvider)
        .value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Camera preview
                if (cameraState is core_providers.CameraStreaming ||
                    cameraState is core_providers.CameraReady)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _CameraPreviewWrapper(
                        controller: cameraState is core_providers.CameraStreaming
                            ? cameraState.controller
                            : (cameraState as core_providers.CameraReady).controller,
                      ),
                    ),
                  )
                else
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0xFF0F172A),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Skeleton overlay
                const Positioned.fill(
                  child: RepaintBoundary(child: SkeletonOverlay()),
                ),

                // Consolidated Header
                const _ActiveScreeningHeader(),

                // Consolidated Footer
                const _ActiveScreeningFooter(),
              ],
            ),
          ),
          // Sidebar showing 10-channel EMG
          const MuscleActivationSidebar(),
        ],
      ),
    );
  }
}

class _ActiveScreeningHeader extends ConsumerWidget {
  const _ActiveScreeningHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final movementIndex = ref.watch(
      screeningControllerProvider.select((s) {
        if (s is ActiveMovement) return s.movementIndex;
        return 0;
      }),
    );

    final movementName = ref.watch(
      screeningControllerProvider.select((s) {
        if (s is ActiveMovement) return s.config.name;
        return '';
      }),
    );

    final movementInstruction = ref.watch(
      screeningControllerProvider.select((s) {
        if (s is ActiveMovement) return s.config.instruction;
        return '';
      }),
    );

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BioliminalTheme.glassEffect.copyWith(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/history'),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Exit Screening',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'STEP ${movementIndex + 1} OF ${screeningMovements.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'LIVE AI',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => ref
                                .read(
                                  core_providers
                                      .appCameraControllerProvider
                                      .notifier,
                                )
                                .toggleCamera(),
                            icon: const Icon(
                              Icons.flip_camera_ios_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Flip Camera',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        movementName.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movementInstruction,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: (movementIndex + 1) / screeningMovements.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.secondary,
                  ),
                  minHeight: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveScreeningFooter extends ConsumerWidget {
  const _ActiveScreeningFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(core_providers.isPremiumProvider);
    final biofeedback = ref.watch(biofeedbackEngineProvider);

    final repsCompleted = ref.watch(
      screeningControllerProvider.select((s) {
        if (s is ActiveMovement) return s.repsCompleted;
        return 0;
      }),
    );

    final movementConfig = ref.watch(
      screeningControllerProvider.select((s) {
        if (s is ActiveMovement) return s.config;
        return screeningMovements.first;
      }),
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BioliminalTheme.glassEffect.copyWith(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: StickFigureAnimation(
                        movementType: movementConfig.type,
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.8,
                        ),
                        strokeWidth: 1.5,
                        jointRadius: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$repsCompleted',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 32,
                            color: theme.colorScheme.secondary,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'REPS / ${movementConfig.targetReps}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 16),
                    _BiofeedbackRatio(
                      ratio: biofeedback.gsRatio,
                      label: 'G:S RATIO',
                      cue: biofeedback.activeCue,
                    ),
                  ],
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => ref
                        .read(screeningControllerProvider.notifier)
                        .skipMovement(),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white30,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiofeedbackRatio extends StatelessWidget {
  const _BiofeedbackRatio({
    required this.ratio,
    required this.label,
    required this.cue,
  });
  final double ratio;
  final String label;
  final BiofeedbackCue cue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = cue == BiofeedbackCue.none ? Colors.white30 : Colors.orange;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ratio.toStringAsFixed(1),
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 8, letterSpacing: 1.0),
        ),
      ],
    );
  }
}

class _EnvironmentSetupScreen extends ConsumerWidget {
  const _EnvironmentSetupScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref
        .watch(core_providers.appCameraControllerProvider)
        .value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (cameraState is core_providers.CameraStreaming ||
              cameraState is core_providers.CameraReady)
            Positioned.fill(
              child: _CameraPreviewWrapper(
                controller: cameraState is core_providers.CameraStreaming
                    ? (cameraState).controller
                    : (cameraState as core_providers.CameraReady).controller,
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFF0F172A),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          Positioned.fill(
            child: SetupChecklist(
              onAllPassed: () => ref
                  .read(screeningControllerProvider.notifier)
                  .completeEnvironmentSetup(),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Exit Screening',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewWrapper extends StatelessWidget {
  const _CameraPreviewWrapper({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
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

class _CompleteScreen extends StatefulWidget {
  const _CompleteScreen({required this.state});

  final ScreeningComplete state;

  @override
  State<_CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<_CompleteScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go(
          '/report/${widget.state.assessment.id}',
          extra: widget.state.assessment,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 24),
            Text(
              'Assessment Complete',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparing your report...',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
