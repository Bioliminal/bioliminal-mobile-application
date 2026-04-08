import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../services/pdf_generator.dart';
import '../widgets/finding_card.dart';

// ---------------------------------------------------------------------------
// Body-path language — NEVER expose chain names to users
// ---------------------------------------------------------------------------

const _bodyPathDescriptions = <ChainType, String>{
  ChainType.sbl:
      'Your ankle, knee, and hip compensate together along your back body',
  ChainType.bfl:
      'Your shoulder and opposite hip are connected through your back',
  ChainType.ffl:
      'Your front body -- ankle, knee, hip -- compensates as a unit',
};

const _standaloneDescription = 'An isolated finding at';

// ---------------------------------------------------------------------------
// Static citation map keyed by CompensationType
// ---------------------------------------------------------------------------

const _citationsByType = <CompensationType, List<Citation>>{
  CompensationType.kneeValgus: [
    Citation(
      finding: 'Knee valgus >10 deg correlates with 2.5x ACL injury risk',
      source: 'Hewett et al. (2005)',
      url: 'https://pubmed.ncbi.nlm.nih.gov/15722287/',
      type: CitationType.research,
      appUsage: 'Primary threshold for knee valgus detection',
    ),
  ],
  CompensationType.hipDrop: [
    Citation(
      finding:
          'Hip strengthening resolves knee pain faster than knee-only treatment (n=199)',
      source: 'Ferber et al.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/25102167/',
      type: CitationType.research,
      appUsage: 'Evidence for upstream driver logic',
    ),
  ],
  CompensationType.ankleRestriction: [
    Citation(
      finding: 'SBL: 3/3 transitions verified across 14 cadaveric studies',
      source: 'Wilke et al. (2016)',
      url: 'https://pubmed.ncbi.nlm.nih.gov/26281953/',
      type: CitationType.research,
      appUsage: 'Foundation for chain selection',
    ),
  ],
  CompensationType.trunkLean: [
    Citation(
      finding:
          'RESTORE trial (n=492): sustained 3-year improvement with upstream treatment',
      source: 'Lancet via PubMed',
      url: 'https://pubmed.ncbi.nlm.nih.gov/37060913/',
      type: CitationType.research,
      appUsage: 'Long-term evidence for upstream reasoning',
    ),
  ],
};

const _chainCitation = Citation(
  finding:
      'Stecco Fascial Manipulation: chain-reasoning treatment resolved pain in 1 session vs 3 for local-only',
  source: 'Gnat 2022 RCT',
  url: 'https://www.mdpi.com/2075-1729/12/2/222',
  type: CitationType.research,
  appUsage: 'Direct evidence for the compensation-chain reasoning used here',
);

const _bahrCitation = Citation(
  finding:
      'Screening scores do not reliably predict injury; this tool identifies patterns, not predictions',
  source: 'Bahr (2016) BJSM',
  url: 'https://bjsm.bmj.com/content/50/13/776',
  type: CitationType.guideline,
  appUsage: 'Educational framing for all findings in this report',
);

// ---------------------------------------------------------------------------
// Upstream driver anatomical origins per chain
// ---------------------------------------------------------------------------

