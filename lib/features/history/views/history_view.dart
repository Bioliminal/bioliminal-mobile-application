import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
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
      appBar: AppBar(title: const Text('Progress Journey')),
      body: asyncAssessments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (assessments) {
          if (assessments.isEmpty) {
            return _EmptyState();
          }

          final trendReport =
              TrendDetectionService.analyzeTrends(assessments);
          final archetype = ArchetypeClassifier.classify(assessments);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryHeader(
                  trendReport: trendReport,
                  archetype: archetype,
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8),
                AssessmentTimeline(
                  assessments: assessments,
                  trendReport: trendReport,
                  onTap: (assessment) {
                    context.go('/report/${assessment.id}');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.trendReport,
    required this.archetype,
  });

  final TrendReport trendReport;
  final MobilityArchetype archetype;

  @override
  Widget build(BuildContext context) {
    final improving = trendReport.trends
        .where((t) => t.trend == TrendClassification.improving)
        .length;
    final stable = trendReport.trends
        .where((t) => t.trend == TrendClassification.stable)
        .length;
    final worsening = trendReport.trends
        .where((t) => t.trend == TrendClassification.worsening)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ArchetypeBadge(archetype: archetype),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TrendCount(
                  count: improving,
                  label: 'improving',
                  icon: Icons.trending_down,
                  color: AuraLinkTheme.confidenceHigh,
                ),
                const SizedBox(width: 16),
                _TrendCount(
                  count: stable,
                  label: 'stable',
                  icon: Icons.trending_flat,
                  color: AuraLinkTheme.confidenceMedium,
                ),
                const SizedBox(width: 16),
                _TrendCount(
                  count: worsening,
                  label: 'worsening',
                  icon: Icons.trending_up,
                  color: AuraLinkTheme.confidenceLow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchetypeBadge extends StatelessWidget {
  const _ArchetypeBadge({required this.archetype});

  final MobilityArchetype archetype;

  static String _label(MobilityArchetype archetype) {
    return switch (archetype) {
      MobilityArchetype.ankleDominant => 'Ankle-Dominant',
      MobilityArchetype.hipDominant => 'Hip-Dominant',
      MobilityArchetype.trunkDominant => 'Trunk-Dominant',
      MobilityArchetype.hypermobile => 'Hypermobile',
      MobilityArchetype.balanced => 'Balanced',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _label(archetype),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TrendCount extends StatelessWidget {
  const _TrendCount({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Complete your first screening to start tracking progress',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/screening'),
              child: const Text('Start Screening'),
            ),
          ],
        ),
      ),
    );
  }
}
