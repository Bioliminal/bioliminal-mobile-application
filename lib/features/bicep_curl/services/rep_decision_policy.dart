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

/// Reason a candidate rep was dropped by a post-cycle gate (ROM, duration,
/// stalled state machine). Surfaces via [RepSuppressedEvent] for diagnostics
/// and downstream cue routing (short-ROM, momentum reps).
enum RepInvalidReason { shortRom, tooFast, stalled }

/// Emitted when the state machine reached the top of an ascent or auto-reset
/// but the candidate rep failed a gate. Carries enough context for a log
/// line and a form-cue decision. [tStartUs] is the rep-start timestamp;
/// [tEndUs] is when the gate fired.
class RepSuppressedEvent extends RepDecisionEvent {
  const RepSuppressedEvent({
    required this.reason,
    required this.tStartUs,
    required this.tEndUs,
    required this.amplitudeDeg,
    required this.durationUs,
  });

  final RepInvalidReason reason;
  final int tStartUs;
  final int tEndUs;

  /// Amplitude observed (start-to-bottom); 0 when the machine stalled
  /// without reaching a bottom.
  final double amplitudeDeg;

  /// Rep duration from start to gate-firing frame.
  final int durationUs;
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
    this.minValidRomDeg = 80.0,
    this.minRepDurationUs = 1000000,
    this.maxRepDurationUs = 10000000,
    this.minVisibility = 0.5,
  });

  factory ExtremaAmplitudeGatePolicy.bicepCurl() =>
      ExtremaAmplitudeGatePolicy(angleFn: elbowAngleDeg);

  final AngleFn angleFn;

  /// Jitter floor — amplitudes below this are silently dropped (noise, not
  /// a rep attempt). The validation gates below only apply once the
  /// candidate clears this floor.
  final double minAmplitudeDeg;
  final double armedAngleDeg;
  final double minDropToStartDeg;

  /// ROM gate (Aaron's compensation threshold — `bicep_short_rom` in
  /// `bicep.yaml`). Candidate reps that clear the jitter floor but fall
  /// below this threshold emit [RepSuppressedEvent] with
  /// [RepInvalidReason.shortRom] rather than [RepCompleteEvent].
  final double minValidRomDeg;

  /// Momentum gate (`bicep_momentum_bias`). Reps completed faster than
  /// this are suppressed as momentum-dominated.
  final int minRepDurationUs;

  /// Stalled-state gate. If the machine stays in descending or ascending
  /// longer than this without completing a rep, reset to armed and emit
  /// [RepSuppressedEvent] with [RepInvalidReason.stalled]. Prevents a
  /// tracking-lost session from freezing mid-rep forever.
  final int maxRepDurationUs;

  /// Skip frames where the tracked elbow landmark's visibility is below
  /// this threshold. State machine freezes — no phase transitions, no
  /// extrema updates — until visibility recovers.
  final double minVisibility;

  _Phase _phase = _Phase.armed;
  int _repNum = 0;
  int _tStartUs = 0;
  double _startAngle = 0.0;
  int _tBottomUs = 0;
  double _bottomAngle = 180.0;
  double _lastObservedAngle = 0.0;

  @override
  RepDecisionEvent? feedFrame({
    required int tUs,
    required List<PoseLandmark> landmarks,
    required ArmSide side,
  }) {
    final elbowIdx = side == ArmSide.left ? kLeftElbow : kRightElbow;
    if (landmarks[elbowIdx].visibility < minVisibility) {
      return null;
    }

    if (_phase != _Phase.armed &&
        tUs - _tStartUs > maxRepDurationUs) {
      final stalled = RepSuppressedEvent(
        reason: RepInvalidReason.stalled,
        tStartUs: _tStartUs,
        tEndUs: tUs,
        amplitudeDeg: _startAngle - _bottomAngle,
        durationUs: tUs - _tStartUs,
      );
      _resetCycle();
      return stalled;
    }

    final angle = angleFn(landmarks, side);
    switch (_phase) {
      case _Phase.armed:
        if (angle < armedAngleDeg - minDropToStartDeg) {
          _phase = _Phase.descending;
          _tStartUs = tUs;
          _startAngle = _lastObservedAngle;
          _tBottomUs = tUs;
          _bottomAngle = angle;
          return RepStartedEvent(tStartUs: tUs);
        }
        // Track peak armed angle — reflects the arm's resting/top position
        // before the rep begins rather than any mid-descent intermediate value.
        if (angle > _lastObservedAngle) _lastObservedAngle = angle;
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
          final durationUs = tUs - tStartSnapshot;
          _resetCycle();
          if (amplitude < minAmplitudeDeg) {
            // Below the jitter floor — not a rep attempt. Silent drop
            // matches historical behavior; no diagnostic surface needed.
            return null;
          }
          if (durationUs < minRepDurationUs) {
            return RepSuppressedEvent(
              reason: RepInvalidReason.tooFast,
              tStartUs: tStartSnapshot,
              tEndUs: tUs,
              amplitudeDeg: amplitude,
              durationUs: durationUs,
            );
          }
          if (amplitude < minValidRomDeg) {
            return RepSuppressedEvent(
              reason: RepInvalidReason.shortRom,
              tStartUs: tStartSnapshot,
              tEndUs: tUs,
              amplitudeDeg: amplitude,
              durationUs: durationUs,
            );
          }
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
  }

  void _resetCycle() {
    _phase = _Phase.armed;
    _bottomAngle = 180.0;
    _lastObservedAngle = 0.0;
  }

  @override
  void reset() {
    _phase = _Phase.armed;
    _repNum = 0;
    _tStartUs = 0;
    _startAngle = 0.0;
    _tBottomUs = 0;
    _bottomAngle = 180.0;
    _lastObservedAngle = 0.0;
  }
}

enum _Phase { armed, descending, ascending }
