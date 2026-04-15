import 'dart:math' as math;

import 'package:flutter/material.dart';

// Premium atmosphere primitives — ported from landing_page_view.dart so the
// SYSTEM/SCIENCE/DEMO/CODE pages share the home page's depth language.
//
// SectionTint    — per-page glow + wash palette.
// SectionShell   — radial glow + top/bottom linear wash behind a section.
// AtmosphereGlow — radial halo intended to sit behind hero type.
// FilmGrainOverlay — deterministic noise texture, same math as home.

class SectionTint {
  // Per-page signature glow tints.
  static const indigo = Color(0xFF818CF8); // indigo-400 — demo
  static const cyan = Color(0xFF22D3EE); // cyan-400 — science
  static const emerald = Color(0xFF34D399); // emerald-400 — system
  static const slate = Color(0xFFBAE6FD); // sky-200 / chrome — code

  // Per-page base washes (low-alpha full-height gradient).
  static const skyWash = Color(0xFF082F49); // sky-950 — demo / signal chapters
  static const cyanWash = Color(0xFF083344); // cyan-950 — science
  static const emeraldWash = Color(0xFF022C22); // emerald-950 — system
  static const slateWash = Color(0xFF060B14); // near-black — code / blackout
}

class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.child,
    this.tint,
    this.glow = Alignment.topRight,
    this.glowPeak = 0.07,
    this.washTint,
    this.washOpacity = 0.03,
  });

  final Widget child;
  final Color? tint;
  final Alignment glow;
  final double glowPeak;
  final Color? washTint;
  final double washOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (washTint != null)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      washTint!.withValues(alpha: 0),
                      washTint!.withValues(alpha: washOpacity),
                      washTint!.withValues(alpha: washOpacity),
                      washTint!.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.18, 0.82, 1],
                  ),
                ),
              ),
            ),
          ),
        if (tint != null)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: glow,
                    radius: 1.2,
                    colors: [
                      tint!.withValues(alpha: glowPeak),
                      tint!.withValues(alpha: glowPeak * 0.3),
                      tint!.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class AtmosphereGlow extends StatelessWidget {
  const AtmosphereGlow({
    super.key,
    this.color = SectionTint.indigo,
    this.center = const Alignment(-0.5, -0.3),
    this.radius = 1.6,
    this.peak = 0.12,
  });

  final Color color;
  final Alignment center;
  final double radius;
  final double peak;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [
              color.withValues(alpha: peak),
              color.withValues(alpha: peak * 0.33),
              Colors.transparent,
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
      ),
    );
  }
}

class FilmGrainOverlay extends StatelessWidget {
  const FilmGrainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FilmGrainPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  _FilmGrainPainter() : _rng = math.Random(42);

  final math.Random _rng;

  @override
  void paint(Canvas canvas, Size size) {
    final area = size.width * size.height;
    final count = (area / 900).clamp(400, 6000).toInt();
    final paintLight = Paint()..color = const Color(0x0FFFFFFF);
    final paintDark = Paint()..color = const Color(0x12000000);

    for (var i = 0; i < count; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 0.9 + 0.2;
      canvas.drawCircle(
        Offset(x, y),
        r,
        _rng.nextBool() ? paintLight : paintDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) => false;
}
