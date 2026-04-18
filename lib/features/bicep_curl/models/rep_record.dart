import 'pose_delta.dart';

/// Per-rep summary written when the rep detector emits a boundary and the
/// controller harvests the peak envelope value across the rep window.
class RepRecord {
  const RepRecord({
    required this.repNum,
    required this.tStartUs,
    required this.tPeakUs,
    required this.tEndUs,
    required this.peakEnv,
    this.poseDelta,
  });

  final int repNum;
  final int tStartUs;
  final int tPeakUs;
  final int tEndUs;

  /// Max of the software-derived envelope (rectified RAW + 4th-order
  /// Butterworth LP @ 5 Hz) across the rep window.
  final double peakEnv;

  /// Pose drift from the calibration reference. Null during calibration
  /// (no reference yet) and when the rep arrived without sufficient
  /// pose-frame coverage (e.g., user briefly out of frame).
  final PoseDelta? poseDelta;

  Duration get duration =>
      Duration(microseconds: tEndUs - tStartUs);
}
