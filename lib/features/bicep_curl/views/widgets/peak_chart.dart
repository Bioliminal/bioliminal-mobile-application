import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../landing/widgets/marketing_tokens.dart';
import '../../models/cue_decision.dart';
import '../../models/cue_event.dart';

/// Line chart of per-rep peak envelope with a rolling-max baseline overlay
/// and per-cue dot annotations colored by cue type. The user reads the
/// "why" of each cue here — the gap between baseline and peak is what
/// fired it.
class PeakChart extends StatelessWidget {
  const PeakChart({
    super.key,
    required this.peaks,
    required this.baseline,
    required this.cueEvents,
  });

  final List<double> peaks;
  final List<double> baseline;
  final List<CueEvent> cueEvents;

  @override
  Widget build(BuildContext context) {
    if (peaks.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'NO REPS RECORDED',
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.4,
            ),
          ),
        ),
      );
    }

    final maxY = (baseline.isNotEmpty
            ? baseline.reduce((a, b) => a > b ? a : b)
            : peaks.reduce((a, b) => a > b ? a : b)) *
        1.15;

    final axisStyle = mktMono(
      9,
      color: MarketingPalette.subtle,
      letterSpacing: 1.4,
      weight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _LegendSwatch(
              color: BioliminalTheme.accent,
              label: 'PEAK ENVELOPE',
            ),
            SizedBox(width: 18),
            _LegendSwatch(
              color: MarketingPalette.subtle,
              label: 'BASELINE',
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: peaks.length.toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: MarketingPalette.hairline,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.toInt().toString(),
                        style: axisStyle,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: peaks.length > 10 ? 5 : 1,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        value.toInt().toString(),
                        style: axisStyle,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(
                      color: MarketingPalette.hairline, width: 1),
                  bottom: BorderSide(
                      color: MarketingPalette.hairline, width: 1),
                ),
              ),
              lineBarsData: [
                // Rolling-max baseline (drawn first so peaks render above).
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < baseline.length; i++)
                      FlSpot(i + 1.0, baseline[i]),
                  ],
                  isCurved: false,
                  color: MarketingPalette.subtle,
                  barWidth: 1,
                  dashArray: const [4, 4],
                  dotData: const FlDotData(show: false),
                ),
                // Per-rep peak envelope.
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < peaks.length; i++)
                      FlSpot(i + 1.0, peaks[i]),
                  ],
                  isCurved: false,
                  color: BioliminalTheme.accent,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, _, _) {
                      final cue = cueEvents.where(
                        (c) => c.repNum == spot.x.toInt(),
                      );
                      if (cue.isEmpty) {
                        return FlDotCirclePainter(
                          radius: 2.5,
                          color: BioliminalTheme.accent,
                          strokeWidth: 0,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 5,
                        color: peakChartCueColor(cue.first.content),
                        strokeColor: MarketingPalette.bg,
                        strokeWidth: 2,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'REP INDEX →',
            style: mktMono(
              9,
              color: MarketingPalette.subtle,
              letterSpacing: 2.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    this.dashed = false,
  });
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(16, 2),
          painter: _SwatchLinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: mktMono(
            9,
            color: MarketingPalette.muted,
            letterSpacing: 2.0,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SwatchLinePainter extends CustomPainter {
  _SwatchLinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    const dash = 3.0;
    const gap = 2.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dash).clamp(0, size.width), size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SwatchLinePainter old) =>
      old.color != color || old.dashed != dashed;
}

/// Cue-badge color lookup for [PeakChart]'s dot annotations. Public so
/// tests can lock in the fade/urgent/stop mapping — the first-fade
/// ambiguity fix depends on FADE and URGENT reading as visually distinct
/// even on a colorblind palette.
Color peakChartCueColor(CueContent content) {
  switch (content) {
    case CueContent.fatigueFade:
      return BioliminalTheme.confidenceMedium;
    case CueContent.fatigueUrgent:
      return BioliminalTheme.confidenceLow;
    case CueContent.fatigueStop:
      return Colors.redAccent;
    case CueContent.compensationDetected:
      // Deprecated — grey for legacy sessions replayed in the debrief.
      return Colors.grey;
    case CueContent.shoulderHike:
      return Colors.purpleAccent;
    case CueContent.torsoSwing:
      return Colors.deepPurpleAccent;
    case CueContent.repTooFast:
      return Colors.amberAccent;
    case CueContent.stabilizerWarning:
      return Colors.orangeAccent;
  }
}
