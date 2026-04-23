import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../landing/widgets/marketing_tokens.dart';
import '../../models/cue_decision.dart';
import '../../models/session_log.dart';

/// Debrief panel for bicep-curl form. Renders two per-rep signed bar charts
/// (shoulder rise + forward lean) against the profile's compensation
/// thresholds.
///
/// Why a bar chart: the underlying pose data is one signed peak per rep
/// per signal. A heatmap-style glow on a silhouette pretended to be
/// spatial and continuous; it isn't. A bar chart reveals the sequence
/// (fatigue-driven drift across reps, sporadic bad reps) that a per-frame
/// glow hid.
class BicepCurlFormSection extends StatelessWidget {
  const BicepCurlFormSection({super.key, required this.log});

  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    if (log.reps.isEmpty) return const SizedBox.shrink();
    return _FormOverTimeStrip(log: log);
  }
}

class _PanelLabeled extends StatelessWidget {
  const _PanelLabeled({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String index;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: MarketingPalette.hairline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(index: index, title: title, subtitle: subtitle),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              index,
              style: mktMono(
                10,
                color: MarketingPalette.signal,
                letterSpacing: 1.6,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 1,
              color: MarketingPalette.signal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: mktMono(
                  11,
                  color: MarketingPalette.text,
                  letterSpacing: 2.6,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: mktMono(
            8,
            color: MarketingPalette.subtle,
            letterSpacing: 1.6,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form-over-time strip — per-rep signed bar charts for pose compensation
// ---------------------------------------------------------------------------

/// Pure classification for a single rep's signed peak delta against the
/// profile threshold. Exposed so tests can exercise the bucketing
/// directly without reaching into the painter.
///
/// Semantics: positive bars (compensation direction — shoulder up /
/// torso forward) bucket by threshold multiplier. Negative bars (slump /
/// back-lean) are never compensation; they bucket to [negative] and draw
/// below the axis in muted grey regardless of magnitude.
enum BarBucket {
  /// No pose data for this rep (calibration window or frame gap).
  missing,

  /// Negative signed delta — drawn downward in muted grey. Not scored.
  negative,

  /// `[0, 0.5×)` threshold. Clean; dim grey.
  clean,

  /// `[0.5×, 1×]` threshold. Approaching; amber.
  amber,

  /// `> 1×` threshold. Cue-firing range; red.
  red,
}

BarBucket bucketFor(double? signed, double threshold) {
  if (signed == null) return BarBucket.missing;
  if (signed < 0) return BarBucket.negative;
  if (signed > threshold) return BarBucket.red;
  if (signed >= threshold * 0.5) return BarBucket.amber;
  return BarBucket.clean;
}

class _FormOverTimeStrip extends StatelessWidget {
  const _FormOverTimeStrip({required this.log});

  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    final shoulderSeries = <double?>[
      for (final r in log.reps) r.poseDelta?.shoulderDriftDeg,
    ];
    final leanSeries = <double?>[
      for (final r in log.reps) r.poseDelta?.torsoPitchDeltaDeg,
    ];

    final shoulderCueReps = <int>{
      for (final e in log.cueEvents)
        if (e.content == CueContent.shoulderHike) e.repNum - 1,
    };
    final leanCueReps = <int>{
      for (final e in log.cueEvents)
        if (e.content == CueContent.torsoSwing) e.repNum - 1,
    };

    final thresholds = log.profile.compensation;

    return _PanelLabeled(
      index: '01',
      title: 'FORM OVER TIME',
      subtitle: 'PER-REP MUSCLE ENGAGEMENT · POSE-INFERRED',
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SignedRepBarChart(
              label: 'SHOULDER RISE',
              muscles: 'trapezius · anterior deltoid',
              signedValues: shoulderSeries,
              threshold: thresholds.shoulderDriftDeg,
              cueMarkerReps: shoulderCueReps,
            ),
            const SizedBox(height: 20),
            _SignedRepBarChart(
              label: 'FORWARD LEAN',
              muscles: 'erector spinae · hip flexors',
              signedValues: leanSeries,
              threshold: thresholds.torsoPitchDeltaDeg,
              cueMarkerReps: leanCueReps,
            ),
            const SizedBox(height: 12),
            _RepAxisLabel(repCount: log.reps.length),
          ],
        ),
      ),
    );
  }
}

class _RepAxisLabel extends StatelessWidget {
  const _RepAxisLabel({required this.repCount});

  final int repCount;

  @override
  Widget build(BuildContext context) {
    final style = mktMono(
      9,
      color: MarketingPalette.subtle,
      letterSpacing: 2.2,
      weight: FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('REP 01', style: style),
        Text('REP ${repCount.toString().padLeft(2, '0')}', style: style),
      ],
    );
  }
}

class _SignedRepBarChart extends StatelessWidget {
  const _SignedRepBarChart({
    required this.label,
    required this.muscles,
    required this.signedValues,
    required this.threshold,
    required this.cueMarkerReps,
  });

  final String label;
  final String muscles;
  final List<double?> signedValues;
  final double threshold;
  final Set<int> cueMarkerReps;

