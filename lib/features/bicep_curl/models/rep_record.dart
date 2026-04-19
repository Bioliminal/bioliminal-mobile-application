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
    this.envelopeSamples,
  });

  final int repNum;
  final int tStartUs;
  final int tPeakUs;
  final int tEndUs;

  /// Max of the software-derived envelope (rectified RAW + 4th-order IIR LP;
  /// see envelope_derivator.dart for the filter-characterization note).
  final double peakEnv;

  /// Pose drift from the calibration reference. Null during calibration
  /// (no reference yet) and when the rep arrived without sufficient
  /// pose-frame coverage (e.g., user briefly out of frame).
  final PoseDelta? poseDelta;

  /// 50 evenly-spaced envelope samples across the rep window, used by the
  /// debrief heatmap to animate within-rep dynamics. Null on sessions
  /// saved before the continuous-heatmap commit; debrief falls back to
  /// a synthetic half-sine peaked at the middle in that case.
  final List<double>? envelopeSamples;

  Duration get duration =>
      Duration(microseconds: tEndUs - tStartUs);

  Map<String, dynamic> toJson() => {
        'rep_num': repNum,
        't_start_us': tStartUs,
        't_peak_us': tPeakUs,
        't_end_us': tEndUs,
        'peak_env': peakEnv,
        if (poseDelta != null) 'pose_delta': poseDelta!.toJson(),
        if (envelopeSamples != null) 'envelope_samples': envelopeSamples,
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
        envelopeSamples: json['envelope_samples'] != null
            ? [
                for (final v in json['envelope_samples'] as List)
                  (v as num).toDouble(),
              ]
            : null,
      );
}
