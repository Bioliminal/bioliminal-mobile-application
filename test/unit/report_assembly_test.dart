import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/features/report/services/report_assembly_service.dart';

void main() {
  Assessment makeAssessment(List<Compensation> compensations) {
    return Assessment(
      id: 'test-001',
      createdAt: DateTime(2026, 4, 8),
      movements: const [],
      compensations: compensations,
    );
  }

  group('buildReport', () {
    test('empty compensations produces empty findings', () {
      final report = ReportAssemblyService.buildReport(makeAssessment([]));
      expect(report.findings, isEmpty);
      expect(report.practitionerPoints, isEmpty);
    });

    test('SBL chain compensations are grouped together', () {
      final compensations = [
        const Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
      ];

      final report = ReportAssemblyService.buildReport(makeAssessment(compensations));

      // Both compensations should be in one finding (same chain).
      expect(report.findings.length, 1);
      expect(report.findings.first.compensations.length, 2);
    });

    test('upstream driver identified for SBL chain', () {
      final compensations = [
        const Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
      ];

      final report = ReportAssemblyService.buildReport(makeAssessment(compensations));
      // SBL upstream driver is ankle.
      expect(report.findings.first.upstreamDriver, isNotNull);
      expect(report.findings.first.upstreamDriver, contains('ankle'));
    });

    test('findings include citations', () {
      final compensations = [
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
      ];

      final report = ReportAssemblyService.buildReport(makeAssessment(compensations));
      expect(report.findings.first.citations, isNotEmpty);
    });

    test('practitioner points generated for upstream driver findings', () {
      final compensations = [
        const Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: Citation(
            finding: 'test', source: 'test', url: 'http://test',
            type: CitationType.research, appUsage: 'test',
          ),
        ),
      ];

      final report = ReportAssemblyService.buildReport(makeAssessment(compensations));
      expect(report.practitionerPoints, isNotEmpty);
    });
  });

  group('overallConfidence', () {
    test('returns worst confidence across findings', () {
      final findings = [
        const Finding(
          bodyPathDescription: 'test',
          compensations: [
            Compensation(
              type: CompensationType.kneeValgus,
              joint: 'knee',
              chain: null,
              confidence: ConfidenceLevel.high,
              value: 15.0,
              threshold: 10.0,
              citation: Citation(
                finding: 'test', source: 'test', url: 'http://test',
                type: CitationType.research, appUsage: 'test',
              ),
            ),
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'ankle',
              chain: null,
              confidence: ConfidenceLevel.low,
              value: 7.0,
              threshold: 10.0,
              citation: Citation(
                finding: 'test', source: 'test', url: 'http://test',
                type: CitationType.research, appUsage: 'test',
              ),
            ),
          ],
          recommendation: 'test',
          citations: [],
        ),
      ];

      expect(ReportAssemblyService.overallConfidence(findings), ConfidenceLevel.low);
    });
  });
}
