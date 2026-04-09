import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../domain/models.dart';
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
      appBar: AppBar(title: const Text('History')),
      body: asyncAssessments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (assessments) {
          if (assessments.isEmpty) {
            return _EmptyState();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AssessmentTimeline(
              assessments: assessments,
              onTap: (assessment) {
                context.go('/report/${assessment.id}');
              },
            ),
          );
        },
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
