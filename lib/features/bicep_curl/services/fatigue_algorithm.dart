import 'dart:math' as math;

import '../models/cue_decision.dart';
import '../models/cue_profile.dart';

/// The fatigue cue decision engine — pure function, zero side effects.
///
/// Inputs the per-rep peak history and the cue context; outputs zero or
/// one [CueDecision] for the current (latest) rep. The controller is
/// responsible for tracking [lastCueRep] across calls and dispatching the
/// returned decision through [CueDispatcher].
///
/// Behavior matches `haptic-cueing-handshake.md` §"The algorithm (data-backed v1)".
/// Calibration silence prevents false-early cues from button-timing noise;
/// the rolling-max baseline ratchets through the recruitment phase rather
/// than freezing too early on the noisy first few reps.
class FatigueAlgorithm {
  /// Evaluate the current rep against the algorithm. Returns null when no
  /// cue should fire.
  static CueDecision? evaluate({
    required List<double> peaks,
    required int currentRepNum,
    required int lastCueRep,
    required CueProfile profile,
    required bool compensationActive,
  }) {
    if (peaks.isEmpty) return null;
    if (currentRepNum <= profile.calibrationReps) return null;

    final windowStart =
        math.max(0, peaks.length - profile.baselineWindow);
    var baseline = peaks[windowStart];
    for (var i = windowStart + 1; i < peaks.length; i++) {
      if (peaks[i] > baseline) baseline = peaks[i];
    }
    if (baseline <= 0) return null;

    final drop = 1.0 - peaks.last / baseline;
    final t = profile.thresholds;

    // STOP overrides cooldown — past useful intervention; UI may auto-end.
    if (drop > t.stop) {
      return CueDecision(
        content: CueContent.fatigueStop,
        repNum: currentRepNum,
        meta: {'drop': drop, 'baseline': baseline},
      );
    }

    // Compensation overrides fatigue cues per haptic-cueing-handshake.md
    // §"Compensation-cue semantics for v0" — silent suppression in v0;
    // dispatcher handles the visual badge.
    if (compensationActive) {
      return CueDecision(
        content: CueContent.compensationDetected,
        repNum: currentRepNum,
        meta: {'drop': drop, 'baseline': baseline},
      );
    }

    if ((currentRepNum - lastCueRep) < profile.cooldownReps) return null;

    if (drop > t.urgent) {
      return CueDecision(
        content: CueContent.fatigueUrgent,
        repNum: currentRepNum,
        meta: {'drop': drop, 'baseline': baseline},
      );
    }
    if (drop > t.fade) {
      return CueDecision(
        content: CueContent.fatigueFade,
        repNum: currentRepNum,
        meta: {'drop': drop, 'baseline': baseline},
      );
    }

    return null;
  }
}
