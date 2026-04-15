import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/premium_atmosphere.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

// Signature for this page: chrome/slate glow + near-black wash.
const _tint = SectionTint.slate;
const _wash = SectionTint.slateWash;

class CodeView extends StatelessWidget {
  const CodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              TopNav(currentPath: '/code', source: WaitlistSource.demo),
              SliverToBoxAdapter(child: _Hero()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _ReposSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _LicenseSection()),
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
          child: AtmosphereGlow(
            color: _tint,
            peak: 0.08,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mktGutter(context),
            vertical: narrow ? 48 : 80,
          ),
          child: narrow ? const _HeroStacked() : const _HeroSplit(),
        ),
      ],
    );
  }
}

// Desktop: text-left, terminal-right. Mirrors the system page hero pattern so
// the visual grammar across marketing pages stays consistent.
class _HeroSplit extends StatelessWidget {
  const _HeroSplit();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ScrollReveal(
                child: MarketingSectionLabel('CODE'),
              ),
              const SizedBox(height: 32),
              ScrollReveal(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'Three repositories.\nOne system.',
                  style: mktDisplay(
                    80,
                    italic: true,
                    letterSpacing: -2.5,
                    height: 0.95,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ScrollReveal(
                delay: const Duration(milliseconds: 180),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    'Bioliminal is open source. The Flutter app is one part of a larger '
                    'system — ESP32 firmware for the sEMG garment and a shared research '
                    'hub for hardware, ML, and team docs. Dev happens on GitLab; these '
                    'are the public mirrors.',
                    style: mktBody(
                      18,
                      color: MarketingPalette.muted,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 56),
        const Expanded(
          flex: 5,
          child: ScrollReveal(
            delay: Duration(milliseconds: 140),
            child: _TerminalPane(),
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
          child: MarketingSectionLabel('CODE'),
        ),
        const SizedBox(height: 20),
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Three repositories.\nOne system.',
            style: mktDisplay(
              48,
              italic: true,
              letterSpacing: -2,
              height: 0.98,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const ScrollReveal(
          delay: Duration(milliseconds: 160),
          child: _TerminalPane(),
        ),
        const SizedBox(height: 24),
        ScrollReveal(
          delay: const Duration(milliseconds: 240),
          child: Text(
            'Bioliminal is open source. The Flutter app is one part of a larger '
            'system — ESP32 firmware for the sEMG garment and a shared research '
            'hub for hardware, ML, and team docs. Dev happens on GitLab; these '
            'are the public mirrors.',
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

// Full terminal pane — traffic-light chrome, realistic git clone output,
// blinking cursor at the tail. The page's signature artifact.
class _TerminalPane extends StatelessWidget {
  const _TerminalPane();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    final fs = narrow ? 12.0 : 14.0;

    Widget promptLine(String cmd) => Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$ ',
              style: mktMono(
                fs,
                color: MarketingPalette.signal,
                weight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            Flexible(
              child: Text(
                cmd,
                style: mktMono(
                  fs,
                  color: MarketingPalette.text,
                  weight: FontWeight.w500,
                  letterSpacing: 0.4,
                  height: 1.6,
                ),
              ),
            ),
          ],
        );

    Widget outputLine(String text, {Color? color}) => Text(
          text,
          style: mktMono(
            fs,
            color: color ?? MarketingPalette.subtle,
            letterSpacing: 0.4,
            height: 1.6,
          ),
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1322),
          border: Border.all(
            color: MarketingPalette.hairline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 48,
              spreadRadius: -10,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Window chrome — traffic lights + title.
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: MarketingPalette.hairline, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const _ChromeDot(color: Color(0xFFF87171)),
                  const SizedBox(width: 8),
                  const _ChromeDot(color: Color(0xFFFBBF24)),
                  const SizedBox(width: 8),
                  const _ChromeDot(color: Color(0xFF4ADE80)),
                  Expanded(
                    child: Center(
                      child: Text(
                        'bioliminal — bash',
                        style: mktMono(
                          10,
                          color: MarketingPalette.subtle,
                          letterSpacing: 1.4,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Symmetric gutter so the title stays centered.
                  const SizedBox(width: 54),
                ],
              ),
            ),
            // Body.
            Padding(
              padding: EdgeInsets.all(narrow ? 18 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  promptLine('git clone https://github.com/Bioliminal'),
                  outputLine('Cloning into \'bioliminal\'...'),
                  outputLine(
                      'remote: Counting objects: 2,847, done.'),
                  outputLine(
                      'Resolving deltas: 100% (1,923/1,923), done.'),
                  const SizedBox(height: 10),
                  promptLine('cd bioliminal && ls'),
                  outputLine(
                    'mobile-app/   esp32-firmware/   ML_RandD_Server/',
                    color: MarketingPalette.signal,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$ ',
                        style: mktMono(
                          fs,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Container(
                        width: narrow ? 8 : 10,
                        height: narrow ? 16 : 20,
                        color: MarketingPalette.signal,
                      )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .fadeOut(
                            duration: 560.ms,
                            curve: Curves.easeInOut,
                            begin: 1,
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChromeDot extends StatelessWidget {
  const _ChromeDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ReposSection extends StatelessWidget {
  const _ReposSection();

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
              child: MarketingSectionLabel('PUBLIC MIRRORS'),
            ),
            SizedBox(height: narrow ? 20 : 32),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'github.com/Bioliminal/',
                style: mktMono(
                  narrow ? 16 : 20,
                  color: MarketingPalette.text,
                  weight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            SizedBox(height: narrow ? 8 : 12),
            const ScrollReveal(
              delay: Duration(milliseconds: 160),
              child: _FileTreeEntry(
                number: '01',
                name: 'bioliminal-mobile-application',
                tagline: 'Flutter app — this surface.',
                description:
                    'iOS, Android, and web client. MediaPipe BlazePose pose estimation, joint-angle '
                    'logic, and the fascial-chain reasoning engine run on-device. Optional cloud '
                    'sync via Firestore is opt-in.',
                language: 'Dart',
                langColor: Color(0xFF38BDF8),
                url: BioliminalRepos.mobileApp,
                isLast: false,
              ),
            ),
            const ScrollReveal(
              delay: Duration(milliseconds: 240),
              child: _FileTreeEntry(
                number: '02',
                name: 'esp32-firmware',
                tagline: 'sEMG capture + haptic cueing.',
                description:
                    'Firmware for the ESP32-based sEMG garment. Captures muscle activation, '
                    'streams over BLE, drives haptic cueing for real-time form feedback. '
                    'Phase 2 hardware — ships after the v1 app validates the reasoning layer.',
                language: 'C++',
                langColor: Color(0xFFF472B6),
                url: BioliminalRepos.esp32,
                isLast: false,
              ),
            ),
            const ScrollReveal(
              delay: Duration(milliseconds: 320),
              child: _FileTreeEntry(
                number: '03',
                name: 'ML_RandD_Server',
                tagline: 'Hardware research, ML training, and cross-team docs.',
                description:
                    'The multidisciplinary hub. Sensor architecture decisions, the BOM, ML training '
                    'pipelines and datasets, the research synthesis, and the mobile-handover '
                    'integration contract all live here.',
                language: 'Python / docs',
                langColor: Color(0xFFFBBF24),
                url: BioliminalRepos.mlServer,
                isLast: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// File-tree listing entry — rendered like a line in `tree` output. No card
// border, just a tree-prefix glyph + mono name + language chip + arrow.
// On hover the row gets a left-accent bar and a subtle wash.
class _FileTreeEntry extends StatefulWidget {
  const _FileTreeEntry({
    required this.number,
    required this.name,
    required this.tagline,
    required this.description,
    required this.language,
    required this.langColor,
    required this.url,
    required this.isLast,
  });

  final String number;
  final String name;
  final String tagline;
  final String description;
  final String language;
  final Color langColor;
  final String url;
  final bool isLast;

  @override
  State<_FileTreeEntry> createState() => _FileTreeEntryState();
}

class _FileTreeEntryState extends State<_FileTreeEntry> {
  bool _hover = false;

  Future<void> _open() async {
    await launchUrl(Uri.parse(widget.url),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    final tree = widget.isLast ? '└─' : '├─';
    final indent = narrow ? 34.0 : 58.0;

    final nameColor =
        _hover ? MarketingPalette.signal : MarketingPalette.text;
    final arrowColor =
        _hover ? MarketingPalette.signal : MarketingPalette.muted;

    final header = narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tree,
                      style: mktMono(14,
                          color: MarketingPalette.muted,
                          weight: FontWeight.w500,
                          letterSpacing: 0.4)),
                  const SizedBox(width: 10),
                  Text(widget.number,
                      style: mktMono(12,
                          color: MarketingPalette.signal,
                          weight: FontWeight.w600,
                          letterSpacing: 1.6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: mktMono(14,
                          color: nameColor,
                          weight: FontWeight.w600,
                          letterSpacing: 0.4),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: indent),
                child: Row(
                  children: [
                    _LangChip(
                        label: widget.language, color: widget.langColor),
                    const Spacer(),
                    Text('↗',
                        style: mktMono(14,
                            color: arrowColor,
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(tree,
                  style: mktMono(17,
                      color: MarketingPalette.muted,
                      weight: FontWeight.w500,
                      letterSpacing: 0.4)),
              const SizedBox(width: 14),
              Text(widget.number,
                  style: mktMono(14,
                      color: MarketingPalette.signal,
                      weight: FontWeight.w600,
                      letterSpacing: 1.6)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  widget.name,
                  style: mktMono(19,
                      color: nameColor,
                      weight: FontWeight.w600,
                      letterSpacing: 0.4),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 18),
              _LangChip(
                  label: widget.language, color: widget.langColor),
              const SizedBox(width: 18),
              Text('↗',
                  style: mktMono(17,
                      color: arrowColor, weight: FontWeight.w600)),
            ],
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            narrow ? 10 : 14,
            narrow ? 18 : 26,
            narrow ? 10 : 14,
            narrow ? 18 : 26,
          ),
          decoration: BoxDecoration(
            color: _hover
                ? MarketingPalette.signal.withValues(alpha: 0.035)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _hover
                    ? MarketingPalette.signal.withValues(alpha: 0.7)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              SizedBox(height: narrow ? 14 : 18),
              Padding(
                padding: EdgeInsets.only(left: indent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tagline,
                      style: mktBody(
                        narrow ? 15 : 17,
                        weight: FontWeight.w500,
                        color: MarketingPalette.text,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: narrow ? 8 : 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 660),
                      child: Text(
                        widget.description,
                        style: mktBody(
                          narrow ? 14 : 15,
                          color: MarketingPalette.muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                    SizedBox(height: narrow ? 10 : 14),
                    Text(
                      widget.url.replaceFirst('https://', ''),
                      style: mktMono(
                        10,
                        color: MarketingPalette.subtle,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: mktMono(
              9,
              color: color,
              letterSpacing: 2,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseSection extends StatelessWidget {
  const _LicenseSection();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return SectionShell(
      tint: _tint,
      glow: const Alignment(-0.85, 0.5),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mktGutter(context),
          vertical: narrow ? 56 : 88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScrollReveal(
              child: MarketingSectionLabel('LICENSE & CONTRIBUTIONS'),
            ),
            SizedBox(height: narrow ? 24 : 36),
            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Use it. Fork it.\nTell us what breaks.',
                style: mktDisplay(narrow ? 38 : 64,
                    italic: true, letterSpacing: -1.5, height: 1.02),
              ),
            ),
            SizedBox(height: narrow ? 28 : 40),
            ScrollReveal(
              delay: const Duration(milliseconds: 160),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Each repo ships with its own LICENSE. Development happens on GitLab; these '
                  'GitHub repos are push-mirrored on a schedule. Issues and PRs opened here are '
                  'monitored and responded to.',
                  style: mktBody(narrow ? 15 : 17,
                      color: MarketingPalette.muted, height: 1.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
