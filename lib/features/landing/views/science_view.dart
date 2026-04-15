import 'package:flutter/material.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

class ScienceView extends StatelessWidget {
  const ScienceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: CustomScrollView(
        slivers: [
          TopNav(currentPath: '/science', source: WaitlistSource.science),
          SliverToBoxAdapter(child: _Hero()),
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
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('SCIENCE'),
          SizedBox(height: narrow ? 28 : 44),
          Text(
            'Nothing moves\nalone.',
            style: mktDisplay(
              narrow ? 64 : 132,
              italic: true,
              letterSpacing: -3,
              height: 0.95,
            ),
          ),
          SizedBox(height: narrow ? 28 : 40),
          ConstrainedBox(
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
        ],
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('CHAINS WE USE'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Three pathways.\nStrong evidence only.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
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
          SizedBox(height: narrow ? 40 : 56),
          _ChainsTableHeader(narrow: narrow),
          ..._rows.map((r) => _ChainRow(
              name: r.$1,
              code: r.$2,
              evidence: r.$3,
              verified: r.$4,
              studies: r.$5,
              narrow: narrow)),
        ],
      ),
    );
  }
}

class _ChainsTableHeader extends StatelessWidget {
  const _ChainsTableHeader({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    Widget th(String s) => Text(
          s,
          style: mktMono(
            10,
            color: MarketingPalette.subtle,
            letterSpacing: 2.6,
            weight: FontWeight.w600,
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: MarketingPalette.hairline, width: 1),
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: narrow
          ? Row(
              children: [
                Expanded(flex: 2, child: th('CHAIN')),
                Expanded(child: th('VERIFIED')),
                Expanded(child: th('STUDIES')),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 360, child: th('CHAIN')),
                SizedBox(width: 140, child: th('EVIDENCE')),
                SizedBox(width: 180, child: th('VERIFIED TRANSITIONS')),
                Expanded(child: th('INDEPENDENT STUDIES')),
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
      child: narrow
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: mktBody(15,
                              weight: FontWeight.w600,
                              color: MarketingPalette.text)),
                      const SizedBox(height: 2),
                      Text(code,
                          style: mktMono(11,
                              color: MarketingPalette.signal,
                              letterSpacing: 2)),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(verified,
                      style: mktMono(13,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(studies,
                      style: mktMono(13,
                          color: MarketingPalette.muted,
                          weight: FontWeight.w500)),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      Text(name,
                          style: mktBody(18,
                              weight: FontWeight.w600,
                              color: MarketingPalette.text)),
                      const SizedBox(width: 14),
                      Text(code,
                          style: mktMono(11,
                              color: MarketingPalette.signal,
                              letterSpacing: 2.4)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(evidence,
                      style: mktMono(13,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w600,
                          letterSpacing: 1.4)),
                ),
                SizedBox(
                  width: 180,
                  child: Text(verified,
                      style: mktMono(14,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(studies,
                      style: mktMono(14,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('CHAINS WE DO NOT USE'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Saying no is\npart of the science.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'These chains appear in the commercial fascial-training world. Their anatomical '
              'evidence does not meet the Wilke threshold. Including them would give coverage '
              'we have not earned.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          SizedBox(height: narrow ? 32 : 48),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: MarketingPalette.hairline, width: 1),
                bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: narrow ? 200 : 320,
                  child: Text('CHAIN',
                      style: mktMono(10,
                          color: MarketingPalette.subtle,
                          letterSpacing: 2.6,
                          weight: FontWeight.w600)),
                ),
                if (!narrow)
                  SizedBox(
                    width: 160,
                    child: Text('EVIDENCE',
                        style: mktMono(10,
                            color: MarketingPalette.subtle,
                            letterSpacing: 2.6,
                            weight: FontWeight.w600)),
                  ),
                Expanded(
                  child: Text('VERIFIED TRANSITIONS',
                      style: mktMono(10,
                          color: MarketingPalette.subtle,
                          letterSpacing: 2.6,
                          weight: FontWeight.w600)),
                ),
                if (!narrow)
                  SizedBox(
                    width: 160,
                    child: Text('',
                        style: mktMono(10,
                            color: MarketingPalette.subtle,
                            letterSpacing: 2.6)),
                  ),
              ],
            ),
          ),
          ..._rows.map((r) => _ExcludedRow(
              name: r.$1, evidence: r.$2, verified: r.$3, status: r.$4, narrow: narrow)),
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
          SizedBox(
            width: narrow ? 200 : 320,
            child: Text(name,
                style: mktBody(narrow ? 15 : 18,
                    weight: FontWeight.w600,
                    color: MarketingPalette.muted)),
          ),
          if (!narrow)
            SizedBox(
              width: 160,
              child: Text(evidence,
                  style: mktMono(13,
                      color: MarketingPalette.muted,
                      letterSpacing: 1.4)),
            ),
          Expanded(
            child: Text(verified,
                style: mktMono(narrow ? 13 : 14,
                    color: MarketingPalette.muted, weight: FontWeight.w500)),
          ),
          if (!narrow)
            SizedBox(
              width: 160,
              child: Text(
                status,
                style: mktMono(11,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('ENGAGING SKEPTICS'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'The critique is\nreal. Our method\nsidesteps it.',
            style: mktDisplay(narrow ? 38 : 60,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 28 : 44),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'Greg Lehman\'s critique — that fascial force transmission maxes out at ~10cm in '
              'cadaveric studies — targets direct mechanical chain effects. We agree.',
              style: mktBody(narrow ? 16 : 18,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'Our approach does not depend on long-range force transmission. We detect '
              'co-occurring compensatory movement patterns that practitioners empirically '
              'associate with chain dysfunction. Whether the mechanism is fascial tension, '
              'neuromuscular compensation, or habitual patterning, the observable video '
              'signature is the same.',
              style: mktBody(narrow ? 16 : 18,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
        ],
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('WHAT WE ARE TESTING'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Three unvalidated\ninferences.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Validated against 2–3 clinicians on 10 test subjects. Layered evaluation: do our '
              'measurements match observations, do clinicians agree with our chain mapping, is '
              'chain-aware output more useful than symptom-only output.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          SizedBox(height: narrow ? 40 : 56),
          ..._items.map((i) =>
              _TestingRow(index: i.$1, title: i.$2, desc: i.$3, narrow: narrow)),
        ],
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('KNOWN LIMITS'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Honest about\nwhere it breaks.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 40 : 56),
          ..._items.map((i) => _LimitRow(
              headline: i.$1, detail: i.$2, narrow: narrow)),
        ],
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
