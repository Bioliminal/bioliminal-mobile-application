import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../services/comparison_service.dart';

const _bodyPathLabels = <CompensationType, String>{
  CompensationType.ankleRestriction: 'Ankle flexibility',
  CompensationType.kneeValgus: 'Knee alignment',
  CompensationType.hipDrop: 'Pelvic level',
  CompensationType.trunkLean: 'Torso balance',
};

class AssessmentTimeline extends StatelessWidget {
  const AssessmentTimeline({
    super.key,
    required this.assessments,
    required this.onTap,
    this.trendReport,
  });

  final List<Assessment> assessments;
  final void Function(Assessment) onTap;
  final TrendReport? trendReport;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TimelinePainter(
        itemCount: assessments.length,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      ),
      child: Column(
        children: List.generate(assessments.length, (i) {
          final assessment = assessments[i];
          final previous = i + 1 < assessments.length
              ? assessments[i + 1]
              : null;
          final metrics = previous != null
              ? ComparisonService.compare(previous, assessment)
              : <ComparisonMetric>[];

          return _TimelineNode(
            assessment: assessment,
            metrics: metrics,
            trendReport: trendReport,
            onTap: () => onTap(assessment),
          );
        }),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({required this.itemCount, required this.color});

  final int itemCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const x = 24.0;
    canvas.drawLine(const Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      itemCount != oldDelegate.itemCount || color != oldDelegate.color;
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.assessment,
    required this.metrics,
    required this.onTap,
    this.trendReport,
  });

  final Assessment assessment;
  final List<ComparisonMetric> metrics;
  final VoidCallback onTap;
  final TrendReport? trendReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = assessment.createdAt;
    final dateStr = '${_monthName(date.month)} ${date.day}, ${date.year}';
    final findingCount =
        assessment.report?.findings.length ?? assessment.compensations.length;
    final confidence = _overallConfidence(assessment);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot
            SizedBox(
              width: 48,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            // Card
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(right: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateStr,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          _ConfidenceBadge(level: confidence),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$findingCount finding${findingCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (metrics.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: metrics
                              .map(
                                (m) => _DeltaChip(
                                  metric: m,
                                  trendReport: trendReport,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ConfidenceLevel _overallConfidence(Assessment assessment) {
    if (assessment.compensations.isEmpty) return ConfidenceLevel.high;
    return ConfidenceLevel.worstOf(
      assessment.compensations.map((c) => c.confidence),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.level});

  final ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      ConfidenceLevel.high => AuraLinkTheme.confidenceHigh,
      ConfidenceLevel.medium => AuraLinkTheme.confidenceMedium,
      ConfidenceLevel.low => AuraLinkTheme.confidenceLow,
    };

    final label = switch (level) {
      ConfidenceLevel.high => 'High',
      ConfidenceLevel.medium => 'Medium',
      ConfidenceLevel.low => 'Low',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.metric, this.trendReport});

  final ComparisonMetric metric;
  final TrendReport? trendReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        _bodyPathLabels[metric.compensationType] ??
        metric.compensationType.name;

    // Determine trend classification from TrendReport if available,
    // otherwise fall back to the pairwise metric.
    final trendClassification = _resolveTrend();

    final color = switch (trendClassification) {
      TrendClassification.improving => AuraLinkTheme.confidenceHigh,
      TrendClassification.stable => AuraLinkTheme.confidenceMedium,
      TrendClassification.worsening => AuraLinkTheme.confidenceLow,
      TrendClassification.newPattern => AuraLinkTheme.confidenceMedium,
    };

    final icon = switch (trendClassification) {
      TrendClassification.improving => Icons.trending_down,
      TrendClassification.stable => Icons.trending_flat,
      TrendClassification.worsening => Icons.trending_up,
      TrendClassification.newPattern => Icons.trending_flat,
    };

    final delta = metric.delta.abs();
    final deltaStr = '${delta.toStringAsFixed(0)}\u00B0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            deltaStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TrendClassification _resolveTrend() {
    final fromReport = trendReport?.trendFor(
      metric.compensationType,
      metric.joint,
    );
    if (fromReport != null) return fromReport.trend;

    // Fallback to pairwise comparison.
    if (metric.delta.abs() < 1.0) return TrendClassification.stable;
    return metric.improved
        ? TrendClassification.improving
        : TrendClassification.worsening;
  }
}
