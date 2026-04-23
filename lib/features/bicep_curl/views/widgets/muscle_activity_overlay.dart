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
/// **Scale discipline:** the plot is fixed-floor-at-0 with a
/// session-ratcheting ceiling. Early-session or quiet-muscle frames sit
/// near the bottom of the widget; real contraction peaks push the
/// ceiling up. This avoids the "synthetic waves" artifact a windowed
/// min/max scale produces, where electrode noise fills the full vertical
/// space even when the muscle is idle.
class MuscleActivityOverlay extends ConsumerStatefulWidget {
  const MuscleActivityOverlay({
    super.key,
    this.windowSeconds = 3.0,
    this.height = 64.0,
    this.initialCeiling = 500.0,
  });

  /// Rolling window length in wall seconds. At 40 Hz packet rate this is
  /// [windowSeconds] * 40 samples kept in the ring.
  final double windowSeconds;
  final double height;

  /// Starting ceiling for the plot's upper bound (in ADC units). Real
  /// contraction peaks ratchet this upward over the session. 500 ADC
  /// (~12% of 4095) is well above MyoWare noise floor on a clean
  /// electrode setup and below typical curl peak envelopes, so a quiet
  /// muscle at session start plots as a flat line near the bottom.
  final double initialCeiling;

  @override
  ConsumerState<MuscleActivityOverlay> createState() =>
      _MuscleActivityOverlayState();
}

class _MuscleActivityOverlayState extends ConsumerState<MuscleActivityOverlay> {
  late final int _cap = (widget.windowSeconds * 40).round();
  late final Queue<double> _ring = Queue<double>();

  /// Session-running max envelope, used as the sparkline's upper bound.
  /// Only ever ratchets upward during a session so later quiet periods
  /// still compare against real peaks seen earlier in the set.
  late double _sessionMax = widget.initialCeiling;

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
          if (mean > _sessionMax) _sessionMax = mean;
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
                maxValue: _sessionMax,
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
