import '../../../domain/models.dart';
import '../models/compensation_reference.dart';
import '../models/pose_delta.dart';
import 'pose_math.dart';

/// Pose-based compensation analysis. Calibration reps 1–3 build a baseline
/// for shoulder Y and torso pitch; subsequent reps compare against it.
///
/// The `shoulderDriftDeg` field is approximated from a normalized y-pixel
/// delta (frame-relative, not true geometry). A scale factor of 175 maps a
/// typical 0.04 normalized delta to ~7° at smartphone-tripod framing
/// distance — accurate enough for the 5–9° threshold band the algorithm
/// cares about. Promote to true geometry when a forearm-length proxy is
/// available from calibration.
class CompensationDetector {
  /// Approximate "degrees per unit of normalized y" for shoulder drift.
  static const double _yToDegFactor = 175.0;

  /// Build the per-session baseline from the pooled pose frames captured
  /// across calibration reps 1–3.
  static CompensationReference buildReference(
    List<List<PoseLandmark>> calibrationFrames,
    ArmSide side,
  ) {
    if (calibrationFrames.isEmpty) {
      // No pose frames landed during calibration (degraded lighting, late
      // channel init, or very fast reps). Return a zero-drift baseline so
      // compensation thresholds don't fire falsely and the session can
      // continue instead of crashing on a StateError.
      return CompensationReference(
        shoulderYRef: 0.0,
        torsoPitchDegRef: 0.0,
        armSide: side,
      );
    }
    var sumShoulderY = 0.0;
    var sumPitch = 0.0;
    for (final frame in calibrationFrames) {
      sumShoulderY += shoulderY(frame, side);
      sumPitch += torsoPitchDeg(frame);
    }
    return CompensationReference(
      shoulderYRef: sumShoulderY / calibrationFrames.length,
      torsoPitchDegRef: sumPitch / calibrationFrames.length,
      armSide: side,
    );
  }

  /// Per-frame drift from the reference. Caller typically aggregates per
  /// rep (e.g. mean across rep window) before evaluating against profile
  /// thresholds.
  static PoseDelta computeDelta(
    List<PoseLandmark> currentFrame,
    CompensationReference ref,
  ) {
    final shoulderDeltaY = shoulderY(currentFrame, ref.armSide) - ref.shoulderYRef;
    return PoseDelta(
      shoulderDriftDeg: shoulderDeltaY * _yToDegFactor,
      torsoPitchDeltaDeg: torsoPitchDeg(currentFrame) - ref.torsoPitchDegRef,
    );
  }
}
