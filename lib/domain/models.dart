enum MovementType {
  overheadSquat,
  singleLegBalance,
  overheadReach,
  forwardFold,
}

enum CompensationType { kneeValgus, hipDrop, ankleRestriction, trunkLean }

enum ChainType { sbl, bfl, ffl }

enum ConfidenceLevel {
  high,
  medium,
  low;

  int get severityValue {
    switch (this) {
      case ConfidenceLevel.high:
        return 0;
      case ConfidenceLevel.medium:
        return 1;
      case ConfidenceLevel.low:
        return 2;
    }
  }

  bool isWorseThan(ConfidenceLevel other) =>
      severityValue > other.severityValue;

  static ConfidenceLevel worstOf(Iterable<ConfidenceLevel> levels) {
    var worst = ConfidenceLevel.high;
    for (final level in levels) {
      if (level.isWorseThan(worst)) worst = level;
    }
    return worst;
  }
}

enum CitationType { research, clinical, guideline }

class Landmark {
  const Landmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    this.presence = 1.0,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    visibility: (json['visibility'] as num).toDouble(),
    presence: (json['presence'] as num?)?.toDouble() ?? 1.0,
  );

  final double x;
  final double y;
  final double z;
  final double visibility;
  final double presence;

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    'visibility': visibility,
    'presence': presence,
  };
}

class JointAngle {
  const JointAngle({
    required this.joint,
    required this.angleDegrees,
    required this.confidence,
  });

  final String joint;
  final double angleDegrees;
  final ConfidenceLevel confidence;
}

class Citation {
  const Citation({
    required this.finding,
    required this.source,
    required this.url,
    required this.type,
    required this.appUsage,
  });

  final String finding;
  final String source;
  final String url;
  final CitationType type;
  final String appUsage;
}

class Compensation {
  const Compensation({
    required this.type,
    required this.joint,
    this.chain,
    required this.confidence,
    required this.value,
    required this.threshold,
    required this.citation,
  });

  final CompensationType type;
  final String joint;
  final ChainType? chain;
  final ConfidenceLevel confidence;
  final double value;
  final double threshold;
  final Citation citation;
}

class Movement {
  const Movement({
    required this.type,
    required this.landmarks,
    required this.keyframeAngles,
    required this.duration,
  });

  final MovementType type;
  final List<List<Landmark>> landmarks;
  final List<JointAngle> keyframeAngles;
  final Duration duration;
}

class MobilityDrill {
  const MobilityDrill({
    required this.name,
    required this.targetArea,
    required this.durationSeconds,
    required this.steps,
    required this.compensationType,
  });

  final String name;
  final String targetArea;
  final int durationSeconds;
  final List<String> steps;
  final CompensationType compensationType;
}

enum TrendClassification { improving, worsening, stable, newPattern }

class Finding {
  const Finding({
    required this.bodyPathDescription,
    required this.compensations,
    this.upstreamDriver,
    required this.recommendation,
    required this.citations,
    this.drills = const [],
    this.trendStatus,
  });

  final String bodyPathDescription;
  final List<Compensation> compensations;
  final String? upstreamDriver;
  final String recommendation;
  final List<Citation> citations;
  final List<MobilityDrill> drills;
  final TrendClassification? trendStatus;
}

class Report {
  const Report({
    required this.findings,
    required this.practitionerPoints,
    this.pdfUrl,
  });

  final List<Finding> findings;
  final List<String> practitionerPoints;
  final String? pdfUrl;
}

class Assessment {
  const Assessment({
    required this.id,
    required this.createdAt,
    required this.movements,
    required this.compensations,
    this.report,
  });

  final String id;
  final DateTime createdAt;
  final List<Movement> movements;
  final List<Compensation> compensations;
  final Report? report;
}

enum MobilityArchetype {
  ankleDominant,
  hipDominant,
  trunkDominant,
  hypermobile,
  balanced,
}

class CompensationTrend {
  const CompensationTrend({
    required this.compensationType,
    required this.joint,
    required this.trend,
    required this.values,
    required this.slope,
  });

  final CompensationType compensationType;
  final String joint;
  final TrendClassification trend;
  final List<double> values;
  final double slope;
}

class TrendReport {
  const TrendReport({required this.trends});

  final List<CompensationTrend> trends;

  CompensationTrend? trendFor(CompensationType type, String joint) {
    for (final t in trends) {
      if (t.compensationType == type && t.joint == joint) return t;
    }
    return null;
  }
}
