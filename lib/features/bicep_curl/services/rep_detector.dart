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
    required this.side,
  });

  final int repNum;
  final int tStartUs;
  final int tPeakUs;
  final int tEndUs;

  /// Which arm fired this rep. Driven by whichever per-arm policy reached
  /// a valid RepComplete first — independent of the user's picker choice.
  final ArmSide side;
}

/// Runs one [RepDecisionPolicy] per arm in parallel and fans their events
/// onto broadcast streams. Detection is arm-agnostic: the user's picker
/// choice is no longer a single point of failure on MediaPipe's left/right
/// labeling. Bilateral (both-arm) curls are collapsed to one rep via a
/// short cross-arm debounce — the second arm's RepComplete inside that
/// window is dropped.
class RepDetector {
  RepDetector({RepDecisionPolicy Function()? policyFactory})
      : _leftPolicy = (policyFactory ?? ExtremaAmplitudeGatePolicy.bicepCurl)(),
        _rightPolicy =
            (policyFactory ?? ExtremaAmplitudeGatePolicy.bicepCurl)();

  final RepDecisionPolicy _leftPolicy;
  final RepDecisionPolicy _rightPolicy;

  final _controller = StreamController<RepBoundary>.broadcast();
  final _startController = StreamController<int>.broadcast();
  final _suppressedController =
      StreamController<RepSuppressedEvent>.broadcast();

  /// Collapse bilateral reps into one. If the *other* arm fires a
  /// RepComplete within this window of the first, the second is dropped.
  /// Same-arm consecutive reps are never debounced — the per-arm policy
  /// already enforces the minimum rep duration.
  static const int _crossArmDebounceUs = 500000;
  int _lastBoundaryUs = -1;
  ArmSide? _lastBoundarySide;

  Stream<RepBoundary> get boundaries => _controller.stream;
  Stream<int> get onRepStart => _startController.stream;

  /// Candidate reps dropped by a policy gate (short-ROM, momentum, stalled).
  /// Consumers use this for diagnostic logs and form-cue routing — the rep
  /// count is already protected from these by [boundaries] skipping them.
  Stream<RepSuppressedEvent> get suppressed => _suppressedController.stream;

  void addPoseFrame(int tUs, List<PoseLandmark> landmarks) {
    _feed(_leftPolicy, tUs, landmarks, ArmSide.left);
    _feed(_rightPolicy, tUs, landmarks, ArmSide.right);
  }

  void _feed(
    RepDecisionPolicy policy,
    int tUs,
    List<PoseLandmark> landmarks,
    ArmSide side,
  ) {
    final event = policy.feedFrame(tUs: tUs, landmarks: landmarks, side: side);
    if (event is RepStartedEvent) {
      _startController.add(event.tStartUs);
    } else if (event is RepCompleteEvent) {
      if (_lastBoundarySide != null &&
          _lastBoundarySide != side &&
          tUs - _lastBoundaryUs < _crossArmDebounceUs) {
        return;
      }
      _lastBoundaryUs = tUs;
      _lastBoundarySide = side;
      _controller.add(RepBoundary(
        repNum: event.repNum,
        tStartUs: event.tStartUs,
        tPeakUs: event.tBottomUs,
        tEndUs: event.tEndUs,
        side: side,
      ));
    } else if (event is RepSuppressedEvent) {
      _suppressedController.add(event);
    }
  }

  Future<void> dispose() async {
    _leftPolicy.reset();
    _rightPolicy.reset();
    await _startController.close();
    await _suppressedController.close();
    await _controller.close();
  }
}
