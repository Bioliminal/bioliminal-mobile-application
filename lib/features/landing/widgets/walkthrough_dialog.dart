import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../waitlist/services/waitlist_service.dart';
import 'marketing_tokens.dart';
import 'top_nav.dart' show showMarketingWaitlistDialog;

// 3-slide mock walkthrough that stands in for the scope-frozen /capture flow.
// Shown when visitors tap START THE REP on /demo before the real app ships.
Future<void> showDemoWalkthrough(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => const _WalkthroughDialog(),
  );
}

class _WalkthroughDialog extends StatefulWidget {
  const _WalkthroughDialog();

  @override
  State<_WalkthroughDialog> createState() => _WalkthroughDialogState();
}

class _WalkthroughDialogState extends State<_WalkthroughDialog> {
  int _slide = 0;
  static const _total = 3;

  void _next() {
    if (_slide < _total - 1) setState(() => _slide += 1);
  }

  void _back() {
    if (_slide > 0) setState(() => _slide -= 1);
  }

  void _joinWaitlist() {
    final nav = Navigator.of(context);
    nav.pop();
    showMarketingWaitlistDialog(context, source: WaitlistSource.demo);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _slide == _total - 1;
    final canGoBack = _slide > 0;
    return Dialog(
      backgroundColor: MarketingPalette.bg,
      insetPadding: const EdgeInsets.all(24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: MarketingPalette.hairline, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(32, 22, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '// MOCK WALKTHROUGH  ·  ${_slide + 1} OF $_total',
                    style: mktMono(
                      10,
                      color: MarketingPalette.subtle,
                      letterSpacing: 2.4,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _ExitButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 22),
              // Fixed-height slide area so the footer controls don't jump
              // between slides. Visuals size themselves within this frame.
              SizedBox(
                height: 500,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_slide),
                    child: _slideFor(_slide),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _DotIndicator(index: _slide, total: _total),
                  const Spacer(),
                  _ArrowButton(
                    direction: _ArrowDir.back,
                    enabled: canGoBack,
                    onTap: canGoBack ? _back : null,
                  ),
                  const SizedBox(width: 10),
                  if (isLast)
                    _FilledButton(
                      label: 'JOIN WAITLIST',
                      onTap: _joinWaitlist,
                    )
                  else
                    _ArrowButton(
                      direction: _ArrowDir.next,
                      enabled: true,
                      onTap: _next,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slideFor(int i) => switch (i) {
        0 => const _PermissionSlide(),
        1 => const _CaptureSlide(),
        _ => const _ResultSlide(),
      };
}

// ---------- Slide 1: browser permission prompt ----------

class _PermissionSlide extends StatelessWidget {
  const _PermissionSlide();

  @override
  Widget build(BuildContext context) {
    return _SlideFrame(
      headline: 'Camera stays on your device.',
      caption:
          'Your browser will ask once. We process video in the tab — nothing '
          'uploads, no server sees a frame.',
      visual: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B30),
          border: Border.all(color: MarketingPalette.hairline, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: MarketingPalette.signal.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MarketingPalette.signal,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: mktMono(
                        12,
                        color: MarketingPalette.signal,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'bioliminal.web.app wants to use your camera',
                  style: mktBody(
                    15,
                    color: MarketingPalette.text,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                _PreviewTag(),
                Spacer(),
                _MockPromptButton(label: 'Block', highlighted: false),
                SizedBox(width: 10),
                _MockPromptButton(label: 'Allow', highlighted: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MockPromptButton extends StatelessWidget {
  const _MockPromptButton({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // Non-interactive preview — flat, desaturated, explicitly not clickable.
    // The "highlighted" variant uses a dashed border instead of a filled
    // signal color so visitors don't mistake it for a real CTA.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MarketingPalette.hairline.withValues(alpha: 0.35),
        border: Border.all(
          color: highlighted
              ? MarketingPalette.signal.withValues(alpha: 0.55)
              : MarketingPalette.hairline,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: mktMono(
          11,
          color: MarketingPalette.muted,
          letterSpacing: 1.4,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------- Slide 2: capture with pose overlay ----------

class _CaptureSlide extends StatefulWidget {
  const _CaptureSlide();

  @override
  State<_CaptureSlide> createState() => _CaptureSlideState();
}

class _CaptureSlideState extends State<_CaptureSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideFrame(
      headline: '33 landmarks, live.',
      caption:
          'BlazePose streams landmarks at 30 fps. Joint angles compute on '
          'each frame. Chain rules fire the moment a compensation pattern '
          'emerges.',
      visual: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border:
                Border.all(color: MarketingPalette.hairline, width: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => CustomPaint(
                    painter: _SkeletonPainter(progress: _ctrl.value),
                  ),
                ),
              ),
              const Positioned(
                top: 12,
                left: 12,
                child: _Readout(
                  label: 'REP',
                  value: '03 / 08',
                  color: MarketingPalette.text,
                ),
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: _Readout(
                  label: 'FPS',
                  value: '30',
                  color: MarketingPalette.signal,
                ),
              ),
              const Positioned(
                bottom: 12,
                left: 12,
                child: _Readout(
                  label: 'KNEE VALGUS',
                  value: '12°  ⚠',
                  color: MarketingPalette.warn,
                ),
              ),
              const Positioned(
                bottom: 12,
                right: 12,
                child: _Readout(
                  label: 'HIP SYMMETRY',
                  value: '94%',
                  color: MarketingPalette.signal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stick-figure skeleton overlaid on the capture mock. Progress drives a
// looping squat: hips lower, knees flex, left knee (joint 10) drifts inward
// to visualize the valgus compensation flagged in the HUD.
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // 0→1→0 over one cycle. Sine gives smooth ease in/out at the turns.
    final depth = math.sin(progress * math.pi);

    // Base pose — standing tall.
    final joints = <Offset>[
      const Offset(0.50, 0.14), // 0 head
      const Offset(0.50, 0.28), // 1 neck
      const Offset(0.38, 0.32), // 2 L shoulder
      const Offset(0.62, 0.32), // 3 R shoulder
      const Offset(0.32, 0.48), // 4 L elbow
      const Offset(0.68, 0.48), // 5 R elbow
      const Offset(0.30, 0.60), // 6 L wrist
      const Offset(0.70, 0.60), // 7 R wrist
      Offset(0.44, 0.54 + 0.06 * depth), // 8 L hip (drops with squat)
      Offset(0.56, 0.54 + 0.06 * depth), // 9 R hip
      // 10 L knee — bends inward (valgus) and lowers
      Offset(0.42 + 0.06 * depth, 0.74 + 0.02 * depth),
      // 11 R knee — tracks straight, lowers only
      Offset(0.58, 0.74 + 0.02 * depth),
      const Offset(0.40, 0.92), // 12 L ankle (planted)
      const Offset(0.60, 0.92), // 13 R ankle
    ];

    const bones = <(int, int)>[
      (0, 1), (1, 2), (1, 3),
      (2, 4), (3, 5), (4, 6), (5, 7),
      (2, 8), (3, 9), (8, 9),
      (8, 10), (9, 11), (10, 12), (11, 13),
    ];

    final bonePaint = Paint()
      ..color = MarketingPalette.signal.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final jointPaint = Paint()
      ..color = MarketingPalette.signal
      ..style = PaintingStyle.fill;
    // Warn joint pulses brighter as the compensation grows through the squat.
    final warnPaint = Paint()
      ..color = MarketingPalette.warn
          .withValues(alpha: 0.6 + 0.4 * depth)
      ..style = PaintingStyle.fill;

    Offset p(Offset o) => Offset(o.dx * size.width, o.dy * size.height);

    for (final (a, b) in bones) {
      // L femur (8→10) highlights warn when valgus engages.
      final paint = (a == 8 && b == 10 && depth > 0.25)
          ? (Paint()
            ..color = MarketingPalette.warn.withValues(alpha: 0.8)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round)
          : bonePaint;
      canvas.drawLine(p(joints[a]), p(joints[b]), paint);
    }
    for (var i = 0; i < joints.length; i++) {
      final paint = i == 10 ? warnPaint : jointPaint;
      final r = i == 10 ? (5 + 1.5 * depth) : 5.0;
      canvas.drawCircle(p(joints[i]), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) =>
      old.progress != progress;
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: mktMono(
              9,
              color: MarketingPalette.subtle,
              letterSpacing: 2,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: mktMono(
              12,
              color: color,
              letterSpacing: 1.2,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Slide 3: findings card ----------

class _ResultSlide extends StatelessWidget {
  const _ResultSlide();

  @override
  Widget build(BuildContext context) {
    return _SlideFrame(
      headline: 'Body-path language. No diagnosis.',
      caption:
          'Results map compensations back to the chain driver so the finding '
          'reads as education, not prescription.',
      visual: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B30),
          border: Border.all(color: MarketingPalette.hairline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'FINDINGS',
                  style: mktMono(
                    10,
                    color: MarketingPalette.subtle,
                    letterSpacing: 2.4,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'CONFIDENCE · 0.88',
                  style: mktMono(
                    10,
                    color: MarketingPalette.signal,
                    letterSpacing: 2.4,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Knee collapses inward at ~40% of rep depth.',
              style: mktBody(
                17,
                color: MarketingPalette.text,
                weight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            const _ChainRow(
                label: 'CHAIN',
                value: 'Superficial Back Line',
                color: MarketingPalette.text),
            const SizedBox(height: 10),
            const _ChainRow(
                label: 'DRIVER',
                value: 'Ankle mobility (upstream)',
                color: MarketingPalette.signal),
            const SizedBox(height: 10),
            const _ChainRow(
                label: 'STATUS',
                value: 'Movement education — not diagnostic',
                color: MarketingPalette.muted),
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.4,
              weight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: mktBody(14, color: color, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ---------- Shared slide chrome ----------

class _SlideFrame extends StatelessWidget {
  const _SlideFrame({
    required this.headline,
    required this.caption,
    required this.visual,
  });

  final String headline;
  final String caption;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          headline,
          style: mktDisplay(
            26,
            italic: true,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          style: mktBody(14, color: MarketingPalette.muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        visual,
      ],
    );
  }
}

// ---------- Controls ----------

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? MarketingPalette.signal
                  : MarketingPalette.hairline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

enum _ArrowDir { back, next }

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  final _ArrowDir direction;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.enabled
        ? (_hover ? MarketingPalette.text : MarketingPalette.muted)
        : MarketingPalette.hairline;
    final glyph = widget.direction == _ArrowDir.back ? '←' : '→';
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: baseColor, width: 1),
          ),
          child: Text(
            glyph,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 18,
              color: baseColor,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MarketingPalette.hairline.withValues(alpha: 0.5),
        border: Border.all(
          color: MarketingPalette.subtle.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        'PREVIEW — NOT INTERACTIVE',
        style: mktMono(
          9,
          color: MarketingPalette.subtle,
          letterSpacing: 2,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilledButton extends StatefulWidget {
  const _FilledButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_FilledButton> createState() => _FilledButtonState();
}

class _FilledButtonState extends State<_FilledButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg =
        _hover ? MarketingPalette.text : MarketingPalette.signal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: bg),
          child: Text(
            widget.label,
            style: mktMono(
              11,
              color: MarketingPalette.bg,
              letterSpacing: 2.4,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// Labeled exit — more discoverable than a bare × and still compact.
class _ExitButton extends StatefulWidget {
  const _ExitButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ExitButton> createState() => _ExitButtonState();
}

class _ExitButtonState extends State<_ExitButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hover ? MarketingPalette.text : MarketingPalette.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EXIT',
                style: mktMono(
                  10,
                  color: color,
                  letterSpacing: 2.4,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '×',
                style: TextStyle(
                  color: color,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 16,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
