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

  static Report buildReport(
    Assessment assessment, {
    TrendReport? trendReport,
    MobilityArchetype? archetype,
  }) {
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

      // Trend lookup — inside the loop so trendStatus and evolved
      // recommendation are set during Finding construction.
      final trendClass = _lookupTrend(comps, trendReport);

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

      // Evolve recommendation based on trend.
      recommendation = _evolveRecommendation(recommendation, trendClass);

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

      final drills = _selectDrills(
        comps,
        _hasHypermobilityIndicators(comps),
        archetype: archetype,
      );

      findings.add(Finding(
        bodyPathDescription: bodyPath,
        compensations: comps,
        upstreamDriver: upstreamDriver,
        recommendation: recommendation,
        citations: citationSet.values.toList(),
        drills: drills,
        trendStatus: trendClass,
      ));
    }

    // 4. Sort findings by priority (stable sort).
    if (trendReport != null) {
      final indexed = List.generate(findings.length, (i) => i);
      indexed.sort((a, b) {
        final sa = _priorityScore(
          findings[a].trendStatus,
          _lookupCompensationTrend(findings[a].compensations, trendReport),
        );
        final sb = _priorityScore(
          findings[b].trendStatus,
          _lookupCompensationTrend(findings[b].compensations, trendReport),
        );
        final cmp = sb.compareTo(sa); // descending
        return cmp != 0 ? cmp : a.compareTo(b); // preserve original order
      });
      final sorted = [for (final i in indexed) findings[i]];
      findings
        ..clear()
        ..addAll(sorted);
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

  // -------------------------------------------------------------------------
  // Trend helpers
  // -------------------------------------------------------------------------

  /// Look up the dominant compensation's trend classification.
  /// Returns null when trendReport is null or no match found.
  static TrendClassification? _lookupTrend(
    List<Compensation> comps,
    TrendReport? trendReport,
  ) {
    if (trendReport == null || comps.isEmpty) return null;
    final dominant = comps.first;
    final ct = trendReport.trendFor(dominant.type, dominant.joint);
    return ct?.trend;
  }

  /// Look up the full CompensationTrend for a finding's dominant compensation.
  static CompensationTrend? _lookupCompensationTrend(
    List<Compensation> comps,
    TrendReport? trendReport,
  ) {
    if (trendReport == null || comps.isEmpty) return null;
    final dominant = comps.first;
    return trendReport.trendFor(dominant.type, dominant.joint);
  }

  /// Map a TrendClassification + CompensationTrend to a numeric priority.
  /// recurring (stable + 3+ data points) = 4, worsening = 3,
  /// newPattern = 2, stable = 1, null = 0.
  static int _priorityScore(TrendClassification? trend, CompensationTrend? ct) {
    if (trend == null) return 0;
    switch (trend) {
      case TrendClassification.stable:
        if (ct != null && ct.values.length >= 3) return 4; // recurring
        return 1;
      case TrendClassification.worsening:
        return 3;
      case TrendClassification.newPattern:
        return 2;
      case TrendClassification.improving:
        return 1;
    }
  }

  /// Mutate recommendation text based on trend status.
  static String _evolveRecommendation(String base, TrendClassification? trend) {
    if (trend == null) return base;
    switch (trend) {
      case TrendClassification.improving:
        return '$base \u2014 this pattern is improving, keep up your current work';
      case TrendClassification.worsening:
        return 'Priority: $base \u2014 this pattern has worsened since your last assessment';
      case TrendClassification.newPattern:
        return '$base \u2014 this is a new pattern we haven\'t seen before';
      case TrendClassification.stable:
        return base;
    }
  }

  // -------------------------------------------------------------------------
  // Drill selection
  // -------------------------------------------------------------------------

  static List<MobilityDrill> _selectDrills(
    List<Compensation> comps,
    bool isHypermobile, {
    MobilityArchetype? archetype,
  }) {
    // Hypermobile archetype always gets stability drills.
    if (archetype == MobilityArchetype.hypermobile || isHypermobile) {
      return stabilityDrills.take(2).toList();
    }

    // Archetype-targeted drill boosting.
    if (archetype != null && archetype != MobilityArchetype.balanced) {
      final preferredType = _archetypePreferredType(archetype);
      if (preferredType != null) {
        final preferred = mobilityDrillsByType[preferredType];
        if (preferred != null && preferred.isNotEmpty) {
          final boosted = <MobilityDrill>[preferred.first];
          // Fill remaining slot from compensation-matched drills.
          final primaryType = comps.isNotEmpty ? comps.first.type : null;
          final fallback = primaryType != null
              ? mobilityDrillsByType[primaryType]
              : null;
          if (fallback != null && fallback.isNotEmpty) {
            // Pick a drill that isn't the same as the boosted one.
            final fill = fallback.firstWhere(
              (d) => d.name != boosted.first.name,
              orElse: () => fallback.first,
            );
            boosted.add(fill);
          }
          return boosted;
        }
      }
    }

    // Default logic (balanced / null archetype).
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

  /// Map archetype to its preferred CompensationType for drill boosting.
  static CompensationType? _archetypePreferredType(MobilityArchetype archetype) {
    switch (archetype) {
      case MobilityArchetype.ankleDominant:
        return CompensationType.ankleRestriction;
      case MobilityArchetype.hipDominant:
        return CompensationType.hipDrop;
      case MobilityArchetype.trunkDominant:
        return CompensationType.trunkLean;
      case MobilityArchetype.hypermobile:
      case MobilityArchetype.balanced:
        return null;
    }
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
