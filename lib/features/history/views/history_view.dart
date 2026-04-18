import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../services/archetype_classifier.dart';
import '../services/trend_detection_service.dart';
import '../widgets/assessment_timeline.dart';

final _assessmentsProvider = FutureProvider<List<Assessment>>((ref) {
  return ref.read(localStorageServiceProvider).listAssessments();
});

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssessments = ref.watch(_assessmentsProvider);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            Expanded(
              child: asyncAssessments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load history: $e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (assessments) {
                  if (assessments.isEmpty) return const _EmptyState();
                  return _PopulatedList(assessments: assessments);
                },
              ),
            ),
            const _NewScanBar(),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROGRESS', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 12),
          const _HardwareStatusRow(),
        ],
      ),
    );
  }
}

class _HardwareStatusRow extends ConsumerWidget {
  const _HardwareStatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(hardwareControllerProvider);

    final Color color;
    final String label;
    final String? action;

    switch (state) {
      case HardwareConnectionState.connected:
        color = theme.colorScheme.secondary;
        label = 'CONNECTED';
        action = null;
      case HardwareConnectionState.scanning:
      case HardwareConnectionState.connecting:
        color = Colors.orange;
        label = 'SEARCHING';
        action = null;
      case HardwareConnectionState.disconnected:
        color = Colors.white.withValues(alpha: 0.3);
        label = 'OFFLINE';
        action = 'TAP TO PAIR';
    }

    return InkWell(
      onTap: state == HardwareConnectionState.disconnected
          ? () => ref.read(hardwareControllerProvider.notifier).startScan()
          : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[
              Text(
                '  ·  ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Text(
                action,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 48),
          Text(
            'No sessions\nyet',
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Complete your first screening to start tracking mobility trends over time.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PopulatedList extends StatelessWidget {
  const _PopulatedList({required this.assessments});
  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendReport = TrendDetectionService.analyzeTrends(assessments);
    final archetype = ArchetypeClassifier.classify(assessments);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArchetypeHero(archetype: archetype, sessionCount: assessments.length),
          const SizedBox(height: 24),
          _TrendGrid(trendReport: trendReport),
          const SizedBox(height: 40),
          Text(
            'SESSIONS',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 2.0,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 16),
          AssessmentTimeline(
            assessments: assessments,
            trendReport: trendReport,
            onTap: (a) => context.go('/report/${a.id}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NewScanBar extends StatelessWidget {
  const _NewScanBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => context.go('/capture'),
          child: const Text('NEW SCAN'),
        ),
      ),
    );
  }
}

class _ArchetypeHero extends StatelessWidget {
  const _ArchetypeHero({required this.archetype, required this.sessionCount});
  final MobilityArchetype archetype;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BioliminalTheme.glassEffect.copyWith(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PROFILE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _archetypeLabel(archetype).toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your last $sessionCount sessions, we see a consistent pattern in your ${_archetypeArea(archetype)} chain.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  String _archetypeLabel(MobilityArchetype a) {
    return a.name.replaceAll('Dominant', '-Dominant');
  }

  String _archetypeArea(MobilityArchetype a) {
    return switch (a) {
      MobilityArchetype.ankleDominant => 'ankle and foot',
      MobilityArchetype.hipDominant => 'hip and pelvis',
      MobilityArchetype.trunkDominant => 'core and spine',
      _ => 'overall movement',
    };
  }
}

class _TrendGrid extends StatelessWidget {
  const _TrendGrid({required this.trendReport});
  final TrendReport trendReport;

  @override
  Widget build(BuildContext context) {
    final improving = trendReport.trends
        .where((t) => t.trend == TrendClassification.improving)
        .length;
    final worsening = trendReport.trends
        .where((t) => t.trend == TrendClassification.worsening)
        .length;
    final stable = trendReport.trends
        .where((t) => t.trend == TrendClassification.stable)
        .length;

    return Row(
      children: [
        Expanded(
          child: _TrendCard(
            count: improving,
            label: 'IMPROVING',
            color: BioliminalTheme.confidenceHigh,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrendCard(
            count: stable,
            label: 'STABLE',
            color: BioliminalTheme.confidenceMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrendCard(
            count: worsening,
            label: 'REGRESSING',
            color: BioliminalTheme.confidenceLow,
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.count,
    required this.label,
    required this.color,
  });
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BioliminalTheme.glassEffect,
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 1.0,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
