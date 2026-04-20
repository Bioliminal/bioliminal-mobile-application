import 'dart:async';

import '../../../domain/models.dart';
import '../models/compensation_reference.dart' show ArmSide;
import 'rep_decision_policy.dart';

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
  Stream<RepBoundary> get boundaries => _controller.stream;

  void addPoseFrame(int tUs, List<PoseLandmark> landmarks, ArmSide side) {
    final event = _policy.feedFrame(tUs: tUs, landmarks: landmarks, side: side);
    if (event is RepCompleteEvent) {
      _controller.add(RepBoundary(
        repNum: event.repNum,
        tStartUs: event.tStartUs,
        tPeakUs: event.tBottomUs,
        tEndUs: event.tEndUs,
      ));
    }
  }

  Future<void> dispose() async {
    _policy.reset();
    await _controller.close();
  }
}
