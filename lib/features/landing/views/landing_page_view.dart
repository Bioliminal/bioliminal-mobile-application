import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../waitlist/services/waitlist_service.dart';
import '../../waitlist/widgets/waitlist_capture.dart';

// =============================================================================
// Bioliminal landing — editorial brutalism, instrument-panel precision.
// Typography-led. Single sky-blue signal accent (BioliminalTheme.accent).
// Palette tracks BioliminalTheme so the site and the app stay in lockstep.
// =============================================================================

class _Palette {
  // Tracks BioliminalTheme — update the app theme and the site follows.
  static const bg = BioliminalTheme.screenBackground; // slate 900
  static const hairline = BioliminalTheme.surface; // slate 800
  static const hairlineSoft = Color(0xFF17233F); // between bg and surface
  static const text = Color(0xFFF8FAFC); // slate 50
  static const muted = Color(0xFF94A3B8); // slate 400
  static const subtle = Color(0xFF475569); // slate 600
  static const signal = BioliminalTheme.accent; // sky 400
  static const primary = BioliminalTheme.primary; // deep indigo — brand
  static const secondary = BioliminalTheme.secondary; // light blue — brand
}

// Typography helpers — centralized so cadence stays tight.
TextStyle _display(
  double size, {
  bool italic = false,
  FontWeight weight = FontWeight.w900,
  Color? color,
  double height = 0.92,
  double letterSpacing = -3,
}) =>
    TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color ?? _Palette.text,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle _body(
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
      color: color ?? _Palette.text,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle _mono(
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
      color: color ?? _Palette.muted,
      letterSpacing: letterSpacing,
      height: height,
    );

// =============================================================================
// Root
// =============================================================================

class LandingPageView extends StatefulWidget {
  const LandingPageView({super.key});

  @override
  State<LandingPageView> createState() => _LandingPageViewState();
}

class _LandingPageViewState extends State<LandingPageView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: const [
              SliverPersistentHeader(
                pinned: true,
                delegate: _TopNavDelegate(),
              ),
              SliverToBoxAdapter(child: _HeroSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              SliverToBoxAdapter(child: _WedgeSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              SliverToBoxAdapter(child: _FiguresSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              SliverToBoxAdapter(child: _SystemSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              SliverToBoxAdapter(child: _ValidationSection()),
              SliverToBoxAdapter(child: _SectionDivider()),
              SliverToBoxAdapter(child: _Footer()),
            ],
          ),
          // Persistent film-grain overlay.
          const Positioned.fill(
            child: IgnorePointer(child: _FilmGrainOverlay()),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared: hairline section divider
// =============================================================================

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: _gutter(context)),
      color: _Palette.hairlineSoft,
    );
  }
}

double _gutter(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 1280) return 64;
  if (w >= 768) return 40;
  return 20;
}

bool _isNarrow(BuildContext context) => MediaQuery.of(context).size.width < 768;
bool _isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1280;

// =============================================================================
// Top nav — sticky. Wordmark left, destinations middle, GitHub CTA right.
// =============================================================================

