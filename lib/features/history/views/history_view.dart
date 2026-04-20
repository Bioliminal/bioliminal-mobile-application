import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../../core/widgets/mobile_action_button.dart';
import '../../landing/widgets/marketing_tokens.dart';
import '../../landing/widgets/premium_atmosphere.dart';
import '../../../domain/models.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(sessionRecordsProvider);

    return Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AtmosphereGlow(
                color: SectionTint.cyan,
                center: Alignment(-0.9, -0.85),
                peak: 0.06,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PageHeader(),
                const _Hairline(),
                Expanded(
                  child: asyncRecords.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load sessions: $e',
                          style: mktBody(14, color: MarketingPalette.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (records) => records.isEmpty
                        ? const _EmptyState()
                        : _SessionList(records: records),
                  ),
                ),
                const _Hairline(),
                const _NewScanBar(),
              ],
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

// ---------------------------------------------------------------------------
// Header — meta row + Fraunces headline + hardware status strip
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessions',
            style: mktDisplay(
              36,
              weight: FontWeight.w500,
              letterSpacing: -1.4,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 14),
          const _HardwareStatusRow(),
        ],
      ),
    );
  }
}

class _HardwareStatusRow extends ConsumerWidget {
  const _HardwareStatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hardwareControllerProvider);

    final Color color;
    final String label;
    final String? action;

    switch (state) {
      case HardwareConnectionState.connected:
        color = MarketingPalette.signal;
        label = 'GARMENT LINK · CONNECTED';
        action = null;
      case HardwareConnectionState.scanning:
      case HardwareConnectionState.connecting:
        color = MarketingPalette.warn;
        label = 'GARMENT LINK · SEARCHING';
        action = null;
      case HardwareConnectionState.disconnected:
        color = MarketingPalette.subtle;
        label = 'GARMENT LINK · OFFLINE';
        action = 'TAP TO PAIR';
    }

    final offline = state == HardwareConnectionState.disconnected;

    return InkWell(
      onTap: offline
          ? () => ref.read(hardwareControllerProvider.notifier).startScan()
          : null,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: mktMono(
                10,
                color: color,
                letterSpacing: 2.2,
                weight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 10,
                  height: 1,
                  color: MarketingPalette.hairline,
                ),
              ),
              Text(
                action,
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 2.4,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// AWAITING FIRST CAPTURE',
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No sessions\nyet.',
            style: mktDisplay(
              40,
              weight: FontWeight.w500,
              letterSpacing: -1.6,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Every session you capture lands here — peak envelope, cue '
              'history, form trajectory. Complete your first set to open '
              'this view.',
              style: mktBody(
                15,
                color: MarketingPalette.muted,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Container(
                width: 18,
                height: 1,
                color: MarketingPalette.signal,
              ),
              const SizedBox(width: 10),
              Text(
                'TAP NEW SCAN TO BEGIN',
                style: mktMono(
                  10,
                  color: MarketingPalette.muted,
                  letterSpacing: 2.4,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session list
// ---------------------------------------------------------------------------

class _SessionList extends StatelessWidget {
  const _SessionList({required this.records});
  final List<SessionRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: records.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _Hairline(),
      ),
      itemBuilder: (context, i) => _SessionRow(record: records[i]),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.record});
  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final isBicepCurl = record.movement == 'bicep_curl';
    final report = record.report;
    final bicepCurl = record.bicepCurl;

    final String statusLabel;
    final Color statusColor;
    final String tapDestination;

    if (isBicepCurl && bicepCurl != null) {
      final reps = (bicepCurl['reps'] as List?)?.length ?? 0;
      statusLabel = '$reps REPS';
      statusColor = MarketingPalette.signal;
      tapDestination = '/bicep-curl/debrief/${record.sessionId}';
    } else {
      final passed = report?.movementSection.qualityReport.passed;
      (statusLabel, statusColor) = switch (passed) {
        true => ('PASSED', MarketingPalette.signal),
        false => ('REJECTED', MarketingPalette.error),
        null => ('PENDING', MarketingPalette.subtle),
      };
      tapDestination = '/report/${record.sessionId}';
    }

    return InkWell(
      onTap: () => context.push(tapDestination),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _movementTitle(record.movement),
                    style: mktDisplay(
                      22,
                      weight: FontWeight.w500,
                      letterSpacing: -0.6,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatDate(record.capturedAt.toLocal()),
                        style: mktMono(
                          10,
                          color: MarketingPalette.muted,
                          letterSpacing: 1.8,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '   ·   ',
                        style: mktMono(
                          10,
                          color: MarketingPalette.subtle,
                          letterSpacing: 1.8,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: mktMono(
                          10,
                          color: statusColor,
                          letterSpacing: 2.0,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: MarketingPalette.subtle,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New scan bar
// ---------------------------------------------------------------------------

class _NewScanBar extends StatelessWidget {
  const _NewScanBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: MobileActionButton(
              label: 'NEW SCAN',
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
// Shared primitives
// ---------------------------------------------------------------------------

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: MarketingPalette.hairline);
  }
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

String _movementTitle(String wire) {
  switch (wire) {
    case 'bicep_curl':
      return 'Bicep curl';
    case 'overhead_squat':
      return 'Overhead squat';
    case 'single_leg_squat':
      return 'Single-leg squat';
    case 'push_up':
      return 'Push-up';
    case 'rollup':
      return 'Rollup';
  }
  final words = wire.replaceAll('_', ' ').split(' ');
  if (words.isEmpty) return wire;
  final first = words.first;
  final head = first.isEmpty
      ? first
      : '${first[0].toUpperCase()}${first.substring(1)}';
  final rest = words.skip(1).join(' ');
  return rest.isEmpty ? head : '$head $rest';
}

String _formatDate(DateTime dt) {
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')} '
      '${dt.year}  ·  $hh:$mm';
}
