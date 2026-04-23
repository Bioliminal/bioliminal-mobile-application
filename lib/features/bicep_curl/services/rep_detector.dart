import 'dart:async';

import '../../../domain/models.dart';
import '../models/compensation_reference.dart' show ArmSide;
import 'rep_decision_policy.dart';

export 'rep_decision_policy.dart' show RepSuppressedEvent, RepInvalidReason;

/// Boundary emitted by [RepDetector] when a rep completes.
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

/// Thin stream driver around a [RepDecisionPolicy]. Holds the policy lifecycle
/// and fans RepComplete events onto a broadcast stream. Decision logic lives
/// in the policy — swap the policy to change behavior (per-exercise).
class RepDetector {
  RepDetector({RepDecisionPolicy? policy})
      : _policy = policy ?? ExtremaAmplitudeGatePolicy.bicepCurl();

  final RepDecisionPolicy _policy;
  final _controller = StreamController<RepBoundary>.broadcast();
  final _startController = StreamController<int>.broadcast();
  final _suppressedController =
      StreamController<RepSuppressedEvent>.broadcast();

  Stream<RepBoundary> get boundaries => _controller.stream;
  Stream<int> get onRepStart => _startController.stream;

  /// Candidate reps dropped by a policy gate (short-ROM, momentum, stalled).
  /// Consumers use this for diagnostic logs and form-cue routing — the rep
  /// count is already protected from these by [boundaries] skipping them.
  Stream<RepSuppressedEvent> get suppressed => _suppressedController.stream;

  void addPoseFrame(int tUs, List<PoseLandmark> landmarks, ArmSide side) {
    final event = _policy.feedFrame(tUs: tUs, landmarks: landmarks, side: side);
    if (event is RepStartedEvent) {
      _startController.add(event.tStartUs);
    } else if (event is RepCompleteEvent) {
      _controller.add(RepBoundary(
        repNum: event.repNum,
        tStartUs: event.tStartUs,
        tPeakUs: event.tBottomUs,
        tEndUs: event.tEndUs,
      ));
    } else if (event is RepSuppressedEvent) {
      _suppressedController.add(event);
    }
  }

  Future<void> dispose() async {
    _policy.reset();
    await _startController.close();
    await _suppressedController.close();
    await _controller.close();
  }
}
