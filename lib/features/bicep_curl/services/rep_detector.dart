import 'dart:async';

import '../../../domain/models.dart';
import '../models/compensation_reference.dart';
import 'pose_math.dart';

/// Pose-derived rep boundary. Emits when the elbow returns past the
/// "armed" threshold after completing a concentric → eccentric cycle.
class RepBoundary {
  const RepBoundary({
    required this.repNum,
    required this.tStartUs,
    required this.tPeakUs,
    required this.tEndUs,
  });

  final int repNum;
  final int tStartUs;
  final int tPeakUs;
  final int tEndUs;
}

enum _RepPhase { armed, concentric, eccentric }

/// Elbow-angle state machine for camera-driven rep counting.
///
/// Bicep curl extension is ~170°, peak contraction is ~30–60°. We arm
/// when the user's elbow is extended, latch the start of the concentric
/// phase when the angle starts dropping, track the minimum angle (peak
/// contraction) through the concentric, transition to eccentric when the
/// angle starts climbing past the minimum, and emit a boundary when the
/// arm returns to extended.
///
/// Hysteresis on the threshold edges prevents micro-jitter from
/// double-counting reps. Numbers are tuned for a typical bicep curl;
/// extreme tempo or partial-range reps may need calibration.
///
/// **Visibility gate:** frames where any of shoulder/elbow/wrist
/// landmark visibility is below `minVisibility` are dropped before
/// angle computation. Keeps MediaPipe jitter under occlusion from
/// producing spurious rep boundaries.
///
/// **Idle reset:** if no valid frame has advanced the state machine in
/// `maxIdleUs`, the detector resets to armed. Prevents a stuck mid-rep
/// state when tracking is lost entirely.
///
/// ROM + duration gates from the mobile brief §1 are deferred to a
/// follow-up PR that refactors the controller's clock injection so
/// integration tests can exercise the gates without real-time waits.
class RepDetector {
  RepDetector({
    this.armedThresholdDeg = 150.0,
    this.minDropToStartDeg = 10.0,
    this.minVisibility = 0.5,
    this.maxIdleUs = 10000000, // 10 s
  });

  /// Angle considered "fully extended" — armed for next rep.
  final double armedThresholdDeg;

  /// Required angle drop from extended to commit to a concentric phase
  /// (avoids false starts on small jitter).
  final double minDropToStartDeg;

  /// Minimum landmark visibility to accept a pose frame. Below this,
  /// the frame is dropped. MediaPipe docs put usable tracking at ≥ 0.5.
  final double minVisibility;

  /// If no valid frame advances the state in this long, reset to armed.
  /// Handles sustained tracking loss mid-rep.
  final int maxIdleUs;

  final _controller = StreamController<RepBoundary>.broadcast();
  Stream<RepBoundary> get boundaries => _controller.stream;

  _RepPhase _phase = _RepPhase.armed;
  int _repNum = 0;
  int _tStartUs = 0;
  int _tPeakUs = 0;
  int _tLastProgressUs = 0;
  double _minAngle = 180.0;

  /// Feed one pose frame. Time monotonic in microseconds.
  void addPoseFrame(int tUs, List<PoseLandmark> landmarks, ArmSide side) {
    // Visibility gate: drop frames where any elbow-triad landmark is
    // low-visibility rather than deriving a bad angle. State machine
    // freezes until visibility recovers.
    final shoulderIdx = side == ArmSide.left ? kLeftShoulder : kRightShoulder;
    final elbowIdx = side == ArmSide.left ? kLeftElbow : kRightElbow;
    final wristIdx = side == ArmSide.left ? kLeftWrist : kRightWrist;
    if (landmarks[shoulderIdx].visibility < minVisibility ||
        landmarks[elbowIdx].visibility < minVisibility ||
        landmarks[wristIdx].visibility < minVisibility) {
      _maybeResetOnIdle(tUs);
      return;
    }

    final angle = elbowAngleDeg(landmarks, side);
    _tLastProgressUs = tUs;

    switch (_phase) {
      case _RepPhase.armed:
        if (angle < armedThresholdDeg - minDropToStartDeg) {
          _phase = _RepPhase.concentric;
          _tStartUs = tUs;
          _minAngle = angle;
          _tPeakUs = tUs;
        }
        break;

      case _RepPhase.concentric:
        if (angle < _minAngle) {
          _minAngle = angle;
          _tPeakUs = tUs;
        } else if (angle > _minAngle + 5.0) {
          _phase = _RepPhase.eccentric;
        }
        break;

      case _RepPhase.eccentric:
        if (angle > armedThresholdDeg) {
          _repNum += 1;
          _controller.add(RepBoundary(
            repNum: _repNum,
            tStartUs: _tStartUs,
            tPeakUs: _tPeakUs,
            tEndUs: tUs,
          ));
          _phase = _RepPhase.armed;
          _minAngle = 180.0;
        } else if (angle < _minAngle) {
          // Dropped back into a deeper contraction without resetting —
          // treat as continuation of the same rep.
          _phase = _RepPhase.concentric;
          _minAngle = angle;
          _tPeakUs = tUs;
        }
        break;
    }
  }

  /// Reset from a non-armed phase when progress has stalled (visibility
  /// loss). Prevents a stuck state machine during sustained tracking loss.
  void _maybeResetOnIdle(int tUs) {
    if (_phase == _RepPhase.armed) return;
    if (_tLastProgressUs > 0 && tUs - _tLastProgressUs > maxIdleUs) {
      _phase = _RepPhase.armed;
      _minAngle = 180.0;
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
