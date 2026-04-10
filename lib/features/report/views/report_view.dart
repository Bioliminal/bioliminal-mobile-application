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

const _archetypeDescriptions = <MobilityArchetype, String>{
  MobilityArchetype.ankleDominant:
      'Your movement patterns suggest ankle mobility is a key focus area. '
          'The patterns we see in your ankles tend to influence your knees and hips.',
  MobilityArchetype.hipDominant:
      'Your hip and pelvis area shows the most consistent patterns. '
          'Strengthening here could improve your overall movement quality.',
  MobilityArchetype.trunkDominant:
      'Your core and torso balance is the most prominent pattern. '
          'Building stability here supports everything above and below.',
  MobilityArchetype.hypermobile:
      'You show more range of motion than average. '
          'Your focus should be on control and stability rather than flexibility.',
  MobilityArchetype.balanced:
      'Your movement patterns are well-distributed. '
          'No single area dominates \u2014 keep up the balanced approach.',
};

const _archetypeDisplayNames = <MobilityArchetype, String>{
  MobilityArchetype.ankleDominant: 'Ankle-Dominant',
  MobilityArchetype.hipDominant: 'Hip-Dominant',
  MobilityArchetype.trunkDominant: 'Trunk-Dominant',
  MobilityArchetype.hypermobile: 'Hypermobile',
  MobilityArchetype.balanced: 'Balanced',
};

// ---------------------------------------------------------------------------
// Archetype to preferred CompensationType mapping (for drill badge)
// ---------------------------------------------------------------------------

const _archetypePreferredType = <MobilityArchetype, CompensationType>{
  MobilityArchetype.ankleDominant: CompensationType.ankleRestriction,
  MobilityArchetype.hipDominant: CompensationType.hipDrop,
  MobilityArchetype.trunkDominant: CompensationType.trunkLean,
};

// ---------------------------------------------------------------------------
// ReportView
// ---------------------------------------------------------------------------

