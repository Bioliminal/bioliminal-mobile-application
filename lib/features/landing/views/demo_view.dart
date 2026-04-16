import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/instrument_button.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/premium_atmosphere.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';
import '../widgets/walkthrough_dialog.dart';

// Signature for this page: indigo glow + sky wash.
const _tint = SectionTint.indigo;
const _wash = SectionTint.skyWash;

class DemoView extends StatelessWidget {
  const DemoView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              TopNav(currentPath: '/demo', source: WaitlistSource.demo),
              SliverToBoxAdapter(child: _Hero()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _WhatSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _SetupSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _StartSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: SiteFooter(source: WaitlistSource.demo)),
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
            vertical: narrow ? 48 : 72,
          ),
          child: narrow ? const _HeroStacked() : const _HeroSplit(),
        ),
      ],
    );
  }
}

// Desktop layout — viewfinder on the left, text block on the right.
// Keeps the whole hero inside one viewport.
class _HeroSplit extends StatelessWidget {
  const _HeroSplit();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const ScrollReveal(
              delay: Duration(milliseconds: 80),
              child: _ViewfinderFrame(narrow: false),
            ),
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ScrollReveal(
                child: MarketingSectionLabel('DEMO'),
              ),
              const SizedBox(height: 28),
              ScrollReveal(
                delay: const Duration(milliseconds: 140),
                child: Text(
                  'One movement.\nThirty seconds.',
                  style: mktDisplay(
                    72,
                    italic: true,
                    letterSpacing: -2,
                    height: 0.98,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ScrollReveal(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  'Live demo ships with v1 — scope-frozen to a single bicep curl. '
                  'The full 4-movement screen (overhead squat, single-leg squat, '
                  'push-up, rollup) follows in v2. Join the waitlist to hear when '
                  'it lands.',
                  style: mktBody(
                    17,
                    color: MarketingPalette.muted,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStacked extends StatelessWidget {
  const _HeroStacked();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScrollReveal(
          child: MarketingSectionLabel('DEMO'),
        ),
        const SizedBox(height: 20),
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'One movement.\nThirty seconds.',
            style: mktDisplay(
              44,
              italic: true,
              letterSpacing: -2,
              height: 0.98,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const ScrollReveal(
          delay: Duration(milliseconds: 160),
          child: _ViewfinderFrame(narrow: true),
        ),
        const SizedBox(height: 24),
        ScrollReveal(
          delay: const Duration(milliseconds: 260),
          child: Text(
            'Live demo ships with v1 — scope-frozen to a single bicep curl. '
            'The full 4-movement screen follows in v2. Join the waitlist to '
            'hear when it lands.',
            style: mktBody(
              16,
              color: MarketingPalette.muted,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

// Camera viewfinder — corner brackets, rule-of-thirds, REC indicator, slate
// code. Since the live demo isn't built yet, a prominent UNDER CONSTRUCTION
// pill sits centered inside the frame so users don't expect it to work.
class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final innerPad = narrow ? 14.0 : 20.0;
    final bracketInset = narrow ? 8.0 : 12.0;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          border: Border.all(
            color: _tint.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _RuleOfThirds()),
            ),
            Positioned(
                top: bracketInset,
                left: bracketInset,
                child: const _CornerBracket(top: true, left: true)),
            Positioned(
                top: bracketInset,
                right: bracketInset,
                child: const _CornerBracket(top: true, left: false)),
            Positioned(
                bottom: bracketInset,
                left: bracketInset,
                child: const _CornerBracket(top: false, left: true)),
            Positioned(
                bottom: bracketInset,
                right: bracketInset,
                child: const _CornerBracket(top: false, left: false)),
            Positioned(
              top: innerPad,
              left: innerPad,
              child: Text(
                'DEMO  /  01  ·  BICEP CURL',
                style: mktMono(
                  narrow ? 9 : 10,
                  color: MarketingPalette.muted,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              top: innerPad,
              right: innerPad,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF87171),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeOut(
                        duration: 820.ms,
                        curve: Curves.easeInOut,
                        begin: 1,
                      ),
                  const SizedBox(width: 8),
                  Text(
                    'REC  00:00:30',
                    style: mktMono(
                      narrow ? 9 : 10,
                      color: const Color(0xFFF87171),
                      letterSpacing: 2.4,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Centered under-construction pill.
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 14 : 18,
                        vertical: narrow ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: MarketingPalette.warn.withValues(alpha: 0.08),
                        border: Border.all(
                          color:
                              MarketingPalette.warn.withValues(alpha: 0.65),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'UNDER CONSTRUCTION',
                        style: mktMono(
                          narrow ? 11 : 13,
                          color: MarketingPalette.warn,
                          letterSpacing: 3.2,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: narrow ? 14 : 18),
                    Text(
                      'Live demo lands with v1.',
                      style: mktMono(
                        narrow ? 10 : 11,
                        color: MarketingPalette.muted,
                        letterSpacing: 1.8,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: innerPad,
              bottom: innerPad,
              child: Text(
                '30 FPS  ·  f/1.8',
                style: mktMono(
                  narrow ? 9 : 10,
                  color: MarketingPalette.subtle,
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

class _RuleOfThirds extends StatelessWidget {
  const _RuleOfThirds();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RuleOfThirdsPainter());
  }
}

class _RuleOfThirdsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MarketingPalette.text.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    final v1 = size.width / 3;
    final v2 = 2 * size.width / 3;
    final h1 = size.height / 3;
    final h2 = 2 * size.height / 3;
    canvas.drawLine(Offset(v1, 0), Offset(v1, size.height), paint);
    canvas.drawLine(Offset(v2, 0), Offset(v2, size.height), paint);
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), paint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), paint);
  }

  @override
  bool shouldRepaint(covariant _RuleOfThirdsPainter oldDelegate) => false;
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const len = 24.0;
    const stroke = 1.5;
    final color = _tint.withValues(alpha: 0.8);
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

class _WhatSection extends StatelessWidget {
  const _WhatSection();

  static const _bullets = [
    ('REAL-TIME POSE',
        'MediaPipe BlazePose runs on your device. 33 body landmarks per frame.'),
    ('PER-JOINT CONFIDENCE',
        'Joints track in green, yellow, or red based on visibility. Low confidence never presents as certain.'),
    ('NO UPLOAD',
        'Video never leaves your device. Processing is local.'),
    ('REPS + FORM',
        'Tracks reps and flags compensation patterns during the movement.'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.9, -0.4),
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
              child: MarketingSectionLabel('WHAT IT TRACKS'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Four signals,\none rep at a time.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ..._bullets.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 160 + e.key * 70),
                  child: _WhatRow(
                      code: e.value.$1, desc: e.value.$2, narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

class _WhatRow extends StatelessWidget {
  const _WhatRow({
    required this.code,
    required this.desc,
    required this.narrow,
  });
  final String code;
  final String desc;
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
                Text(code,
                    style: mktMono(11,
                        color: MarketingPalette.signal,
                        letterSpacing: 2.6,
                        weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(desc,
                    style: mktBody(15,
                        color: MarketingPalette.muted, height: 1.5)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 260,
                  child: Text(code,
                      style: mktMono(12,
                          color: MarketingPalette.signal,
                          letterSpacing: 2.6,
                          weight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(desc,
                      style: mktBody(17,
                          color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}

class _SetupSection extends StatelessWidget {
  const _SetupSection();

  static const _items = [
    ('01', 'LIGHTING', 'Front-lit. Bright enough to see your whole body clearly in the preview.'),
    ('02', 'ANGLE',
        'Phone at roughly chest height, pointed straight at you. Full body in frame.'),
    ('03', 'DISTANCE',
        'About 6–8 feet back. Shoulders and hips fully inside the frame during the rep.'),
    ('04', 'CLOTHING',
        'Fitted, contrasting clothing. Loose layers tank visibility scores.'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, 0.4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('SETUP'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Before\nyou start.',
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
                  'Tracking quality depends on these four. The app checks them one at a time before '
                  'the rep begins — this is a preview of what to expect.',
                  style: mktBody(narrow ? 15 : 17,
                      color: MarketingPalette.muted, height: 1.55),
                ),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ..._items.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 220 + e.key * 70),
                  child: _SetupRow(
                      index: e.value.$1,
                      code: e.value.$2,
                      desc: e.value.$3,
                      narrow: narrow),
                )),
          ],
        ),
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({
    required this.index,
    required this.code,
    required this.desc,
    required this.narrow,
  });
  final String index;
  final String code;
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
                  Text(code,
                      style: mktMono(12,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600,
                          letterSpacing: 2.8)),
                ]),
                const SizedBox(height: 10),
                Text(desc,
                    style: mktBody(15,
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
                  width: 180,
                  child: Text(code,
                      style: mktMono(12,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600,
                          letterSpacing: 2.8)),
                ),
                Expanded(
                  child: Text(desc,
                      style: mktBody(17,
                          color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}

class _StartSection extends StatelessWidget {
  const _StartSection();

  static const _onTap = [
    ('01', 'PERMISSION', 'Browser asks for camera access.'),
    ('02', 'POSE', 'BlazePose loads on-device. No upload.'),
    ('03', 'CAPTURE', '30-second recording window.'),
    ('04', 'RESULT', 'Feedback renders locally, immediately.'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ScrollReveal(
          child: MarketingSectionLabel('START'),
        ),
        SizedBox(height: narrow ? 20 : 28),
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Camera on.\nOne clean rep.',
            style: mktDisplay(narrow ? 44 : 72,
                italic: true, letterSpacing: -2, height: 0.98),
          ),
        ),
        SizedBox(height: narrow ? 32 : 44),
        ScrollReveal(
          delay: const Duration(milliseconds: 180),
          child: InstrumentButton(
            label: 'START THE REP',
            hint: 'WALKTHROUGH →',
            filled: true,
            onTap: () => showDemoWalkthrough(context),
          ),
        ),
        SizedBox(height: narrow ? 24 : 32),
        ScrollReveal(
          delay: const Duration(milliseconds: 260),
          child: Text(
            'Nothing uploads. You can close the tab at any point without leaving '
            'a trace on any server.',
            style: mktBody(narrow ? 14 : 15,
                color: MarketingPalette.subtle, height: 1.55),
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ScrollReveal(
          delay: const Duration(milliseconds: 140),
          child: Text(
            '// ON TAP',
            style: mktMono(11,
                color: MarketingPalette.subtle, letterSpacing: 2.6),
          ),
        ),
        SizedBox(height: narrow ? 28 : 36),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: MarketingPalette.hairline, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_onTap.length, (i) {
              final (idx, code, desc) = _onTap[i];
              return ScrollReveal(
                delay: Duration(milliseconds: 200 + i * 70),
                child: _OnTapRow(
                  index: idx,
                  code: code,
                  desc: desc,
                  isLast: i == _onTap.length - 1,
                ),
              );
            }),
          ),
        ),
      ],
    );

    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.85, 0.7),
      washTint: _wash,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 56 : 88,
        ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 56), right],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 64),
                  Expanded(child: right),
                ],
              ),
      ),
    );
  }
}

class _OnTapRow extends StatelessWidget {
  const _OnTapRow({
    required this.index,
    required this.code,
    required this.desc,
    required this.isLast,
  });

  final String index;
  final String code;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? MarketingPalette.hairline
                : MarketingPalette.hairline.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              index,
              style: mktMono(11,
                  color: MarketingPalette.signal,
                  weight: FontWeight.w600,
                  letterSpacing: 2.4),
            ),
          ),
          SizedBox(
            width: 128,
            child: Text(
              code,
              style: mktMono(12,
                  color: MarketingPalette.text,
                  weight: FontWeight.w600,
                  letterSpacing: 2.6),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: mktBody(15,
                  color: MarketingPalette.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
