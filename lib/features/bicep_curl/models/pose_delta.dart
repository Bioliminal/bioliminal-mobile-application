import 'cue_profile.dart';

/// Per-rep signed PEAK pose deltas captured during an active rep.
///
/// Semantics (both fields are in degrees):
/// - [shoulderDriftDeg] is the signed peak SHOULDER RISE across the rep:
///   `refShoulderY - min(shoulderY over rep frames)`, converted to degrees
///   via the calibration reference's arm-segment scale proxy. Positive =
///   shoulders hiked up (compensation). Negative = the user slumped;
///   intentionally NOT flagged as compensation.
/// - [torsoPitchDeltaDeg] is the signed peak FORWARD LEAN across the rep:
///   `max(torsoPitchDeg over rep frames) - refTorsoPitchDeg`. Positive =
///   user leaned forward (compensation). Negative = leaned back; not
///   flagged.
///
/// Averages are washed-out and miss the brief concentric peak where
/// compensation actually happens, so the controller stores the signed peak
/// here instead of a mean. Fields keep their historical names so persisted
/// session logs deserialize without a schema migration, but the SEMANTICS
/// of the stored value changed: older logs contain signed means; new logs
/// contain signed peaks.
class PoseDelta {
  const PoseDelta({
    required this.shoulderDriftDeg,
    required this.torsoPitchDeltaDeg,
  });

  final double shoulderDriftDeg;
  final double torsoPitchDeltaDeg;

  /// True when either signed peak exceeds its threshold. Signed: a negative
  /// delta (slump / back-lean) is never flagged, even if its magnitude is
  /// large — that's user posture, not bicep-curl compensation.
  bool exceedsThresholds(CompensationThresholds thresholds) =>
      shoulderDriftDeg > thresholds.shoulderDriftDeg ||
      torsoPitchDeltaDeg > thresholds.torsoPitchDeltaDeg;

  Map<String, dynamic> toJson() => {
        'shoulder_drift_deg': shoulderDriftDeg,
        'torso_pitch_delta_deg': torsoPitchDeltaDeg,
      };

  factory PoseDelta.fromJson(Map<String, dynamic> json) => PoseDelta(
        shoulderDriftDeg: (json['shoulder_drift_deg'] as num).toDouble(),
        torsoPitchDeltaDeg:
            (json['torso_pitch_delta_deg'] as num).toDouble(),
      );
}

/// One-rep output from [CompensationDetector.computePerRepDeltas].
/// Contains both the signed peak deltas (for threshold evaluation in the
/// controller) and a per-frame delta series (for the debrief chart and
/// muscle-heatmap animations).
class PerRepDeltas {
  const PerRepDeltas({
    required this.series,
    required this.peakShoulderRiseDeg,
    required this.peakForwardLeanDeg,
  });

  /// Per-frame `PoseDelta` series across the rep window — each entry is an
  /// instantaneous signed delta vs the reference. Consumers that need a
  /// summary (debrief chart baseline, heatmap) build their own reduction.
  final List<PoseDelta> series;

  /// Signed peak of the shoulder rise across the rep (degrees). Positive =
  /// shoulder went up (compensation). Negative = shoulder slumped below
  /// the resting reference (not flagged).
  final double peakShoulderRiseDeg;

  /// Signed peak of the forward lean across the rep (degrees). Positive =
  /// leaned forward (compensation). Negative = leaned back (not flagged).
  final double peakForwardLeanDeg;

  /// Convenience: the two peaks packaged as a `PoseDelta` so the rest of
  /// the pipeline (RepRecord.poseDelta, SessionLog.formScore, debrief
  /// widgets) can continue reading signed values without a schema change.
  PoseDelta asPeakPoseDelta() => PoseDelta(
        shoulderDriftDeg: peakShoulderRiseDeg,
        torsoPitchDeltaDeg: peakForwardLeanDeg,
      );
}
