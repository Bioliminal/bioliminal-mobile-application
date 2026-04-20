import 'package:flutter/material.dart';

import '../../features/landing/widgets/marketing_tokens.dart';

// Primary in-app CTA. Sized and shaped for thumbs, not cursors:
//   filled=true  — signal fill, used for the dominant action.
//   filled=false — soft surface chip, used for the secondary action.
// Press feedback is a brief scale-down. No hover, no glow, no hint text —
// those belong on the marketing surface (InstrumentButton).

class MobileActionButton extends StatefulWidget {
  const MobileActionButton({
    super.key,
    required this.label,
    this.filled = false,
    this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  State<MobileActionButton> createState() => _MobileActionButtonState();
}

class _MobileActionButtonState extends State<MobileActionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.filled ? MarketingPalette.bg : MarketingPalette.text;
    final bg = widget.filled
        ? MarketingPalette.signal
        : Colors.white.withValues(alpha: 0.05);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 56,
          decoration: BoxDecoration(
            color: _pressed
                ? Color.alphaBlend(Colors.black.withValues(alpha: 0.12), bg)
                : bg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: mktMono(
              12,
              color: fg,
              letterSpacing: 2.6,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
