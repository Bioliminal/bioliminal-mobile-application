import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../landing/widgets/instrument_button.dart';
import '../../landing/widgets/marketing_tokens.dart';
import '../../landing/widgets/premium_atmosphere.dart';
import '../models/compensation_reference.dart' show ArmSide;
import '../models/session_log.dart';
import 'widgets/body_heatmap.dart';
import 'widgets/cue_timeline.dart';
import 'widgets/peak_chart.dart';
import 'widgets/session_trends.dart';

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
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AtmosphereGlow(
                color: SectionTint.indigo,
                center: Alignment(0.9, -0.8),
                peak: 0.06,
              ),
            ),
          ),
          SafeArea(
            child: asyncLog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load session: $e',
                    style: mktBody(14, color: MarketingPalette.muted),
                  ),
                ),
              ),
              data: (log) {
                if (log == null) {
                  return Center(
                    child: Text(
                      'Session not found',
                      style: mktMono(12, color: MarketingPalette.subtle,
                          letterSpacing: 2.2),
                    ),
                  );
                }
                return _DebriefBody(log: log, sessionId: sessionId);
              },
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: FilmGrainOverlay()),
          ),
        ],
      ),
    );
  }
}

class _DebriefBody extends StatelessWidget {
  const _DebriefBody({required this.log, required this.sessionId});

