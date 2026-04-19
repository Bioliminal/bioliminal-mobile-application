import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';

final _sessionRecordsProvider = FutureProvider.autoDispose<List<SessionRecord>>(
  (ref) {
    return ref.read(localStorageServiceProvider).listSessionRecords();
  },
);

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(_sessionRecordsProvider);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            Expanded(
              child: asyncRecords.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load history: $e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (records) => records.isEmpty
                    ? const _EmptyState()
                    : _SessionList(records: records),
              ),
            ),
            const _NewScanBar(),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SESSIONS', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 12),
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
    final theme = Theme.of(context);
    final state = ref.watch(hardwareControllerProvider);

    final Color color;
    final String label;
    final String? action;

    switch (state) {
      case HardwareConnectionState.connected:
        color = theme.colorScheme.secondary;
        label = 'CONNECTED';
        action = null;
      case HardwareConnectionState.scanning:
      case HardwareConnectionState.connecting:
        color = Colors.orange;
        label = 'SEARCHING';
        action = null;
      case HardwareConnectionState.disconnected:
        color = Colors.white.withValues(alpha: 0.3);
        label = 'OFFLINE';
        action = 'TAP TO PAIR';
    }

    return InkWell(
      onTap: state == HardwareConnectionState.disconnected
          ? () => ref.read(hardwareControllerProvider.notifier).startScan()
          : null,
      borderRadius: BorderRadius.circular(4),
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
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[
              Text(
                '  ·  ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Text(
                action,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 80, color: theme.colorScheme.secondary),
          const SizedBox(height: 48),
          Text(
            'No sessions\nyet',
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Complete your first capture to see your analysis here.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.records});
  final List<SessionRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _SessionCard(record: records[i]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.record});
  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBicepCurl = record.movement == 'bicep_curl';
    final report = record.report;
    final bicepCurl = record.bicepCurl;

    final _CardStatus status;
    final String summary;
    final String tapDestination;

    if (isBicepCurl && bicepCurl != null) {
      final reps = (bicepCurl['reps'] as List?)?.length ?? 0;
      final cueCount = (bicepCurl['cue_events'] as List?)?.length ?? 0;
      final bleDropped = bicepCurl['ble_dropped_during_set'] as bool? ?? false;
      status = _CardStatus(
        label: '$reps REPS',
        color: theme.colorScheme.secondary,
      );
      summary = bleDropped
          ? '$cueCount cues fired · BLE dropped mid-set'
          : '$cueCount cues fired across the set';
      tapDestination = '/bicep-curl/debrief/${record.sessionId}';
    } else {
      final passed = report?.movementSection.qualityReport.passed;
      status = switch (passed) {
        true => _CardStatus(
          label: 'PASSED',
          color: theme.colorScheme.secondary,
        ),
        false => const _CardStatus(label: 'REJECTED', color: Colors.redAccent),
        null => const _CardStatus(label: 'PENDING', color: Colors.white38),
      };
      summary = report != null
          ? _truncate(report.overallNarrative, 140)
          : 'Waiting for server analysis...';
      tapDestination = '/report/${record.sessionId}';
    }

    return InkWell(
      onTap: () => context.go(tapDestination),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BioliminalTheme.glassEffect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  record.movement.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                status,
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(record.capturedAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 14),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStatus extends StatelessWidget {
  const _CardStatus({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NewScanBar extends StatelessWidget {
  const _NewScanBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => context.go('/sets'),
          child: const Text('NEW SCAN'),
        ),
      ),
    );
  }
}

String _truncate(String text, int max) {
  if (text.length <= max) return text;
  return '${text.substring(0, max).trimRight()}…';
}

String _formatDate(DateTime dt) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hh:$mm';
}
