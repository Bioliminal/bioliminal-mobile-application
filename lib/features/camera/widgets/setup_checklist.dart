import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/domain/models.dart';

// ---------------------------------------------------------------------------
// AI validation thresholds
// ---------------------------------------------------------------------------

const int kRequiredLandmarkCount = 33;
const double kMinLandmarkVisibility = 0.5;
const double kMinLightingVisibility = 0.7;
const double kHipYMin = 0.4;
const double kHipYMax = 0.6;

const List<int> kKeyJointIndices = [11, 12, 23, 24, 25, 26, 27, 28];
const int kLeftHipIndex = 23;
const int kRightHipIndex = 24;

// ---------------------------------------------------------------------------
// SetupChecklistState
// ---------------------------------------------------------------------------

class SetupChecklistState {
  const SetupChecklistState({
    this.angleOk = false,
    this.distanceOk = false,
    this.lightingOk = false,
    this.clothingOk = false,
  });

  final bool angleOk;
  final bool distanceOk;
  final bool lightingOk;
  final bool clothingOk;

  bool get allPassed => angleOk && distanceOk && lightingOk && clothingOk;

  int get completedCount =>
      (angleOk ? 1 : 0) +
      (distanceOk ? 1 : 0) +
      (lightingOk ? 1 : 0) +
      (clothingOk ? 1 : 0);

  SetupChecklistState copyWith({
    bool? angleOk,
    bool? distanceOk,
    bool? lightingOk,
    bool? clothingOk,
  }) {
    return SetupChecklistState(
      angleOk: angleOk ?? this.angleOk,
      distanceOk: distanceOk ?? this.distanceOk,
      lightingOk: lightingOk ?? this.lightingOk,
      clothingOk: clothingOk ?? this.clothingOk,
    );
  }
}

// ---------------------------------------------------------------------------
// SetupChecklistNotifier — watches landmarks, auto-validates conditions
// ---------------------------------------------------------------------------

class SetupChecklistNotifier extends Notifier<SetupChecklistState> {
  bool _clothingConfirmed = false;

  @override
  SetupChecklistState build() {
    final landmarks = ref.watch(currentLandmarksProvider);
    final validated = _validateLandmarks(landmarks);
    return validated.copyWith(clothingOk: _clothingConfirmed);
  }

  static const int totalSteps = 4;

  SetupChecklistState _validateLandmarks(List<PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return const SetupChecklistState();

    final distanceOk = _checkDistance(landmarks);
    final lightingOk = _checkLighting(landmarks);
    final angleOk = _checkCameraAngle(landmarks);

    return SetupChecklistState(
      distanceOk: distanceOk,
      lightingOk: lightingOk,
      angleOk: angleOk,
    );
  }

  bool _checkDistance(List<PoseLandmark> landmarks) {
    if (landmarks.length < kRequiredLandmarkCount) return false;
    return landmarks.every((lm) => lm.visibility > kMinLandmarkVisibility);
  }

  bool _checkLighting(List<PoseLandmark> landmarks) {
    if (landmarks.length <= kKeyJointIndices.reduce((a, b) => a > b ? a : b)) {
      return false;
    }
    double sum = 0;
    for (final idx in kKeyJointIndices) {
      sum += landmarks[idx].visibility;
    }
    return (sum / kKeyJointIndices.length) > kMinLightingVisibility;
  }

  bool _checkCameraAngle(List<PoseLandmark> landmarks) {
    if (landmarks.length <= kRightHipIndex) return false;
    final leftHipY = landmarks[kLeftHipIndex].y;
    final rightHipY = landmarks[kRightHipIndex].y;
    return leftHipY >= kHipYMin &&
        leftHipY <= kHipYMax &&
        rightHipY >= kHipYMin &&
        rightHipY <= kHipYMax;
  }

  void confirmClothing() {
    _clothingConfirmed = true;
    ref.invalidateSelf();
  }

  void reset() {
    _clothingConfirmed = false;
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final setupChecklistProvider =
    NotifierProvider<SetupChecklistNotifier, SetupChecklistState>(
      SetupChecklistNotifier.new,
    );

// ---------------------------------------------------------------------------
// Setup step definitions
// ---------------------------------------------------------------------------

class SetupStep {
  const SetupStep({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.isManual,
  });

  final String title;
  final String instruction;
  final IconData icon;
  final bool isManual;
}

const setupSteps = [
  SetupStep(
    title: 'Camera Angle',
    instruction: 'Place your phone at waist height, 6\u20138 feet away.',
    icon: Icons.phone_android,
    isManual: false,
  ),
  SetupStep(
    title: 'Distance',
    instruction: 'Step back until your full body is visible.',
    icon: Icons.accessibility_new,
    isManual: false,
  ),
  SetupStep(
    title: 'Lighting',
    instruction: 'Make sure you\u2019re well-lit from the front.',
    icon: Icons.light_mode,
    isManual: false,
  ),
  SetupStep(
    title: 'Clothing',
    instruction: 'Wear fitted clothing so joints are visible.',
    icon: Icons.checkroom,
    isManual: true,
  ),
];

// ---------------------------------------------------------------------------
// SetupChecklist widget
// ---------------------------------------------------------------------------

class SetupChecklist extends ConsumerStatefulWidget {
  const SetupChecklist({super.key, required this.onAllPassed});

  final VoidCallback onAllPassed;

  @override
  ConsumerState<SetupChecklist> createState() => _SetupChecklistState();
}

class _SetupChecklistState extends ConsumerState<SetupChecklist>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onAllPassed() {
    if (_dismissed) return;
    _dismissed = true;
    _fadeController.forward().then((_) {
      widget.onAllPassed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistState = ref.watch(setupChecklistProvider);

    if (checklistState.allPassed && !_dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAllPassed());
    }

    if (_dismissed) {
      return FadeTransition(
        opacity: ReverseAnimation(_fadeAnimation),
        child: _buildOverlay(context, checklistState),
      );
    }

    return _buildOverlay(context, checklistState);
  }

  Widget _buildOverlay(
    BuildContext context,
    SetupChecklistState checklistState,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Setup',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${checklistState.completedCount} of ${setupSteps.length} ready',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),

              // Progress indicators.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(setupSteps.length, (i) {
                  final passed = _isStepPassed(checklistState, i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: passed ? Colors.green : Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // All step cards shown simultaneously.
              ...List.generate(setupSteps.length, (i) {
                final step = setupSteps[i];
                final passed = _isStepPassed(checklistState, i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StepCard(
                    step: step,
                    passed: passed,
                    onConfirm: step.isManual && !passed
                        ? () => ref
                              .read(setupChecklistProvider.notifier)
                              .confirmClothing()
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStepPassed(SetupChecklistState s, int index) {
    return switch (index) {
      0 => s.angleOk,
      1 => s.distanceOk,
      2 => s.lightingOk,
      3 => s.clothingOk,
      _ => false,
    };
  }
}

// ---------------------------------------------------------------------------
// Individual step card — AI-validated steps show status, manual steps show button
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.passed, this.onConfirm});

  final SetupStep step;
  final bool passed;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = passed ? Colors.green : Colors.orange;

    return Card(
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(step.icon, size: 32, color: statusColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.instruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (passed)
              const Icon(Icons.check_circle, color: Colors.green, size: 28)
            else if (onConfirm != null)
              FilledButton(onPressed: onConfirm, child: const Text('Confirm'))
            else
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
