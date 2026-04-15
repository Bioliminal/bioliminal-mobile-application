import 'package:flutter/material.dart';

import 'marketing_tokens.dart';

// Oversized numeric display — ported from landing_page_view._FigureBig.
// Used in stat walls across the marketing surface for cinematic emphasis.

class FigureBig extends StatelessWidget {
  const FigureBig({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.accent,
  });

  final String value;
  final String unit;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1280;
    final isNarrow = width < 768;
    final valueSize = isDesktop ? 108.0 : (isNarrow ? 60.0 : 84.0);
    final rule = accent ?? MarketingPalette.signal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: mktDisplay(
                valueSize,
                weight: FontWeight.w500,
                letterSpacing: -4,
                height: 0.95,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: valueSize * 0.2),
              child: Text(
                unit,
                style: mktMono(
                  isDesktop ? 13 : 11,
                  color: MarketingPalette.muted,
                  letterSpacing: 2,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 1, color: rule),
            const SizedBox(width: 10),
            Text(
              label,
              style: mktMono(
                10,
                color: MarketingPalette.muted,
                letterSpacing: 2.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
