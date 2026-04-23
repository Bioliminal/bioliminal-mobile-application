import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hardware_controller.dart';
import '../../../../core/services/sample_batch.dart';
import '../../../../core/theme.dart';

/// Live EMG envelope sparkline — the baseline UI feedback during a
/// hardware-led session. Shows the user what their muscle is doing in
/// real time without requiring any form-correction CV overlay.
///
/// Reads the raw ENV channel from the [rawEmgStreamProvider], downsamples
/// one value per packet (50 samples → mean), and keeps a rolling window
/// of recent values in a paint cache. One `CustomPaint` per frame —
/// cheap enough to leave always-on during the set.
///
/// **Scale discipline:** fixed floor at 0, ceiling = `max(initialCeiling,
/// max-in-visible-window * 1.2)`. Quiet muscle plots near the bottom
/// (noise doesn't fill vertical space). After a hard initial flex the
/// ceiling relaxes back down as the peak ages out of the window, so
/// subsequent real reps aren't stuck plotting tiny against a one-time
/// early spike. Per Rajat's live-test finding 2026-04-23: "after the
/// first 5 reps the EMG is not reading" — the session-ratcheting version
/// locked in the calibration flex and never decayed, compressing all
/// subsequent envelopes visually.
class MuscleActivityOverlay extends ConsumerStatefulWidget {
  const MuscleActivityOverlay({
    super.key,
    this.windowSeconds = 3.0,
    this.height = 64.0,
    this.initialCeiling = 500.0,
  });

  /// Rolling window length in wall seconds. At 40 Hz packet rate this is
  /// [windowSeconds] * 40 samples kept in the ring. Also defines the
  /// decay window for the ceiling — peaks older than this age out.
  final double windowSeconds;
  final double height;

  /// Floor-level ceiling (in ADC units) when no recent activity is
  /// present. Real contraction peaks push the ceiling above this via
  /// the window-max computation. 500 ADC (~12% of 4095) is above the
  /// MyoWare noise floor on a clean electrode setup, so quiet muscle
  /// plots as a small flat band near the bottom rather than filling the
  /// widget with amplified noise.
  final double initialCeiling;

  @override
  ConsumerState<MuscleActivityOverlay> createState() =>
      _MuscleActivityOverlayState();
}

class _MuscleActivityOverlayState extends ConsumerState<MuscleActivityOverlay> {
  late final int _cap = (widget.windowSeconds * 40).round();
  late final Queue<double> _ring = Queue<double>();

  /// Ceiling = `max(initialCeiling, max(_ring) * 1.2)`. Recomputes on
  /// every packet. Decays as old peaks slide out of the window.
  double get _ceiling {
    var maxInWindow = widget.initialCeiling;
    for (final v in _ring) {
      if (v > maxInWindow) maxInWindow = v;
    }
    return maxInWindow * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    // Pull ENV mean out of every decoded packet.
    ref.listen<AsyncValue<SampleBatch>>(rawEmgStreamProvider, (_, next) {
      next.whenData((batch) {
        if (batch.env.isEmpty) return;
        var sum = 0;
        for (final v in batch.env) {
          sum += v;
        }
        final mean = sum / batch.env.length;
        setState(() {
          _ring.addLast(mean);
          while (_ring.length > _cap) {
            _ring.removeFirst();
          }
        });
      });
    });

    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'MUSCLE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomPaint(
              painter: _SparklinePainter(
                values: List<double>.from(_ring),
                color: BioliminalTheme.accent,
                maxValue: _ceiling,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.maxValue,
  });

  final List<double> values;
  final Color color;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Fixed floor at 0 + session-running max ceiling. Quiet muscle plots
    // at the bottom; real activation peaks fill toward the top. Ceiling
    // only ratchets upward over the session so future quiet periods stay
    // honestly small relative to the contractions the user actually did.
    const lo = 0.0;
    final hi = maxValue;
    final range = (hi - lo).clamp(1.0, double.infinity);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final dx = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = ((values[i] - lo) / range).clamp(0.0, 1.0);
      // Leave a ~10% margin at top/bottom so the peak doesn't clip the edge.
      final y = size.height - (0.1 + 0.8 * norm) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(values.length * dx - dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.maxValue != maxValue ||
      old.values.length != values.length ||
      (values.isNotEmpty &&
          old.values.isNotEmpty &&
          old.values.last != values.last);
}
