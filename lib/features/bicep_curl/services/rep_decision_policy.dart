import 'dart:math' as math;

import '../../../domain/models.dart';
import '../models/compensation_reference.dart' show ArmSide;
import 'pose_math.dart';

typedef AngleFn = double Function(List<PoseLandmark> frame, ArmSide side);

sealed class RepDecisionEvent {
  const RepDecisionEvent();
}

class RepStartedEvent extends RepDecisionEvent {
  const RepStartedEvent({required this.tStartUs});
  final int tStartUs;
}

class RepCompleteEvent extends RepDecisionEvent {
  const RepCompleteEvent({
    required this.repNum,
    required this.tStartUs,
    required this.tBottomUs,
    required this.tEndUs,
    required this.startAngle,
    required this.bottomAngle,
    required this.endAngle,
  });

  final int repNum;
  final int tStartUs;
  final int tBottomUs;
  final int tEndUs;
  final double startAngle;
  final double bottomAngle;
  final double endAngle;
}

abstract class RepDecisionPolicy {
  RepDecisionEvent? feedFrame({
    required int tUs,
    required List<PoseLandmark> landmarks,
    required ArmSide side,
  });

  void reset();
}

class ExtremaAmplitudeGatePolicy implements RepDecisionPolicy {
  ExtremaAmplitudeGatePolicy({
    required this.angleFn,
    this.minAmplitudeDeg = 30.0,
    this.armedAngleDeg = 150.0,
    this.minDropToStartDeg = 20.0,
  });

  factory ExtremaAmplitudeGatePolicy.bicepCurl() =>
      ExtremaAmplitudeGatePolicy(angleFn: elbowAngleDeg);

  final AngleFn angleFn;
  final double minAmplitudeDeg;
  final double armedAngleDeg;
  final double minDropToStartDeg;

  _Phase _phase = _Phase.armed;
  int _repNum = 0;
  int _tStartUs = 0;
  double _startAngle = 0.0;
  int _tBottomUs = 0;
  double _bottomAngle = 180.0;

  @override
  RepDecisionEvent? feedFrame({
    required int tUs,
    required List<PoseLandmark> landmarks,
    required ArmSide side,
  }) {
    final angle = angleFn(landmarks, side);
    switch (_phase) {
      case _Phase.armed:
        if (angle < armedAngleDeg - minDropToStartDeg) {
          _phase = _Phase.descending;
          _tStartUs = tUs;
          _startAngle = armedAngleDeg;
          _tBottomUs = tUs;
          _bottomAngle = angle;
          return RepStartedEvent(tStartUs: tUs);
        }
        return null;
      case _Phase.descending:
        if (angle < _bottomAngle) {
          _bottomAngle = angle;
          _tBottomUs = tUs;
          return null;
        }
        if (angle > _bottomAngle + 5.0) {
          _phase = _Phase.ascending;
        }
        return null;
      case _Phase.ascending:
        if (angle < _bottomAngle) {
          _bottomAngle = angle;
          _tBottomUs = tUs;
          _phase = _Phase.descending;
          return null;
        }
        if (angle >= armedAngleDeg) {
          final amplitude = math.max(_startAngle, angle) - _bottomAngle;
          final startSnapshot = _startAngle;
          final bottomSnapshot = _bottomAngle;
          final tBottomSnapshot = _tBottomUs;
          final tStartSnapshot = _tStartUs;
          _phase = _Phase.armed;
          _bottomAngle = 180.0;
          if (amplitude >= minAmplitudeDeg) {
            _repNum += 1;
            return RepCompleteEvent(
              repNum: _repNum,
              tStartUs: tStartSnapshot,
              tBottomUs: tBottomSnapshot,
              tEndUs: tUs,
              startAngle: startSnapshot,
              bottomAngle: bottomSnapshot,
              endAngle: angle,
            );
          }
          return null;
        }
        return null;
    }
  }

  @override
  void reset() {
    _phase = _Phase.armed;
    _repNum = 0;
    _tStartUs = 0;
    _startAngle = 0.0;
    _tBottomUs = 0;
    _bottomAngle = 180.0;
  }
}

enum _Phase { armed, descending, ascending }
