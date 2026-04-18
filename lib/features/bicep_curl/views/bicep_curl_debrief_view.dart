import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../models/session_log.dart';
import 'widgets/body_heatmap.dart';
import 'widgets/cue_timeline.dart';
import 'widgets/peak_chart.dart';

/// Loads a persisted bicep curl session by id and renders the post-set
/// debrief. The chain (commit 7 persistence → commit 8 load) means the
/// live view navigates here with `?id=bicep_<ms>` and history-tile taps
/// route here too with the same shape.
final _debriefSessionProvider =
    FutureProvider.autoDispose.family<SessionLog?, String>((ref, id) async {
  final record =
      await ref.read(localStorageServiceProvider).loadSessionRecord(id);
  final blob = record?.bicepCurl;
  if (blob == null) return null;
  return SessionLog.fromJson(blob);
});

class BicepCurlDebriefView extends ConsumerWidget {
  const BicepCurlDebriefView({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLog = ref.watch(_debriefSessionProvider(sessionId));

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('DEBRIEF'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: asyncLog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load session: $e',
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
        data: (log) {
          if (log == null) {
            return const Center(
              child: Text(
                'Session not found',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return _DebriefBody(log: log);
        },
      ),
    );
  }
}

class _DebriefBody extends StatelessWidget {
  const _DebriefBody({required this.log});

  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    final baseline = log.baselineTrajectory(log.profile.baselineWindow);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsRow(log: log),
          const SizedBox(height: 20),
          if (log.bleDroppedDuringSet) _bleDropBanner(),
          _Section(
            title: 'EMG PEAKS PER REP',
            child: PeakChart(
              peaks: log.peaks,
              baseline: baseline,
              cueEvents: log.cueEvents,
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'MUSCLE ACTIVITY',
            child: BicepCurlHeatmapSection(log: log),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'CUE TIMELINE',
            child: CueTimeline(events: log.cueEvents),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'COMPENSATION EVENTS',
            child: _CompensationList(log: log),
          ),
          const SizedBox(height: 24),
          _CtaRow(),
        ],
      ),
    );
  }

  Widget _bleDropBanner() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.15),
          border:
              Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.bluetooth_disabled,
                color: Colors.orangeAccent, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'BLE link dropped during this set — fatigue evaluation went '
                'silent partway through. Pose-based form analysis continued.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.log});
  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'REPS', value: '${log.reps.length}')),
        Expanded(
          child: _Stat(
            label: 'DURATION',
            value: _fmtDuration(log.duration),
          ),
        ),
        Expanded(
          child: _Stat(
            label: 'FORM SCORE',
            value: '${log.formScore.toStringAsFixed(0)}%',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BioliminalTheme.glassEffect,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'IBMPlexMono',
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BioliminalTheme.glassEffect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CompensationList extends StatelessWidget {
  const _CompensationList({required this.log});
  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    final events = <Widget>[];
    for (final r in log.reps) {
      final d = r.poseDelta;
      if (d == null) continue;
      if (!d.exceedsThresholds(log.profile.compensation)) continue;
      events.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Rep ${r.repNum}: shoulder ${d.shoulderDriftDeg.toStringAsFixed(1)}°, '
          'torso ${d.torsoPitchDeltaDeg.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ));
    }
    if (events.isEmpty) {
      return const Text(
        'Clean form across the set.',
        style: TextStyle(color: Colors.white54),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: events);
  }
}

class _CtaRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('DONE'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => context.go('/sets'),
            style: FilledButton.styleFrom(
              backgroundColor: BioliminalTheme.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('ANOTHER SET'),
          ),
        ),
      ],
    );
  }
}

String _fmtDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60);
  if (m == 0) return '${s}s';
  return '${m}m ${s}s';
}
