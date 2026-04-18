import 'cue_profile.dart';

/// Per-rep pose drift from the calibration reference. Field names use
/// degrees for the whole pipeline; the shoulder figure is approximated
/// from a normalized y-pixel delta in v0 (frame-relative, not true
/// geometric degrees) — good enough at typical phone-tripod framing for
/// the 5–9° threshold band the algorithm cares about. Promote to true
/// geometry if a future calibration step gives us a forearm-length proxy.
class PoseDelta {
  const PoseDelta({
    required this.shoulderDriftDeg,
    required this.torsoPitchDeltaDeg,
  });

  final double shoulderDriftDeg;
  final double torsoPitchDeltaDeg;

  bool exceedsThresholds(CompensationThresholds thresholds) =>
      shoulderDriftDeg.abs() > thresholds.shoulderDriftDeg ||
      torsoPitchDeltaDeg.abs() > thresholds.torsoPitchDeltaDeg;
}
