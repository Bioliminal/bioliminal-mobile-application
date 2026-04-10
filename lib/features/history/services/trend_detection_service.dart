import '../../../domain/models.dart';

class TrendDetectionService {
  TrendDetectionService._();

  static TrendReport analyzeTrends(List<Assessment> assessments) {
    if (assessments.isEmpty) {
      return const TrendReport(trends: []);
    }

    // listAssessments returns newest-first; reverse to oldest-first.
    final chronological = assessments.reversed.toList();
    final newestIndex = chronological.length - 1;

    // Group compensation values by (type, joint) in chronological order.
    final groups = <(CompensationType, String), List<double>>{};
    // Track which keys appear only in the newest assessment.
    final allIndices = <(CompensationType, String), Set<int>>{};

    for (var i = 0; i < chronological.length; i++) {
      for (final comp in chronological[i].compensations) {
        final key = (comp.type, comp.joint);
        groups.putIfAbsent(key, () => []).add(comp.value);
        allIndices.putIfAbsent(key, () => {}).add(i);
      }
    }

    final trends = <CompensationTrend>[];

    for (final entry in groups.entries) {
      final key = entry.key;
      final values = entry.value;
      final indices = allIndices[key]!;

      TrendClassification classification;
      double slope;

      if (values.length == 1) {
        // Single data point.
        final onlyInNewest =
            indices.length == 1 &&
            indices.first == newestIndex &&
            chronological.length > 1;
        if (onlyInNewest) {
          classification = TrendClassification.newPattern;
          slope = 0.0;
        } else {
          classification = TrendClassification.stable;
          slope = 0.0;
        }
      } else {
        slope = (values.last - values.first) / (values.length - 1);
        if (slope.abs() < 1.0) {
          classification = TrendClassification.stable;
        } else if (slope < 0) {
          classification = TrendClassification.improving;
        } else {
          classification = TrendClassification.worsening;
        }
      }

      trends.add(CompensationTrend(
        compensationType: key.$1,
        joint: key.$2,
        trend: classification,
        values: values,
        slope: slope,
      ));
    }

    return TrendReport(trends: trends);
  }
}