  @override
  Widget build(BuildContext context) {
    final positiveValues = signedValues
        .whereType<double>()
        .where((v) => v > 0)
        .toList();
    final negativeValues = signedValues
        .whereType<double>()
        .where((v) => v < 0)
        .toList();
    final observedMaxPos = positiveValues.isEmpty
        ? 0.0
        : positiveValues.reduce(math.max);
    final observedMaxNeg = negativeValues.isEmpty
        ? 0.0
        : negativeValues.map((v) => v.abs()).reduce(math.max);

    final peakLabelValue = signedValues
        .whereType<double>()
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: mktMono(
                  10,
                  color: MarketingPalette.text,
                  letterSpacing: 2.4,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'peak ${_formatDeg(peakLabelValue)}',
              style: mktMono(
                9,
                color: MarketingPalette.muted,
                letterSpacing: 1.8,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          muscles,
          style: mktMono(
            8,
            color: MarketingPalette.subtle,
            letterSpacing: 1.4,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, 78),
              painter: _RepBarPainter(
                signedValues: signedValues,
                threshold: threshold,
                observedMaxPos: observedMaxPos,
                observedMaxNeg: observedMaxNeg,
                cueMarkerReps: cueMarkerReps,
              ),
            );
          },
        ),
      ],
    );
  }
}

String _formatDeg(double deg) {
  if (deg == 0) return '0°';
  final sign = deg > 0 ? '+' : '-';
  return '$sign${deg.abs().toStringAsFixed(0)}°';
}

class _RepBarPainter extends CustomPainter {
  _RepBarPainter({
    required this.signedValues,
    required this.threshold,
    required this.observedMaxPos,
    required this.observedMaxNeg,
    required this.cueMarkerReps,
  });

  final List<double?> signedValues;
  final double threshold;
  final double observedMaxPos;
  final double observedMaxNeg;
  final Set<int> cueMarkerReps;

  static const double _markerGutter = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (signedValues.isEmpty) return;

    final posMax = math.max(threshold * 1.5, observedMaxPos);
    final negMax = math.max(threshold * 0.5, observedMaxNeg);
    final totalRange = posMax + negMax;
    if (totalRange <= 0) return;

    final chartTop = _markerGutter;
    final chartBottom = size.height - 4;
    final chartHeight = chartBottom - chartTop;
    if (chartHeight <= 0) return;

    final axisY = chartTop + chartHeight * (posMax / totalRange);

    final thresholdY = axisY - (threshold / totalRange) * chartHeight;
    final hairline = Paint()
      ..color = MarketingPalette.hairline
      ..strokeWidth = 1;
    const dashLen = 4.0;
    const dashGap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset(math.min(x + dashLen, size.width), thresholdY),
        hairline,
      );
      x += dashLen + dashGap;
    }

    canvas.drawLine(
      Offset(0, axisY),
      Offset(size.width, axisY),
      Paint()
        ..color = MarketingPalette.hairline
        ..strokeWidth = 1,
    );

    final reps = signedValues.length;
    final gap = reps <= 8 ? 4.0 : (reps <= 16 ? 2.5 : 1.5);
    final totalGap = gap * (reps - 1).clamp(0, reps - 1);
    final barWidth = math.max(1.5, (size.width - totalGap) / reps);

    for (var i = 0; i < reps; i++) {
      final bucket = bucketFor(signedValues[i], threshold);
      if (bucket == BarBucket.missing) continue;

      final signed = signedValues[i]!;
      final barX = i * (barWidth + gap);

      final color = _colorFor(bucket);
      final fill = Paint()..color = color;

      if (bucket == BarBucket.negative) {
        final mag = signed.abs();
        final h = (mag / totalRange) * chartHeight;
        canvas.drawRect(
          Rect.fromLTWH(barX, axisY, barWidth, h),
          fill,
        );
      } else {
        final h = (signed / totalRange) * chartHeight;
        canvas.drawRect(
          Rect.fromLTWH(barX, axisY - h, barWidth, h),
          fill,
        );

        if (cueMarkerReps.contains(i)) {
          _drawCueMarker(canvas, barX + barWidth / 2, axisY - h - 2);
        }
      }
    }
  }

  Color _colorFor(BarBucket bucket) {
    switch (bucket) {
      case BarBucket.clean:
        return MarketingPalette.subtle;
      case BarBucket.amber:
        return MarketingPalette.warn;
      case BarBucket.red:
        return MarketingPalette.error;
      case BarBucket.negative:
        return MarketingPalette.subtle.withValues(alpha: 0.55);
      case BarBucket.missing:
        return Colors.transparent;
    }
  }

  void _drawCueMarker(Canvas canvas, double cx, double tipY) {
    const half = 3.0;
    const height = 5.0;
    final path = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx - half, tipY - height)
      ..lineTo(cx + half, tipY - height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = MarketingPalette.error,
    );
  }

  @override
  bool shouldRepaint(covariant _RepBarPainter old) =>
      old.signedValues != signedValues ||
      old.threshold != threshold ||
      old.observedMaxPos != observedMaxPos ||
      old.observedMaxNeg != observedMaxNeg ||
      old.cueMarkerReps != cueMarkerReps;
}
