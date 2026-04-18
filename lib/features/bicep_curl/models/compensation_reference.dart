enum ArmSide { left, right }

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
}
