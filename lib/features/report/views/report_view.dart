import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../services/pdf_generator.dart';
import '../services/report_assembly_service.dart';
import '../widgets/finding_card.dart';

// ---------------------------------------------------------------------------
// ReportView
// ---------------------------------------------------------------------------

class ReportView extends StatefulWidget {
  const ReportView({super.key, required this.id});

  final String id;

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  String? _cachedPdfPath;
  bool _generating = false;

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

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final assessment = GoRouterState.of(context).extra as Assessment?;
    final theme = Theme.of(context);

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

    final report = ReportAssemblyService.buildReport(assessment);
    final overall = ReportAssemblyService.overallConfidence(report.findings);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              // Match practitioner point by upstream driver presence.
              final point = finding.upstreamDriver != null
                  ? report.practitionerPoints
                        .where((p) => p.contains(finding.upstreamDriver!))
                        .firstOrNull
                  : null;
              return FindingCard(
                finding: finding,
                practitionerPoint:
                    point?.replaceFirst('Ask about ', ''),
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
