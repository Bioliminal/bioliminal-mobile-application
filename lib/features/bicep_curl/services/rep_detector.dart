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
class RepDetector {
  RepDetector({this.armedThresholdDeg = 150.0, this.minDropToStartDeg = 10.0});

  /// Angle considered "fully extended" — armed for next rep.
  final double armedThresholdDeg;

  /// Required angle drop from extended to commit to a concentric phase
  /// (avoids false starts on small jitter).
  final double minDropToStartDeg;

  final _controller = StreamController<RepBoundary>.broadcast();
  Stream<RepBoundary> get boundaries => _controller.stream;

  _RepPhase _phase = _RepPhase.armed;
  int _repNum = 0;
  int _tStartUs = 0;
  int _tPeakUs = 0;
  double _minAngle = 180.0;

  /// Feed one pose frame. Time monotonic in microseconds.
  void addPoseFrame(int tUs, List<PoseLandmark> landmarks, ArmSide side) {
    final angle = elbowAngleDeg(landmarks, side);

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

  Future<void> dispose() async {
    await _controller.close();
  }
}
