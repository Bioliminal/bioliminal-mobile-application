import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Premium reveal — fade + 12px upward translate over 500ms ease-out.
// Fires once on mount. Wrap content blocks on secondary pages for rhythm.
//
// Use `delay` to stagger siblings (e.g., 0ms, 80ms, 160ms) for a soft cascade.

class ScrollReveal extends StatelessWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .moveY(
          begin: offset,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}
