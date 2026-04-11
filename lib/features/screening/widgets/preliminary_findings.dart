import 'package:flutter/material.dart';

import 'package:auralink/core/theme.dart';
import '../models/movement.dart';

class PreliminaryFindings extends StatelessWidget {
  const PreliminaryFindings({
    super.key,
    required this.feedbackMessage,
    required this.completedMovementIndex,
    required this.onContinue,
  });

  final String feedbackMessage;
  final int completedMovementIndex;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedConfig = screeningMovements[completedMovementIndex];
    final isFinalNext = completedMovementIndex == screeningMovements.length - 2;

    return Scaffold(
      backgroundColor: AuraLinkTheme.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                '${completedConfig.name} Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  feedbackMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _ProgressDots(
                total: screeningMovements.length,
                completed: completedMovementIndex + 1,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isFinalNext
                        ? 'Continue to Final Movement'
                        : 'Continue to Next Movement',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.green.shade300 : Colors.white24,
            ),
          ),
        );
      }),
    );
  }
}
