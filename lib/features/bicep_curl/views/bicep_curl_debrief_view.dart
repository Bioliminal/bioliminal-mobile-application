import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/mobile_action_button.dart';
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
                return _DebriefBody(log: log);
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
  const _DebriefBody({required this.log});

  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    final baseline = log.baselineTrajectory(log.profile.baselineWindow);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(log: log),
        const _Hairline(),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
                  title: 'Compensation patterns.',
                  signal: 'POSE · PER REP',
                  body:
                      'Per-rep shoulder rise and forward lean. Bars colored '
                      'by how far past threshold the deviation went; red '
                      'markers flag reps where a cue fired.',
                  child: BicepCurlFormSection(log: log),
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
                const _InstrumentSection(
                  index: '04',
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
  const _PageHeader({required this.log});
  final SessionLog log;

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
          _BackChevron(onTap: () => _goBack(context)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Debrief',
              style: mktDisplay(
                36,
                weight: FontWeight.w500,
                letterSpacing: -1.4,
                height: 0.95,
              ),
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
            child: MobileActionButton(
              label: 'DONE',
              onTap: () => _goBack(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MobileActionButton(
              label: 'ANOTHER SET',
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

/// Prefer `pop` when the nav stack has something to return to (entered from
/// history list via push). Fall back to a direct `go('/history')` for the
/// replace-semantic entry from the live bicep-curl view — in that case
/// there is no live-view page to return to.
void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/history');
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String _durationValue(Duration d) {
  if (d.inMinutes == 0) return d.inSeconds.toString();
  final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$sec';
}

String _durationUnit(Duration d) {
  return d.inMinutes == 0 ? 'SEC' : 'MIN';
}
