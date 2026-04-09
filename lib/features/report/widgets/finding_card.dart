import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import 'citation_expandable.dart';
import 'drill_card.dart';

class FindingCard extends StatelessWidget {
  const FindingCard({
    super.key,
    required this.finding,
    this.practitionerPoint,
    this.selected = false,
    this.onTap,
  });

  final Finding finding;
  final String? practitionerPoint;
  final bool selected;
  final VoidCallback? onTap;

  static bool _isLowConfidence(List<Compensation> compensations) {
    return compensations.any((c) => c.confidence == ConfidenceLevel.low);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLow = _isLowConfidence(finding.compensations);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        key: ValueKey('finding_${finding.bodyPathDescription}_$selected'),
        initiallyExpanded: selected,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (_) => onTap?.call(),
        title: Text(
          finding.bodyPathDescription,
          style: theme.textTheme.titleMedium,
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
          if (finding.drills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mobility Drills',
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 4),
            ...finding.drills.map((d) => DrillCard(drill: d)),
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
