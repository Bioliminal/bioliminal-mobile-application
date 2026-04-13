import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import 'drill_card.dart';

class FindingCard extends StatelessWidget {
  const FindingCard({
    super.key,
    required this.finding,
    this.practitionerPoint,
    this.selected = false,
    this.onTap,
    this.archetypePreferredType,
  });

  final Finding finding;
  final String? practitionerPoint;
  final bool selected;
  final VoidCallback? onTap;
  final CompensationType? archetypePreferredType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: selected
            ? BioliminalTheme.glassEffect.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 2,
                ),
              )
            : BioliminalTheme.glassEffect,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      finding.bodyPathDescription.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: selected
                            ? theme.colorScheme.secondary
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (finding.trendStatus != null)
                    _TrendIcon(trend: finding.trendStatus!),
                ],
              ),
              const SizedBox(height: 12),
              if (finding.upstreamDriver != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: BioliminalTheme.confidenceHigh.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRIMARY DRIVER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: BioliminalTheme.confidenceHigh,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                finding.recommendation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (finding.drills.isNotEmpty) ...[
                Text(
                  'RECOMMENDED DRILLS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 8),
                ...finding.drills
                    .take(1)
                    .map(
                      (d) => DrillCard(
                        drill: d,
                        isArchetypeMatch:
                            archetypePreferredType != null &&
                            d.compensationType == archetypePreferredType,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({required this.trend});
  final TrendClassification trend;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (trend) {
      case TrendClassification.improving:
        icon = Icons.trending_up;
        color = BioliminalTheme.confidenceHigh;
      case TrendClassification.worsening:
        icon = Icons.trending_down;
        color = BioliminalTheme.confidenceLow;
      case TrendClassification.stable:
        icon = Icons.trending_flat;
        color = Colors.white38;
      case TrendClassification.newPattern:
        icon = Icons.fiber_new;
        color = Colors.blueAccent;
    }
    return Icon(icon, color: color, size: 20);
  }
}
