import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../controllers/bicep_curl_controller.dart';
import '../models/cue_decision.dart' show CueContent;
import '../models/cue_event.dart';

// ---------------------------------------------------------------------------
// Rep counter — long-press to cycle the cue profile (debug toggle)
// ---------------------------------------------------------------------------

class RepCounter extends ConsumerWidget {
  const RepCounter({super.key, required this.repCount, required this.label});

  final int repCount;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () {
        ref.read(bicepCurlControllerProvider.notifier).cycleProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile cycled'),
            duration: Duration(milliseconds: 700),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$repCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fatigue bar — color-graded based on current drop fraction
// ---------------------------------------------------------------------------

class FatigueBar extends StatelessWidget {
  const FatigueBar({
    super.key,
    required this.dropFraction,
    required this.emgOnline,
  });

  final double dropFraction;
  final bool emgOnline;

  @override
  Widget build(BuildContext context) {
    final pct = (dropFraction * 100).clamp(0, 100).toInt();
    final color = !emgOnline
        ? Colors.white24
        : dropFraction < 0.10
            ? BioliminalTheme.confidenceHigh
            : dropFraction < 0.25
                ? BioliminalTheme.confidenceMedium
                : BioliminalTheme.confidenceLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            emgOnline ? 'FATIGUE' : 'EMG OFFLINE',
            style: TextStyle(
              color: emgOnline ? Colors.white70 : Colors.orangeAccent,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: emgOnline ? dropFraction.clamp(0, 1) : 0,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              emgOnline ? '$pct%' : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'IBMPlexMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compensation badge — visible when current rep is compensating
// ---------------------------------------------------------------------------

class CompensationBadge extends StatelessWidget {
  const CompensationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BioliminalTheme.confidenceLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'WATCH YOUR FORM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cue flash — full-screen brief flash on each cue event
// ---------------------------------------------------------------------------

class CueFlashIndicator extends StatefulWidget {
  const CueFlashIndicator({super.key, required this.bus});

  final ValueListenable<CueEvent?> bus;

  @override
  State<CueFlashIndicator> createState() => _CueFlashIndicatorState();
}

class _CueFlashIndicatorState extends State<CueFlashIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  CueEvent? _lastShown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    widget.bus.addListener(_onBus);
  }

  @override
  void dispose() {
    widget.bus.removeListener(_onBus);
    _controller.dispose();
    super.dispose();
  }

  void _onBus() {
    final ev = widget.bus.value;
    if (ev == null || ev == _lastShown) return;
    _lastShown = ev;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          final t = _controller.value;
          // 0 → 1: pulse opacity 0 → 0.35 → 0
          final opacity = t < 0.3
              ? (t / 0.3) * 0.35
              : (1 - (t - 0.3) / 0.7) * 0.35;
          return Container(
            color: BioliminalTheme.accent.withValues(alpha: opacity),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Too-fast banner — prominent top-of-frame flag when a rep is dropped
// below the momentum-gate floor (1.5 s per Wilk/Davies tempo review)
// ---------------------------------------------------------------------------

class RepTooFastBanner extends StatefulWidget {
  const RepTooFastBanner({super.key, required this.bus});

  final ValueListenable<CueEvent?> bus;

  @override
  State<RepTooFastBanner> createState() => _RepTooFastBannerState();
}

class _RepTooFastBannerState extends State<RepTooFastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  CueEvent? _lastShown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    widget.bus.addListener(_onBus);
  }

  @override
  void dispose() {
    widget.bus.removeListener(_onBus);
    _controller.dispose();
    super.dispose();
  }

  void _onBus() {
    final ev = widget.bus.value;
    if (ev == null || ev == _lastShown) return;
    if (ev.content != CueContent.repTooFast) return;
    _lastShown = ev;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          final t = _controller.value;
          // Slide in + fade: 0-0.15 rise, 0.15-0.85 hold, 0.85-1.0 fade.
          double opacity;
          double offsetY;
          if (t == 0) {
            opacity = 0;
            offsetY = -40;
          } else if (t < 0.15) {
            final u = t / 0.15;
            opacity = u;
            offsetY = -40 * (1 - u);
          } else if (t < 0.85) {
            opacity = 1;
            offsetY = 0;
          } else {
            final u = (t - 0.85) / 0.15;
            opacity = 1 - u;
            offsetY = 0;
          }
          opacity = opacity.clamp(0.0, 1.0);
          if (opacity == 0) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, left: 24, right: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, color: Colors.black87, size: 22),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Too fast — slow down to count',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form banner — prominent top-of-frame cue for shoulderHike / torsoSwing.
// Purple accent distinguishes it from the amber too-fast banner. Mirrors
// the RepTooFastBanner slide+fade timing (2.2 s) and shows per-cue copy.
// Complementary to the cue flash indicator and timeline entry — the
// banner gives the user a readable in-session explanation of WHY the
// form cue just fired.
// ---------------------------------------------------------------------------

class FormBanner extends StatefulWidget {
  const FormBanner({super.key, required this.bus});

  final ValueListenable<CueEvent?> bus;

  @override
  State<FormBanner> createState() => _FormBannerState();
}

class _FormBannerState extends State<FormBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  CueEvent? _lastShown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    widget.bus.addListener(_onBus);
  }

  @override
  void dispose() {
    widget.bus.removeListener(_onBus);
    _controller.dispose();
    super.dispose();
  }

  void _onBus() {
    final ev = widget.bus.value;
    if (ev == null || ev == _lastShown) return;
    if (ev.content != CueContent.shoulderHike &&
        ev.content != CueContent.torsoSwing) {
      return;
    }
    _lastShown = ev;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          final t = _controller.value;
          // Slide in + fade: 0-0.15 rise, 0.15-0.85 hold, 0.85-1.0 fade.
          double opacity;
          double offsetY;
          if (t == 0) {
            opacity = 0;
            offsetY = -40;
          } else if (t < 0.15) {
            final u = t / 0.15;
            opacity = u;
            offsetY = -40 * (1 - u);
          } else if (t < 0.85) {
            opacity = 1;
            offsetY = 0;
          } else {
            final u = (t - 0.85) / 0.15;
            opacity = 1 - u;
            offsetY = 0;
          }
          opacity = opacity.clamp(0.0, 1.0);
          if (opacity == 0) return const SizedBox.shrink();
          final ev = _lastShown;
          if (ev == null) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, left: 24, right: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _bannerColor(ev.content),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_bannerIcon(ev.content),
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _bannerText(ev.content),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Color _bannerColor(CueContent c) {
  switch (c) {
    case CueContent.shoulderHike:
      return const Color(0xFF7A3FB8); // purple
    case CueContent.torsoSwing:
      return const Color(0xFF5B2A8E); // deeper purple
    default:
      return const Color(0xFF7A3FB8);
  }
}

IconData _bannerIcon(CueContent c) {
  switch (c) {
    case CueContent.shoulderHike:
      return Icons.arrow_upward;
    case CueContent.torsoSwing:
      return Icons.swap_horiz;
    default:
      return Icons.warning_amber_rounded;
  }
}

String _bannerText(CueContent c) {
  switch (c) {
    case CueContent.shoulderHike:
      return 'Shoulders up — keep them relaxed';
    case CueContent.torsoSwing:
      return 'Body swinging — keep your torso still';
    default:
      return 'Watch your form';
  }
}

// ---------------------------------------------------------------------------
// Framing-check overlay — shown during BicepCurlSetup state
// ---------------------------------------------------------------------------

class FramingCheckOverlay extends StatelessWidget {
  const FramingCheckOverlay({
    super.key,
    required this.holdProgress,
    required this.message,
  });

  /// 0..1 — how far into the 1 s hold we are.
  final double holdProgress;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FRAMING',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (holdProgress > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: holdProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(
                    BioliminalTheme.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge (CALIBRATING N/M, READY)
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: BioliminalTheme.accent.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
