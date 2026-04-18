import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';

/// Displays the analysis server's report for a single captured session.
///
/// The route is `/report/{session_id}`. The view loads any locally-stored
/// SessionRecord, then polls the server every 3 seconds for the report until
/// it arrives. All rendered content comes from the server — there is no
/// local fallback.
class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  SessionRecord? _record;
  bool _loadingLocal = true;
  bool _fetching = false;
  String? _fetchError;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final storage = ref.read(localStorageServiceProvider);
    final record = await storage.loadSessionRecord(widget.id);
    if (!mounted) return;
    setState(() {
      _record = record;
      _loadingLocal = false;
    });
    if (record?.report == null) _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _fetchOnce();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchOnce(),
    );
  }

  Future<void> _fetchOnce() async {
    if (_fetching) return;
    _fetching = true;

    try {
      final report = await ref
          .read(bioliminalClientProvider)
          .fetchReport(widget.id);
      if (!mounted) return;

      if (report != null) {
        _pollingTimer?.cancel();

        final updated = (_record ?? _bootstrapRecord()).copyWith(report: report);
        await ref.read(localStorageServiceProvider).saveSessionRecord(updated);

        if (!mounted) return;
        setState(() {
          _record = updated;
          _fetchError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = e.toString());
    } finally {
      _fetching = false;
    }
  }

  /// Fallback when the user navigates to /report/{id} without a prior local
  /// record (e.g. deep link). We stamp a minimal record so persistence still
  /// has something to update once the server responds.
  SessionRecord _bootstrapRecord() => SessionRecord(
    sessionId: widget.id,
    movement: 'unknown',
    capturedAt: DateTime.now().toUtc(),
  );

  @override
  Widget build(BuildContext context) {
    if (_loadingLocal) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final record = _record;
    final report = record?.report;

    if (report == null) {
      return _ProcessingView(
        sessionId: widget.id,
        error: _fetchError,
        onRetry: _startPolling,
      );
    }

    return _ReportContent(record: record!, report: report);
  }
}

// ---------------------------------------------------------------------------
// Processing state
// ---------------------------------------------------------------------------

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({
    required this.sessionId,
    required this.error,
    required this.onRetry,
  });

  final String sessionId;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('ANALYSIS'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
              Text(
                'ANALYZING YOUR SESSION',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The server is computing joint angles, rep metrics, and '
                'movement chain observations. This usually takes 10–15 '
                'seconds.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'session: ${_shortId(sessionId)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Last fetch failed: $error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('RETRY'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main report content
// ---------------------------------------------------------------------------

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.record, required this.report});

  final SessionRecord record;
  final ServerReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quality = report.movementSection.qualityReport;

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('ANALYSIS'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(record: record, movement: report.metadata.movement),
            const SizedBox(height: 32),
            _QualityBanner(quality: quality),
            const SizedBox(height: 24),
            if (quality.passed) ...[
              _NarrativeSection(narrative: report.overallNarrative),
              if (report.movementSection.chainObservations.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'CHAIN OBSERVATIONS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                ...report.movementSection.chainObservations.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChainObservationCard(observation: o),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.record, required this.movement});

  final SessionRecord record;
  final String movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movement.replaceAll('_', ' ').toUpperCase(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatDate(record.capturedAt.toLocal())} · ${_shortId(record.sessionId)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white38,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _QualityBanner extends StatelessWidget {
  const _QualityBanner({required this.quality});

  final SessionQualityReport quality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = quality.passed;
    final color = passed ? theme.colorScheme.secondary : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.error,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                passed ? 'SESSION QUALITY: PASSED' : 'SESSION QUALITY: REJECTED',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          if (quality.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...quality.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '· ${issue.code}: ${issue.detail}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NarrativeSection extends StatelessWidget {
  const _NarrativeSection({required this.narrative});

  final String narrative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUMMARY',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white70,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            narrative,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChainObservationCard extends StatelessWidget {
  const _ChainObservationCard({required this.observation});

  final ChainObservation observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = switch (observation.severity) {
      ObservationSeverity.info => theme.colorScheme.secondary,
      ObservationSeverity.concern => Colors.orange,
      ObservationSeverity.flag => Colors.redAccent,
    };
    final chainLabel = observation.chain.wire
        .replaceAll('_', ' ')
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                chainLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: severityColor,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${observation.severity.name.toUpperCase()} · '
                '${(observation.confidence * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            observation.narrative,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          if (observation.involvedJoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'joints: ${observation.involvedJoints.join(", ")}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _shortId(String sessionId) {
  if (sessionId.length <= 8) return sessionId;
  return sessionId.substring(0, 8);
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
