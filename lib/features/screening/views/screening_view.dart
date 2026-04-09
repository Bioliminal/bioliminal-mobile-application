import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:auralink/core/providers.dart' as core_providers;
import 'package:auralink/core/theme.dart';
import '../controllers/screening_controller.dart';
import '../widgets/movement_instructions.dart';
import '../widgets/preliminary_findings.dart';
import '../models/movement.dart';

class ScreeningView extends ConsumerStatefulWidget {
  const ScreeningView({super.key});

  @override
  ConsumerState<ScreeningView> createState() => _ScreeningViewState();
}

class _ScreeningViewState extends ConsumerState<ScreeningView> {
  @override
  void initState() {
    super.initState();
    // Save assessment to local storage when screening completes.
    ref.listenManual(screeningControllerProvider, (previous, next) {
      if (next is ScreeningComplete) {
        ref
            .read(core_providers.localStorageServiceProvider)
            .saveAssessment(next.assessment);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screeningState = ref.watch(screeningControllerProvider);

    return switch (screeningState) {
      ScreeningSetup() => _SetupScreen(
          onBegin: () =>
              ref.read(screeningControllerProvider.notifier).startScreening(),
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

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AuraLinkTheme.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.accessibility_new,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Movement Screening',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ll guide you through 4 simple movements. '
                'Each takes about a minute. Just follow the '
                'instructions and move at your own pace.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Overhead Squat \u2022 Single-Leg Balance \u2022 '
                'Overhead Reach \u2022 Forward Fold',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onBegin,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Begin Screening'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveMovementScreen extends StatelessWidget {
  const _ActiveMovementScreen({required this.state});

  final ActiveMovement state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder.
          // TODO: Replace with CameraView from story-1294
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xFF111111),
              child: Center(
                child: Text(
                  'Camera Preview',
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ),
            ),
          ),

          // Movement instructions overlay at top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MovementInstructions(
              config: state.config,
              remaining: state.remaining,
            ),
          ),

          // Progress indicator — top left.
          Positioned(
            top: 48,
            left: 16,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Movement ${state.movementIndex + 1} of '
                  '${screeningMovements.length}: ${state.config.name}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Rep counter — top right.
          Positioned(
            top: 48,
            right: 16,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Rep ${state.repsCompleted} of ${state.config.targetReps}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Countdown timer — center bottom.
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _formatTimer(state.remaining),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),

          // Skip button — bottom right.
          Positioned(
            bottom: 32,
            right: 24,
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => ref
                    .read(screeningControllerProvider.notifier)
                    .skipMovement(),
                child: Text(
                  'Skip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimer(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
      backgroundColor: AuraLinkTheme.screenBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade300,
            ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
