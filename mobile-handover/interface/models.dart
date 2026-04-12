// Dart data classes mirroring the server pydantic schema at
// software/server/src/auralink/api/schemas.py
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
  PoseFrame({
    required this.timestampMs,
    required this.landmarks,
  }) {
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
  rollup('rollup');

  const MovementType(this.wire);
  final String wire;

  static MovementType fromWire(String value) =>
      MovementType.values.firstWhere((m) => m.wire == value);
}

/// Metadata attached to a session upload.
class SessionMetadata {
  SessionMetadata({
    required this.movement,
    required this.device,
    required this.model,
    required this.frameRate,
    DateTime? capturedAt,
  })  : capturedAt = capturedAt ?? DateTime.now().toUtc() {
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
class SessionPayload {
  const SessionPayload({
    required this.metadata,
    required this.frames,
  });

  final SessionMetadata metadata;
  final List<PoseFrame> frames;

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'frames': frames.map((f) => f.toJson()).toList(),
      };
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
