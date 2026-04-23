import 'dart:math' as math;

import '../../../domain/models.dart';
import '../models/compensation_reference.dart';
import '../models/pose_delta.dart';
import 'pose_math.dart';

/// Pose-based compensation analysis.
///
/// # Reference
/// Built once at the end of calibration from STABLE RESTING FRAMES only:
/// frames where the curling arm is near full extension and angular velocity
/// is below the stationary threshold. Pooling every calibration frame
/// (including mid-rep transitions) lands the reference at a mid-rep average
/// rather than at the user's true resting posture, which caused persistent
/// false-positive "compensation" during active reps. The resting-frame
/// filter is the structural fix.
///
/// # Per-rep signal
/// Rather than averaging across the rep (which washes out the concentric
/// peak where compensation actually occurs), the detector emits SIGNED
/// peak deltas:
/// - peakShoulderRiseDeg = refShoulderY - min(shoulderY over rep) scaled
///   to degrees via the calibration arm-segment length.
/// - peakForwardLeanDeg = max(torsoPitchDeg over rep) - refTorsoPitchDeg.
///
/// Sign is load-bearing: only positive peaks (shoulder hike, forward
/// lean) count as compensation. A user slumping or leaning back produces
/// a negative peak and is deliberately not flagged — that's posture, not
/// mid-curl compensation.
///
/// # Scale proxy
/// The old algorithm used a fixed `175` magic-number to convert a
/// normalized y-delta into degrees, which fired on any phone reframing.
/// The new algorithm uses the calibration-measured arm-segment length
/// (normalized shoulder→elbow distance) as the radius of the arc the
/// shoulder sweeps through; asin clamps the degenerate case where the
/// numeric delta exceeds the segment length. Linear small-angle would
/// work too, but asin is monotonic at larger angles and defensible.
class CompensationDetector {
  /// Stable-resting-frame gate: elbow must be extended past this angle.
  /// Picks up the top-of-rep posture, filtering out mid-rep transitions.
  static const double _stableElbowAngleDeg = 150.0;

  /// Angular-velocity gate for stationary frames, in degrees per frame.
  /// A ~2°/frame cap at 30 fps equals 60°/s, well below the concentric
  /// transition rate of a bicep curl (~180°/s average). The value is a
  /// starting point — empirical tuning may be needed once we have bench
  /// sessions to calibrate against.
  static const double _stationaryElbowVelDegPerFrame = 2.0;

  /// Number of consecutive qualifying frames required before we accept a
  /// frame as "stable resting". Protects against single-frame jitter that
  /// momentarily satisfies both gates during a rapid transition. 3 frames
  /// ≈ 100 ms at 30 fps — short enough to capture brief natural holds,
  /// long enough to reject noise spikes.
  static const int _stableRunLength = 3;

  /// Build the per-session reference from the pooled calibration frames.
  ///
  /// Filters to stable resting frames (elbow > 150° AND |Δelbow| < 2°/frame
  /// for 3 consecutive frames), then averages shoulder-Y / torso pitch
  /// across those frames and computes the mean shoulder-to-elbow segment
  /// length for use as the shoulder-rise scale proxy.
  ///
  /// Falls back to a zero-drift baseline (with `armSegmentLen` null) if
  /// no qualifying frames landed — degraded lighting, very fast reps, or
  /// a user who never rested between calibration reps. Downstream
  /// threshold evaluations naturally no-op in that case since the peak
  /// deltas will all measure against a zero reference.
  static CompensationReference buildReference(
    List<List<PoseLandmark>> calibrationFrames,
    ArmSide side,
  ) {
    final stable = _stableRestingFrames(calibrationFrames, side);
    if (stable.isEmpty) {
      return CompensationReference(
        shoulderYRef: 0.0,
        torsoPitchDegRef: 0.0,
        armSide: side,
        armSegmentLen: null,
      );
    }

    var sumShoulderY = 0.0;
    var sumPitch = 0.0;
    var sumSegLen = 0.0;
    for (final frame in stable) {
      sumShoulderY += shoulderY(frame, side);
      sumPitch += torsoPitchDeg(frame);
      sumSegLen += _shoulderElbowLen(frame, side);
    }
    final n = stable.length;
    final meanSegLen = sumSegLen / n;
    return CompensationReference(
      shoulderYRef: sumShoulderY / n,
      torsoPitchDegRef: sumPitch / n,
      armSide: side,
      // Guard against a degenerate 0-length segment (collapsed landmarks)
      // by dropping to null, which forces downstream scaling to no-op.
      armSegmentLen: meanSegLen > 1e-6 ? meanSegLen : null,
    );
  }

