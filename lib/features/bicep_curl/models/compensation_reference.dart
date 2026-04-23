enum ArmSide {
  left,
  right;

  static ArmSide fromName(String name) => ArmSide.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ArmSide.right,
      );
}

/// Per-session pose baseline captured during the calibration window.
/// Subsequent reps compare current shoulder Y / torso pitch against these
/// references to derive per-rep peak deltas (see [CompensationDetector]).
class CompensationReference {
  const CompensationReference({
    required this.shoulderYRef,
    required this.torsoPitchDegRef,
    required this.armSide,
    this.armSegmentLen,
  });

  /// Normalized [0..1] y-coordinate of the curling-arm shoulder landmark
  /// (BlazePose 11 for left, 12 for right), averaged across stable resting
  /// frames captured during calibration (elbow near full extension, angular
  /// velocity below the stationary threshold).
  final double shoulderYRef;

  /// Torso pitch in degrees from vertical (mid-shoulder → mid-hip line),
  /// averaged across the same stable resting frames.
  final double torsoPitchDegRef;

  final ArmSide armSide;

  /// Mean normalized shoulder→elbow distance across the stable resting
  /// frames, used as the small-angle scale proxy when converting a
  /// normalized shoulder-Y delta into approximate degrees of shoulder
  /// elevation. Nullable to preserve backward-compatibility with sessions
  /// persisted before the stable-resting-frame rewrite (those reps' per-rep
  /// deltas already live on disk as degrees; the reference no longer needs
  /// to recompute them).
  final double? armSegmentLen;

  Map<String, dynamic> toJson() => {
        'shoulder_y_ref': shoulderYRef,
        'torso_pitch_deg_ref': torsoPitchDegRef,
        'arm_side': armSide.name,
        if (armSegmentLen != null) 'arm_segment_len': armSegmentLen,
      };

  factory CompensationReference.fromJson(Map<String, dynamic> json) =>
      CompensationReference(
        shoulderYRef: (json['shoulder_y_ref'] as num).toDouble(),
        torsoPitchDegRef: (json['torso_pitch_deg_ref'] as num).toDouble(),
        armSide: ArmSide.fromName(json['arm_side'] as String),
        armSegmentLen: json['arm_segment_len'] != null
            ? (json['arm_segment_len'] as num).toDouble()
            : null,
      );
}