class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  String? _cachedPdfPath;
  bool _generating = false;
  Assessment? _assessment;
  bool _didLoad = false;
  bool _loading = false;
  int? _selectedFindingIndex;

  TrendReport? _trendReport;
  MobilityArchetype? _archetype;

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
    final file = File('${dir.path}/auralink_report_${assessment.id}.pdf');
    await file.writeAsBytes(bytes);
    _cachedPdfPath = file.path;
    return file.path;
  }

  Future<void> _onExportPdf(Report report, Assessment assessment) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      await _generatePdf(report, assessment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved to temp directory')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _onShare(Report report, Assessment assessment) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final path = await _generatePdf(report, assessment);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'AuraLink Movement Screen',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
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
      return;
    }

    // Deep-link: no router extra, load from local storage.
    setState(() => _loading = true);
    ref
        .read(localStorageServiceProvider)
        .loadAssessment(widget.id)
        .then((loaded) {
      if (!mounted) return;
      setState(() {
        _assessment = loaded;
        _loading = false;
      });
      if (loaded != null) {
        _loadLongitudinalContext();
      }
    });
  }

  Future<void> _loadLongitudinalContext() async {
    final allAssessments =
        await ref.read(localStorageServiceProvider).listAssessments();

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
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final assessment = _assessment;
    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Center(child: Text('Assessment not found')),
      );
    }

    // Empty state: no compensations.
    if (assessment.compensations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Report')),
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

    final report = ReportAssemblyService.buildReport(
      assessment,
      trendReport: _trendReport,
      archetype: _archetype,
    );
    final overall = ReportAssemblyService.overallConfidence(report.findings);

    // Ensure we have GlobalKeys for each finding.
    for (var i = 0; i < report.findings.length; i++) {
      _findingKeys.putIfAbsent(i, () => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Report'),
        actions: [
          IconButton(
            icon: _generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed:
                _generating ? null : () => _onExportPdf(report, assessment),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed:
                _generating ? null : () => _onShare(report, assessment),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Body map --
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: BodyMap(
                findings: report.findings,
                selectedFindingIndex: _selectedFindingIndex,
                onRegionTap: _onRegionTap,
              ),
            ),

            // -- Legend --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _LegendDot(
                    color: const Color(0xFF00897B),
                    label: 'Upstream driver',
                  ),
                  const SizedBox(width: 16),
                  _LegendDot(
                    color: const Color(0xFFFF9800),
                    label: 'Symptom',
                  ),
                ],
              ),
            ),

            // -- Summary card --
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We found ${report.findings.length} movement '
                        'pattern${report.findings.length == 1 ? '' : 's'} '
                        'worth discussing with a practitioner.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Overall confidence: ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _confidenceFlutterColor(overall),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _confidenceText(overall),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overall == ConfidenceLevel.low
                            ? 'Some findings had lower tracking confidence -- marked below.'
                            : 'Tracking quality was high throughout.',
                        style: theme.textTheme.bodySmall,
                      ),
                      // -- Movement Profile Section --
                      if (_archetype != null)
                        _MovementProfileSection(archetype: _archetype!),
                    ],
                  ),
                ),
              ),
            ),

            // -- Findings header --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your Findings',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 4),

            // -- Finding cards --
            ...List.generate(report.findings.length, (i) {
              final finding = report.findings[i];
              final point = finding.upstreamDriver != null
                  ? report.practitionerPoints
                        .where((p) => p.contains(finding.upstreamDriver!))
                        .firstOrNull
                  : null;
              return Container(
                key: _findingKeys[i],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (finding.trendStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 4),
                        child: _TrendBadge(trend: finding.trendStatus!),
                      ),
                    FindingCard(
                      finding: finding,
                      practitionerPoint:
                          point?.replaceFirst('Ask about ', ''),
                      selected: _selectedFindingIndex == i,
                      onTap: () => _onRegionTap(i),
                      archetypePreferredType: _archetype != null
                          ? _archetypePreferredType[_archetype!]
                          : null,
                    ),
                  ],
                ),
              );
            }),

            // -- Practitioner Discussion Points --
            if (report.practitionerPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Practitioner Discussion Points',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...report.practitionerPoints.map(
                (point) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\u2022  '),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _confidenceFlutterColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return AuraLinkTheme.confidenceHigh;
      case ConfidenceLevel.medium:
        return AuraLinkTheme.confidenceMedium;
      case ConfidenceLevel.low:
        return AuraLinkTheme.confidenceLow;
    }
  }

  String _confidenceText(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }
}

// ---------------------------------------------------------------------------
// Movement Profile Section
// ---------------------------------------------------------------------------

class _MovementProfileSection extends StatelessWidget {
  const _MovementProfileSection({required this.archetype});

  final MobilityArchetype archetype;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Movement Profile',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _archetypeDisplayNames[archetype] ?? archetype.name,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _archetypeDescriptions[archetype] ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend Badge
// ---------------------------------------------------------------------------

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend});

  final TrendClassification trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _trendColor(trend),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _trendLabel(trend),
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Color _trendColor(TrendClassification trend) {
    switch (trend) {
      case TrendClassification.improving:
        return Colors.green;
      case TrendClassification.worsening:
        return AuraLinkTheme.confidenceLow;
      case TrendClassification.stable:
        return Colors.grey;
      case TrendClassification.newPattern:
        return Colors.blue;
    }
  }

  static String _trendLabel(TrendClassification trend) {
    switch (trend) {
      case TrendClassification.improving:
        return 'Improving';
      case TrendClassification.worsening:
        return 'Worsening';
      case TrendClassification.stable:
        return 'Stable';
      case TrendClassification.newPattern:
        return 'New Pattern';
    }
  }
}

// ---------------------------------------------------------------------------
// Legend dot
// ---------------------------------------------------------------------------

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
