import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import 'citation_expandable.dart';

class FindingCard extends StatelessWidget {
  const FindingCard({
    super.key,
    required this.finding,
    this.practitionerPoint,
  });

  final Finding finding;
  final String? practitionerPoint;

  static Color _confidenceColor(List<Compensation> compensations) {
    var worst = ConfidenceLevel.high;
    for (final c in compensations) {
      if (c.confidence.index > worst.index) worst = c.confidence;
    }
    switch (worst) {
      case ConfidenceLevel.high:
        return AuraLinkTheme.confidenceHigh;
      case ConfidenceLevel.medium:
        return AuraLinkTheme.confidenceMedium;
      case ConfidenceLevel.low:
        return AuraLinkTheme.confidenceLow;
    }
  }

  static String _confidenceLabel(List<Compensation> compensations) {
    var worst = ConfidenceLevel.high;
    for (final c in compensations) {
      if (c.confidence.index > worst.index) worst = c.confidence;
    }
    switch (worst) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }

  static bool _isLowConfidence(List<Compensation> compensations) {
    return compensations.any((c) => c.confidence == ConfidenceLevel.low);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _confidenceColor(finding.compensations);
    final label = _confidenceLabel(finding.compensations);
    final isLow = _isLowConfidence(finding.compensations);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                finding.bodyPathDescription,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: isLow
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tracking was unclear for this finding -- verify with a practitioner',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AuraLinkTheme.confidenceLow,
                  ),
                ),
              )
            : null,
        children: [
          if (finding.upstreamDriver != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Likely upstream driver: ${finding.upstreamDriver}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              finding.recommendation,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (practitionerPoint != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ask your practitioner about: $practitionerPoint',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (finding.citations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Evidence',
                style: theme.textTheme.labelLarge,
              ),
            ),
            ...finding.citations.map(
              (c) => CitationExpandable(citation: c),
            ),
          ],
        ],
      ),
    );
  }
}
