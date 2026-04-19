enum ArmSide {
  left,
  right;

  static ArmSide fromName(String name) =>
      ArmSide.values.firstWhere((s) => s.name == name);
}

/// Per-session pose baseline captured during reps 1–3 of the calibration
/// window. Subsequent reps compare current shoulder Y / torso pitch
/// against these references to derive a [PoseDelta].
class CompensationReference {
  const CompensationReference({
    required this.shoulderYRef,
    required this.torsoPitchDegRef,
    required this.armSide,
  });

  /// Normalized [0..1] y-coordinate of the curling-arm shoulder landmark
  /// (BlazePose 11 for left, 12 for right), averaged across calibration
  /// reps 1–3.
  final double shoulderYRef;

  /// Torso pitch in degrees from vertical (mid-shoulder → mid-hip line),
  /// averaged across the same calibration window.
  final double torsoPitchDegRef;

  final ArmSide armSide;

  Map<String, dynamic> toJson() => {
        'shoulder_y_ref': shoulderYRef,
        'torso_pitch_deg_ref': torsoPitchDegRef,
        'arm_side': armSide.name,
      };

  factory CompensationReference.fromJson(Map<String, dynamic> json) =>
      CompensationReference(
        shoulderYRef: (json['shoulder_y_ref'] as num).toDouble(),
        torsoPitchDegRef: (json['torso_pitch_deg_ref'] as num).toDouble(),
        armSide: ArmSide.fromName(json['arm_side'] as String),
      );
}
