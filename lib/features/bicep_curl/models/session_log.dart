import 'compensation_reference.dart';
import 'cue_event.dart';
import 'cue_profile.dart';
import 'rep_record.dart';

/// Snapshot of a completed (or aborted) bicep curl session. Bound to the
/// debrief view; persisted via SessionRecord (see commit 7).
class SessionLog {
  const SessionLog({
    required this.reps,
    required this.cueEvents,
    required this.ref,
    required this.startedAt,
    required this.duration,
    required this.profile,
    required this.armSide,
    required this.bleDroppedDuringSet,
  });

  final List<RepRecord> reps;
  final List<CueEvent> cueEvents;
  final CompensationReference? ref;
  final DateTime startedAt;
  final Duration duration;
  final CueProfile profile;
  final ArmSide armSide;

  /// True when the BLE link dropped at any point during the active set —
  /// surfaces in the debrief as "EMG offline from rep N".
  final bool bleDroppedDuringSet;

  List<double> get peaks => [for (final r in reps) r.peakEnv];

  /// Per-rep rolling-max baseline used by the algorithm. Useful for the
  /// debrief's chart overlay so the user can see *why* a cue fired.
  List<double> baselineTrajectory(int window) {
    final out = <double>[];
    for (var i = 0; i < reps.length; i++) {
      final start = i < window ? 0 : i - window + 1;
      var maxV = reps[start].peakEnv;
      for (var j = start + 1; j <= i; j++) {
        if (reps[j].peakEnv > maxV) maxV = reps[j].peakEnv;
      }
      out.add(maxV);
    }
    return out;
  }

  /// Percentage of reps with no compensation event (`poseDelta == null` or
  /// within thresholds). Returns 100 for an empty set.
  double get formScore {
    if (reps.isEmpty) return 100.0;
    final clean = reps.where((r) {
      final d = r.poseDelta;
      return d == null || !d.exceedsThresholds(profile.compensation);
    }).length;
    return (clean / reps.length) * 100.0;
  }
}
