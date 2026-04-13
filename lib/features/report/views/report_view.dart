import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../history/services/archetype_classifier.dart';
import '../../history/services/trend_detection_service.dart';
import '../services/pdf_generator.dart';
import '../services/report_assembly_service.dart';
import '../widgets/body_map.dart';
import '../widgets/finding_card.dart';

// ---------------------------------------------------------------------------
// Archetype descriptions — user-facing, no chain names
// ---------------------------------------------------------------------------

const _archetypeDisplayNames = <MobilityArchetype, String>{
  MobilityArchetype.ankleDominant: 'Ankle-Dominant',
  MobilityArchetype.hipDominant: 'Hip-Dominant',
  MobilityArchetype.trunkDominant: 'Trunk-Dominant',
  MobilityArchetype.hypermobile: 'Hypermobile',
  MobilityArchetype.balanced: 'Balanced',
};

const _archetypePreferredType = <MobilityArchetype, CompensationType>{
  MobilityArchetype.ankleDominant: CompensationType.ankleRestriction,
  MobilityArchetype.hipDominant: CompensationType.hipDrop,
  MobilityArchetype.trunkDominant: CompensationType.trunkLean,
};

// ---------------------------------------------------------------------------
// ReportView
// ---------------------------------------------------------------------------

class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key, required this.id, this.localOnly = false});

  final String id;
  final bool localOnly;

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  String? _cachedPdfPath;
  bool _generating = false;
  Assessment? _assessment;
  Report? _remoteReport;
  bool _didLoad = false;
  bool _loading = false;
  bool _polling = false;
  int? _selectedFindingIndex;

  TrendReport? _trendReport;
  MobilityArchetype? _archetype;

  Timer? _pollingTimer;
  final _scrollController = ScrollController();
  final _findingKeys = <int, GlobalKey>{};

  // -- PDF / Share --

  Future<String> _generatePdf(Report report, Assessment assessment) async {
    if (_cachedPdfPath != null) return _cachedPdfPath!;

    final bytes = await PdfGenerator.generate(
      report,
      assessmentId: assessment.id,
      date: assessment.createdAt,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bioliminal_report_${assessment.id}.pdf');
    await file.writeAsBytes(bytes);
    _cachedPdfPath = file.path;
    return file.path;
  }

  Future<void> _onShare(Report report, Assessment assessment) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final path = await _generatePdf(report, assessment);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], subject: 'Bioliminal Movement Screen'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // -- Lifecycle --

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;

    final extra = GoRouterState.of(context).extra as Assessment?;
    if (extra != null) {
      _assessment = extra;
      _loadLongitudinalContext();
      if (extra.report == null && !widget.localOnly) _startPolling();
      return;
    }

    setState(() => _loading = true);
    ref.read(localStorageServiceProvider).loadAssessment(widget.id).then((
      loaded,
    ) {
      if (!mounted) return;
      setState(() {
        _assessment = loaded;
        _loading = false;
      });
      if (loaded != null) {
        _loadLongitudinalContext();
        if (loaded.report == null && !widget.localOnly) _startPolling();
      }
    });
  }

  void _startPolling() {
    if (_polling) return;
    setState(() => _polling = true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final client = ref.read(bioliminalClientProvider);
      try {
        final report = await client.fetchReport(widget.id);
        if (report != null && mounted) {
          timer.cancel();
          setState(() {
            _remoteReport = report;
            _polling = false;
          });
          // Save the fetched report locally
          if (_assessment != null) {
            final updated = Assessment(
              id: _assessment!.id,
              createdAt: _assessment!.createdAt,
              movements: _assessment!.movements,
              compensations: _assessment!.compensations,
              payload: _assessment!.payload,
              report: report,
            );
            ref.read(localStorageServiceProvider).saveAssessment(updated);
          }
        }
      } catch (_) {
        // Retry on next tick
      }
    });
  }

  Future<void> _loadLongitudinalContext() async {
    final allAssessments = await ref
        .read(localStorageServiceProvider)
        .listAssessments();

    if (!mounted || allAssessments.length <= 1) return;

    final trendReport = TrendDetectionService.analyzeTrends(allAssessments);
    final archetype = ArchetypeClassifier.classify(allAssessments);

    setState(() {
      _trendReport = trendReport;
      _archetype = archetype;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // -- Body map interaction --

  void _onRegionTap(int findingIndex) {
    setState(() {
      _selectedFindingIndex = findingIndex;
    });
    _scrollToFinding(findingIndex);
  }

  void _scrollToFinding(int index) {
    final key = _findingKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final assessment = _assessment;
    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Center(child: Text('Assessment not found')),
      );
    }

    final report = _remoteReport ?? assessment.report;

    // Processing state: no local report and still polling
    if (report == null && _polling) {
      return Scaffold(
        backgroundColor: BioliminalTheme.screenBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
              Text(
                'CLINICAL ANALYSIS IN PROGRESS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Our servers are calculating joint moments and muscle forces. This usually takes 10-15 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback: build a local report if server fails or for prototype fallback
    final activeReport = report ??
        ReportAssemblyService.buildReport(
          assessment,
          trendReport: _trendReport,
          archetype: _archetype,
        );

    // Empty state: no findings detected.
    if (activeReport.findings.isEmpty) {
      return Scaffold(
        backgroundColor: BioliminalTheme.screenBackground,
        appBar: AppBar(
          title: const Text('ANALYSIS'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No significant movement patterns detected. Your movement looks good!',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Ensure we have GlobalKeys for each finding.
    for (var i = 0; i < activeReport.findings.length; i++) {
      _findingKeys.putIfAbsent(i, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('ANALYSIS'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: _generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            onPressed:
                _generating ? null : () => _onShare(activeReport, assessment),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header / Archetype --
            if (_archetype != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_search,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _archetypeDisplayNames[_archetype]!.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Movement Archetype',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // -- Body Map (Primary Visual) --
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BioliminalTheme.glassEffect,
                child: BodyMap(
                  findings: activeReport.findings,
                  selectedFindingIndex: _selectedFindingIndex,
                  onRegionTap: _onRegionTap,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // -- Findings Label --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KEY FINDINGS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 2.0,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${activeReport.findings.length} DETECTED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -- Horizontal Findings Carousel --
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: activeReport.findings.length,
                itemBuilder: (context, i) {
                  final finding = activeReport.findings[i];
                  final isSelected = _selectedFindingIndex == i;
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: FindingCard(
                      finding: finding,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedFindingIndex = i),
                      archetypePreferredType:
                          _archetype != null
                              ? _archetypePreferredType[_archetype!]
                              : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // -- Practitioner Points --
            if (activeReport.practitionerPoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOVEMENT INSIGHTS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...activeReport.practitionerPoints.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      () => _onShare(activeReport, assessment),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('EXPORT CLINICAL PDF'),
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
