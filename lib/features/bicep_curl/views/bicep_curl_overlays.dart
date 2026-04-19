import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../controllers/bicep_curl_controller.dart';
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
