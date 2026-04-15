import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: CustomScrollView(
        slivers: [
          TopNav(currentPath: '/system', source: WaitlistSource.system),
          SliverToBoxAdapter(child: _Hero()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _PipelineSection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _AccuracySection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _StackSection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _NovelSection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: SiteFooter(source: WaitlistSource.system)),
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
          const MarketingSectionLabel('SYSTEM'),
          SizedBox(height: narrow ? 28 : 44),
          Text(
            'Open-source\nchain reasoning\nengine.',
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
              'No neural network. A rule system that encodes expert fascial-chain logic '
              'into computable rules, running in the browser on 33 body landmarks per frame. '
              'The intelligence is the logic, not a black box.',
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

class _PipelineSection extends StatelessWidget {
  const _PipelineSection();

  static const _steps = [
    ('01', 'CAMERA', 'Phone camera, on-device. No upload.'),
    ('02', 'POSE', 'MediaPipe BlazePose — 33 landmarks per frame.'),
    ('03', 'ANGLES', 'Joint angle math from landmark triplets (hip, knee, ankle, shoulder).'),
    ('04', 'THRESHOLDS', 'Flags against published values (knee valgus >10°, asymmetry >10°).'),
    ('05', 'CHAINS', 'Co-occurring flags mapped along SBL, BFL, FFL to identify upstream driver.'),
    ('06', 'CONFIDENCE', 'Per-joint score from MediaPipe visibility — low confidence never presents as certain.'),
    ('07', 'REPORT', 'Body-path language, cited findings, recommendations adapted to pattern.'),
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
          const MarketingSectionLabel('PIPELINE'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Seven steps,\nzero server hops.',
            style: mktDisplay(narrow ? 38 : 64, italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 32 : 56),
          ...List.generate(_steps.length, (i) {
            final (idx, code, desc) = _steps[i];
            return _PipelineRow(
              index: idx,
              code: code,
              description: desc,
              isLast: i == _steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.index,
    required this.code,
    required this.description,
    required this.isLast,
  });

  final String index;
  final String code;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : MarketingPalette.hairline,
            width: 1,
          ),
        ),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(index,
                        style: mktMono(11,
                            color: MarketingPalette.signal,
                            weight: FontWeight.w600,
                            letterSpacing: 2.4)),
                    const SizedBox(width: 16),
                    Text(code,
                        style: mktMono(12,
                            color: MarketingPalette.text,
                            weight: FontWeight.w600,
                            letterSpacing: 2.8)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description,
                    style: mktBody(15, color: MarketingPalette.muted, height: 1.5)),
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
                  width: 160,
                  child: Text(code,
                      style: mktMono(12,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600,
                          letterSpacing: 2.8)),
                ),
                Expanded(
                  child: Text(description,
                      style:
                          mktBody(16, color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}

class _AccuracySection extends StatelessWidget {
  const _AccuracySection();

  static const _rows = [
    ('Hip', '~2.4°', '5–10°', 'Yes'),
    ('Knee', '~2.8°', '5–10°', 'Yes'),
    ('Ankle', '~3.1°', '10°+ with occlusion', 'Limited — flagged inline'),
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
          const MarketingSectionLabel('MEASUREMENT'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'What we\ncan actually\nmeasure.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 24 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Published error bounds for phone-camera pose estimation, not vendor marketing numbers. '
              'Real-world degrades with occlusion, loose clothing, lighting. Ankle-dependent findings '
              'carry explicit reduced confidence.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          SizedBox(height: narrow ? 40 : 56),
          _AccuracyTableHeader(narrow: narrow),
          ..._rows.map((r) =>
              _AccuracyTableRow(joint: r.$1, controlled: r.$2, real: r.$3, ok: r.$4, narrow: narrow)),
          SizedBox(height: narrow ? 20 : 28),
          Text(
            'Controlled = lab MAE. Real-world = published phone-camera estimates.',
            style: mktMono(11, color: MarketingPalette.subtle, letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }
}

class _AccuracyTableHeader extends StatelessWidget {
  const _AccuracyTableHeader({required this.narrow});
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
      child: narrow
          ? Row(
              children: [
                Expanded(child: _th('JOINT')),
                Expanded(child: _th('CONTROLLED')),
                Expanded(child: _th('TRIAGE')),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 160, child: _th('JOINT')),
                SizedBox(width: 160, child: _th('CONTROLLED')),
                SizedBox(width: 280, child: _th('REAL-WORLD')),
                Expanded(child: _th('ADEQUATE FOR TRIAGE')),
              ],
            ),
    );
  }

  Widget _th(String s) => Text(
        s,
        style: mktMono(
          10,
          color: MarketingPalette.subtle,
          letterSpacing: 2.6,
          weight: FontWeight.w600,
        ),
      );
}

class _AccuracyTableRow extends StatelessWidget {
  const _AccuracyTableRow({
    required this.joint,
    required this.controlled,
    required this.real,
    required this.ok,
    required this.narrow,
  });
  final String joint;
  final String controlled;
  final String real;
  final String ok;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final okColor = ok == 'Yes'
        ? MarketingPalette.signal
        : MarketingPalette.warn;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MarketingPalette.hairline, width: 1),
        ),
      ),
      child: narrow
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _td(joint, MarketingPalette.text, 16, w: FontWeight.w600)),
                Expanded(
                    child: _td(controlled, MarketingPalette.muted, 14)),
                Expanded(child: _td(ok, okColor, 11, mono: true)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 160, child: _td(joint, MarketingPalette.text, 18, w: FontWeight.w600)),
                SizedBox(width: 160, child: _td(controlled, MarketingPalette.muted, 16)),
                SizedBox(width: 280, child: _td(real, MarketingPalette.muted, 16)),
                Expanded(child: _td(ok, okColor, 12, mono: true)),
              ],
            ),
    );
  }

  Widget _td(String text, Color color, double size,
      {FontWeight w = FontWeight.w400, bool mono = false}) {
    return Text(
      text,
      style: mono
          ? mktMono(size, color: color, weight: FontWeight.w600, letterSpacing: 1.6)
          : mktBody(size, color: color, weight: w, height: 1.4),
    );
  }
}

