import 'package:flutter/material.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/figure_big.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/premium_atmosphere.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

// Signature for this page: cyan glow + cyan wash.
const _tint = SectionTint.cyan;
const _wash = SectionTint.cyanWash;

class ScienceView extends StatelessWidget {
  const ScienceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              TopNav(currentPath: '/science', source: WaitlistSource.science),
              SliverToBoxAdapter(child: _Hero()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _EvidenceWall()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _ChainsSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _ExcludedSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _SkepticsSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _TestingSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _LimitsSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(
                  child: SiteFooter(source: WaitlistSource.science)),
            ],
          ),
          Positioned.fill(child: FilmGrainOverlay()),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Stack(
      children: [
        const Positioned.fill(
          child: AtmosphereGlow(color: _tint),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mktGutter(context),
            vertical: narrow ? 56 : 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScrollReveal(
                child: MarketingSectionLabel('SCIENCE'),
              ),
              SizedBox(height: narrow ? 24 : 40),
              ScrollReveal(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'Nothing moves\nalone.',
                  style: mktDisplay(
                    narrow ? 56 : 120,
                    italic: true,
                    letterSpacing: -3,
                    height: 0.95,
                  ),
                ),
              ),
              SizedBox(height: narrow ? 24 : 36),
              ScrollReveal(
                delay: const Duration(milliseconds: 160),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'A knee that collapses is often compensating for an ankle that can\'t move. '
                    'The pain site is rarely the cause. We encode the three fascial chains with '
                    'strong anatomical evidence and trace compensations back to their upstream driver.',
                    style: mktBody(
                      narrow ? 17 : 20,
                      color: MarketingPalette.muted,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              SizedBox(height: narrow ? 36 : 56),
              const ScrollReveal(
                delay: Duration(milliseconds: 260),
                child: _FascialBanner(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Full-width banner anchoring the hero. The image's two-torsos-connected-by-
// fascia composition illustrates the page's thesis ("Nothing moves alone")
// more directly than any paragraph could.
class _FascialBanner extends StatelessWidget {
  const _FascialBanner();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    final height = narrow ? 220.0 : 420.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: _tint.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/premium/fascial_network.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            // Soft edge fade so the image bleeds into the page bg.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        MarketingPalette.bg.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.transparent,
                        MarketingPalette.bg.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.12, 0.88, 1],
                    ),
                  ),
                ),
              ),
            ),
            // Top-left mono annotation.
            Positioned(
              top: 14,
              left: 14,
              child: Text(
                '// FASCIAL MAP  /  3 CHAINS',
                style: mktMono(
                  10,
                  color: MarketingPalette.text,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            // Top-right chain codes.
            Positioned(
              top: 14,
              right: 14,
              child: Text(
                'SBL  /  BFL  /  FFL',
                style: mktMono(
                  10,
                  color: _tint,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            // Corner brackets.
            const Positioned(
                top: 10, left: 10, child: _FbBracket(top: true, left: true)),
            const Positioned(
                top: 10,
                right: 10,
                child: _FbBracket(top: true, left: false)),
            const Positioned(
                bottom: 10,
                left: 10,
                child: _FbBracket(top: false, left: true)),
            const Positioned(
                bottom: 10,
                right: 10,
                child: _FbBracket(top: false, left: false)),
            // Bottom-left citation tag.
            Positioned(
              bottom: 14,
              left: 14,
              child: Text(
                'WILKE  /  2016',
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 2.2,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FbBracket extends StatelessWidget {
  const _FbBracket({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const len = 20.0;
    const stroke = 1.5;
    final color = _tint.withValues(alpha: 0.85);
    return SizedBox(
      width: len,
      height: len,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(width: len, height: stroke, color: color),
          ),
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(width: stroke, height: len, color: color),
          ),
        ],
      ),
    );
  }
}

class _EvidenceWall extends StatelessWidget {
  const _EvidenceWall();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1280;
    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.9, -0.3),
      washTint: _wash,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('EVIDENCE STACK'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'The credentials,\nbefore the argument.',
                style: mktDisplay(narrow ? 36 : 56,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 48 : 80),
            Wrap(
              spacing: isDesktop ? 80 : 56,
              runSpacing: 56,
              children: const [
                ScrollReveal(
                  delay: Duration(milliseconds: 180),
                  child: FigureBig(
                    value: '3',
                    unit: 'CHAINS',
                    label: 'ENCODED — SBL / BFL / FFL',
                    accent: _tint,
                  ),
                ),
                ScrollReveal(
                  delay: Duration(milliseconds: 260),
                  child: FigureBig(
                    value: '28',
                    unit: 'STUDIES',
                    label: 'INDEPENDENT CITATIONS',
                    accent: _tint,
                  ),
                ),
                ScrollReveal(
                  delay: Duration(milliseconds: 340),
                  child: FigureBig(
                    value: '8',
                    unit: 'TRANSITIONS',
                    label: 'CADAVERICALLY VERIFIED',
                    accent: _tint,
                  ),
                ),
                ScrollReveal(
                  delay: Duration(milliseconds: 420),
                  child: FigureBig(
                    value: '2',
                    unit: 'REVIEWS',
                    label: 'WILKE (2016) + KALICHMAN (2025)',
                    accent: _tint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainsSection extends StatelessWidget {
  const _ChainsSection();

  static const _rows = [
    ('Superficial Back Line', 'SBL', 'Strong', '3 / 3', '14'),
    ('Back Functional Line', 'BFL', 'Strong', '3 / 3', '8'),
    ('Front Functional Line', 'FFL', 'Strong', '2 / 2', '6'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, 0.3),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('CHAINS WE USE'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Three pathways.\nStrong evidence only.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 24 : 32),
            ScrollReveal(
              delay: const Duration(milliseconds: 160),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Text(
                  'Source: Wilke et al. (2016), Archives of Physical Medicine and Rehabilitation. '
                  'Independently confirmed by Kalichman (2025) — a separate review that does not '
                  'cite Wilke yet reaches the same evidence hierarchy.',
                  style: mktBody(
                    narrow ? 15 : 17,
                    color: MarketingPalette.muted,
                    height: 1.55,
                  ),
                ),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ScrollReveal(
              delay: const Duration(milliseconds: 240),
              child: _ChainsTableHeader(narrow: narrow),
            ),
            ..._rows.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 300 + e.key * 70),
                  child: _ChainRow(
                      name: e.value.$1,
                      code: e.value.$2,
                      evidence: e.value.$3,
                      verified: e.value.$4,
                      studies: e.value.$5,
                      narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

// Shared table grammar for the two chains tables: CHAIN | EVIDENCE |
// VERIFIED | STUDIES. Consistent flex factors keep header cells aligned
// with row cells at every viewport width.
const _chainFlex = [5, 2, 2, 2];

Widget _chainTh(String s) => Text(
      s,
      style: mktMono(
        10,
        color: MarketingPalette.subtle,
        letterSpacing: 2.4,
        weight: FontWeight.w600,
      ),
    );

class _ChainsTableHeader extends StatelessWidget {
  const _ChainsTableHeader({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: MarketingPalette.hairline, width: 1),
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: _chainFlex[0], child: _chainTh('CHAIN')),
          Expanded(flex: _chainFlex[1], child: _chainTh('EVIDENCE')),
          Expanded(
              flex: _chainFlex[2],
              child: _chainTh(narrow ? 'VERIFIED' : 'VERIFIED TRANSITIONS')),
          Expanded(
              flex: _chainFlex[3],
              child: _chainTh(narrow ? 'STUDIES' : 'INDEPENDENT STUDIES')),
        ],
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({
    required this.name,
    required this.code,
    required this.evidence,
    required this.verified,
    required this.studies,
    required this.narrow,
  });
  final String name;
  final String code;
  final String evidence;
  final String verified;
  final String studies;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _chainFlex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: mktBody(narrow ? 15 : 18,
                        weight: FontWeight.w600,
                        color: MarketingPalette.text,
                        height: 1.3)),
                const SizedBox(height: 4),
                Text(code,
                    style: mktMono(11,
                        color: MarketingPalette.signal,
                        letterSpacing: 2.4,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: _chainFlex[1],
            child: Text(evidence,
                style: mktMono(narrow ? 12 : 13,
                    color: MarketingPalette.signal,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4)),
          ),
          Expanded(
            flex: _chainFlex[2],
            child: Text(verified,
                style: mktMono(narrow ? 13 : 14,
                    color: MarketingPalette.text,
                    weight: FontWeight.w600)),
          ),
          Expanded(
            flex: _chainFlex[3],
            child: Text(studies,
                style: mktMono(narrow ? 13 : 14,
                    color: MarketingPalette.muted,
                    weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ExcludedSection extends StatelessWidget {
  const _ExcludedSection();

  static const _rows = [
    ('Spiral Line', 'Moderate', '5 / 9', 'Excluded'),
    ('Lateral Line', 'Limited', '2 / 5', 'Excluded'),
    ('Superficial Front Line', 'None', '0 / —', 'Excluded'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.85, 0.5),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('CHAINS WE DO NOT USE'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Saying no is\npart of the science.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 24 : 32),
            ScrollReveal(
              delay: const Duration(milliseconds: 160),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'These chains appear in the commercial fascial-training world. Their anatomical '
                  'evidence does not meet the Wilke threshold. Including them would give coverage '
                  'we have not earned.',
                  style: mktBody(narrow ? 15 : 17,
                      color: MarketingPalette.muted, height: 1.55),
                ),
              ),
            ),
            SizedBox(height: narrow ? 32 : 48),
            ScrollReveal(
              delay: const Duration(milliseconds: 220),
              child: _ExcludedTableHeader(narrow: narrow),
            ),
            ..._rows.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 280 + e.key * 70),
                  child: _ExcludedRow(
                      name: e.value.$1,
                      evidence: e.value.$2,
                      verified: e.value.$3,
                      status: e.value.$4,
                      narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

class _ExcludedTableHeader extends StatelessWidget {
  const _ExcludedTableHeader({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: MarketingPalette.hairline, width: 1),
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: _chainFlex[0], child: _chainTh('CHAIN')),
          Expanded(flex: _chainFlex[1], child: _chainTh('EVIDENCE')),
          Expanded(
              flex: _chainFlex[2],
              child: _chainTh(narrow ? 'VERIFIED' : 'VERIFIED TRANSITIONS')),
          Expanded(flex: _chainFlex[3], child: _chainTh('STATUS')),
        ],
      ),
    );
  }
}

class _ExcludedRow extends StatelessWidget {
  const _ExcludedRow({
    required this.name,
    required this.evidence,
    required this.verified,
    required this.status,
    required this.narrow,
  });
  final String name;
  final String evidence;
  final String verified;
  final String status;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _chainFlex[0],
            child: Text(name,
                style: mktBody(narrow ? 15 : 18,
                    weight: FontWeight.w600,
                    color: MarketingPalette.muted,
                    height: 1.3)),
          ),
          Expanded(
            flex: _chainFlex[1],
            child: Text(evidence,
                style: mktMono(narrow ? 12 : 13,
                    color: MarketingPalette.muted,
                    letterSpacing: 1.4)),
          ),
          Expanded(
            flex: _chainFlex[2],
            child: Text(verified,
                style: mktMono(narrow ? 13 : 14,
                    color: MarketingPalette.muted, weight: FontWeight.w500)),
          ),
          Expanded(
            flex: _chainFlex[3],
            child: Text(
              status,
              style: mktMono(narrow ? 10 : 11,
                  color: MarketingPalette.warn,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkepticsSection extends StatelessWidget {
  const _SkepticsSection();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, -0.4),
      washTint: _wash,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 96 : 160,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ScrollReveal(
                  child: Center(
                    child: MarketingSectionLabel('ENGAGING SKEPTICS'),
                  ),
                ),
                SizedBox(height: narrow ? 40 : 64),
                ScrollReveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    '\u201C',
                    style: mktDisplay(
                      narrow ? 140 : 220,
                      italic: true,
                      weight: FontWeight.w500,
                      color: _tint.withValues(alpha: 0.55),
                      height: 0.7,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(height: narrow ? 12 : 20),
                ScrollReveal(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    'Fascial force transmission maxes out at ~10 cm\nin cadaveric studies.',
                    textAlign: TextAlign.center,
                    style: mktDisplay(
                      narrow ? 28 : 44,
                      italic: true,
                      weight: FontWeight.w500,
                      letterSpacing: -1,
                      height: 1.15,
                    ),
                  ),
                ),
                SizedBox(height: narrow ? 36 : 56),
                ScrollReveal(
                  delay: const Duration(milliseconds: 260),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 1,
                        color: MarketingPalette.muted,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'GREG LEHMAN  /  MECHANICAL CRITIQUE',
                        style: mktMono(
                          11,
                          color: MarketingPalette.muted,
                          letterSpacing: 2.8,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 48,
                        height: 1,
                        color: MarketingPalette.muted,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: narrow ? 48 : 80),
                ScrollReveal(
                  delay: const Duration(milliseconds: 340),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Text(
                      'We agree — and our method sidesteps it.',
                      textAlign: TextAlign.center,
                      style: mktBody(
                        narrow ? 18 : 22,
                        weight: FontWeight.w600,
                        color: MarketingPalette.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: narrow ? 20 : 28),
                ScrollReveal(
                  delay: const Duration(milliseconds: 420),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Text(
                      'Our approach does not depend on long-range force transmission. We detect '
                      'co-occurring compensatory movement patterns that practitioners empirically '
                      'associate with chain dysfunction. Whether the mechanism is fascial tension, '
                      'neuromuscular compensation, or habitual patterning, the observable video '
                      'signature is the same.',
                      textAlign: TextAlign.center,
                      style: mktBody(narrow ? 16 : 17,
                          color: MarketingPalette.muted, height: 1.6),
                    ),
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

class _TestingSection extends StatelessWidget {
  const _TestingSection();

  static const _items = [
    (
      '01',
      'Proxy hypothesis',
      'Can co-occurring joint angle patterns on video serve as proxies for what practitioners detect by touch?'
    ),
    (
      '02',
      'Threshold portability',
      'Do clinical thresholds from motion capture remain meaningful under 5–10° real-world error?'
    ),
    (
      '03',
      'Chain attribution',
      'Is a chain-level root-cause attribution more accurate than treating each finding independently?'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.9, 0.3),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('WHAT WE ARE TESTING'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Three unvalidated\ninferences.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 24 : 32),
            ScrollReveal(
              delay: const Duration(milliseconds: 160),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Validated against 2–3 clinicians on 10 test subjects. Layered evaluation: do our '
                  'measurements match observations, do clinicians agree with our chain mapping, is '
                  'chain-aware output more useful than symptom-only output.',
                  style: mktBody(narrow ? 15 : 17,
                      color: MarketingPalette.muted, height: 1.55),
                ),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ..._items.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 220 + e.key * 70),
                  child: _TestingRow(
                      index: e.value.$1,
                      title: e.value.$2,
                      desc: e.value.$3,
                      narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

class _TestingRow extends StatelessWidget {
  const _TestingRow({
    required this.index,
    required this.title,
    required this.desc,
    required this.narrow,
  });
  final String index;
  final String title;
  final String desc;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(index,
                      style: mktMono(11,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w600,
                          letterSpacing: 2.4)),
                  const SizedBox(width: 14),
                  Text(title,
                      style: mktBody(17,
                          weight: FontWeight.w600,
                          color: MarketingPalette.text)),
                ]),
                const SizedBox(height: 8),
                Text(desc,
                    style: mktBody(14,
                        color: MarketingPalette.muted, height: 1.5)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(index,
                      style: mktMono(11,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w600,
                          letterSpacing: 2.4)),
                ),
                SizedBox(
                  width: 260,
                  child: Text(title,
                      style: mktBody(20,
                          weight: FontWeight.w600,
                          color: MarketingPalette.text)),
                ),
                Expanded(
                  child: Text(desc,
                      style: mktBody(16,
                          color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}

class _LimitsSection extends StatelessWidget {
  const _LimitsSection();

  static const _items = [
    ('Ankle tracking unreliable with occlusion or certain footwear.',
        'Communicated inline with reduced-confidence flags.'),
    ('No disaggregated accuracy data by skin tone or body type.',
        'MediaPipe has not published bias audits for BlazePose.'),
    ('Chain attribution has no ground truth.',
        'We encode practitioner reasoning, not empirically validated causal pathways.'),
    ('Validation shows internal consistency, not external validity.',
        'Longitudinal outcome tracking is Phase 2.'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, 0.6),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('KNOWN LIMITS'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Honest about\nwhere it breaks.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ..._items.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 160 + e.key * 70),
                  child: _LimitRow(
                      headline: e.value.$1,
                      detail: e.value.$2,
                      narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.headline,
    required this.detail,
    required this.narrow,
  });
  final String headline;
  final String detail;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline,
                    style: mktBody(16,
                        weight: FontWeight.w600,
                        color: MarketingPalette.text,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(detail,
                    style: mktBody(14,
                        color: MarketingPalette.muted, height: 1.5)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('—',
                      style: mktMono(13,
                          color: MarketingPalette.warn,
                          weight: FontWeight.w600)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Text(headline,
                      style: mktBody(18,
                          weight: FontWeight.w600,
                          color: MarketingPalette.text,
                          height: 1.35)),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Text(detail,
                      style: mktBody(16,
                          color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}
