import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/figure_big.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/premium_atmosphere.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

// Signature for this page: emerald glow + emerald wash.
const _tint = SectionTint.emerald;
const _wash = SectionTint.emeraldWash;

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
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
              SliverToBoxAdapter(
                  child: SiteFooter(source: WaitlistSource.system)),
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
            vertical: narrow ? 72 : 140,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScrollReveal(
                child: MarketingSectionLabel('SYSTEM'),
              ),
              SizedBox(height: narrow ? 28 : 44),
              ScrollReveal(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'Open-source\nchain reasoning\nengine.',
                  style: mktDisplay(
                    narrow ? 56 : 108,
                    italic: true,
                    letterSpacing: -2.5,
                    height: 0.95,
                  ),
                ),
              ),
              SizedBox(height: narrow ? 28 : 40),
              ScrollReveal(
                delay: const Duration(milliseconds: 160),
                child: ConstrainedBox(
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
              ),
            ],
          ),
        ),
      ],
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
              child: MarketingSectionLabel('PIPELINE'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Seven steps,\nzero server hops.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 40 : 72),
            ...List.generate(_steps.length, (i) {
              final (idx, code, desc) = _steps[i];
              return ScrollReveal(
                delay: Duration(milliseconds: 160 + i * 70),
                child: _TimelineStep(
                  index: idx,
                  code: code,
                  description: desc,
                  isLast: i == _steps.length - 1,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Subway-map timeline: a rail of emerald dots connected by a thin vertical
// line on the left, with each step's code + description to the right. The
// final dot has no connector below, so the rail terminates cleanly at 07.
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
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
    final railWidth = narrow ? 32.0 : 56.0;
    final dotSize = narrow ? 12.0 : 16.0;
    final gap = narrow ? 18.0 : 28.0;
    final bottomPad = isLast ? 0.0 : (narrow ? 28.0 : 44.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dot sits at the top; aligns with the first text line.
                Padding(
                  padding: EdgeInsets.only(top: narrow ? 2 : 4),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: _tint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _tint.withValues(alpha: 0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 6),
                      color: _tint.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        index,
                        style: mktMono(
                          narrow ? 11 : 12,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w600,
                          letterSpacing: 2.4,
                        ),
                      ),
                      SizedBox(width: narrow ? 14 : 20),
                      Text(
                        code,
                        style: mktMono(
                          narrow ? 13 : 15,
                          color: MarketingPalette.text,
                          weight: FontWeight.w600,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: narrow ? 10 : 14),
                  Text(
                    description,
                    style: mktBody(
                      narrow ? 15 : 17,
                      color: MarketingPalette.muted,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 1280;
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
              child: MarketingSectionLabel('MEASUREMENT'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'What we\ncan actually\nmeasure.',
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
                  'Published error bounds for phone-camera pose estimation, not vendor marketing numbers. '
                  'Real-world degrades with occlusion, loose clothing, lighting. Ankle-dependent findings '
                  'carry explicit reduced confidence.',
                  style: mktBody(narrow ? 15 : 17,
                      color: MarketingPalette.muted, height: 1.55),
                ),
              ),
            ),
            SizedBox(height: narrow ? 48 : 72),
            Wrap(
              spacing: isDesktop ? 72 : 48,
              runSpacing: 48,
              children: const [
                ScrollReveal(
                  delay: Duration(milliseconds: 220),
                  child: FigureBig(
                    value: '2.4',
                    unit: '° MAE',
                    label: 'HIP — LAB ACCURACY',
                    accent: _tint,
                  ),
                ),
                ScrollReveal(
                  delay: Duration(milliseconds: 300),
                  child: FigureBig(
                    value: '2.8',
                    unit: '° MAE',
                    label: 'KNEE — LAB ACCURACY',
                    accent: _tint,
                  ),
                ),
                ScrollReveal(
                  delay: Duration(milliseconds: 380),
                  child: FigureBig(
                    value: '33',
                    unit: 'LM',
                    label: 'BLAZEPOSE LANDMARKS',
                    accent: _tint,
                  ),
                ),
              ],
            ),
            SizedBox(height: narrow ? 40 : 56),
            ScrollReveal(
              delay: const Duration(milliseconds: 440),
              child: _AccuracyTableHeader(narrow: narrow),
            ),
            ..._rows.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 500 + e.key * 70),
                  child: _AccuracyTableRow(
                      joint: e.value.$1,
                      controlled: e.value.$2,
                      real: e.value.$3,
                      ok: e.value.$4,
                      narrow: narrow),
                )),
            SizedBox(height: narrow ? 20 : 28),
            Text(
              'Controlled = lab MAE. Real-world = published phone-camera estimates.',
              style: mktMono(11, color: MarketingPalette.subtle, letterSpacing: 1.6),
            ),
          ],
        ),
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
    return SectionShell(
      tint: _tint,
      glow: const Alignment(0.85, 0.5),
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
              child: Align(
                alignment: Alignment.centerRight,
                child: MarketingSectionLabel('STACK'),
              ),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Five moving parts.\nNo server.',
                  textAlign: TextAlign.right,
                  style: mktDisplay(narrow ? 38 : 64,
                      italic: true, letterSpacing: -1.5, height: 1.02),
                ),
              ),
            ),
            SizedBox(height: narrow ? 40 : 56),
            ..._items.asMap().entries.map((e) => ScrollReveal(
                  delay: Duration(milliseconds: 160 + e.key * 70),
                  child: _StackRow(name: e.value.$1, purpose: e.value.$2),
                )),
          ],
        ),
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
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, -0.4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 72 : 140,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ScrollReveal(
                  child: MarketingSectionLabel('NOVEL'),
                ),
                SizedBox(height: narrow ? 24 : 36),
                ScrollReveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Zero cross-citations\nbetween the fields\nneeded to build this.',
                    textAlign: TextAlign.center,
                    style: mktDisplay(narrow ? 36 : 60,
                        italic: true, letterSpacing: -1.5, height: 1.05),
                  ),
                ),
                SizedBox(height: narrow ? 28 : 44),
                ScrollReveal(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    'A citation analysis of 7 landmark papers across computer vision, biomechanics, '
                    'and fascial-chain science (4,071 classified citing papers via Semantic Scholar, '
                    'April 2026) found zero cross-citations between computer-vision and fascial-chain '
                    'research in either direction.',
                    textAlign: TextAlign.center,
                    style: mktBody(narrow ? 16 : 18,
                        color: MarketingPalette.muted, height: 1.6),
                  ),
                ),
                const SizedBox(height: 20),
                ScrollReveal(
                  delay: const Duration(milliseconds: 260),
                  child: Text(
                    'The three fields required to build this tool have no history of academic exchange. '
                    'Commercial platforms stop at kinematics. We built the interpretation layer between them.',
                    textAlign: TextAlign.center,
                    style: mktBody(narrow ? 15 : 17,
                        color: MarketingPalette.muted, height: 1.6),
                  ),
                ),
                SizedBox(height: narrow ? 40 : 60),
                const ScrollReveal(
                  delay: Duration(milliseconds: 340),
                  child: _InlineCodeLink(),
                ),
              ],
            ),
          ),
        ),
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
