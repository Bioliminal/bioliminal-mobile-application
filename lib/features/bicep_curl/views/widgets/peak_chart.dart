import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
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
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No reps recorded',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    final maxY = (baseline.isNotEmpty
            ? baseline.reduce((a, b) => a > b ? a : b)
            : peaks.reduce((a, b) => a > b ? a : b)) *
        1.15;

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: peaks.length.toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.white12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: peaks.length > 10 ? 5 : 1,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    value.toInt().toString(),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Rolling-max baseline (drawn first so peaks render above).
            LineChartBarData(
              spots: [
                for (var i = 0; i < baseline.length; i++)
                  FlSpot(i + 1.0, baseline[i]),
              ],
              isCurved: false,
              color: Colors.white24,
              barWidth: 1.5,
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
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) {
                  final cue = cueEvents.where(
                    (c) => c.repNum == spot.x.toInt(),
                  );
                  if (cue.isEmpty) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: BioliminalTheme.accent,
                      strokeWidth: 0,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 6,
                    color: peakChartCueColor(cue.first.content),
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      return Colors.purpleAccent;
    case CueContent.stabilizerWarning:
      return Colors.orangeAccent;
  }
}
