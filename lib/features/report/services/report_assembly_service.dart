import '../../../domain/models.dart';
import '../data/mobility_drills.dart';

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
// ReportAssemblyService
// ---------------------------------------------------------------------------

class ReportAssemblyService {
  ReportAssemblyService._();

  static Report buildReport(Assessment assessment) {
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
        if (originJoint != null) {
          final originComp = comps
              .where((c) => c.joint.contains(originJoint))
              .firstOrNull;
          if (originComp != null) {
            upstreamDriver =
                '${originComp.joint} ${_readableCompType(originComp.type)}';
          }
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

      final drills = _selectDrills(comps, _hasHypermobilityIndicators(comps));

      findings.add(Finding(
        bodyPathDescription: bodyPath,
        compensations: comps,
        upstreamDriver: upstreamDriver,
        recommendation: recommendation,
        citations: citationSet.values.toList(),
        drills: drills,
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

  static ConfidenceLevel overallConfidence(List<Finding> findings) {
    var worst = ConfidenceLevel.high;
    for (final f in findings) {
      for (final c in f.compensations) {
        if (c.confidence.index > worst.index) worst = c.confidence;
      }
    }
    return worst;
  }

  static bool _hasHypermobilityIndicators(List<Compensation> comps) {
    // Low valgus value with high ROM suggests hypermobility.
    final valgusComps =
        comps.where((c) => c.type == CompensationType.kneeValgus);
    if (valgusComps.isEmpty) return false;
    return valgusComps
        .any((c) => c.value < 5.0 && c.chain == null);
  }

  static List<MobilityDrill> _selectDrills(
    List<Compensation> comps,
    bool isHypermobile,
  ) {
    if (isHypermobile) {
      return stabilityDrills.take(2).toList();
    }

    // Collect candidate drills from each compensation type present.
    // Prioritize ankle-specific drills when ankle restriction is involved.
    final hasAnkle =
        comps.any((c) => c.type == CompensationType.ankleRestriction);
    final primaryType = comps.first.type;

    if (hasAnkle) {
      final ankleDrills =
          mobilityDrillsByType[CompensationType.ankleRestriction];
      if (ankleDrills != null && ankleDrills.length >= 2) {
        return ankleDrills.take(2).toList();
      }
    }

    final drills = mobilityDrillsByType[primaryType];
    if (drills != null && drills.isNotEmpty) {
      return drills.take(2).toList();
    }

    return const [];
  }

  static String _readableCompType(CompensationType type) {
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
}
