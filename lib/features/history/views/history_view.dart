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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('PROGRESS'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 90,
        ), // Offset for floating bottom nav
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/screening'),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: BioliminalTheme.screenBackground,
          label: const Text(
            'NEW SCAN',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          icon: const Icon(Icons.add),
        ),
      ),
      body: asyncAssessments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (assessments) {
          if (assessments.isEmpty) return _EmptyState();

          final trendReport = TrendDetectionService.analyzeTrends(assessments);
          final archetype = ArchetypeClassifier.classify(assessments);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _ArchetypeHero(
                  archetype: archetype,
                  sessionCount: assessments.length,
                ),
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
                const SizedBox(height: 120), // Bottom padding for glass nav
              ],
            ),
          );
        },
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
