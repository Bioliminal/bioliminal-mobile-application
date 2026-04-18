import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import '../../models/cue_decision.dart';
import '../../models/session_log.dart';

/// Loads every persisted bicep curl session, oldest first. Used by the
/// trends widget to show metric trajectories across the user's history.
final allBicepCurlSessionsProvider =
    FutureProvider.autoDispose<List<SessionLog>>((ref) async {
  final records = await ref
      .read(localStorageServiceProvider)
      .listSessionRecords();
  final logs = <SessionLog>[];
  for (final r in records) {
    if (r.movement != 'bicep_curl') continue;
    final blob = r.bicepCurl;
    if (blob == null) continue;
    logs.add(SessionLog.fromJson(blob));
  }
  logs.sort((a, b) => a.startedAt.compareTo(b.startedAt));
  return logs;
});

/// Three mini sparkline cards: form score, first fade rep, peak EMG.
/// Surfaces the "are you improving" signal the per-session debrief
/// can't show on its own. Renders an empty-state below 2 sessions.
class SessionTrends extends ConsumerWidget {
  const SessionTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(allBicepCurlSessionsProvider);
    return asyncSessions.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Failed to load trends: $e',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      data: (sessions) {
        if (sessions.length < 2) return const _NotEnoughSessions();
        final formScores = sessions.map((s) => s.formScore).toList();
        final firstFades = sessions.map(_firstFadeRep).toList();
        final maxPeaks = sessions
            .map((s) =>
                s.peaks.isEmpty ? 0.0 : s.peaks.reduce((a, b) => a > b ? a : b))
            .toList();

        return Column(
          children: [
            _TrendCard(
              label: 'FORM SCORE',
              unit: '%',
              values: formScores,
              format: (v) => v.toStringAsFixed(0),
              higherIsBetter: true,
            ),
            const SizedBox(height: 10),
            _TrendCard(
              label: 'FIRST FADE REP',
              unit: '',
              values: firstFades.map((v) => v.toDouble()).toList(),
              format: (v) => v == 0 ? '—' : v.toStringAsFixed(0),
              higherIsBetter: true,
            ),
            const SizedBox(height: 10),
            _TrendCard(
              label: 'PEAK EMG',
              unit: '',
              values: maxPeaks,
              format: (v) => v.toStringAsFixed(0),
              higherIsBetter: true,
            ),
          ],
        );
      },
    );
  }

  /// Returns the rep number where the first FADE/URGENT cue fired, or 0
  /// if the session never fatigued (which is itself a strength signal).
  int _firstFadeRep(SessionLog s) {
    for (final e in s.cueEvents) {
      if (e.content == CueContent.fatigueFade ||
          e.content == CueContent.fatigueUrgent) {
        return e.repNum;
      }
    }
    return 0;
  }
}

class _NotEnoughSessions extends StatelessWidget {
  const _NotEnoughSessions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Trends appear after your second session.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.unit,
    required this.values,
    required this.format,
    required this.higherIsBetter,
  });

  final String label;
  final String unit;
  final List<double> values;
  final String Function(double) format;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final latest = values.last;
    final previous = values[values.length - 2];
    final delta = latest - previous;
    final improved = higherIsBetter ? delta >= 0 : delta <= 0;
    final deltaColor = delta == 0
        ? Colors.white54
        : improved
            ? BioliminalTheme.confidenceHigh
            : BioliminalTheme.confidenceLow;
    final arrow = delta == 0 ? '' : (delta > 0 ? '↑' : '↓');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${format(latest)}$unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'IBMPlexMono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      arrow,
                      style: TextStyle(color: deltaColor, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 40, child: _Sparkline(values: values))),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final padded = (maxV - minV).abs() < 1e-6 ? maxV * 0.1 + 1 : 0.0;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: minV - padded,
        maxY: maxV + padded,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: BioliminalTheme.accent,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: BioliminalTheme.accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