class _StackSection extends StatelessWidget {
  const _StackSection();

  static const _items = [
    ('MediaPipe BlazePose', '33-landmark body model, on-device via ML Kit / tasks-vision.'),
    ('Flutter', 'iOS, Android, web — one codebase. Flutter 3.11, Dart 3.11.'),
    ('CustomPainter', 'Real-time skeleton overlay + confidence coloring.'),
    ('Rule-based decision trees',
        'Compensation thresholds + fascial-chain mapping as computable rules.'),
    ('Firestore', 'Optional cloud sync (opt-in). No backend server required.'),
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
          const MarketingSectionLabel('STACK'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Five moving parts.\nNo server.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 40 : 56),
          ..._items.map((i) => _StackRow(name: i.$1, purpose: i.$2)),
        ],
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  const _StackRow({required this.name, required this.purpose});
  final String name;
  final String purpose;

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
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
                Text(name,
                    style: mktBody(17,
                        weight: FontWeight.w600, color: MarketingPalette.text)),
                const SizedBox(height: 6),
                Text(purpose,
                    style: mktBody(14,
                        color: MarketingPalette.muted, height: 1.5)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 320,
                  child: Text(name,
                      style: mktBody(19,
                          weight: FontWeight.w600,
                          color: MarketingPalette.text)),
                ),
                Expanded(
                  child: Text(purpose,
                      style: mktBody(16,
                          color: MarketingPalette.muted, height: 1.5)),
                ),
              ],
            ),
    );
  }
}

class _NovelSection extends StatelessWidget {
  const _NovelSection();

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
          const MarketingSectionLabel('NOVEL'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Zero cross-citations\nbetween the fields\nneeded to build this.',
            style: mktDisplay(narrow ? 36 : 60,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 28 : 44),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'A citation analysis of 7 landmark papers across computer vision, biomechanics, '
              'and fascial-chain science (4,071 classified citing papers via Semantic Scholar, '
              'April 2026) found zero cross-citations between computer-vision and fascial-chain '
              'research in either direction.',
              style: mktBody(narrow ? 16 : 18,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'The three fields required to build this tool have no history of academic exchange. '
              'Commercial platforms (Kinetisense, DARI Motion, Uplift Labs, VueMotion, Model Health) '
              'stop at kinematics. We built the interpretation layer between them.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
          SizedBox(height: narrow ? 40 : 60),
          const _InlineCodeLink(),
        ],
      ),
    );
  }
}

class _InlineCodeLink extends StatefulWidget {
  const _InlineCodeLink();

  @override
  State<_InlineCodeLink> createState() => _InlineCodeLinkState();
}

class _InlineCodeLinkState extends State<_InlineCodeLink> {
  bool _hover = false;

  Future<void> _openOrRoute() async {
    // Prefer the on-site /code page for the multi-repo story.
    if (!mounted) return;
    context.go('/code');
  }

  Future<void> _openExternal() async {
    await launchUrl(Uri.parse(BioliminalRepos.mobileApp),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _hover ? MarketingPalette.text : MarketingPalette.signal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: _openOrRoute,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('</>  ',
                    style: mktMono(13, color: color, weight: FontWeight.w500)),
                Text(
                  'READ THE CODE',
                  style: mktMono(
                    11,
                    color: color,
                    letterSpacing: 2.6,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Text('→', style: mktMono(13, color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 28),
        _AltExternalLink(onTap: _openExternal),
      ],
    );
  }
}

class _AltExternalLink extends StatefulWidget {
  const _AltExternalLink({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AltExternalLink> createState() => _AltExternalLinkState();
}

class _AltExternalLinkState extends State<_AltExternalLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hover ? MarketingPalette.text : MarketingPalette.subtle;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          'or jump to this repo ↗',
          style: mktMono(11, color: color, letterSpacing: 1.6),
        ),
      ),
    );
  }
}
