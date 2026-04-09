import '../models.dart';
import '../services/chain_mapper.dart';

/// Rule-based chain mapper using published thresholds from scout data.
/// Applies threshold detection, chain mapping, CC/CP logic, confidence
/// assignment, and citations. Not hardcoded returns -- Person A vs
/// Person B must produce different results.
class RuleBasedChainMapper implements ChainMapper {
  // -- Thresholds from scout data --

  static const double _kneeValgusThreshold = 10.0; // degrees
  static const double _hipDropAsymmetryThreshold = 10.0; // degrees
  static const double _ankleDorsiflexionMin = 10.0; // degrees
  static const double _anklePlantarflexionAsymmetryThreshold = 15.0; // degrees
  static const double _trunkLeanThreshold = 5.0; // degrees
  static const double _kneeERHypermobilityThreshold = 45.0; // degrees
  static const double _kneeValgusHypermobilityCeiling = 5.0; // degrees
  static const double _shoulderAsymmetryThreshold = 8.0; // degrees
  static const double _thoracicRotationMin = 35.0; // degrees
  static const double _plantarflexionDominanceThreshold = 20.0; // degrees
  static const double _hipFlexionStandingThreshold = 30.0; // degrees

  // -- Citations --

  static const _hewettCitation = Citation(
    finding: 'Knee valgus >10 degrees correlates with 2.5x ACL injury risk',
    source: 'Hewett et al. (2005)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/15722287/',
    type: CitationType.research,
    appUsage:
        'Primary threshold for knee valgus detection; establishes clinical meaningfulness above noise floor',
  );

  static const _ferberCitation = Citation(
    finding:
        'Hip strengthening resolves knee pain faster than knee-only treatment (n=199)',
    source: 'Ferber et al.',
    url: 'https://pubmed.ncbi.nlm.nih.gov/25102167/',
    type: CitationType.research,
    appUsage:
        'Evidence for upstream driver logic; validates hip as CC for knee CP',
  );

  static const _wilkeCitation = Citation(
    finding:
        'SBL: 3/3 transitions verified across 14 cadaveric studies; BFL: 3/3 across 8; FFL: 2/2 across 6',
    source: 'Wilke et al. (2016)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/26281953/',
    type: CitationType.research,
    appUsage: 'Foundation for chain selection; only three chains with strong evidence',
  );

  static const _hypermobilityCitation = Citation(
    finding:
        'Hypermobile athletes show 3.5 deg lower minimum knee valgus and 4.5 deg greater peak external rotation',
    source: 'PMC8558993',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8558993/',
    type: CitationType.research,
    appUsage:
        'Critical for threshold adjustment; fixed thresholds misclassify hypermobile individuals',
  );

  static const _ankleRestrictionCitation = Citation(
    finding:
        'Ankle mobility blocks force transmission up kinetic chain; appears with knee valgus and hip drop on SBL',
    source: 'Clinical consensus; MediaPipe ankle r=0.45 with occlusion',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC10886083/',
    type: CitationType.clinical,
    appUsage:
        'Use with caution; surface in findings as lower-confidence',
  );