  /// Walks the rep's pose frames once, computing per-frame signed deltas
  /// and tracking the signed peak of each signal.
  ///
  /// Returns:
  /// - `series`: per-frame deltas for the debrief chart and heatmap
  /// - `peakShoulderRiseDeg`: signed peak (positive = shoulder up)
  /// - `peakForwardLeanDeg`: signed peak (positive = leaned forward)
  ///
  /// Returns zero peaks on an empty frame list (defensive — the controller
  /// shouldn't call this with an empty rep, but a calibration rep with
  /// sparse pose coverage could race).
  static PerRepDeltas computePerRepDeltas(
    List<List<PoseLandmark>> frames,
    ArmSide side,
    CompensationReference reference,
  ) {
    if (frames.isEmpty) {
      return const PerRepDeltas(
        series: <PoseDelta>[],
        peakShoulderRiseDeg: 0.0,
        peakForwardLeanDeg: 0.0,
      );
    }

    final segLen = reference.armSegmentLen;
    final series = <PoseDelta>[];
    var minShoulderY = double.infinity;
    var maxPitchDeg = -double.infinity;

    for (final frame in frames) {
      final sY = shoulderY(frame, side);
      final pitch = torsoPitchDeg(frame);
      if (sY < minShoulderY) minShoulderY = sY;
      if (pitch > maxPitchDeg) maxPitchDeg = pitch;

      series.add(PoseDelta(
        shoulderDriftDeg: _yDeltaToDeg(reference.shoulderYRef - sY, segLen),
        torsoPitchDeltaDeg: pitch - reference.torsoPitchDegRef,
      ));
    }

    final peakShoulderRiseDeg =
        _yDeltaToDeg(reference.shoulderYRef - minShoulderY, segLen);
    final peakForwardLeanDeg = maxPitchDeg - reference.torsoPitchDegRef;

    return PerRepDeltas(
      series: series,
      peakShoulderRiseDeg: peakShoulderRiseDeg,
      peakForwardLeanDeg: peakForwardLeanDeg,
    );
  }

  // ---------- internal helpers ----------

  /// Filters the pooled calibration frames down to those captured while the
  /// user was holding a stable resting posture (elbow near extension, low
  /// angular velocity). Requires a run of at least [_stableRunLength]
  /// consecutive qualifying frames to accept the center frame.
  static List<List<PoseLandmark>> _stableRestingFrames(
    List<List<PoseLandmark>> frames,
    ArmSide side,
  ) {
    if (frames.isEmpty) return const <List<PoseLandmark>>[];
    final out = <List<PoseLandmark>>[];
    final angles = [for (final f in frames) elbowAngleDeg(f, side)];

    for (var i = 0; i < frames.length; i++) {
      if (angles[i] < _stableElbowAngleDeg) continue;
      // Check that this frame + enough neighbors form a stationary run.
      var run = 1;
      // Walk back.
      for (var j = i - 1;
          j >= 0 && run < _stableRunLength;
          j--) {
        if (angles[j] < _stableElbowAngleDeg) break;
        if ((angles[j] - angles[j + 1]).abs() >
            _stationaryElbowVelDegPerFrame) {
          break;
        }
        run++;
      }
      // Walk forward.
      for (var j = i + 1;
          j < frames.length && run < _stableRunLength;
          j++) {
        if (angles[j] < _stableElbowAngleDeg) break;
        if ((angles[j] - angles[j - 1]).abs() >
            _stationaryElbowVelDegPerFrame) {
          break;
        }
        run++;
      }
      if (run >= _stableRunLength) out.add(frames[i]);
    }
    return out;
  }

  /// Normalized shoulder-to-elbow distance for the curling arm. Used as
  /// the small-angle scale proxy when converting a shoulder-Y delta to
  /// degrees.
  static double _shoulderElbowLen(List<PoseLandmark> frame, ArmSide side) {
    final sIdx = side == ArmSide.left ? kLeftShoulder : kRightShoulder;
    final eIdx = side == ArmSide.left ? kLeftElbow : kRightElbow;
    final dx = frame[eIdx].x - frame[sIdx].x;
    final dy = frame[eIdx].y - frame[sIdx].y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Converts a normalized shoulder-Y delta (positive = shoulder higher in
  /// frame coordinates, i.e. moved UP) into approximate degrees of
  /// shoulder elevation using the calibration arm-segment length. Returns
  /// 0 when the segment length is unavailable (degenerate calibration
  /// reference) so the detector fails quiet rather than emitting huge
  /// false-positive peaks.
  static double _yDeltaToDeg(double yDelta, double? segLen) {
    if (segLen == null || segLen <= 0) return 0.0;
    final ratio = (yDelta / segLen).clamp(-1.0, 1.0);
    return math.asin(ratio) * 180.0 / math.pi;
  }
}