class _TopNavDelegate extends SliverPersistentHeaderDelegate {
  const _TopNavDelegate();

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bg = _Palette.bg.withValues(alpha: 0.88);
    final narrow = _isNarrow(context);
    return Container(
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: _gutter(context)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Text(
                      'BIOLIMINAL',
                      style: _mono(
                        13,
                        color: _Palette.text,
                        weight: FontWeight.w600,
                        letterSpacing: 3.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
                if (!narrow) ...[
                  _NavItem(
                    label: 'SYSTEM',
                    onTap: () => context.go('/system'),
                  ),
                  _NavItem(
                    label: 'SCIENCE',
                    onTap: () => context.go('/science'),
                  ),
                  _NavItem(
                    label: 'DEMO',
                    onTap: () => context.go('/demo'),
                  ),
                ],
                const Spacer(),
                _JoinWaitlistCta(
                  compact: narrow,
                  source: WaitlistSource.home,
                ),
              ],
            ),
          ),
          Container(height: 1, color: _Palette.hairlineSoft),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 150.ms);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            widget.label,
            style: _mono(
              11,
              color: _hover ? _Palette.signal : _Palette.muted,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Join Waitlist CTA — primary conversion target. Opens a centered modal with
// the email capture widget. Source tags which page the signup came from.
// =============================================================================

class _JoinWaitlistCta extends StatefulWidget {
  const _JoinWaitlistCta({required this.compact, required this.source});
  final bool compact;
  final WaitlistSource source;

  @override
  State<_JoinWaitlistCta> createState() => _JoinWaitlistCtaState();
}

class _JoinWaitlistCtaState extends State<_JoinWaitlistCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? _Palette.text : _Palette.signal;
    final label = widget.compact ? 'WAITLIST' : 'JOIN WAITLIST';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => showWaitlistDialog(context, source: widget.source),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: _mono(
              10,
              color: color,
              letterSpacing: 2.6,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showWaitlistDialog(
  BuildContext context, {
  required WaitlistSource source,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => _WaitlistDialog(source: source),
  );
}

class _WaitlistDialog extends StatelessWidget {
  const _WaitlistDialog({required this.source});
  final WaitlistSource source;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Palette.bg,
      insetPadding: const EdgeInsets.all(24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _Palette.hairlineSoft, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _DialogCloseButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              WaitlistCapture(source: source, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? _Palette.text : _Palette.subtle;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            '×',
            style: TextStyle(
              color: color,
              fontFamily: 'IBMPlexMono',
              fontSize: 22,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Hero — mixed-style display type, editorial meta rows, CTA
// =============================================================================

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double heroScale;
    if (width >= 1280) {
      heroScale = 152;
    } else if (width >= 768) {
      heroScale = 96;
    } else {
      heroScale = 60;
    }

    return Stack(
      children: [
        // Atmosphere — radial glow + animated sEMG waveform behind type.
        const Positioned.fill(child: _AtmosphereGlow()),
        const Positioned.fill(child: _EmgWaveformBackground()),
        // Content sits above.
        _HeroContent(heroScale: heroScale),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.heroScale});
  final double heroScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: _isNarrow(context) ? 80 : 160,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MetaRow(
            left: 'SPEC. BL-01 / PROTOCOL 4.6',
            right: 'REV. 04.14.26  ·  AUSTIN, TX',
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          SizedBox(height: _isNarrow(context) ? 60 : 140),
          // "Movement,"
          Text('Movement,', style: _display(heroScale))
              .animate()
              .slideY(
                begin: 0.25,
                end: 0,
                duration: 900.ms,
                delay: 300.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 700.ms, delay: 300.ms),
          // "measured." — italic, slightly indented, negative top margin for overlap
          Transform.translate(
            offset: Offset(heroScale * 0.18, -heroScale * 0.08),
            child: Text(
              'measured.',
              style: _display(
                heroScale,
                italic: true,
                color: _Palette.signal,
              ),
            ),
          )
              .animate()
              .slideY(
                begin: 0.25,
                end: 0,
                duration: 900.ms,
                delay: 500.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 700.ms, delay: 500.ms),
          SizedBox(height: _isNarrow(context) ? 48 : 88),
          // Subhead
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'The closed-loop biometric training instrument. Sense the recruitment, cue the correction, verify the lift — in under half a second, every repetition.',
              style: _body(
                _isNarrow(context) ? 16 : (_isDesktop(context) ? 18 : 17),
                color: _Palette.muted,
                height: 1.55,
              ),
            ),
          ).animate().fadeIn(duration: 700.ms, delay: 800.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 700.ms,
                delay: 800.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: _isNarrow(context) ? 56 : 96),
          // CTAs
          const Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _InstrumentButton(
                label: 'WATCH THE LIVE DEMO',
                hint: '04.20.26',
                filled: true,
              ),
              _InstrumentButton(
                label: 'TECHNICAL BRIEF',
                hint: 'PDF',
                filled: false,
              ),
            ],
          ).animate().fadeIn(duration: 700.ms, delay: 1050.ms).slideY(
                begin: 0.15,
                end: 0,
                duration: 700.ms,
                delay: 1050.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: _isNarrow(context) ? 72 : 120),
          // Scroll hint
          Row(
            children: [
              Text(
                '↓   SCROLL TO INSTRUMENT INDEX',
                style: _mono(10, color: _Palette.subtle, letterSpacing: 2.4),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 1400.ms),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.left, required this.right});
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(left, style: _mono(10, letterSpacing: 2.2)),
        const Spacer(),
        if (!_isNarrow(context))
          Text(right, style: _mono(10, letterSpacing: 2.2)),
      ],
    );
  }
}

class _InstrumentButton extends StatefulWidget {
  const _InstrumentButton({
    required this.label,
    required this.hint,
    required this.filled,
  });
  final String label;
  final String hint;
  final bool filled;

  @override
  State<_InstrumentButton> createState() => _InstrumentButtonState();
}

