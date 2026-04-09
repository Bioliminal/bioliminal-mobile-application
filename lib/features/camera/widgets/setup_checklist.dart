import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// SetupChecklistState
// ---------------------------------------------------------------------------

class SetupChecklistState {
  const SetupChecklistState({
    this.angleOk = false,
    this.distanceOk = false,
    this.lightingOk = false,
    this.clothingOk = false,
    this.currentStep = 0,
  });

  final bool angleOk;
  final bool distanceOk;
  final bool lightingOk;
  final bool clothingOk;
  final int currentStep;

  bool get allPassed => angleOk && distanceOk && lightingOk && clothingOk;

  SetupChecklistState copyWith({
    bool? angleOk,
    bool? distanceOk,
    bool? lightingOk,
    bool? clothingOk,
    int? currentStep,
  }) {
    return SetupChecklistState(
      angleOk: angleOk ?? this.angleOk,
      distanceOk: distanceOk ?? this.distanceOk,
      lightingOk: lightingOk ?? this.lightingOk,
      clothingOk: clothingOk ?? this.clothingOk,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

// ---------------------------------------------------------------------------
// SetupChecklistNotifier
// ---------------------------------------------------------------------------

class SetupChecklistNotifier extends Notifier<SetupChecklistState> {
  @override
  SetupChecklistState build() => const SetupChecklistState();

  static const int totalSteps = 4;

  void confirmCurrentStep() {
    switch (state.currentStep) {
      case 0:
        state = state.copyWith(angleOk: true, currentStep: 1);
      case 1:
        state = state.copyWith(distanceOk: true, currentStep: 2);
      case 2:
        state = state.copyWith(lightingOk: true, currentStep: 3);
      case 3:
        state = state.copyWith(clothingOk: true, currentStep: 4);
    }
  }

  void reset() {
    state = const SetupChecklistState();
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

class _SetupStep {
  const _SetupStep({
    required this.title,
    required this.instruction,
    required this.icon,
  });

  final String title;
  final String instruction;
  final IconData icon;
}

const _steps = [
  _SetupStep(
    title: 'Camera Angle',
    instruction: 'Place your phone at waist height, 6\u20138 feet away.',
    icon: Icons.phone_android,
  ),
  _SetupStep(
    title: 'Distance',
    instruction: 'Step back until your full body is visible.',
    icon: Icons.accessibility_new,
  ),
  _SetupStep(
    title: 'Lighting',
    instruction: 'Make sure you\u2019re well-lit from the front.',
    icon: Icons.light_mode,
  ),
  _SetupStep(
    title: 'Clothing',
    instruction: 'Wear fitted clothing so joints are visible.',
    icon: Icons.checkroom,
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

  Widget _buildOverlay(BuildContext context, SetupChecklistState checklistState) {
    final theme = Theme.of(context);
    final currentStep = checklistState.currentStep;

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
                'Step ${currentStep < _steps.length ? currentStep + 1 : _steps.length} of ${_steps.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),

              // Progress indicators for completed steps.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final passed = _isStepPassed(checklistState, i);
                  final isCurrent = i == currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isCurrent ? 32 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: passed
                            ? Colors.green
                            : isCurrent
                                ? Colors.white
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Current step card.
              if (currentStep < _steps.length)
                _StepCard(
                  step: _steps[currentStep],
                  onConfirm: () {
                    ref.read(setupChecklistProvider.notifier).confirmCurrentStep();
                  },
                ),
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
// Individual step card
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.onConfirm});

  final _SetupStep step;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(step.icon, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              step.title,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              step.instruction,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
