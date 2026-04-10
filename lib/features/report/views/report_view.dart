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
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'AuraLink Movement Screen',
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

    // Ensure we have GlobalKeys for each finding.
    for (var i = 0; i < report.findings.length; i++) {
      _findingKeys.putIfAbsent(i, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: AuraLinkTheme.screenBackground,
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
            onPressed: _generating ? null : () => _onShare(report, assessment),
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
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_search, color: theme.colorScheme.secondary),
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
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
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
                decoration: AuraLinkTheme.glassEffect,
                child: BodyMap(
                  findings: report.findings,
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
                    '${report.findings.length} DETECTED',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
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
                itemCount: report.findings.length,
                itemBuilder: (context, i) {
                  final finding = report.findings[i];
                  final isSelected = _selectedFindingIndex == i;
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: FindingCard(
                      finding: finding,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedFindingIndex = i),
                      archetypePreferredType: _archetype != null
                          ? _archetypePreferredType[_archetype!]
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // -- Practitioner Points --
            if (report.practitionerPoints.isNotEmpty)
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
                      ...report.practitionerPoints.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: Colors.white38),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p, style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      )),
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
                  onPressed: () => _onShare(report, assessment),
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