class _InstrumentButtonState extends State<_InstrumentButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.filled
        ? _Palette.bg
        : (_hover ? _Palette.signal : _Palette.text);
    final bg = widget.filled
        ? (_hover ? _Palette.text : _Palette.signal)
        : Colors.transparent;
    final border = widget.filled
        ? Colors.transparent
        : (_hover ? _Palette.signal : _Palette.hairline);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: _mono(
                11,
                color: fg,
                letterSpacing: 2.8,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              widget.hint,
              style: _mono(
                10,
                color: widget.filled
                    ? _Palette.bg.withValues(alpha: 0.6)
                    : _Palette.subtle,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Wedge — 01 SENSE, 02 CUE, 03 VERIFY
// =============================================================================

class _WedgeSection extends StatelessWidget {
  const _WedgeSection();

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      tint: _Palette.signal,
      glow: const Alignment(0.85, -0.6),
      washTint: _SectionPalettes.skyWash,
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: _isNarrow(context) ? 80 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// INSTRUMENT INDEX  —  THE CLOSED LOOP',
            style: _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
          ),
          SizedBox(height: _isNarrow(context) ? 40 : 72),
          const _WedgeBlock(
            index: '01',
            title: 'Sense.',
            signal: 'SEMG + POSE',
            body:
                'Two-channel surface electromyography reads the bicep/brachioradialis recruitment ratio at 1 kHz. A 33-point pose inference pipeline renders the lift on-device at 30 FPS, with zero raw video leaving the phone.',
            figures: [
              _Figure('CHANNELS', '2'),
              _Figure('POSE LM', '33'),
              _Figure('SAMPLE', '1 kHz'),
            ],
            visual: _PoseSkeletonViz(),
          ),
          SizedBox(height: _isNarrow(context) ? 64 : 96),
          const _WedgeBlock(
            index: '02',
            title: 'Cue.',
            signal: 'HAPTIC',
            body:
                'When brachioradialis dominance persists across two consecutive concentric phases, a graduated haptic squeeze fires on the bicep. The cue retrains wrist supination mid-rep, at the exact joint angle where the correction is most learnable.',
            figures: [
              _Figure('LATENCY', '< 500 ms'),
              _Figure('CUE TYPE', 'GRADUATED'),
              _Figure('LOCKOUT', '1 REP'),
            ],
            visual: _CuePulseViz(),
          ),
          SizedBox(height: _isNarrow(context) ? 64 : 96),
          const _WedgeBlock(
            index: '03',
            title: 'Verify.',
            signal: 'RMS SHIFT',
            body:
                'The same sensor measures the correction. A ≥15% shift in the recruitment ratio toward the bicep — within 500 ms of the cue — is logged as a verified rep. No shift, the system flags the rep. The loop closes in real time, or not at all.',
            figures: [
              _Figure('WINDOW', '500 ms'),
              _Figure('THRESHOLD', '≥ 15%'),
              _Figure('VERIFY RATE', 'LIVE'),
            ],
            visual: _RatioBarChart(),
          ),
        ],
      ),
      ),
    );
  }
}

class _WedgeBlock extends StatelessWidget {
  const _WedgeBlock({
    required this.index,
    required this.title,
    required this.signal,
    required this.body,
    required this.figures,
    this.visual,
  });

  final String index;
  final String title;
  final String signal;
  final String body;
  final List<_Figure> figures;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final titleSize = isDesktop ? 72.0 : (_isNarrow(context) ? 40.0 : 56.0);

    final leftCol = SizedBox(
      width: isDesktop ? 180 : 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: _mono(
              isDesktop ? 64 : 44,
              color: _Palette.signal,
              weight: FontWeight.w300,
              letterSpacing: -2,
              height: 0.9,
            ),
          ),
          SizedBox(height: isDesktop ? 18 : 12),
          Container(width: 24, height: 1, color: _Palette.signal),
          const SizedBox(height: 14),
          Text(
            signal,
            style: _mono(
              10,
              color: _Palette.muted,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );

    final contentCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _display(titleSize, letterSpacing: -2.5, height: 1),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            body,
            style: _body(
              _isNarrow(context) ? 16 : 18,
              color: _Palette.muted,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 48,
          runSpacing: 20,
          children: figures
              .map(
                (f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.label,
                      style: _mono(
                        9,
                        color: _Palette.subtle,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.value,
                      style: _mono(
                        16,
                        color: _Palette.text,
                        weight: FontWeight.w500,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );

    final visualPanel = visual == null
        ? null
        : _VisualPanel(child: visual!);

    if (_isNarrow(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCol,
          const SizedBox(height: 24),
          contentCol,
          if (visualPanel != null) ...[
            const SizedBox(height: 40),
            SizedBox(height: 260, child: visualPanel),
          ],
        ],
      );
    }

    if (isDesktop && visualPanel != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCol,
          Expanded(child: contentCol),
          const SizedBox(width: 48),
          SizedBox(width: 360, height: 320, child: visualPanel),
        ],
      );
    }

    // Tablet: visual stacks below at 2-col remainder width.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [leftCol, Expanded(child: contentCol)],
        ),
        if (visualPanel != null) ...[
          const SizedBox(height: 40),
          SizedBox(height: 260, child: visualPanel),
        ],
      ],
    );
  }
}