  final SessionLog log;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final baseline = log.baselineTrajectory(log.profile.baselineWindow);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(log: log, sessionId: sessionId),
        const _Hairline(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsWall(log: log),
                const SizedBox(height: 44),
                _InstrumentSection(
                  index: '01',
                  title: 'EMG peaks per rep.',
                  signal: 'ENVELOPE',
                  body:
                      'Per-rep peak envelope against a rolling-max baseline. '
                      'Colored dots mark cues — the gap between baseline and '
                      'peak is what fired them.',
                  child: PeakChart(
                    peaks: log.peaks,
                    baseline: baseline,
                    cueEvents: log.cueEvents,
                  ),
                ),
                const SizedBox(height: 44),
                _InstrumentSection(
                  index: '02',
                  title: 'Muscle activity.',
                  signal: 'HEATMAP',
                  body:
                      'Measured bicep envelope, sample-by-sample. Inferred '
                      'synergists step at rep boundaries — that is the truth '
                      'of what pose can tell us.',
                  child: BicepCurlHeatmapSection(log: log),
                ),
                const SizedBox(height: 44),
                _InstrumentSection(
                  index: '03',
                  title: 'Cue timeline.',
                  signal: 'EVENTS',
                  body: log.cueEvents.isEmpty
                      ? 'Nothing fired this set — your envelope held above '
                          'the fade threshold for every rep.'
                      : 'Every cue the system surfaced, in order. '
                          'Color codes fade / urgent / stop.',
                  child: CueTimeline(events: log.cueEvents),
                ),
                const SizedBox(height: 44),
                _InstrumentSection(
                  index: '04',
                  title: 'Compensation.',
                  signal: 'POSE DELTA',
                  body: 'Reps where shoulder or torso drift exceeded '
                      'profile thresholds.',
                  child: _CompensationList(log: log),
                ),
                const SizedBox(height: 44),
                const _InstrumentSection(
                  index: '05',
                  title: 'Trajectory.',
                  signal: 'HISTORY',
                  body: 'Form, first-fade rep, and peak envelope across '
                      'every saved bicep curl session.',
                  child: SessionTrends(),
                ),
              ],
            ),
          ),
        ),
        const _Hairline(),
        _CtaBar(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page header — meta row + Fraunces headline + status strip
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.log, required this.sessionId});
  final SessionLog log;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final dropped = log.bleDroppedDuringSet;
    final dotColor =
        dropped ? MarketingPalette.warn : MarketingPalette.signal;
    final statusLabel = dropped ? 'BLE DROPPED' : 'COMPLETE';
    final arm = log.armSide == ArmSide.left ? 'LEFT' : 'RIGHT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackChevron(onTap: () => context.go('/history')),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'SESSION / ${_shortId(sessionId)}',
                  style: mktMono(
                    10,
                    color: MarketingPalette.subtle,
                    letterSpacing: 2.2,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatMetaDate(log.startedAt.toLocal()),
                style: mktMono(
                  10,
                  color: MarketingPalette.subtle,
                  letterSpacing: 2.2,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Debriefed',
                  style: mktDisplay(
                    52,
                    italic: true,
                    weight: FontWeight.w500,
                    letterSpacing: -2,
                    height: 0.95,
                    color: MarketingPalette.signal,
                  ),
                ),
                Text(
                  '.',
                  style: mktDisplay(
                    52,
                    weight: FontWeight.w500,
                    letterSpacing: -2,
                    height: 0.95,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  statusLabel,
                  style: mktMono(
                    10,
                    color: dotColor,
                    letterSpacing: 2.4,
                    weight: FontWeight.w700,
                  ),
                ),
                _MetaDivider(),
                Text(
                  'BICEP CURL',
                  style: mktMono(
                    10,
                    color: MarketingPalette.muted,
                    letterSpacing: 2.4,
                    weight: FontWeight.w500,
                  ),
                ),
                _MetaDivider(),
                Text(
                  '$arm ARM',
                  style: mktMono(
                    10,
                    color: MarketingPalette.muted,
                    letterSpacing: 2.4,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackChevron extends StatelessWidget {
  const _BackChevron({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      iconSize: 18,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const Icon(Icons.arrow_back, color: MarketingPalette.muted),
      tooltip: 'Back to sessions',
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 12,
        height: 1,
        color: MarketingPalette.subtle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats wall — three oversized Fraunces numerals with rule+label underneath
// ---------------------------------------------------------------------------

class _StatsWall extends StatelessWidget {
  const _StatsWall({required this.log});
  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// INSTRUMENT READOUT',
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.6,
            ),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _StatFigure(
                    value: '${log.reps.length}',
                    unit: 'REPS',
                    label: 'VOLUME',
                  ),
                ),
                const _VerticalHairline(),
                Expanded(
                  child: _StatFigure(
                    value: _durationValue(log.duration),
                    unit: _durationUnit(log.duration),
                    label: 'DURATION',
                  ),
                ),
                const _VerticalHairline(),
                Expanded(
                  child: _StatFigure(
                    value: log.formScore.toStringAsFixed(0),
                    unit: '%',
                    label: 'FORM',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatFigure extends StatelessWidget {
  const _StatFigure({
    required this.value,
    required this.unit,
    required this.label,
  });
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  value,
                  style: mktDisplay(
                    52,
                    weight: FontWeight.w500,
                    letterSpacing: -3,
                    height: 0.9,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                unit,
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 1,
              color: MarketingPalette.signal,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: mktMono(
                9,
                color: MarketingPalette.muted,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalHairline extends StatelessWidget {
  const _VerticalHairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      color: MarketingPalette.hairline,
    );
  }
}

// ---------------------------------------------------------------------------
// Instrument section — numbered, mono signal tag, Fraunces title, body, child
// ---------------------------------------------------------------------------

class _InstrumentSection extends StatelessWidget {
  const _InstrumentSection({
    required this.index,
    required this.title,
    required this.signal,
    required this.body,
    required this.child,
  });

  final String index;
  final String title;
  final String signal;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              index,
              style: mktMono(
                32,
                color: MarketingPalette.signal,
                weight: FontWeight.w300,
                letterSpacing: -1,
                height: 0.9,
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: 18,
                height: 1,
                color: MarketingPalette.signal,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                signal,
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 2.6,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: mktDisplay(
            32,
            weight: FontWeight.w600,
            letterSpacing: -1.4,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: mktBody(
            14,
            color: MarketingPalette.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            border: Border.all(color: MarketingPalette.hairline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compensation list
// ---------------------------------------------------------------------------

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
      if (events.isNotEmpty) {
        events.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: MarketingPalette.hairline,
        ));
      }
      events.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                'REP ${r.repNum.toString().padLeft(2, '0')}',
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: mktBody(
                    13,
                    color: MarketingPalette.text,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'shoulder ',
                      style: TextStyle(color: MarketingPalette.muted),
                    ),
                    TextSpan(
                      text: '${d.shoulderDriftDeg.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: MarketingPalette.text,
                      ),
                    ),
                    const TextSpan(
                      text: '   torso ',
                      style: TextStyle(color: MarketingPalette.muted),
                    ),
                    TextSpan(
                      text: '${d.torsoPitchDeltaDeg.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: MarketingPalette.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (events.isEmpty) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: MarketingPalette.signal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'CLEAN FORM ACROSS THE SET',
            style: mktMono(
              10,
              color: MarketingPalette.signal,
              letterSpacing: 2.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events,
    );
  }
}

// ---------------------------------------------------------------------------
// CTA bar — InstrumentButton doubles
// ---------------------------------------------------------------------------

class _CtaBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: InstrumentButton(
              label: 'DONE',
              hint: '↖ HISTORY',
              onTap: () => context.go('/history'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InstrumentButton(
              label: 'ANOTHER SET',
              hint: '↗',
              filled: true,
              onTap: () => context.go('/sets'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small primitives
// ---------------------------------------------------------------------------

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: MarketingPalette.hairline,
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String _shortId(String id) {
  if (id.length <= 18) return id.toUpperCase();
  return '${id.substring(0, 6)}…${id.substring(id.length - 6)}'.toUpperCase();
}

String _durationValue(Duration d) {
  if (d.inMinutes == 0) return d.inSeconds.toString();
  final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$sec';
}

String _durationUnit(Duration d) {
  return d.inMinutes == 0 ? 'SEC' : 'MIN';
}

String _formatMetaDate(DateTime dt) {
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return 'REV. $mm.$dd.$yy · $hh:$mi';
}
