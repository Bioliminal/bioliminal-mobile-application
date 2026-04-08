import 'package:flutter/material.dart';

import '../../../domain/models.dart';

class CitationExpandable extends StatelessWidget {
  const CitationExpandable({super.key, required this.citation});

  final Citation citation;

  String _typeBadgeLabel(CitationType type) {
    switch (type) {
      case CitationType.research:
        return 'Research';
      case CitationType.clinical:
        return 'Clinical';
      case CitationType.guideline:
        return 'Guideline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      leading: Icon(
        Icons.menu_book_outlined,
        size: 18,
        color: colorScheme.primary,
      ),
      title: Text(
        citation.source,
        style: theme.textTheme.bodyMedium,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            citation.finding,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (citation.url.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              citation.url,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _typeBadgeLabel(citation.type),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'How this applies: ${citation.appUsage}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
