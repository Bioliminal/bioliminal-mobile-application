import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/history/services/trend_detection_service.dart';

const _testCitation = Citation(
  finding: 'test',
  source: 'test',
  url: 'http://test',
  type: CitationType.research,
  appUsage: 'test',
);

Assessment _makeAssessment({
  required String id,
  required DateTime date,
  required List<Compensation> compensations,
}) {
  return Assessment(
    id: id,
    createdAt: date,
    movements: const [],
    compensations: compensations,
  );
}

Compensation _comp(CompensationType type, String joint, double value) {
  return Compensation(
    type: type,
    joint: joint,
    confidence: ConfidenceLevel.high,
    value: value,
    threshold: 10.0,
    citation: _testCitation,
  );
}

void main() {
  group('TrendDetectionService.analyzeTrends', () {
    test('empty assessment list returns empty TrendReport', () {
      final report = TrendDetectionService.analyzeTrends([]);
      expect(report.trends, isEmpty);
    });

    test('single assessment classifies all compensations as stable', () {
      final assessment = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          _comp(CompensationType.kneeValgus, 'left knee', 12.0),
          _comp(CompensationType.hipDrop, 'hip', 8.0),
        ],
      );

      // listAssessments returns newest-first; single item is trivially that.
      final report = TrendDetectionService.analyzeTrends([assessment]);

      expect(report.trends.length, 2);
      for (final trend in report.trends) {
        expect(trend.trend, TrendClassification.stable);
        expect(trend.slope, 0.0);
      }
    });

    test('two assessments with decreasing value classifies as improving', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'left knee', 14.0)],
      );
      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'left knee', 10.0)],
      );

      // newest-first ordering (as from listAssessments).
      final report = TrendDetectionService.analyzeTrends([newer, older]);

      final trend = report.trends.first;
      expect(trend.trend, TrendClassification.improving);
      // slope = (10 - 14) / (2 - 1) = -4.0
      expect(trend.slope, -4.0);
      expect(trend.values, [14.0, 10.0]);
    });

    test('two assessments with increasing value classifies as worsening', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.hipDrop, 'hip', 5.0)],
      );
      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [_comp(CompensationType.hipDrop, 'hip', 9.0)],
      );

      final report = TrendDetectionService.analyzeTrends([newer, older]);

      final trend = report.trends.first;
      expect(trend.trend, TrendClassification.worsening);
      // slope = (9 - 5) / 1 = 4.0
      expect(trend.slope, 4.0);
    });

    test('two assessments with same value classifies as stable', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.trunkLean, 'trunk', 7.0)],
      );
      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [_comp(CompensationType.trunkLean, 'trunk', 7.0)],
      );

      final report = TrendDetectionService.analyzeTrends([newer, older]);

      final trend = report.trends.first;
      expect(trend.trend, TrendClassification.stable);
      expect(trend.slope, 0.0);
    });

    test('compensation only in newest assessment classifies as newPattern', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'left knee', 12.0)],
      );
      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          _comp(CompensationType.kneeValgus, 'left knee', 10.0),
          // This type+joint only appears in the newest assessment.
          _comp(CompensationType.ankleRestriction, 'right ankle', 6.0),
        ],
      );

      final report = TrendDetectionService.analyzeTrends([newer, older]);

      final newTrend = report.trendFor(
        CompensationType.ankleRestriction,
        'right ankle',
      );
      expect(newTrend, isNotNull);
      expect(newTrend!.trend, TrendClassification.newPattern);
      expect(newTrend.slope, 0.0);
    });

    test('three assessments uses slope from oldest to newest', () {
      // Values: 10 -> 14 -> 8. Slope = (8 - 10) / (3 - 1) = -1.0
      // abs(-1.0) < 1.0 is false, slope < 0 => improving
      final a1 = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 1, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'knee', 10.0)],
      );
      final a2 = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 2, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'knee', 14.0)],
      );
      final a3 = _makeAssessment(
        id: 'a3',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.kneeValgus, 'knee', 8.0)],
      );

      // newest-first ordering.
      final report = TrendDetectionService.analyzeTrends([a3, a2, a1]);

      final trend = report.trends.first;
      expect(trend.slope, -1.0);
      expect(trend.trend, TrendClassification.improving);
      expect(trend.values, [10.0, 14.0, 8.0]);
    });

    test('stable threshold: slope.abs() < 1.0 is stable', () {
      // Values: 10 -> 10.5. Slope = 0.5, abs < 1.0 => stable.
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [_comp(CompensationType.hipDrop, 'hip', 10.0)],
      );
      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [_comp(CompensationType.hipDrop, 'hip', 10.5)],
      );

      final report = TrendDetectionService.analyzeTrends([newer, older]);

      final trend = report.trends.first;
      expect(trend.slope, 0.5);
      expect(trend.trend, TrendClassification.stable);
    });
  });

  group('TrendReport.trendFor', () {
    test('returns matching CompensationTrend', () {
      const report = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.kneeValgus,
            joint: 'left knee',
            trend: TrendClassification.improving,
            values: [14.0, 10.0],
            slope: -4.0,
          ),
          CompensationTrend(
            compensationType: CompensationType.hipDrop,
            joint: 'hip',
            trend: TrendClassification.stable,
            values: [8.0, 8.0],
            slope: 0.0,
          ),
        ],
      );

      final result = report.trendFor(CompensationType.hipDrop, 'hip');
      expect(result, isNotNull);
      expect(result!.trend, TrendClassification.stable);
      expect(result.slope, 0.0);
    });

    test('returns null for missing type+joint', () {
      const report = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.kneeValgus,
            joint: 'left knee',
            trend: TrendClassification.improving,
            values: [14.0, 10.0],
            slope: -4.0,
          ),
        ],
      );

      final result = report.trendFor(
        CompensationType.ankleRestriction,
        'right ankle',
      );
      expect(result, isNull);
    });
  });

  group('Finding.trendStatus', () {
    test('defaults to null for backward compatibility', () {
      const finding = Finding(
        bodyPathDescription: 'test path',
        compensations: [],
        recommendation: 'test rec',
        citations: [],
      );
      expect(finding.trendStatus, isNull);
    });

    test('accepts a TrendClassification value', () {
      const finding = Finding(
        bodyPathDescription: 'test path',
        compensations: [],
        recommendation: 'test rec',
        citations: [],
        trendStatus: TrendClassification.improving,
      );
      expect(finding.trendStatus, TrendClassification.improving);
    });
  });
}