const _chainOriginJoint = <ChainType, String>{
  ChainType.sbl: 'ankle',
  ChainType.ffl: 'ankle',
  ChainType.bfl: 'shoulder',
};

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

  // -- Report assembly --

  Report _buildReport(Assessment assessment) {
    // 1. Cap ankle-dependent confidence to medium.
    final compensations = assessment.compensations.map((c) {
      if (c.type == CompensationType.ankleRestriction &&
          c.confidence == ConfidenceLevel.high) {
        return Compensation(
          type: c.type,
          joint: c.joint,
          chain: c.chain,
          confidence: ConfidenceLevel.medium,
          value: c.value,
          threshold: c.threshold,
          citation: c.citation,
        );
      }
      return c;
    }).toList();

    // 2. Group by chain.
    final groups = <ChainType?, List<Compensation>>{};
    for (final c in compensations) {
      groups.putIfAbsent(c.chain, () => []).add(c);
    }

    // 3. Build findings.
    final findings = <Finding>[];
    for (final entry in groups.entries) {
      final chain = entry.key;
      final comps = entry.value;

      final bodyPath = chain != null
          ? _bodyPathDescriptions[chain]!
          : '$_standaloneDescription ${comps.first.joint}';

      // Upstream driver: compensation at anatomical origin of chain.
      String? upstreamDriver;
      if (chain != null) {
        final originJoint = _chainOriginJoint[chain];
        final originComp = comps.cast<Compensation?>().firstWhere(
              (c) => c!.joint.contains(originJoint!),
              orElse: () => null,
            );
        if (originComp != null) {
          upstreamDriver =
              '${originComp.joint} ${_readableCompType(originComp.type)}';
        }
      }

      // Recommendation logic.
      final hasAnkleRestriction =
          comps.any((c) => c.type == CompensationType.ankleRestriction);
      final isRestrictionChain =
          chain == ChainType.sbl || chain == ChainType.ffl;

      String recommendation;
      if (hasAnkleRestriction && isRestrictionChain) {
        recommendation = 'Prioritize ankle and hip mobility work';
      } else if (_hasHypermobilityIndicators(comps)) {
        recommendation =
            'Focus on neuromuscular control and stability training';
      } else {
        recommendation =
            'Discuss this pattern with a movement professional';
      }

      // Citations: gather from compensation types + chain-level + universal.
      final citationSet = <String, Citation>{};
      for (final c in comps) {
        final typeCitations = _citationsByType[c.type];
        if (typeCitations != null) {
          for (final tc in typeCitations) {
            citationSet[tc.url] = tc;
          }
        }
      }
      if (chain != null) {
        citationSet[_chainCitation.url] = _chainCitation;
      }
      citationSet[_bahrCitation.url] = _bahrCitation;

      findings.add(Finding(
        bodyPathDescription: bodyPath,
        compensations: comps,
        upstreamDriver: upstreamDriver,
        recommendation: recommendation,
        citations: citationSet.values.toList(),
      ));
    }

    // 4. Practitioner discussion points — keyed per finding.
    final practitionerPointsByFinding = <int, String>{};
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      if (f.upstreamDriver != null) {
        final symptomJoints = f.compensations
            .where((c) =>
                !c.joint.contains(_chainOriginJoint[f.compensations.first.chain] ?? ''))
            .map((c) => c.joint)
            .toSet();
        if (symptomJoints.isNotEmpty) {
          practitionerPointsByFinding[i] =
            'Ask about ${f.upstreamDriver} and how it affects ${symptomJoints.join(', ')}';
        } else {
          practitionerPointsByFinding[i] =
              'Ask about ${f.upstreamDriver} as a possible driver';
        }
      }
    }

    return Report(
      findings: findings,
      practitionerPoints: practitionerPointsByFinding.values.toList(),
    );
  }

  bool _hasHypermobilityIndicators(List<Compensation> comps) {
    // Low valgus value with high ROM suggests hypermobility.
    final valgusComps =
        comps.where((c) => c.type == CompensationType.kneeValgus);
    if (valgusComps.isEmpty) return false;
    return valgusComps
        .any((c) => c.value < 5.0 && c.chain == null);
  }

  String _readableCompType(CompensationType type) {
    switch (type) {
      case CompensationType.kneeValgus:
        return 'knee valgus';
      case CompensationType.hipDrop:
        return 'hip drop';
      case CompensationType.ankleRestriction:
        return 'ankle restriction';
      case CompensationType.trunkLean:
        return 'trunk lean';
    }
  }

  ConfidenceLevel _overallConfidence(List<Finding> findings) {
    var worst = ConfidenceLevel.high;
    for (final f in findings) {
      for (final c in f.compensations) {
        if (c.confidence.index > worst.index) worst = c.confidence;
      }
    }
    return worst;
  }

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

    final report = _buildReport(assessment);
    final overall = _overallConfidence(report.findings);

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
                  ? report.practitionerPoints.cast<String?>().firstWhere(
                        (p) => p != null && p.contains(finding.upstreamDriver!),
                        orElse: () => null,
                      )
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
