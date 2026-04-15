import 'package:flutter/material.dart';

import 'marketing_tokens.dart';

// Premium CTA used across the marketing surface. Two variants:
//   filled=true  — signal-colored fill, used for primary action.
//   filled=false — ghost with hairline border, used for secondary.
//
// Hover adds: color swap (matches home page), soft glow bloom, and a subtle
// 1.015x scale. This is the "premium" treatment promised for secondary pages.

class InstrumentButton extends StatefulWidget {
  const InstrumentButton({
    super.key,
    required this.label,
    required this.hint,
    this.filled = false,
    this.accent,
    this.onTap,
  });

  final String label;
  final String hint;
  final bool filled;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  State<InstrumentButton> createState() => _InstrumentButtonState();
}

class _InstrumentButtonState extends State<InstrumentButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? MarketingPalette.signal;

    final fg = widget.filled
        ? MarketingPalette.bg
        : (_hover ? accent : MarketingPalette.text);
    final bg = widget.filled
        ? (_hover ? MarketingPalette.text : accent)
        : Colors.transparent;
    final border = widget.filled
        ? Colors.transparent
        : (_hover ? accent : MarketingPalette.hairline);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 1),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: mktMono(
                    11,
                    color: fg,
                    letterSpacing: 2.8,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  widget.hint,
                  style: mktMono(
                    10,
                    color: widget.filled
                        ? MarketingPalette.bg.withValues(alpha: 0.6)
                        : MarketingPalette.subtle,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
