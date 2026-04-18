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

// ---------------------------------------------------------------------------
// Server report wire types — mirror software/mobile-handover/schemas/report.schema.json
// from ML_RandD_Server. Decode-only. Use ServerReportAdapter to convert into
// the legacy Report shape the UI renders.
// ---------------------------------------------------------------------------

enum ChainName {
  superficialBackLine('superficial_back_line'),
  backFunctionalLine('back_functional_line'),
  frontFunctionalLine('front_functional_line');

  const ChainName(this.wire);
  final String wire;

  static ChainName fromWire(String value) =>
      ChainName.values.firstWhere((c) => c.wire == value);
}

enum ObservationSeverity { info, concern, flag }

class QualityIssue {
  const QualityIssue({required this.code, required this.detail});

  final String code;
  final String detail;

  factory QualityIssue.fromJson(Map<String, dynamic> json) => QualityIssue(
    code: json['code'] as String,
    detail: json['detail'] as String,
  );
}

class SessionQualityReport {
  const SessionQualityReport({required this.passed, this.issues = const []});

  final bool passed;
  final List<QualityIssue> issues;

  factory SessionQualityReport.fromJson(Map<String, dynamic> json) =>
      SessionQualityReport(
        passed: json['passed'] as bool,
        issues:
            (json['issues'] as List<dynamic>?)
                ?.map((e) => QualityIssue.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class ChainObservation {
  const ChainObservation({
    required this.chain,
    required this.severity,
    required this.confidence,
    required this.triggerRule,
    required this.narrative,
    this.involvedJoints = const [],
  });

  final ChainName chain;
  final ObservationSeverity severity;
  final double confidence;
  final String triggerRule;
  final String narrative;
  final List<String> involvedJoints;

  factory ChainObservation.fromJson(Map<String, dynamic> json) =>
      ChainObservation(
        chain: ChainName.fromWire(json['chain'] as String),
        severity: ObservationSeverity.values.byName(json['severity'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        triggerRule: json['trigger_rule'] as String,
        narrative: json['narrative'] as String,
        involvedJoints:
            (json['involved_joints'] as List<dynamic>?)?.cast<String>() ??
            const [],
      );
}

class MovementSection {
  const MovementSection({
    required this.movement,
    required this.qualityReport,
    this.chainObservations = const [],
  });

  final String movement;
  final SessionQualityReport qualityReport;
  final List<ChainObservation> chainObservations;

  factory MovementSection.fromJson(Map<String, dynamic> json) =>
      MovementSection(
        movement: json['movement'] as String,
        qualityReport: SessionQualityReport.fromJson(
          json['quality_report'] as Map<String, dynamic>,
        ),
        chainObservations:
            (json['chain_observations'] as List<dynamic>?)
                ?.map(
                  (e) => ChainObservation.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}

class ReportMetadata {
  const ReportMetadata({
    required this.sessionId,
    required this.movement,
    this.capturedAtMs,
  });

  final String sessionId;
  final String movement;
  final int? capturedAtMs;

  factory ReportMetadata.fromJson(Map<String, dynamic> json) => ReportMetadata(
    sessionId: json['session_id'] as String,
    movement: json['movement'] as String,
    capturedAtMs: json['captured_at_ms'] as int?,
  );
}

/// Top-level report returned by GET /sessions/{id}/report.
///
/// Only `metadata`, `movement_section`, and `overall_narrative` are decoded.
/// Optional `temporal_section` / `cross_movement_section` are ignored until
/// the UI needs them.
class ServerReport {
  const ServerReport({
    required this.metadata,
    required this.movementSection,
    required this.overallNarrative,
    required this.raw,
  });

  final ReportMetadata metadata;
  final MovementSection movementSection;
  final String overallNarrative;

  /// The raw JSON body for this report. Kept so local persistence can round-
  /// trip the full server payload (including fields we don't yet decode) and
  /// so the UI can lazily consume them once rendering catches up.
  final Map<String, dynamic> raw;

  factory ServerReport.fromJson(Map<String, dynamic> json) => ServerReport(
    metadata: ReportMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>,
    ),
    movementSection: MovementSection.fromJson(
      json['movement_section'] as Map<String, dynamic>,
    ),
    overallNarrative: json['overall_narrative'] as String,
    raw: json,
  );
}

// ---------------------------------------------------------------------------
// Local session persistence — one record per completed server POST /sessions.
// The ServerReport inside is null until the report has been fetched.
// ---------------------------------------------------------------------------

class SessionRecord {
  const SessionRecord({
    required this.sessionId,
    required this.movement,
    required this.capturedAt,
    this.report,
  });

  /// The session_id returned by POST /sessions.
  final String sessionId;

  /// Wire movement value (e.g. "bicep_curl"). Cached from the payload so the
  /// history view can show movement labels before the report arrives.
  final String movement;

  /// When the capture was finalized on-device (UTC).
  final DateTime capturedAt;

  /// The server's analysis report. Null until it has been fetched.
  final ServerReport? report;

  SessionRecord copyWith({ServerReport? report}) => SessionRecord(
    sessionId: sessionId,
    movement: movement,
    capturedAt: capturedAt,
    report: report ?? this.report,
  );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'movement': movement,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    if (report != null) 'report': report!.raw,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    sessionId: json['session_id'] as String,
    movement: json['movement'] as String,
    capturedAt: DateTime.parse(json['captured_at'] as String),
    report: json['report'] != null
        ? ServerReport.fromJson(json['report'] as Map<String, dynamic>)
        : null,
  );
}
