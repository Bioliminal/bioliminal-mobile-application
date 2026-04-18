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

  Map<String, dynamic> toJson() => {
        'rep_num': repNum,
        't_start_us': tStartUs,
        't_peak_us': tPeakUs,
        't_end_us': tEndUs,
        'peak_env': peakEnv,
        if (poseDelta != null) 'pose_delta': poseDelta!.toJson(),
      };

  factory RepRecord.fromJson(Map<String, dynamic> json) => RepRecord(
        repNum: json['rep_num'] as int,
        tStartUs: json['t_start_us'] as int,
        tPeakUs: json['t_peak_us'] as int,
        tEndUs: json['t_end_us'] as int,
        peakEnv: (json['peak_env'] as num).toDouble(),
        poseDelta: json['pose_delta'] != null
            ? PoseDelta.fromJson(json['pose_delta'] as Map<String, dynamic>)
            : null,
      );
}
