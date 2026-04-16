// Dart data classes mirroring the server pydantic schema at
// software/server/src/bioliminal/api/schemas.py
//
// These are the ONLY shapes the server accepts on POST /sessions.
// Keep them in lockstep with schemas.py — if you see drift, re-export the JSON
// schema via tools/export_schemas.py and regenerate.
//
// No third-party codegen needed (no freezed, no json_serializable) — the
// classes are small and hand-written toJson/fromJson keeps the dependency
// surface minimal for a capstone.

/// A single BlazePose landmark.
///
/// Coordinates:
///   x, y ∈ [0, 1] — normalized image coordinates.
///   z      — depth relative to the hip midpoint, in the same scale as x.
///              Negative = closer to the camera.
/// visibility ∈ [0, 1] — probability the landmark is visible (not occluded).
/// presence   ∈ [0, 1] — probability the landmark is present in the frame.
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

/// A single captured frame with exactly 33 BlazePose landmarks in canonical
/// order. See `blazepose_landmark_order.md` in the handover package for the
/// index → joint name mapping.
class PoseFrame {
  PoseFrame({required this.timestampMs, required this.landmarks}) {
    if (landmarks.length != 33) {
      throw ArgumentError(
        'PoseFrame requires exactly 33 BlazePose landmarks, got ${landmarks.length}.',
      );
    }
    if (timestampMs < 0) {
      throw ArgumentError('timestampMs must be >= 0, got $timestampMs.');
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

/// Supported movement types. Must match the server's MovementType literal.
enum MovementType {
  overheadSquat('overhead_squat'),
  singleLegSquat('single_leg_squat'),
  pushUp('push_up'),
  rollup('rollup'),
  bicepCurl('bicep_curl');

  const MovementType(this.wire);
  final String wire;

  static MovementType fromWire(String value) =>
      MovementType.values.firstWhere((m) => m.wire == value);
}

/// Encoding of a single sEMG sample value.
///
/// Raw sEMG (raw_mv, normalized_0_1 of raw signal) is biometrically
/// re-identifiable — research shows 90–97% re-id accuracy from just 0.8 s of
/// 4-channel data. For privacy-conscious deployments, the phone/firmware SHOULD
/// compute features (RMS, MDF) on-device and upload the feature stream instead
/// of raw signal. See research/synthesis/deep-read-semg-privacy-regulation-2026-04-15.md
/// in the research repo for the full regulatory rationale (MHMDA, GDPR Art 9,
/// FTC HBNR).
enum SEMGEncoding {
  rawMv('raw_mv'),
  normalized01('normalized_0_1'),
  featureRms('feature_rms'),
  featureMdf('feature_mdf');

  const SEMGEncoding(this.wire);
  final String wire;

  static SEMGEncoding fromWire(String value) =>
      SEMGEncoding.values.firstWhere((e) => e.wire == value);
}

/// Jurisdiction the session's consent was collected under. Drives which
/// downstream retention / deletion / disclosure rules the server applies.
enum ConsentJurisdiction {
  usWa('US-WA'),
  usOther('US-other'),
  eu('EU'),
  other('other');

  const ConsentJurisdiction(this.wire);
  final String wire;

  static ConsentJurisdiction fromWire(String value) =>
      ConsentJurisdiction.values.firstWhere((j) => j.wire == value);
}

/// One sEMG reading. Optional on any session — pending the ML_RandD_Server#13
/// decision on whether sEMG ships in the `SessionPayload`. The schema is kept
/// minimal + extensible (the server accepts extra fields) so we can extend for
/// windowing / feature-extraction parameters without a schema migration.
class SEMGSample {
  const SEMGSample({
    required this.channel,
    required this.timestampMs,
    required this.value,
    this.encoding = SEMGEncoding.normalized01,
  });

  /// 0 = biceps belly, 1 = brachioradialis for the demo. Extend as channels are added.
  final int channel;

  /// MCU-clock timestamp. Needs to be reconciled with Frame.timestamp_ms via
  /// the clock-sync handshake (IC-1 §clock_sync).
  final int timestampMs;

  final double value;
  final SEMGEncoding encoding;

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'timestamp_ms': timestampMs,
    'value': value,
    'encoding': encoding.wire,
  };

  factory SEMGSample.fromJson(Map<String, dynamic> json) => SEMGSample(
    channel: json['channel'] as int,
    timestampMs: json['timestamp_ms'] as int,
    value: (json['value'] as num).toDouble(),
    encoding: json['encoding'] != null
        ? SEMGEncoding.fromWire(json['encoding'] as String)
        : SEMGEncoding.normalized01,
  );
}

/// Session-level consent fingerprint. REQUIRED by the server on any session
/// that includes `emg` — server returns 422 if emg is present without consent.
/// MHMDA requires opt-in with a specified purpose; GDPR Art 9 requires explicit
/// consent with no wellness exception. `consentVersion` is the hash / semver of
/// the specific policy text the user agreed to.
class ConsentMetadata {
  const ConsentMetadata({
    required this.consentVersion,
    required this.consentJurisdiction,
    required this.consentTimestamp,
    this.dataRetentionDays,
  });

  final String consentVersion;
  final ConsentJurisdiction consentJurisdiction;
  final DateTime consentTimestamp;

  /// null = retain per the server's default policy for this jurisdiction.
  final int? dataRetentionDays;

  Map<String, dynamic> toJson() => {
    'consent_version': consentVersion,
    'consent_jurisdiction': consentJurisdiction.wire,
    'consent_timestamp': consentTimestamp.toUtc().toIso8601String(),
    if (dataRetentionDays != null) 'data_retention_days': dataRetentionDays,
  };
}

/// Metadata attached to a session upload.
class SessionMetadata {
  SessionMetadata({
    required this.movement,
    required this.device,
    required this.model,
    required this.frameRate,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now().toUtc() {
    if (frameRate <= 0) {
      throw ArgumentError('frameRate must be > 0, got $frameRate.');
    }
  }

  final MovementType movement;

  /// Short device identifier, e.g. "Pixel 8 Pro". Free-form, used by the
  /// server for rough device-class analytics.
  final String device;

  /// Model identifier. For the launch build this is always
  /// "mediapipe_blazepose_full". Kept as a string so we can swap to
  /// "movenet_thunder" / "hrpose_small" later without a schema change.
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
}

/// Full session payload. Matches the pydantic Session model exactly.
///
/// `emg` is optional pending ML_RandD_Server#13. `consent` is REQUIRED by the
/// server whenever `emg` is non-null — server returns 422 otherwise.
class SessionPayload {
  SessionPayload({
    required this.metadata,
    required this.frames,
    this.emg,
    this.consent,
  }) {
    if (emg != null && consent == null) {
      throw ArgumentError(
        'consent metadata is required for any session that carries sEMG '
        '(MHMDA / GDPR Art 9 / FTC HBNR).',
      );
    }
  }

  final SessionMetadata metadata;
  final List<PoseFrame> frames;
  final List<SEMGSample>? emg;
  final ConsentMetadata? consent;

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'frames': frames.map((f) => f.toJson()).toList(),
    if (emg != null) 'emg': emg!.map((e) => e.toJson()).toList(),
    if (consent != null) 'consent': consent!.toJson(),
  };
}

/// Per-rep score as returned in the server's `SessionReport`. Schema mirrors
/// the server `RepScore` pydantic model. The server accepts extra fields
/// (`extra='allow'`) so `#12` (bicep curl rule YAML + report narrative) can
/// enrich this without a mobile-side schema bump.
class RepScore {
  const RepScore({
    required this.repIndex,
    this.activationDelta,
    this.cueFired = false,
    this.cueVerified = false,
    this.elbowAngleRange,
  });

  final int repIndex;

  /// sEMG pre/post-cue activation delta. Null if session had no sEMG.
  final double? activationDelta;

  final bool cueFired;

  /// Verify-delta ≥ 15 % within 500 ms per cue spec. Meaningful only when
  /// cueFired is true.
  final bool cueVerified;

  /// (min, max) in degrees. Null if angle tracking unavailable.
  final ({double min, double max})? elbowAngleRange;

  factory RepScore.fromJson(Map<String, dynamic> json) {
    final range = json['elbow_angle_range'];
    return RepScore(
      repIndex: json['rep_index'] as int,
      activationDelta: (json['activation_delta'] as num?)?.toDouble(),
      cueFired: json['cue_fired'] as bool? ?? false,
      cueVerified: json['cue_verified'] as bool? ?? false,
      elbowAngleRange: range is List && range.length == 2
          ? (
              min: (range[0] as num).toDouble(),
              max: (range[1] as num).toDouble(),
            )
          : null,
    );
  }
}

/// Full session report. Mirrors the server `SessionReport`. Both sides use
/// `extra='allow'` so this can grow without lockstep updates.
class SessionReport {
  const SessionReport({
    required this.sessionId,
    this.reps = const [],
    this.totalReps = 0,
    this.chainObservations = const [],
    this.narrative = '',
  });

  final String sessionId;
  final List<RepScore> reps;
  final int totalReps;
  final List<String> chainObservations;
  final String narrative;

  factory SessionReport.fromJson(Map<String, dynamic> json) => SessionReport(
    sessionId: json['session_id'] as String,
    reps: (json['reps'] as List<dynamic>? ?? const [])
        .map((e) => RepScore.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalReps: json['total_reps'] as int? ?? 0,
    chainObservations:
        (json['chain_observations'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
    narrative: json['narrative'] as String? ?? '',
  );
}

/// Response body returned by POST /sessions.
class SessionCreateResponse {
  const SessionCreateResponse({
    required this.sessionId,
    required this.framesReceived,
  });

  final String sessionId;
  final int framesReceived;

  factory SessionCreateResponse.fromJson(Map<String, dynamic> json) =>
      SessionCreateResponse(
        sessionId: json['session_id'] as String,
        framesReceived: json['frames_received'] as int,
      );
}
