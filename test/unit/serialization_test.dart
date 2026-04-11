import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/core/services/local_storage_service.dart';

void main() {
  group('Assessment round-trip', () {
    test('assessmentToJson → assessmentFromJson preserves all fields', () {
      final original = Assessment(
        id: 'test-rt-001',
        createdAt: DateTime(2026, 4, 8, 12, 30),
        movements: const [
          Movement(
            type: MovementType.overheadSquat,
            landmarks: [
              [
                Landmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.95),
                Landmark(x: 0.6, y: 0.4, z: 0.1, visibility: 0.8),
              ],
            ],
            keyframeAngles: [
              JointAngle(
                joint: 'left_knee_valgus',
                angleDegrees: 15.0,
                confidence: ConfidenceLevel.high,
              ),
            ],
            duration: Duration(seconds: 45),
          ),
        ],
        compensations: [
          const Compensation(
            type: CompensationType.kneeValgus,
            joint: 'knee',
            chain: ChainType.sbl,
            confidence: ConfidenceLevel.high,
            value: 15.0,
            threshold: 10.0,
            citation: Citation(
              finding: 'Knee valgus test',
              source: 'Test Source',
              url: 'https://example.com',
              type: CitationType.research,
              appUsage: 'Test usage',
            ),
          ),
        ],
      );

      final json = assessmentToJson(original);
      final restored = assessmentFromJson(json);

      expect(restored.id, original.id);
      expect(
        restored.createdAt.toIso8601String(),
        original.createdAt.toIso8601String(),
      );
      expect(restored.movements.length, original.movements.length);
      expect(restored.movements.first.type, MovementType.overheadSquat);
      expect(restored.movements.first.landmarks.first.length, 2);
      expect(
        restored.movements.first.keyframeAngles.first.joint,
        'left_knee_valgus',
      );
      expect(restored.movements.first.duration.inSeconds, 45);
      expect(restored.compensations.length, 1);
      expect(restored.compensations.first.type, CompensationType.kneeValgus);
      expect(restored.compensations.first.chain, ChainType.sbl);
      expect(restored.compensations.first.citation.source, 'Test Source');
    });

    test('null report in assessment round-trips', () {
      final original = Assessment(
        id: 'test-null-report',
        createdAt: DateTime(2026, 1, 1),
        movements: const [],
        compensations: const [],
        report: null,
      );

      final json = assessmentToJson(original);
      final restored = assessmentFromJson(json);

      expect(restored.report, isNull);
    });

    test('assessment with report round-trips', () {
      final original = Assessment(
        id: 'test-with-report',
        createdAt: DateTime(2026, 1, 1),
        movements: const [],
        compensations: const [],
        report: const Report(
          findings: [],
          practitionerPoints: ['Point 1', 'Point 2'],
          pdfUrl: null,
        ),
      );

      final json = assessmentToJson(original);
      final restored = assessmentFromJson(json);

      expect(restored.report, isNotNull);
      expect(restored.report!.practitionerPoints.length, 2);
      expect(restored.report!.pdfUrl, isNull);
    });
  });

  group('Report round-trip', () {
    test('reportToJson → reportFromJson preserves all fields', () {
      const original = Report(
        findings: [
          Finding(
            bodyPathDescription: 'Test path',
            compensations: [],
            upstreamDriver: 'ankle restriction',
            recommendation: 'Test recommendation',
            citations: [
              Citation(
                finding: 'Test finding',
                source: 'Test source',
                url: 'https://example.com',
                type: CitationType.clinical,
                appUsage: 'Test usage',
              ),
            ],
          ),
        ],
        practitionerPoints: ['Ask about ankle'],
        pdfUrl: 'https://storage.example.com/report.pdf',
      );

      final json = reportToJson(original);
      final restored = reportFromJson(json);

      expect(restored.findings.length, 1);
      expect(restored.findings.first.bodyPathDescription, 'Test path');
      expect(restored.findings.first.upstreamDriver, 'ankle restriction');
      expect(
        restored.findings.first.citations.first.type,
        CitationType.clinical,
      );
      expect(restored.practitionerPoints.first, 'Ask about ankle');
      expect(restored.pdfUrl, 'https://storage.example.com/report.pdf');
    });

    test('null chain in compensation round-trips', () {
      final json = assessmentToJson(
        Assessment(
          id: 'null-chain',
          createdAt: DateTime(2026, 1, 1),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.kneeValgus,
              joint: 'knee',
              chain: null,
              confidence: ConfidenceLevel.medium,
              value: 12.0,
              threshold: 10.0,
              citation: Citation(
                finding: 'test',
                source: 'test',
                url: 'http://test',
                type: CitationType.research,
                appUsage: 'test',
              ),
            ),
          ],
        ),
      );

      final restored = assessmentFromJson(json);
      expect(restored.compensations.first.chain, isNull);
    });

    test('enum serialization uses name', () {
      final json = assessmentToJson(
        Assessment(
          id: 'enum-test',
          createdAt: DateTime(2026, 1, 1),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.hipDrop,
              joint: 'hip',
              chain: ChainType.bfl,
              confidence: ConfidenceLevel.low,
              value: 12.0,
              threshold: 10.0,
              citation: Citation(
                finding: 'test',
                source: 'test',
                url: 'http://test',
                type: CitationType.guideline,
                appUsage: 'test',
              ),
            ),
          ],
        ),
      );

      // Check that enums are serialized by name.
      final comp =
          (json['compensations'] as List).first as Map<String, dynamic>;
      expect(comp['type'], 'hipDrop');
      expect(comp['chain'], 'bfl');
      expect(comp['confidence'], 'low');
    });
  });
}
