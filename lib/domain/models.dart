enum MovementType {
  overheadSquat,
  singleLegBalance,
  overheadReach,
  forwardFold,
}

enum CompensationType {
  kneeValgus,
  hipDrop,
  ankleRestriction,
  trunkLean,
}

enum ChainType {
  sbl,
  bfl,
  ffl,
}

enum ConfidenceLevel {
  high,
  medium,
  low,
}

enum CitationType {
  research,
  clinical,
  guideline,
}

class Landmark {
  const Landmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  final double x;
  final double y;
  final double z;
  final double visibility;
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

class Finding {
  const Finding({
    required this.bodyPathDescription,
    required this.compensations,
    this.upstreamDriver,
    required this.recommendation,
    required this.citations,
  });

  final String bodyPathDescription;
  final List<Compensation> compensations;
  final String? upstreamDriver;
  final String recommendation;
  final List<Citation> citations;
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
