import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/features/report/services/report_assembly_service.dart';
import 'package:auralink/features/report/data/mobility_drills.dart';
import 'package:auralink/core/services/local_storage_service.dart';

const _testCitation = Citation(
  finding: 'test',
  source: 'test',
  url: 'http://test',
  type: CitationType.research,
  appUsage: 'test',
);

Assessment _makeAssessment(List<Compensation> compensations) {
  return Assessment(
    id: 'test-drill-001',
    createdAt: DateTime(2026, 4, 9),
    movements: const [],
    compensations: compensations,
  );
}

void main() {
  group('MobilityDrill model', () {
    test(
      'has required fields: name, targetArea, durationSeconds, steps, compensationType',
      () {
        const drill = MobilityDrill(
          name: 'Test Drill',
          targetArea: 'ankle',
          durationSeconds: 60,
          steps: ['Step 1', 'Step 2', 'Step 3'],
          compensationType: CompensationType.ankleRestriction,
        );

        expect(drill.name, 'Test Drill');
        expect(drill.targetArea, 'ankle');
        expect(drill.durationSeconds, 60);
        expect(drill.steps.length, 3);
        expect(drill.compensationType, CompensationType.ankleRestriction);
      },
    );
  });

  group('Drill content database', () {
    test('each CompensationType has at least 2 drills', () {
      for (final type in CompensationType.values) {
        final drills = mobilityDrillsByType[type];
        expect(drills, isNotNull, reason: '$type missing from drill map');
        expect(
          drills!.length,
          greaterThanOrEqualTo(2),
          reason: '$type has fewer than 2 drills',
        );
      }
    });

    test('each drill has 3-5 instruction steps', () {
      for (final entry in mobilityDrillsByType.entries) {
        for (final drill in entry.value) {
          expect(
            drill.steps.length,
            inInclusiveRange(3, 5),
            reason: '${drill.name} has ${drill.steps.length} steps',
          );
        }
      }
    });

    test('stability drills exist for hypermobility', () {
      expect(stabilityDrills.length, greaterThanOrEqualTo(2));
      for (final drill in stabilityDrills) {
        expect(
          drill.steps.length,
          inInclusiveRange(3, 5),
          reason: '${drill.name} has ${drill.steps.length} steps',
        );
      }
    });
  });

  group('Drill selection in buildReport', () {
    test('attaches 1-2 drills to each finding based on compensation type', () {
      final compensations = [
        const Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ];

      final report = ReportAssemblyService.buildReport(
        _makeAssessment(compensations),
      );

      expect(report.findings.length, 1);
      final drills = report.findings.first.drills;
      expect(drills.length, inInclusiveRange(1, 2));
      expect(drills.first.compensationType, CompensationType.hipDrop);
    });

    test('ankle restriction findings prioritize ankle-specific drills', () {
      final compensations = [
        const Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ];

      final report = ReportAssemblyService.buildReport(
        _makeAssessment(compensations),
      );

      final drills = report.findings.first.drills;
      expect(drills.length, 2);
      for (final drill in drills) {
        expect(drill.targetArea, 'ankle');
        expect(drill.compensationType, CompensationType.ankleRestriction);
      }
    });

    test('hypermobility findings get stability-focused drills', () {
      // Low valgus value with null chain triggers hypermobility indicator.
      final compensations = [
        const Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 3.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ];

      final report = ReportAssemblyService.buildReport(
        _makeAssessment(compensations),
      );

      final drills = report.findings.first.drills;
      expect(drills.length, 2);
      // Stability drills should match the ones from the stabilityDrills list.
      expect(drills.first.name, stabilityDrills.first.name);
      expect(drills.last.name, stabilityDrills.last.name);
    });

    test('trunk lean findings get core-targeted drills', () {
      final compensations = [
        const Compensation(
          type: CompensationType.trunkLean,
          joint: 'trunk',
          chain: null,
          confidence: ConfidenceLevel.medium,
          value: 12.0,
          threshold: 8.0,
          citation: _testCitation,
        ),
      ];

      final report = ReportAssemblyService.buildReport(
        _makeAssessment(compensations),
      );

      final drills = report.findings.first.drills;
      expect(drills.length, 2);
      expect(drills.first.compensationType, CompensationType.trunkLean);
    });

    test('Finding.drills defaults to empty list', () {
      const finding = Finding(
        bodyPathDescription: 'test',
        compensations: [],
        recommendation: 'test',
        citations: [],
      );

      expect(finding.drills, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Finding prioritization (story-1329)
  // -------------------------------------------------------------------------

  group('Finding prioritization with trendReport', () {
    test('assigns trendStatus to findings based on dominant compensation', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      const trendReport = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.hipDrop,
            joint: 'hip',
            trend: TrendClassification.worsening,
            values: [5.0, 7.0, 8.0],
            slope: 1.5,
          ),
        ],
      );

      final report = ReportAssemblyService.buildReport(
        assessment,
        trendReport: trendReport,
      );

      expect(report.findings.first.trendStatus, TrendClassification.worsening);
    });

    test('sorts findings by priority: worsening before stable', () {
      // Two separate chain groups → two findings.
      final assessment = _makeAssessment(const [
        // This one will be stable.
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        // This one will be worsening.
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      const trendReport = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.ankleRestriction,
            joint: 'ankle',
            trend: TrendClassification.stable,
            values: [7.0],
            slope: 0.0,
          ),
          CompensationTrend(
            compensationType: CompensationType.hipDrop,
            joint: 'hip',
            trend: TrendClassification.worsening,
            values: [5.0, 7.0, 8.0],
            slope: 1.5,
          ),
        ],
      );

      final report = ReportAssemblyService.buildReport(
        assessment,
        trendReport: trendReport,
      );

      expect(report.findings.length, 2);
      // Worsening (score 3) should come before stable (score 1).
      expect(report.findings[0].trendStatus, TrendClassification.worsening);
      expect(report.findings[1].trendStatus, TrendClassification.stable);
    });

    test('without trendReport preserves original finding order', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          chain: ChainType.sbl,
          confidence: ConfidenceLevel.medium,
          value: 7.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      final report = ReportAssemblyService.buildReport(assessment);

      expect(report.findings.length, 2);
      // Original order: SBL chain group first, then null-chain (hipDrop).
      expect(
        report.findings[0].compensations.first.type,
        CompensationType.ankleRestriction,
      );
      expect(
        report.findings[1].compensations.first.type,
        CompensationType.hipDrop,
      );
      // No trendStatus assigned.
      expect(report.findings[0].trendStatus, isNull);
      expect(report.findings[1].trendStatus, isNull);
    });

    test(
      'recurring detection: stable trend with 3+ data points scores higher than worsening',
      () {
        final assessment = _makeAssessment(const [
          // Worsening.
          Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            chain: null,
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
          // Stable with 3+ values → recurring (score 4).
          Compensation(
            type: CompensationType.trunkLean,
            joint: 'trunk',
            chain: ChainType.bfl,
            confidence: ConfidenceLevel.medium,
            value: 12.0,
            threshold: 8.0,
            citation: _testCitation,
          ),
        ]);

        const trendReport = TrendReport(
          trends: [
            CompensationTrend(
              compensationType: CompensationType.hipDrop,
              joint: 'hip',
              trend: TrendClassification.worsening,
              values: [5.0, 7.0, 8.0],
              slope: 1.5,
            ),
            CompensationTrend(
              compensationType: CompensationType.trunkLean,
              joint: 'trunk',
              trend: TrendClassification.stable,
              values: [12.0, 11.5, 12.0, 11.8],
              slope: 0.0,
            ),
          ],
        );

        final report = ReportAssemblyService.buildReport(
          assessment,
          trendReport: trendReport,
        );

        expect(report.findings.length, 2);
        // Recurring (score 4) should come before worsening (score 3).
        expect(
          report.findings[0].compensations.first.type,
          CompensationType.trunkLean,
        );
        expect(
          report.findings[1].compensations.first.type,
          CompensationType.hipDrop,
        );
      },
    );
  });

  group('Recommendation text evolution', () {
    test(
      'worsening finding recommendation starts with Priority: and mentions worsened',
      () {
        final assessment = _makeAssessment(const [
          Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            chain: null,
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ]);

        const trendReport = TrendReport(
          trends: [
            CompensationTrend(
              compensationType: CompensationType.hipDrop,
              joint: 'hip',
              trend: TrendClassification.worsening,
              values: [5.0, 7.0, 8.0],
              slope: 1.5,
            ),
          ],
        );

        final report = ReportAssemblyService.buildReport(
          assessment,
          trendReport: trendReport,
        );

        final rec = report.findings.first.recommendation;
        expect(rec, startsWith('Priority: '));
        expect(rec, contains('worsened since your last assessment'));
      },
    );

    test('improving finding recommendation mentions improving', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 3.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      const trendReport = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.hipDrop,
            joint: 'hip',
            trend: TrendClassification.improving,
            values: [8.0, 5.0, 3.0],
            slope: -2.5,
          ),
        ],
      );

      final report = ReportAssemblyService.buildReport(
        assessment,
        trendReport: trendReport,
      );

      final rec = report.findings.first.recommendation;
      expect(rec, contains('improving, keep up your current work'));
    });

    test('newPattern finding recommendation mentions new pattern', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.trunkLean,
          joint: 'trunk',
          chain: null,
          confidence: ConfidenceLevel.medium,
          value: 12.0,
          threshold: 8.0,
          citation: _testCitation,
        ),
      ]);

      const trendReport = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.trunkLean,
            joint: 'trunk',
            trend: TrendClassification.newPattern,
            values: [12.0],
            slope: 0.0,
          ),
        ],
      );

      final report = ReportAssemblyService.buildReport(
        assessment,
        trendReport: trendReport,
      );

      final rec = report.findings.first.recommendation;
      expect(rec, contains("new pattern we haven't seen before"));
    });

    test('stable finding recommendation is unchanged', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      // No trend report → stable/null behavior.
      final reportNoTrend = ReportAssemblyService.buildReport(assessment);
      final baseRec = reportNoTrend.findings.first.recommendation;

      const trendReport = TrendReport(
        trends: [
          CompensationTrend(
            compensationType: CompensationType.hipDrop,
            joint: 'hip',
            trend: TrendClassification.stable,
            values: [8.0],
            slope: 0.0,
          ),
        ],
      );

      final reportWithTrend = ReportAssemblyService.buildReport(
        assessment,
        trendReport: trendReport,
      );

      expect(reportWithTrend.findings.first.recommendation, baseRec);
    });
  });

  group('Archetype-targeted drill selection', () {
    test(
      'archetype hipDominant boosts hip drills for non-hip compensation',
      () {
        // Trunk lean compensation — normally gets core drills.
        final assessment = _makeAssessment(const [
          Compensation(
            type: CompensationType.trunkLean,
            joint: 'trunk',
            chain: null,
            confidence: ConfidenceLevel.medium,
            value: 12.0,
            threshold: 8.0,
            citation: _testCitation,
          ),
        ]);

        final report = ReportAssemblyService.buildReport(
          assessment,
          archetype: MobilityArchetype.hipDominant,
        );

        final drills = report.findings.first.drills;
        expect(drills.length, 2);
        // First drill should be hip-targeted.
        expect(drills.first.compensationType, CompensationType.hipDrop);
      },
    );

    test(
      'archetype ankleDominant boosts ankle drills for non-ankle compensation',
      () {
        final assessment = _makeAssessment(const [
          Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            chain: null,
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ]);

        final report = ReportAssemblyService.buildReport(
          assessment,
          archetype: MobilityArchetype.ankleDominant,
        );

        final drills = report.findings.first.drills;
        expect(drills.length, 2);
        // First drill should be ankle-targeted.
        expect(
          drills.first.compensationType,
          CompensationType.ankleRestriction,
        );
      },
    );

    test(
      'archetype hypermobile returns stability drills regardless of compensation type',
      () {
        final assessment = _makeAssessment(const [
          Compensation(
            type: CompensationType.hipDrop,
            joint: 'hip',
            chain: null,
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _testCitation,
          ),
        ]);

        final report = ReportAssemblyService.buildReport(
          assessment,
          archetype: MobilityArchetype.hypermobile,
        );

        final drills = report.findings.first.drills;
        expect(drills.length, 2);
        expect(drills.first.name, stabilityDrills.first.name);
        expect(drills.last.name, stabilityDrills.last.name);
      },
    );

    test('archetype null uses default drill selection logic', () {
      final assessment = _makeAssessment(const [
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          chain: null,
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
      ]);

      final report = ReportAssemblyService.buildReport(assessment);

      final drills = report.findings.first.drills;
      expect(drills.length, inInclusiveRange(1, 2));
      expect(drills.first.compensationType, CompensationType.hipDrop);
    });
  });

  group('Drill serialization', () {
    test('round-trip: finding with drills serializes and deserializes', () {
      const report = Report(
        findings: [
          Finding(
            bodyPathDescription: 'Test path',
            compensations: [],
            upstreamDriver: 'ankle restriction',
            recommendation: 'Test recommendation',
            citations: [],
            drills: [
              MobilityDrill(
                name: 'Ankle Circles',
                targetArea: 'ankle',
                durationSeconds: 60,
                steps: ['Step 1', 'Step 2', 'Step 3'],
                compensationType: CompensationType.ankleRestriction,
              ),
            ],
          ),
        ],
        practitionerPoints: [],
      );

      final json = reportToJson(report);
      final restored = reportFromJson(json);

      expect(restored.findings.first.drills.length, 1);
      final drill = restored.findings.first.drills.first;
      expect(drill.name, 'Ankle Circles');
      expect(drill.targetArea, 'ankle');
      expect(drill.durationSeconds, 60);
      expect(drill.steps, ['Step 1', 'Step 2', 'Step 3']);
      expect(drill.compensationType, CompensationType.ankleRestriction);
    });

    test('backward compat: missing drills key returns empty list', () {
      // Simulate JSON from an old assessment without drills.
      final oldJson = {
        'bodyPathDescription': 'Old finding',
        'compensations': <dynamic>[],
        'upstreamDriver': null,
        'recommendation': 'Old recommendation',
        'citations': <dynamic>[],
        // No 'drills' key.
      };

      final reportJson = {
        'findings': [oldJson],
        'practitionerPoints': <dynamic>[],
        'pdfUrl': null,
      };

      final restored = reportFromJson(reportJson);
      expect(restored.findings.first.drills, isEmpty);
    });

    test('full assessment round-trip with drills', () {
      final assessment = Assessment(
        id: 'drill-rt-001',
        createdAt: DateTime(2026, 4, 9),
        movements: const [],
        compensations: const [
          Compensation(
            type: CompensationType.ankleRestriction,
            joint: 'ankle',
            chain: ChainType.sbl,
            confidence: ConfidenceLevel.medium,
            value: 7.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
        report: const Report(
          findings: [
            Finding(
              bodyPathDescription: 'Test',
              compensations: [],
              recommendation: 'Test',
              citations: [],
              drills: [
                MobilityDrill(
                  name: 'Wall Ankle Mobilization',
                  targetArea: 'ankle',
                  durationSeconds: 90,
                  steps: ['Step A', 'Step B', 'Step C', 'Step D'],
                  compensationType: CompensationType.ankleRestriction,
                ),
              ],
            ),
          ],
          practitionerPoints: [],
        ),
      );

      final json = assessmentToJson(assessment);
      final jsonStr = jsonEncode(json);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = assessmentFromJson(decoded);

      expect(restored.report!.findings.first.drills.length, 1);
      expect(
        restored.report!.findings.first.drills.first.name,
        'Wall Ankle Mobilization',
      );
      expect(restored.report!.findings.first.drills.first.steps.length, 4);
    });
  });
}
