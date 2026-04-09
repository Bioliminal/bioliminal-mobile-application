import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../services/comparison_service.dart';

class AssessmentTimeline extends StatelessWidget {
  const AssessmentTimeline({
    super.key,
    required this.assessments,
    required this.onTap,
  });

  final List<Assessment> assessments;
  final void Function(Assessment) onTap;

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
          final previous = i + 1 < assessments.length ? assessments[i + 1] : null;
          final metrics = previous != null
              ? ComparisonService.compare(previous, assessment)
              : <ComparisonMetric>[];

          return _TimelineNode(
            assessment: assessment,
            metrics: metrics,
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
    canvas.drawLine(
      const Offset(x, 0),
      Offset(x, size.height),
      paint,
    );
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
  });

  final Assessment assessment;
  final List<ComparisonMetric> metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = assessment.createdAt;
    final dateStr =
        '${_monthName(date.month)} ${date.day}, ${date.year}';
    final findingCount = assessment.report?.findings.length ??
        assessment.compensations.length;
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
                        ...metrics.map((m) => _DeltaIndicator(metric: m)),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

class _DeltaIndicator extends StatelessWidget {
  const _DeltaIndicator({required this.metric});

  final ComparisonMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = ComparisonService.readableType(metric.compensationType);
    final arrow = metric.improved ? '\u2193' : '\u2191';
    final color = metric.improved
        ? AuraLinkTheme.confidenceHigh
        : AuraLinkTheme.confidenceLow;
    final suffix = metric.improved ? '(improved)' : '(worsened)';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$label: ${metric.oldValue.toStringAsFixed(0)}\u00B0 \u2192 '
        '${metric.newValue.toStringAsFixed(0)}\u00B0 $arrow $suffix',
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}
