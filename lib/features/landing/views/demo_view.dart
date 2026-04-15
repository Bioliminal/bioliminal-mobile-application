import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

class DemoView extends StatelessWidget {
  const DemoView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: CustomScrollView(
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
          const MarketingSectionLabel('DEMO'),
          SizedBox(height: narrow ? 28 : 44),
          Text(
            'One movement.\nThirty seconds.',
            style: mktDisplay(
              narrow ? 56 : 108,
              italic: true,
              letterSpacing: -2.5,
              height: 0.95,
            ),
          ),
          SizedBox(height: narrow ? 28 : 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'This demo is scope-frozen to a single bicep curl. The full 4-movement screen '
              '(overhead squat, single-leg balance, overhead reach, forward fold) ships with v2. '
              'Join the waitlist to hear when it does.',
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('WHAT IT TRACKS'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Four signals,\none rep at a time.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 40 : 56),
          ..._bullets.map((b) =>
              _WhatRow(code: b.$1, desc: b.$2, narrow: narrow)),
        ],
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('SETUP'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Before you start.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Tracking quality depends on these four. The app checks them one at a time before '
              'the rep begins — this is a preview of what to expect.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          SizedBox(height: narrow ? 40 : 56),
          ..._items.map((i) => _SetupRow(
              index: i.$1, code: i.$2, desc: i.$3, narrow: narrow)),
        ],
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

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 96 : 160,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('START'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Camera on.\nOne clean rep.',
            style: mktDisplay(narrow ? 44 : 80,
                italic: true, letterSpacing: -2, height: 0.98),
          ),
          SizedBox(height: narrow ? 40 : 60),
          const _StartButton(),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'The next screen asks for camera permission. Nothing uploads. You can close the '
              'tab at any point without leaving a trace on any server.',
              style: mktBody(narrow ? 14 : 15,
                  color: MarketingPalette.subtle, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton();

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/capture'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: _hover ? MarketingPalette.signal : Colors.transparent,
            border: Border.all(color: MarketingPalette.signal, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'START THE REP',
                style: mktMono(
                  12,
                  color: _hover ? MarketingPalette.bg : MarketingPalette.signal,
                  letterSpacing: 3.2,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '→',
                style: mktMono(
                  15,
                  color: _hover ? MarketingPalette.bg : MarketingPalette.signal,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
