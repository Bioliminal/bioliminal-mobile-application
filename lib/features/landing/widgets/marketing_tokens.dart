import 'package:flutter/material.dart';

import '../../../core/theme.dart';

// Design tokens for the marketing surface (SYSTEM/SCIENCE/DEMO/CODE pages).
// Mirrors the private palette inside landing_page_view.dart so the home page
// and the rest of the site read as one coherent brand.

class MarketingPalette {
  static const bg = BioliminalTheme.screenBackground;
  static const surface = BioliminalTheme.surface;
  static const hairline = Color(0xFF17233F);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const subtle = Color(0xFF475569);
  static const signal = BioliminalTheme.accent;
  static const warn = Color(0xFFF59E0B);
  static const error = Color(0xFFF87171);
}

TextStyle mktDisplay(
  double size, {
  bool italic = false,
  FontWeight weight = FontWeight.w900,
  Color? color,
  double height = 0.92,
  double letterSpacing = -2,
}) =>
    TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color ?? MarketingPalette.text,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle mktBody(
  double size, {
  Color? color,
  double height = 1.55,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0,
}) =>
    TextStyle(
      fontFamily: 'IBMPlexSans',
      fontSize: size,
      fontWeight: weight,
      color: color ?? MarketingPalette.text,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle mktMono(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 1.4,
  double height = 1.3,
}) =>
    TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: size,
      fontWeight: weight,
      color: color ?? MarketingPalette.muted,
      letterSpacing: letterSpacing,
      height: height,
    );

// Widest a marketing content column is ever allowed to grow. On viewports
// above this + standard gutter, the extra width becomes auto-gutter so
// content stays a readable 1280px centered block instead of stretching
// edge-to-edge on 2K/4K displays.
const mktMaxContentWidth = 1280.0;

double mktGutter(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= mktMaxContentWidth + 128) {
    return (w - mktMaxContentWidth) / 2;
  }
  if (w >= 1280) return 64;
  if (w >= 768) return 40;
  return 20;
}

bool mktNarrow(BuildContext context) =>
    MediaQuery.of(context).size.width < 768;

bool mktDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1280;

// Shared: hairline section divider used between SliverToBoxAdapter sections.
class MarketingDivider extends StatelessWidget {
  const MarketingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: mktGutter(context)),
      color: MarketingPalette.hairline,
    );
  }
}

// Shared: label chip — "// SYSTEM", "// SCIENCE", etc.
class MarketingSectionLabel extends StatelessWidget {
  const MarketingSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '// $label',
      style: mktMono(
        11,
        color: MarketingPalette.subtle,
        letterSpacing: 2.6,
        weight: FontWeight.w500,
      ),
    );
  }
}

// GitHub URLs for the three repos — single source of truth.
class BioliminalRepos {
  static const mobileApp =
      'https://github.com/Bioliminal/bioliminal-mobile-application';
  static const esp32 = 'https://github.com/Bioliminal/esp32-firmware';
  static const mlServer = 'https://github.com/Bioliminal/ML_RandD_Server';
  static const org = 'https://github.com/Bioliminal';
}
