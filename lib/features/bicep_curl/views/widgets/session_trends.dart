import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import '../../../landing/widgets/marketing_tokens.dart';
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

/// Three hairline-separated trend rows: form score, first fade rep, peak EMG.
/// Surfaces the "are you improving" signal the per-session debrief
/// can't show on its own. Renders an empty-state below 2 sessions.
class SessionTrends extends ConsumerWidget {
  const SessionTrends({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(allBicepCurlSessionsProvider);
    return asyncSessions.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Failed to load trends: $e',
        style: mktMono(10, color: MarketingPalette.subtle, letterSpacing: 1.4),
      ),
      data: (sessions) {
        if (sessions.length < 2) return const _NotEnoughSessions();
        final formScores = sessions.map((s) => s.formScore).toList();
        // For sessions where no fade ever fired, plot at total_reps + 1
        // so the user reads "your fade rep was past the end of the set"
        // instead of looking at a "—" gap that reads as missing data.
        // Display also flips to "RIR+<n>" so the value is unambiguous.
        final firstFades = <_FadePoint>[];
        for (final s in sessions) {
          final fade = _firstFadeRep(s);
          if (fade > 0) {
            firstFades.add(_FadePoint(value: fade.toDouble(), faded: true));
          } else {
            firstFades.add(
              _FadePoint(value: (s.reps.length + 1).toDouble(), faded: false),
            );
          }
        }
        final maxPeaks = sessions
            .map((s) => s.peaks.isEmpty
                ? 0.0
                : s.peaks.reduce((a, b) => a > b ? a : b))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrendRow(
              label: 'FORM SCORE',
              unit: '%',
              values: formScores,
              format: (v) => v.toStringAsFixed(0),
              higherIsBetter: true,
            ),
            _Hairline(),
            _TrendRow(
              label: 'FIRST FADE',
              unit: 'REP',
              values: firstFades.map((p) => p.value).toList(),
              format: (v) {
                final p = firstFades.firstWhere(
                  (p) => p.value == v,
                  orElse: () => firstFades.last,
                );
                return p.faded
                    ? v.toStringAsFixed(0)
                    : 'RIR+${(v - 1).toStringAsFixed(0)}';
              },
              higherIsBetter: true,
            ),
            _Hairline(),
            _TrendRow(
              label: 'PEAK EMG',
              unit: 'ENV',
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

class _Hairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: MarketingPalette.hairline);
  }
}

class _NotEnoughSessions extends StatelessWidget {
  const _NotEnoughSessions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: MarketingPalette.subtle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'TRENDS UNLOCK AFTER SESSION 02',
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FadePoint {
  const _FadePoint({required this.value, required this.faded});
  final double value;
  final bool faded;
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
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
    // Colorblind-safe palette (Wong-style): blue for improving, orange
    // for regressing. Avoids the classic red/green deuteranopia trap.
    // Arrows still carry the same signal redundantly.
    final deltaColor = delta == 0
        ? MarketingPalette.subtle
        : improved
            ? const Color(0xFF56B4E9) // sky blue
            : const Color(0xFFE69F00); // orange
    final arrow = delta == 0 ? '—' : (delta > 0 ? '↑' : '↓');
    final displayed = format(latest);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: mktMono(
                    9,
                    color: MarketingPalette.muted,
                    letterSpacing: 2.4,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          displayed,
                          style: mktDisplay(
                            32,
                            weight: FontWeight.w500,
                            letterSpacing: -1.6,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit,
                        style: mktMono(
                          9,
                          color: MarketingPalette.subtle,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(height: 42, child: _Sparkline(values: values)),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 22,
            child: Text(
              arrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: deltaColor,
                fontFamily: 'IBMPlexMono',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            barWidth: 1.5,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, bar) =>
                  spot.x == (values.length - 1).toDouble(),
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 2.5,
                color: BioliminalTheme.accent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: BioliminalTheme.accent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