  @override
  List<Compensation> mapCompensations(List<JointAngle> angles) {
    final angleMap = _buildAngleMap(angles);
    final confidenceMap = _buildConfidenceMap(angles);

    // Check for hypermobility first -- it changes threshold interpretation.
    final isHypermobile = _detectHypermobility(angleMap);

    // Detect individual flags.
    final hasKneeValgus = _detectKneeValgus(angleMap, isHypermobile);
    final hasAnkleRestriction = _detectAnkleRestriction(angleMap);
    final hasHipDrop = _detectHipDrop(angleMap);
    final hasShoulderDepression = _detectShoulderDepression(angleMap);
    final hasThoracicLimitation = _detectThoracicLimitation(angleMap);
    final hasContralateralHipWeakness =
        _detectContralateralHipWeakness(angleMap);
    final hasPlantarflexionDominance =
        _detectPlantarflexionDominance(angleMap);
    final hasKneeExtensionBias = _detectKneeExtensionBias(angleMap);
    final hasHipFlexionDominance = _detectHipFlexionDominance(angleMap);
    final hasTrunkLean = _detectTrunkLean(angleMap);

    final compensations = <Compensation>[];

    // -- Chain mapping: check co-occurring patterns --

    // SBL: ankle restriction + knee valgus + hip drop
    if (hasAnkleRestriction && hasKneeValgus && hasHipDrop) {
      final ankleConf =
          _ankleConfidence(confidenceMap);
      final kneeConf = confidenceMap['knee'] ?? ConfidenceLevel.medium;
      final hipConf = confidenceMap['hip'] ?? ConfidenceLevel.medium;
      final chainConf = _worstConfidence([ankleConf, kneeConf, hipConf]);

      compensations.add(Compensation(
        type: CompensationType.ankleRestriction,
        joint: 'ankle',
        chain: ChainType.sbl,
        confidence: _neverHighForAnkle(ankleConf),
        value: _getAnkleDorsiflexionValue(angleMap),
        threshold: _ankleDorsiflexionMin,
        citation: _ankleRestrictionCitation,
      ));
      compensations.add(Compensation(
        type: CompensationType.kneeValgus,
        joint: 'knee',
        chain: ChainType.sbl,
        confidence: chainConf,
        value: _getKneeValgusValue(angleMap),
        threshold: _kneeValgusThreshold,
        citation: _hewettCitation,
      ));
      compensations.add(Compensation(
        type: CompensationType.hipDrop,
        joint: 'hip',
        chain: ChainType.sbl,
        confidence: chainConf,
        value: _getHipAsymmetryValue(angleMap),
        threshold: _hipDropAsymmetryThreshold,
        citation: _ferberCitation,
      ));
    }
    // BFL: shoulder depression + thoracic limitation + contralateral hip weakness
    else if (hasShoulderDepression &&
        hasThoracicLimitation &&
        hasContralateralHipWeakness) {
      final shoulderConf =
          confidenceMap['shoulder'] ?? ConfidenceLevel.medium;
      final hipConf = confidenceMap['hip'] ?? ConfidenceLevel.medium;
      final chainConf = _worstConfidence([shoulderConf, hipConf]);

      compensations.add(Compensation(
        type: CompensationType.trunkLean,
        joint: 'shoulder',
        chain: ChainType.bfl,
        confidence: chainConf,
        value: _getShoulderAsymmetryValue(angleMap),
        threshold: _shoulderAsymmetryThreshold,
        citation: _wilkeCitation,
      ));
      compensations.add(Compensation(
        type: CompensationType.hipDrop,
        joint: 'contralateral_hip',
        chain: ChainType.bfl,
        confidence: chainConf,
        value: _getHipAsymmetryValue(angleMap),
        threshold: _hipDropAsymmetryThreshold,
        citation: _wilkeCitation,
      ));
    }
    // FFL: plantarflexion dominance + knee extension + hip flexion dominance
    else if (hasPlantarflexionDominance &&
        hasKneeExtensionBias &&
        hasHipFlexionDominance) {
      final ankleConf = _ankleConfidence(confidenceMap);
      final kneeConf = confidenceMap['knee'] ?? ConfidenceLevel.medium;
      final hipConf = confidenceMap['hip'] ?? ConfidenceLevel.medium;
      final chainConf = _worstConfidence([ankleConf, kneeConf, hipConf]);

      compensations.add(Compensation(
        type: CompensationType.ankleRestriction,
        joint: 'ankle',
        chain: ChainType.ffl,
        confidence: _neverHighForAnkle(ankleConf),
        value: _getPlantarflexionValue(angleMap),
        threshold: _plantarflexionDominanceThreshold,
        citation: _wilkeCitation,
      ));
      compensations.add(Compensation(
        type: CompensationType.kneeValgus,
        joint: 'knee',
        chain: ChainType.ffl,
        confidence: chainConf,
        value: _getKneeExtensionValue(angleMap),
        threshold: 0.0,
        citation: _wilkeCitation,
      ));
      compensations.add(Compensation(
        type: CompensationType.hipDrop,
        joint: 'hip_flexors',
        chain: ChainType.ffl,
        confidence: chainConf,
        value: _getHipFlexionValue(angleMap),
        threshold: _hipFlexionStandingThreshold,
        citation: _wilkeCitation,
      ));
    }
    // Hypermobility: reversed interpretation (not SBL mapping)
    else if (isHypermobile) {
      final kneeConf = confidenceMap['knee'] ?? ConfidenceLevel.medium;
      compensations.add(Compensation(
        type: CompensationType.kneeValgus,
        joint: 'knee',
        chain: null,
        confidence: kneeConf,
        value: _getKneeERValue(angleMap),
        threshold: _kneeERHypermobilityThreshold,
        citation: _hypermobilityCitation,
      ));
    }
    // Individual flags that don't cluster into a chain
    else {
      if (hasKneeValgus) {
        compensations.add(Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: null,
          confidence: confidenceMap['knee'] ?? ConfidenceLevel.medium,
          value: _getKneeValgusValue(angleMap),
          threshold: _kneeValgusThreshold,
          citation: _hewettCitation,
        ));
      }
      if (hasAnkleRestriction) {
        final ankleConf = _ankleConfidence(confidenceMap);
        compensations.add(Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: null,
          confidence: _neverHighForAnkle(ankleConf),
          value: _getAnkleDorsiflexionValue(angleMap),
          threshold: _ankleDorsiflexionMin,
          citation: _ankleRestrictionCitation,
        ));
      }
      if (hasHipDrop) {
        compensations.add(Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: confidenceMap['hip'] ?? ConfidenceLevel.medium,
          value: _getHipAsymmetryValue(angleMap),
          threshold: _hipDropAsymmetryThreshold,
          citation: _ferberCitation,
        ));
      }
      if (hasTrunkLean) {
        compensations.add(Compensation(
          type: CompensationType.trunkLean,
          joint: 'trunk',
          chain: null,
          confidence: confidenceMap['hip'] ?? ConfidenceLevel.medium,
          value: angleMap['trunk_lateral_lean'] ?? 0.0,
          threshold: _trunkLeanThreshold,
          citation: _wilkeCitation,
        ));
      }
    }

    return compensations;
  }

  // -- Angle map helpers --

  Map<String, double> _buildAngleMap(List<JointAngle> angles) {
    final map = <String, double>{};
    for (final a in angles) {
      map[a.joint] = a.angleDegrees;
    }
    return map;
  }

  Map<String, ConfidenceLevel> _buildConfidenceMap(List<JointAngle> angles) {
    final map = <String, ConfidenceLevel>{};
    for (final a in angles) {
      final region = _jointToRegion(a.joint);
      final existing = map[region];
      if (existing == null || a.confidence.index > existing.index) {
        // Worse confidence wins (higher index = worse in our enum order).
        map[region] = a.confidence;
      }
    }
    return map;
  }

  String _jointToRegion(String joint) {
    if (joint.contains('ankle')) return 'ankle';
    if (joint.contains('knee')) return 'knee';
    if (joint.contains('hip')) return 'hip';
    if (joint.contains('shoulder') || joint.contains('thoracic')) {
      return 'shoulder';
    }
    if (joint.contains('trunk')) return 'hip';
    return 'other';
  }

  // -- Threshold detection --

  bool _detectKneeValgus(Map<String, double> m, bool isHypermobile) {
    final left = m['left_knee_valgus'] ?? 0.0;
    final right = m['right_knee_valgus'] ?? 0.0;
    final threshold =
        isHypermobile ? _kneeValgusHypermobilityCeiling : _kneeValgusThreshold;
    // For hypermobile: valgus < ceiling means NOT flagged (reversed).
    if (isHypermobile) {
      return false; // Hypermobility uses different interpretation.
    }
    return left > threshold || right > threshold;
  }

  bool _detectAnkleRestriction(Map<String, double> m) {
    final leftDF = m['left_ankle_dorsiflexion'] ?? 15.0;
    final rightDF = m['right_ankle_dorsiflexion'] ?? 15.0;
    final leftPF = m['left_ankle_plantarflexion'] ?? 0.0;
    final rightPF = m['right_ankle_plantarflexion'] ?? 0.0;
    final pfAsymmetry = (leftPF - rightPF).abs();

    return leftDF < _ankleDorsiflexionMin ||
        rightDF < _ankleDorsiflexionMin ||
        pfAsymmetry > _anklePlantarflexionAsymmetryThreshold;
  }

  bool _detectHipDrop(Map<String, double> m) {
    final left = m['left_hip_abduction'] ?? 0.0;
    final right = m['right_hip_abduction'] ?? 0.0;
    return (left - right).abs() > _hipDropAsymmetryThreshold;
  }

  bool _detectShoulderDepression(Map<String, double> m) {
    final left = m['left_shoulder_elevation'] ?? 0.0;
    final right = m['right_shoulder_elevation'] ?? 0.0;
    return (left - right).abs() > _shoulderAsymmetryThreshold;
  }

  bool _detectThoracicLimitation(Map<String, double> m) {
    final rotation = m['thoracic_rotation'] ?? 45.0;
    return rotation < _thoracicRotationMin;
  }

  bool _detectContralateralHipWeakness(Map<String, double> m) {
    final left = m['left_hip_abduction'] ?? 0.0;
    final right = m['right_hip_abduction'] ?? 0.0;
    return (left - right).abs() > _hipDropAsymmetryThreshold;
  }

  bool _detectPlantarflexionDominance(Map<String, double> m) {
    final left = m['left_ankle_plantarflexion'] ?? 0.0;
    final right = m['right_ankle_plantarflexion'] ?? 0.0;
    return left > _plantarflexionDominanceThreshold ||
        right > _plantarflexionDominanceThreshold;
  }

  bool _detectKneeExtensionBias(Map<String, double> m) {
    // Knee extension >0 in standing indicates hyperextension tendency.
    final left = m['left_knee_extension'] ?? 0.0;
    final right = m['right_knee_extension'] ?? 0.0;
    return left > 0.0 || right > 0.0;
  }

  bool _detectHipFlexionDominance(Map<String, double> m) {
    final left = m['left_hip_flexion'] ?? 0.0;
    final right = m['right_hip_flexion'] ?? 0.0;
    return left > _hipFlexionStandingThreshold ||
        right > _hipFlexionStandingThreshold;
  }

  bool _detectTrunkLean(Map<String, double> m) {
    final lean = m['trunk_lateral_lean'] ?? 0.0;
    return lean > _trunkLeanThreshold;
  }

  bool _detectHypermobility(Map<String, double> m) {
    final leftER = m['left_knee_external_rotation'] ?? 0.0;
    final rightER = m['right_knee_external_rotation'] ?? 0.0;
    final leftValgus = m['left_knee_valgus'] ?? 10.0;
    final rightValgus = m['right_knee_valgus'] ?? 10.0;

    return (leftER > _kneeERHypermobilityThreshold ||
            rightER > _kneeERHypermobilityThreshold) &&
        leftValgus < _kneeValgusHypermobilityCeiling &&
        rightValgus < _kneeValgusHypermobilityCeiling;
  }

  // -- Value extraction --

  double _getKneeValgusValue(Map<String, double> m) {
    final left = m['left_knee_valgus'] ?? 0.0;
    final right = m['right_knee_valgus'] ?? 0.0;
    return left > right ? left : right;
  }

  double _getAnkleDorsiflexionValue(Map<String, double> m) {
    final left = m['left_ankle_dorsiflexion'] ?? 15.0;
    final right = m['right_ankle_dorsiflexion'] ?? 15.0;
    return left < right ? left : right;
  }

  double _getHipAsymmetryValue(Map<String, double> m) {
    final left = m['left_hip_abduction'] ?? 0.0;
    final right = m['right_hip_abduction'] ?? 0.0;
    return (left - right).abs();
  }

  double _getShoulderAsymmetryValue(Map<String, double> m) {
    final left = m['left_shoulder_elevation'] ?? 0.0;
    final right = m['right_shoulder_elevation'] ?? 0.0;
    return (left - right).abs();
  }

  double _getPlantarflexionValue(Map<String, double> m) {
    final left = m['left_ankle_plantarflexion'] ?? 0.0;
    final right = m['right_ankle_plantarflexion'] ?? 0.0;
    return left > right ? left : right;
  }

  double _getKneeExtensionValue(Map<String, double> m) {
    final left = m['left_knee_extension'] ?? 0.0;
    final right = m['right_knee_extension'] ?? 0.0;
    return left > right ? left : right;
  }

  double _getHipFlexionValue(Map<String, double> m) {
    final left = m['left_hip_flexion'] ?? 0.0;
    final right = m['right_hip_flexion'] ?? 0.0;
    return left > right ? left : right;
  }

  double _getKneeERValue(Map<String, double> m) {
    final left = m['left_knee_external_rotation'] ?? 0.0;
    final right = m['right_knee_external_rotation'] ?? 0.0;
    return left > right ? left : right;
  }

  // -- Confidence helpers --

  ConfidenceLevel _ankleConfidence(Map<String, ConfidenceLevel> m) {
    return m['ankle'] ?? ConfidenceLevel.medium;
  }

  /// Ankle-dependent findings never get high confidence.
  ConfidenceLevel _neverHighForAnkle(ConfidenceLevel conf) {
    if (conf == ConfidenceLevel.high) return ConfidenceLevel.medium;
    return conf;
  }

  ConfidenceLevel _worstConfidence(List<ConfidenceLevel> levels) {
    var worst = ConfidenceLevel.high;
    for (final l in levels) {
      if (l.index > worst.index) worst = l;
    }
    return worst;
  }
}
