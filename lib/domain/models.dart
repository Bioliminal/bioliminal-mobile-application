import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Supported movement types. Must match the server's MovementType literal.
///
/// `bicepCurl` is the M1–M6 demo target. The four screening movements below
/// (overhead squat / single-leg squat / push-up / rollup) are dormant until
/// post-demo and are not reachable from the current user flow. See
/// bioliminal-mobile-application#30.
enum MovementType {
  bicepCurl('bicep_curl'),
  overheadSquat('overhead_squat'),
  singleLegSquat('single_leg_squat'),
  pushUp('push_up'),
  rollup('rollup');

  const MovementType(this.wire);
  final String wire;

  static MovementType fromWire(String value) =>
      MovementType.values.firstWhere((m) => m.wire == value);
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

/// A single BlazePose landmark.
class PoseLandmark {
  const PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
  });

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

  factory PoseLandmark.fromJson(Map<String, dynamic> json) => PoseLandmark(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    visibility: (json['visibility'] as num).toDouble(),
    presence: (json['presence'] as num).toDouble(),
  );
}

/// A single captured frame with exactly 33 BlazePose landmarks.
class PoseFrame {
  PoseFrame({required this.timestampMs, required this.landmarks}) {
    if (landmarks.length != 33) {
      throw ArgumentError(
        'PoseFrame requires exactly 33 BlazePose landmarks, got ${landmarks.length}.',
      );
    }
  }

  final int timestampMs;
  final List<PoseLandmark> landmarks;

  Map<String, dynamic> toJson() => {
    'timestamp_ms': timestampMs,
    'landmarks': landmarks.map((l) => l.toJson()).toList(),
  };

  factory PoseFrame.fromJson(Map<String, dynamic> json) => PoseFrame(
    timestampMs: json['timestamp_ms'] as int,
    landmarks: (json['landmarks'] as List<dynamic>)
        .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Metadata attached to a session upload.
class SessionMetadata {
  SessionMetadata({
    required this.movement,
    required this.device,
    required this.model,
    required this.frameRate,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now().toUtc();

  final MovementType movement;
  final String device;
  final String model;
  final double frameRate;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
    'movement': movement.wire,
    'device': device,
    'model': model,
    'frame_rate': frameRate,
    'captured_at': capturedAt.toUtc().toIso8601String(),
  };

  factory SessionMetadata.fromJson(Map<String, dynamic> json) =>
      SessionMetadata(
        movement: MovementType.fromWire(json['movement'] as String),
        device: json['device'] as String,
        model: json['model'] as String,
        frameRate: (json['frame_rate'] as num).toDouble(),
        capturedAt: DateTime.parse(json['captured_at'] as String),
      );
}

/// Full session payload. Matches the server's Session schema.
class SessionPayload {
  const SessionPayload({required this.metadata, required this.frames});

  final SessionMetadata metadata;
  final List<PoseFrame> frames;

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'frames': frames.map((f) => f.toJson()).toList(),
  };

  factory SessionPayload.fromJson(Map<String, dynamic> json) => SessionPayload(
    metadata: SessionMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>,
    ),
    frames: (json['frames'] as List<dynamic>)
        .map((e) => PoseFrame.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Serialize to JSON string in a background isolate.
  static Future<String> serializeAsync(SessionPayload payload) async {
    return compute((p) => jsonEncode(p.toJson()), payload);
  }
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

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
    finding: json['finding'] as String,
    source: json['source'] as String,
    url: json['url'] as String,
    type: CitationType.values.byName(json['type'] as String),
    appUsage: json['app_usage'] as String,
  );
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

  factory Compensation.fromJson(Map<String, dynamic> json) => Compensation(
    type: CompensationType.values.byName(json['type'] as String),
    joint: json['joint'] as String,
    chain: json['chain'] != null
        ? ChainType.values.byName(json['chain'] as String)
        : null,
    confidence: ConfidenceLevel.values.byName(json['confidence'] as String),
    value: (json['value'] as num).toDouble(),
    threshold: (json['threshold'] as num).toDouble(),
    citation: Citation.fromJson(json['citation'] as Map<String, dynamic>),
  );
}

class Movement {
  const Movement({
    required this.type,
    required this.frames,
    required this.keyframeAngles,
    required this.duration,
  });

  final MovementType type;
  final List<PoseFrame> frames;
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

  factory MobilityDrill.fromJson(Map<String, dynamic> json) => MobilityDrill(
    name: json['name'] as String,
    targetArea: json['target_area'] as String,
    durationSeconds: json['duration_seconds'] as int,
    steps: (json['steps'] as List<dynamic>).cast<String>(),
    compensationType: CompensationType.values.byName(
      json['compensation_type'] as String,
    ),
  );
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

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
    bodyPathDescription: json['body_path_description'] as String,
    compensations: (json['compensations'] as List<dynamic>)
        .map((e) => Compensation.fromJson(e as Map<String, dynamic>))
        .toList(),
    upstreamDriver: json['upstream_driver'] as String?,
    recommendation: json['recommendation'] as String,
    citations: (json['citations'] as List<dynamic>)
        .map((e) => Citation.fromJson(e as Map<String, dynamic>))
        .toList(),
    drills: json['drills'] != null
        ? (json['drills'] as List<dynamic>)
              .map((e) => MobilityDrill.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
    trendStatus: json['trend_status'] != null
        ? TrendClassification.values.byName(json['trend_status'] as String)
        : null,
  );
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

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    findings: (json['findings'] as List<dynamic>)
        .map((e) => Finding.fromJson(e as Map<String, dynamic>))
        .toList(),
    practitionerPoints: (json['practitioner_points'] as List<dynamic>)
        .cast<String>(),
    pdfUrl: json['pdf_url'] as String?,
  );
}

class Assessment {
  const Assessment({
    required this.id,
    required this.createdAt,
    required this.movements,
    required this.compensations,
    this.report,
    this.payload,
  });

  final String id;
  final DateTime createdAt;
  final List<Movement> movements;
  final List<Compensation> compensations;
  final Report? report;
  final SessionPayload? payload;
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
