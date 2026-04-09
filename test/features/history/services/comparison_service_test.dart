import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/features/history/services/comparison_service.dart';

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

void main() {
  group('ComparisonService.compare', () {
    test('matches compensations by type and joint', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'left knee',
            confidence: ConfidenceLevel.high,
            value: 14.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'left knee',
            confidence: ConfidenceLevel.high,
            value: 10.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics.length, 1);
      expect(metrics.first.joint, 'left knee');
      expect(metrics.first.compensationType, CompensationType.kneeValgus);
      expect(metrics.first.oldValue, 14.0);
      expect(metrics.first.newValue, 10.0);
      expect(metrics.first.delta, -4.0);
      expect(metrics.first.improved, isTrue);
    });

    test('returns empty list when no matching compensations', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          const Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'knee',
            confidence: ConfidenceLevel.high,
            value: 12.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics, isEmpty);
    });

    test('marks worsened when new value is higher', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          const Compensation(
            type: CompensationType.trunkLean,
            joint: 'trunk',
            confidence: ConfidenceLevel.medium,
            value: 6.0,
            threshold: 8.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          const Compensation(
            type: CompensationType.trunkLean,
            joint: 'trunk',
            confidence: ConfidenceLevel.medium,
            value: 10.0,
            threshold: 8.0,
            citation: _testCitation,
          ),
        ],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics.length, 1);
      expect(metrics.first.delta, 4.0);
      expect(metrics.first.improved, isFalse);
    });

    test('compares multiple compensations across assessments', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'knee',
            confidence: ConfidenceLevel.high,
            value: 14.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
          const Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'knee',
            confidence: ConfidenceLevel.high,
            value: 10.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
          const Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            confidence: ConfidenceLevel.high,
            value: 6.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics.length, 2);
      expect(metrics[0].improved, isTrue);
      expect(metrics[1].improved, isTrue);
    });

    test('only matches same joint for same type', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'left knee',
            confidence: ConfidenceLevel.high,
            value: 14.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'right knee',
            confidence: ConfidenceLevel.high,
            value: 10.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics, isEmpty);
    });

    test('returns empty for assessments with no compensations', () {
      final older = _makeAssessment(
        id: 'a1',
        date: DateTime(2026, 3, 1),
        compensations: [],
      );

      final newer = _makeAssessment(
        id: 'a2',
        date: DateTime(2026, 4, 1),
        compensations: [],
      );

      final metrics = ComparisonService.compare(older, newer);
      expect(metrics, isEmpty);
    });
  });

  group('ComparisonService.readableType', () {
    test('returns body-path language for each type', () {
      expect(
        ComparisonService.readableType(CompensationType.kneeValgus),
        'Knee valgus',
      );
      expect(
        ComparisonService.readableType(CompensationType.hipDrop),
        'Hip drop',
      );
      expect(
        ComparisonService.readableType(CompensationType.ankleRestriction),
        'Ankle restriction',
      );
      expect(
        ComparisonService.readableType(CompensationType.trunkLean),
        'Trunk lean',
      );
    });
  });
}