class _VisualPanel extends StatelessWidget {
  const _VisualPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1425),
        border: Border.all(color: _Palette.hairline, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _Figure {
  const _Figure(this.label, this.value);
  final String label;
  final String value;
}

// =============================================================================
// System — spec sheet block
// =============================================================================

class _SystemSection extends StatelessWidget {
  const _SystemSection();

  @override
  Widget build(BuildContext context) {
    final cells = const [
      _SpecCell(code: 'S-01', label: 'sEMG HUB', value: 'ESP32-S3', meta: '2-CH · 1 kHz'),
      _SpecCell(code: 'S-02', label: 'POSE', value: 'BLAZEPOSE', meta: '33 LANDMARKS'),
      _SpecCell(code: 'S-03', label: 'CUE', value: 'HAPTIC MOTOR', meta: 'GRADUATED'),
      _SpecCell(code: 'S-04', label: 'TRANSPORT', value: 'BLE 5.0', meta: 'ON-DEVICE'),
    ];

    final isNarrow = _isNarrow(context);

    return _SectionShell(
      washTint: _Palette.primary, // theme primary — deep indigo, brand authority
      washOpacity: 0.06,
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: isNarrow ? 80 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// SYSTEM  —  THE INSTRUMENT',
            style: _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
          ),
          SizedBox(height: isNarrow ? 40 : 72),
          Text(
            'Built for one rep,\nread for every rep.',
            style: _display(
              isNarrow ? 40 : (_isDesktop(context) ? 72 : 56),
              letterSpacing: -2,
              height: 1.02,
            ),
          ),
          SizedBox(height: isNarrow ? 40 : 64),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _Palette.hairline),
                bottom: BorderSide(color: _Palette.hairline),
              ),
            ),
            child: isNarrow
                ? Column(children: cells)
                : Row(
                    children: cells
                        .asMap()
                        .entries
                        .map(
                          (e) => Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: e.key < cells.length - 1
                                      ? const BorderSide(
                                          color: _Palette.hairline)
                                      : BorderSide.none,
                                ),
                              ),
                              child: e.value,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({
    required this.code,
    required this.label,
    required this.value,
    required this.meta,
  });

  final String code;
  final String label;
  final String value;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                code,
                style: _mono(
                  10,
                  color: _Palette.signal,
                  letterSpacing: 2.4,
                  weight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: _mono(10, color: _Palette.muted, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            value,
            style: _display(
              26,
              weight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            meta,
            style: _mono(11, color: _Palette.muted, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Validation — editorial wellness disclaimer
// =============================================================================

class _ValidationSection extends StatelessWidget {
  const _ValidationSection();

  @override
  Widget build(BuildContext context) {
    final isNarrow = _isNarrow(context);

    return _SectionShell(
      tint: _SectionPalettes.chrome,
      glow: const Alignment(-0.85, 0.7),
      washTint: _SectionPalettes.chromeWash,
      glowPeak: 0.04,
      washOpacity: 0.04,
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: isNarrow ? 80 : 140,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNarrow)
            SizedBox(
              width: 180,
              child: Text(
                '// FRAME',
                style: _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNarrow) ...[
                  Text(
                    '// FRAME',
                    style:
                        _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
                  ),
                  const SizedBox(height: 32),
                ],
                Text(
                  'Nothing moves\nalone.',
                  style: _display(
                    isNarrow ? 44 : 72,
                    italic: true,
                    letterSpacing: -1.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 36),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    'Bioliminal is a movement education tool, not a diagnostic device. It reasons only along pathways with strong anatomical evidence and carries reduced confidence where tracking is noisy. Operated under the FDA General Wellness Policy.',
                    style: _body(
                      isNarrow ? 16 : 19,
                      color: _Palette.muted,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: _Palette.signal,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'NOT A MEDICAL DEVICE',
                      style: _mono(
                        10,
                        color: _Palette.signal,
                        letterSpacing: 2.6,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const _ScienceBridgeLink(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ScienceBridgeLink extends StatefulWidget {
  const _ScienceBridgeLink();

  @override
  State<_ScienceBridgeLink> createState() => _ScienceBridgeLinkState();
}

class _ScienceBridgeLinkState extends State<_ScienceBridgeLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? _Palette.text : _Palette.signal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/science'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'READ THE SCIENCE',
              style: _mono(
                11,
                color: color,
                letterSpacing: 2.6,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '→',
              style: _mono(13, color: color, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Footer
// =============================================================================

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isNarrow = _isNarrow(context);

    return _SectionShell(
      washTint: _SectionPalettes.footerWash,
      washOpacity: 0.05,
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: isNarrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEMO ↘',
                      style: _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '04.20.26',
                      style: _display(
                        isNarrow ? 52 : 96,
                        weight: FontWeight.w600,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Austin, Texas',
                      style: _display(
                        isNarrow ? 22 : 32,
                        italic: true,
                        weight: FontWeight.w400,
                        letterSpacing: -0.5,
                        color: _Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isNarrow)
                const Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FooterLink('CONTACT', 'team@bioliminal.co'),
                      SizedBox(height: 20),
                      _FooterLink('PRESS', 'press@bioliminal.co'),
                      SizedBox(height: 20),
                      _FooterLink('SUBSTACK', 'bioliminal.substack.com'),
                    ],
                  ),
                ),
            ],
          ),
          if (isNarrow) ...[
            const SizedBox(height: 48),
            const _FooterLink('CONTACT', 'team@bioliminal.co'),
            const SizedBox(height: 20),
            const _FooterLink('PRESS', 'press@bioliminal.co'),
            const SizedBox(height: 20),
            const _FooterLink('SUBSTACK', 'bioliminal.substack.com'),
          ],
          SizedBox(height: isNarrow ? 60 : 120),
          Container(height: 1, color: _Palette.hairlineSoft),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                '© 2026 BIOLIMINAL, INC.',
                style: _mono(10, color: _Palette.subtle, letterSpacing: 2),
              ),
              const Spacer(),
              if (!isNarrow)
                Text(
                  'SPEC. BL-01  ·  REV. 04.14.26',
                  style: _mono(10, color: _Palette.subtle, letterSpacing: 2),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label, this.value);
  final String label;
  final String value;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: _mono(10, color: _Palette.subtle, letterSpacing: 2.4),
          ),
          const SizedBox(height: 6),
          Text(
            widget.value,
            style: _body(
              16,
              weight: FontWeight.w400,
              color: _hover ? _Palette.signal : _Palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Film grain overlay — deterministic noise for texture
// =============================================================================

class _FilmGrainOverlay extends StatelessWidget {
  const _FilmGrainOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilmGrainPainter(),
      size: Size.infinite,
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  _FilmGrainPainter() : _rng = math.Random(42);

  final math.Random _rng;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic grain: density tuned for subtle texture without perf hit.
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

// =============================================================================
// Section atmosphere — each chapter gets its own tonal identity.
// Low-opacity wash shifts the base color; directional glow provides depth.
// Alternating glow corners create scroll rhythm (Z-pattern).
// =============================================================================

class _SectionPalettes {
  // Glow tints
  static const indigo = Color(0xFF818CF8);     // indigo-400 (hero ambient)
  static const chrome = Color(0xFFBAE6FD);     // sky-200 — ice / spec-light
  // Washes — very low alpha applied in _SectionShell
  static const skyWash = Color(0xFF082F49);    // sky-950 — signal chapter
  static const chromeWash = Color(0xFF060B14); // near-black slate — blackout
  static const footerWash = Color(0xFF05090F); // sink to black
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
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

// =============================================================================
// Hero atmosphere — radial glow for depth behind type
// =============================================================================

class _AtmosphereGlow extends StatelessWidget {
  const _AtmosphereGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.5, -0.3),
            radius: 1.6,
            colors: [
              _SectionPalettes.indigo.withValues(alpha: 0.12),
              _SectionPalettes.indigo.withValues(alpha: 0.04),
              Colors.transparent,
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Hero EMG waveform background — animated pseudo-EMG signal, sub-ambient
// =============================================================================

class _EmgWaveformBackground extends StatefulWidget {
  const _EmgWaveformBackground();

  @override
  State<_EmgWaveformBackground> createState() => _EmgWaveformBackgroundState();
}

class _EmgWaveformBackgroundState extends State<_EmgWaveformBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _EmgWaveformPainter(t: _c.value * 14),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _EmgWaveformPainter extends CustomPainter {
  _EmgWaveformPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle vertical grid — reads like an oscilloscope graticule.
    final gridPaint = Paint()
      ..color = _Palette.hairline.withValues(alpha: 0.20)
      ..strokeWidth = 1;
    const gridStep = 90.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    void drawSignal({
      required double baseY,
      required double phaseOffset,
      required double amplitude,
      required Color color,
    }) {
      final path = Path();
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (double x = 0; x <= size.width; x += 2) {
        final normalized = x / size.width;
        final slow = math.sin(normalized * math.pi * 2 + t * 0.4 + phaseOffset);
        final envelope = math.pow(slow.abs(), 2).toDouble() * 0.9 + 0.1;
        final hf =
            math.sin(normalized * math.pi * 20 + t * 4 + phaseOffset) * 0.5 +
                math.sin(normalized * math.pi * 44 + t * 6 + phaseOffset) * 0.4;
        final y = baseY + hf * envelope * amplitude;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawSignal(
      baseY: size.height * 0.58,
      phaseOffset: 0,
      amplitude: size.height * 0.08,
      color: _Palette.signal.withValues(alpha: 0.22),
    );
    drawSignal(
      baseY: size.height * 0.82,
      phaseOffset: math.pi / 2,
      amplitude: size.height * 0.06,
      color: _Palette.text.withValues(alpha: 0.10),
    );

    // Channel callouts.
    final labelStyle = TextStyle(
      color: _Palette.subtle.withValues(alpha: 0.8),
      fontSize: 9,
      letterSpacing: 2,
      fontFamily: 'IBMPlexMono',
    );
    _paintText(
      canvas,
      'CH-1 · BRACH',
      Offset(size.width - 150, size.height * 0.58 - 18),
      labelStyle,
    );
    _paintText(
      canvas,
      'CH-2 · BICEP',
      Offset(size.width - 150, size.height * 0.82 - 18),
      labelStyle,
    );
  }

  @override
  bool shouldRepaint(covariant _EmgWaveformPainter old) => old.t != t;
}

void _paintText(Canvas c, String s, Offset o, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, o);
}

double _easeInOutCubic(double x) =>
    x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;

// =============================================================================
// Pose skeleton — animated BlazePose figure cycling a curl, Section 01
// =============================================================================

class _PoseSkeletonViz extends StatefulWidget {
  const _PoseSkeletonViz();

  @override
  State<_PoseSkeletonViz> createState() => _PoseSkeletonVizState();
}

class _PoseSkeletonVizState extends State<_PoseSkeletonViz>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _PosePainter(t: _c.value)),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            '33 / 33 LM',
            style: _mono(9, color: _Palette.muted, letterSpacing: 2),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Text(
            '30 FPS',
            style: _mono(9, color: _Palette.muted, letterSpacing: 2),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Text(
            'POSE · BLAZE-FULL',
            style: _mono(9, color: _Palette.signal, letterSpacing: 2),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final pct = (math.sin(_c.value * math.pi).abs() * 100).round();
              return Text(
                'FLEX $pct%',
                style: _mono(
                  9,
                  color: _Palette.text,
                  letterSpacing: 2,
                  weight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PosePainter extends CustomPainter {
  _PosePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final curlRaw = math.sin(t * math.pi).clamp(0.0, 1.0);
    final curl = _easeInOutCubic(curlRaw);

    Offset p(double nx, double ny) =>
        Offset(size.width * nx, size.height * ny);

    final head = p(0.5, 0.14);
    final lShoulder = p(0.38, 0.30);
    final rShoulder = p(0.62, 0.30);
    final lElbow = p(0.33, 0.50);
    final rElbow = p(0.67, 0.50);
    final lWrist = p(0.30, 0.68);
    final lHip = p(0.44, 0.58);
    final rHip = p(0.56, 0.58);
    final lKnee = p(0.43, 0.78);
    final rKnee = p(0.57, 0.78);
    final lAnkle = p(0.43, 0.94);
    final rAnkle = p(0.57, 0.94);

    final rWrist = Offset.lerp(p(0.74, 0.70), p(0.58, 0.34), curl)!;

    final bone = Paint()
      ..color = _Palette.muted.withValues(alpha: 0.55)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final boneActive = Paint()
      ..color = _Palette.signal.withValues(alpha: 0.95)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Torso + neck.
    final neck = Offset((lShoulder.dx + rShoulder.dx) / 2,
        (lShoulder.dy + rShoulder.dy) / 2);
    canvas.drawLine(head, neck, bone);
    canvas.drawLine(lShoulder, rShoulder, bone);
    canvas.drawLine(lShoulder, lHip, bone);
    canvas.drawLine(rShoulder, rHip, bone);
    canvas.drawLine(lHip, rHip, bone);

    // Legs.
    canvas.drawLine(lHip, lKnee, bone);
    canvas.drawLine(lKnee, lAnkle, bone);
    canvas.drawLine(rHip, rKnee, bone);
    canvas.drawLine(rKnee, rAnkle, bone);

    // Left arm — static.
    canvas.drawLine(lShoulder, lElbow, bone);
    canvas.drawLine(lElbow, lWrist, bone);

    // Right arm — active, highlighted.
    canvas.drawLine(rShoulder, rElbow, boneActive);
    canvas.drawLine(rElbow, rWrist, boneActive);

    // Joint dots — all 13 visible.
    final dotStatic = Paint()..color = _Palette.muted.withValues(alpha: 0.7);
    final dotActive = Paint()..color = _Palette.signal;
    final glow = Paint()
      ..color = _Palette.signal.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final pt in [
      head,
      lShoulder,
      lElbow,
      lWrist,
      lHip,
      rHip,
      lKnee,
      rKnee,
      lAnkle,
      rAnkle,
    ]) {
      canvas.drawCircle(pt, 2.5, dotStatic);
    }
    for (final pt in [rShoulder, rElbow, rWrist]) {
      canvas.drawCircle(pt, 6, glow);
      canvas.drawCircle(pt, 3, dotActive);
    }

    // Mini recruitment indicator beside the active elbow.
    _drawMiniIndicator(
      canvas,
      Offset(rElbow.dx + 20, rElbow.dy - 28),
      curl,
    );
  }

  void _drawMiniIndicator(Canvas c, Offset origin, double curl) {
    const w = 6.0;
    const gap = 4.0;
    const maxH = 30.0;

    final brachPct = 0.7 - 0.35 * curl;
    final bicepPct = 0.3 + 0.35 * curl;

    final trackPaint = Paint()..color = _Palette.hairline.withValues(alpha: 0.9);
    final brachPaint = Paint()..color = _Palette.muted.withValues(alpha: 0.9);
    final bicepPaint = Paint()..color = _Palette.signal;

    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, w, maxH),
        const Radius.circular(1),
      ),
      trackPaint,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx,
          origin.dy + maxH * (1 - brachPct),
          w,
          maxH * brachPct,
        ),
        const Radius.circular(1),
      ),
      brachPaint,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + w + gap, origin.dy, w, maxH),
        const Radius.circular(1),
      ),
      trackPaint,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx + w + gap,
          origin.dy + maxH * (1 - bicepPct),
          w,
          maxH * bicepPct,
        ),
        const Radius.circular(1),
      ),
      bicepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PosePainter old) => old.t != t;
}

// =============================================================================
// Cue pulse — haptic signal traveling wire + shockwave impact, Section 02
// =============================================================================

class _CuePulseViz extends StatefulWidget {
  const _CuePulseViz();

  @override
  State<_CuePulseViz> createState() => _CuePulseVizState();
}

class _CuePulseVizState extends State<_CuePulseViz>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _CuePulsePainter(t: _c.value)),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            'HAPTIC CUE',
            style: _mono(9, color: _Palette.muted, letterSpacing: 2),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final firing = _c.value > 0.20 && _c.value < 0.85;
              return Text(
                firing ? '● FIRE' : '○ ARMED',
                style: _mono(
                  9,
                  color: firing ? _Palette.signal : _Palette.muted,
                  letterSpacing: 2,
                  weight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Text(
            'LATENCY < 500 MS',
            style: _mono(9, color: _Palette.signal, letterSpacing: 2),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final ms = (_c.value * 500).clamp(0, 500).round();
              return Text(
                '$ms MS',
                style: _mono(9, color: _Palette.text, letterSpacing: 2),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CuePulsePainter extends CustomPainter {
  _CuePulsePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final startY = size.height * 0.5;
    final wireStart = Offset(28, startY);
    final wireEnd = Offset(size.width - 28, startY);

    final wirePaint = Paint()
      ..color = _Palette.hairline.withValues(alpha: 0.95)
      ..strokeWidth = 1.2;
    canvas.drawLine(wireStart, wireEnd, wirePaint);

    final nodePaint = Paint()..color = _Palette.muted;
    canvas.drawCircle(wireStart, 5, nodePaint);
    canvas.drawCircle(wireEnd, 5, nodePaint);

    const labelStyle = TextStyle(
      color: _Palette.subtle,
      fontSize: 9,
      letterSpacing: 2,
      fontFamily: 'IBMPlexMono',
    );
    _paintText(canvas, 'PHONE',
        Offset(wireStart.dx - 12, wireStart.dy + 14), labelStyle);
    _paintText(canvas, 'MOTOR',
        Offset(wireEnd.dx - 24, wireEnd.dy + 14), labelStyle);

    // Traveling pulse.
    if (t > 0.15 && t < 0.60) {
      final progress = ((t - 0.15) / 0.45).clamp(0.0, 1.0);
      final eased = _easeInOutCubic(progress);
      final pulseX = wireStart.dx + (wireEnd.dx - wireStart.dx) * eased;
      final center = Offset(pulseX, startY);

      final streakPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            _Palette.signal.withValues(alpha: 0),
            _Palette.signal.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(pulseX - 64, startY - 2, 64, 4))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(pulseX - 64, startY), center, streakPaint);

      canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = _Palette.signal.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(center, 3.5, Paint()..color = _Palette.signal);
    }

    // Shockwave at motor end.
    if (t > 0.55 && t < 0.85) {
      final progress = ((t - 0.55) / 0.30).clamp(0.0, 1.0);
      final radius = 12 + progress * 48;
      final alpha = (1 - progress) * 0.6;
      canvas.drawCircle(
        wireEnd,
        radius,
        Paint()
          ..color = _Palette.signal.withValues(alpha: alpha)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        wireEnd,
        radius * 0.6,
        Paint()
          ..color = _Palette.signal.withValues(alpha: alpha * 0.6)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CuePulsePainter old) => old.t != t;
}

// =============================================================================
// Recruitment ratio chart — animated pre/post cue bars, Section 03
// =============================================================================

class _RatioBarChart extends StatefulWidget {
  const _RatioBarChart();

  @override
  State<_RatioBarChart> createState() => _RatioBarChartState();
}

class _RatioBarChartState extends State<_RatioBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _shift(double t) {
    if (t < 0.30) return 0;
    if (t > 0.55) return 1;
    return _easeInOutCubic((t - 0.30) / 0.25);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _RatioPainter(shift: _shift(_c.value), cycle: _c.value),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            'RMS RATIO · 500 MS WINDOW',
            style: _mono(9, color: _Palette.muted, letterSpacing: 2),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final shift = _shift(_c.value);
              final shiftPct = (shift * 22).round();
              final ok = shiftPct >= 15;
              return Text(
                ok ? 'Δ $shiftPct% · OK' : 'Δ $shiftPct%',
                style: _mono(
                  9,
                  color: ok ? _Palette.signal : _Palette.muted,
                  letterSpacing: 2,
                  weight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RatioPainter extends CustomPainter {
  _RatioPainter({required this.shift, required this.cycle});
  final double shift;
  final double cycle;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0;
    const top = 52.0;
    const barH = 38.0;
    const labelGap = 30.0;
    final trackW = size.width - pad * 2;
    final y1 = top;
    final y2 = top + barH + labelGap + 22;

    final trackPaint = Paint()
      ..color = _Palette.hairline.withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(pad, y1, trackW, barH), trackPaint);
    canvas.drawRect(Rect.fromLTWH(pad, y2, trackW, barH), trackPaint);

    final brachPct = 0.62 - 0.22 * shift;
    final bicepPct = 0.38 + 0.22 * shift;

    canvas.drawRect(
      Rect.fromLTWH(pad, y1, trackW * brachPct, barH),
      Paint()..color = _Palette.muted.withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(pad, y2, trackW * bicepPct, barH),
      Paint()..color = _Palette.signal,
    );

    _paintMono(
      canvas,
      'BRACH  ·  ${(brachPct * 100).round()}%',
      Offset(pad, y1 - 14),
      _Palette.text,
      10,
    );
    _paintMono(
      canvas,
      'BICEP  ·  ${(bicepPct * 100).round()}%',
      Offset(pad, y2 - 14),
      _Palette.signal,
      10,
    );

    // 15% threshold marker.
    final thresholdX = pad + trackW * (0.62 - 0.15);
    final crossed = shift >= (15.0 / 22.0);
    final markerColor = crossed ? _Palette.signal : _Palette.subtle;
    canvas.drawLine(
      Offset(thresholdX, y1 - 8),
      Offset(thresholdX, y2 + barH + 8),
      Paint()
        ..color = markerColor.withValues(alpha: crossed ? 0.9 : 0.6)
        ..strokeWidth = 1.4,
    );
    _paintMono(
      canvas,
      '≥15%',
      Offset(thresholdX - 14, y2 + barH + 10),
      markerColor,
      9,
    );

    // Cue-fired flash marker.
    if (cycle > 0.28 && cycle < 0.40) {
      final alpha = (1 - ((cycle - 0.33).abs() / 0.05)).clamp(0.0, 1.0);
      _paintMono(
        canvas,
        '◉ CUE',
        Offset(size.width - 70, y1 + barH + 10),
        _Palette.signal.withValues(alpha: alpha),
        9,
        weight: FontWeight.w600,
      );
    }
  }

  void _paintMono(
    Canvas c,
    String s,
    Offset o,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w400,
  }) {
    final style = TextStyle(
      color: color,
      fontSize: size,
      letterSpacing: 2,
      fontWeight: weight,
      fontFamily: 'IBMPlexMono',
    );
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _RatioPainter old) =>
      old.shift != shift || old.cycle != cycle;
}

// =============================================================================
// Figures section — oversized numerals with mono captions
// =============================================================================

class _FiguresSection extends StatelessWidget {
  const _FiguresSection();

  @override
  Widget build(BuildContext context) {
    final isNarrow = _isNarrow(context);
    final isDesktop = _isDesktop(context);

    const primary = [
      _FigureBig(value: '< 500', unit: 'MS', label: 'LATENCY'),
      _FigureBig(value: '≥ 15', unit: '%', label: 'THRESHOLD'),
      _FigureBig(value: '33', unit: 'LM', label: 'LANDMARKS'),
      _FigureBig(value: '2', unit: 'CH', label: 'CHANNELS'),
    ];

    const secondary = [
      _FigureSmall(value: '1 kHz', label: 'SAMPLE'),
      _FigureSmall(value: '30 FPS', label: 'POSE'),
      _FigureSmall(value: '500 ms', label: 'WINDOW'),
      _FigureSmall(value: 'BLE 5.0', label: 'TRANSPORT'),
    ];

    return _SectionShell(
      washTint: _Palette.secondary, // theme secondary — light blue, bridges sky→indigo
      washOpacity: 0.05,
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter(context),
        vertical: isNarrow ? 80 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// FIGURES  —  SYSTEM PARAMETERS',
            style: _mono(11, color: _Palette.subtle, letterSpacing: 2.6),
          ),
          SizedBox(height: isNarrow ? 36 : 56),
          Wrap(
            spacing: isDesktop ? 80 : 40,
            runSpacing: 56,
            children: primary,
          ),
          SizedBox(height: isNarrow ? 64 : 96),
          Container(height: 1, color: _Palette.hairlineSoft),
          SizedBox(height: isNarrow ? 28 : 40),
          Wrap(
            spacing: isDesktop ? 56 : 32,
            runSpacing: 28,
            children: secondary,
          ),
        ],
      ),
      ),
    );
  }
}

class _FigureBig extends StatelessWidget {
  const _FigureBig({
    required this.value,
    required this.unit,
    required this.label,
  });
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isNarrow = _isNarrow(context);
    final valueSize = isDesktop ? 108.0 : (isNarrow ? 60.0 : 84.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: _display(
                valueSize,
                weight: FontWeight.w500,
                letterSpacing: -4,
                height: 0.95,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: valueSize * 0.2),
              child: Text(
                unit,
                style: _mono(
                  isDesktop ? 13 : 11,
                  color: _Palette.muted,
                  letterSpacing: 2,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 1, color: _Palette.signal),
            const SizedBox(width: 10),
            Text(
              label,
              style: _mono(10, color: _Palette.muted, letterSpacing: 2.6),
            ),
          ],
        ),
      ],
    );
  }
}

class _FigureSmall extends StatelessWidget {
  const _FigureSmall({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: _display(
            _isDesktop(context) ? 34 : 26,
            weight: FontWeight.w500,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: _mono(9, color: _Palette.subtle, letterSpacing: 2.2),
        ),
      ],
    );
  }
}
