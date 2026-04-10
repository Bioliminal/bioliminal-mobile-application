import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/core/theme.dart';
import 'package:auralink/domain/models.dart';
import 'package:auralink/features/history/widgets/assessment_timeline.dart';

const _testCitation = Citation(
  finding: 'test',
  source: 'test',
  url: 'http://test',
  type: CitationType.research,
  appUsage: 'test',
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('AssessmentTimeline delta chips', () {
    final older = Assessment(
      id: 'assess-001',
      createdAt: DateTime(2026, 3, 1),
      movements: const [],
      compensations: const [
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          confidence: ConfidenceLevel.high,
          value: 15.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          confidence: ConfidenceLevel.high,
          value: 14.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          confidence: ConfidenceLevel.medium,
          value: 5.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.trunkLean,
          joint: 'trunk',
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ],
    );

    final newer = Assessment(
      id: 'assess-002',
      createdAt: DateTime(2026, 4, 1),
      movements: const [],
      compensations: const [
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          confidence: ConfidenceLevel.high,
          value: 10.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          confidence: ConfidenceLevel.high,
          value: 18.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.hipDrop,
          joint: 'hip',
          confidence: ConfidenceLevel.medium,
          value: 5.0,
          threshold: 5.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.trunkLean,
          joint: 'trunk',
          confidence: ConfidenceLevel.high,
          value: 12.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ],
    );

    testWidgets('displays body-path labels instead of compensation type names',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer, older],
          onTap: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Body-path labels should appear.
      expect(find.text('Ankle flexibility'), findsOneWidget);
      expect(find.text('Knee alignment'), findsOneWidget);
      expect(find.text('Pelvic level'), findsOneWidget);
      expect(find.text('Torso balance'), findsOneWidget);

      // Raw compensation type names should NOT appear.
      expect(find.text('ankleRestriction'), findsNothing);
      expect(find.text('kneeValgus'), findsNothing);
      expect(find.text('hipDrop'), findsNothing);
      expect(find.text('trunkLean'), findsNothing);
    });

    testWidgets('delta chips show trend arrow icons', (tester) async {
      final trendReport = TrendReport(trends: [
        CompensationTrend(
          compensationType: CompensationType.ankleRestriction,
          joint: 'ankle',
          trend: TrendClassification.improving,
          values: [15.0, 10.0],
          slope: -5.0,
        ),
        CompensationTrend(
          compensationType: CompensationType.kneeValgus,
          joint: 'knee',
          trend: TrendClassification.worsening,
          values: [14.0, 18.0],
          slope: 4.0,
        ),
        CompensationTrend(
          compensationType: CompensationType.hipDrop,
          joint: 'hip',
          trend: TrendClassification.stable,
          values: [5.0, 5.0],
          slope: 0.0,
        ),
        CompensationTrend(
          compensationType: CompensationType.trunkLean,
          joint: 'trunk',
          trend: TrendClassification.worsening,
          values: [8.0, 12.0],
          slope: 4.0,
        ),
      ]);

      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer, older],
          trendReport: trendReport,
          onTap: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Improving gets trending_down, worsening gets trending_up,
      // stable gets trending_flat.
      expect(find.byIcon(Icons.trending_down), findsWidgets);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
      expect(find.byIcon(Icons.trending_flat), findsWidgets);
    });

    testWidgets('delta chips are color-coded by trend', (tester) async {
      final trendReport = TrendReport(trends: [
        CompensationTrend(
          compensationType: CompensationType.ankleRestriction,
          joint: 'ankle',
          trend: TrendClassification.improving,
          values: [15.0, 10.0],
          slope: -5.0,
        ),
      ]);

      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer, older],
          trendReport: trendReport,
          onTap: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Find the chip container for "Ankle flexibility".
      final chipFinder = find.ancestor(
        of: find.text('Ankle flexibility'),
        matching: find.byType(Container),
      );
      expect(chipFinder, findsWidgets);

      // Verify the chip's container has a green-tinted background (improving).
      final container = tester.widget<Container>(chipFinder.first);
      final decoration = container.decoration as BoxDecoration;
      // The chip background uses confidenceHigh (green) at 10% alpha.
      expect(
        decoration.color,
        AuraLinkTheme.confidenceHigh.withValues(alpha: 0.1),
      );
    });

    testWidgets('delta chips show delta values', (tester) async {
      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer, older],
          onTap: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Ankle: |10 - 15| = 5
      expect(find.text('5\u00B0'), findsOneWidget);
      // Knee: |18 - 14| = 4
      expect(find.text('4\u00B0'), findsOneWidget);
      // Hip: |5 - 5| = 0
      expect(find.text('0\u00B0'), findsOneWidget);
      // Trunk: |12 - 8| = 4 (second 4° — total 2)
      expect(find.text('4\u00B0'), findsNWidgets(2));
    });

    testWidgets('tap on timeline node fires callback', (tester) async {
      Assessment? tapped;

      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer],
          onTap: (a) => tapped = a,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apr 1, 2026'));
      expect(tapped?.id, 'assess-002');
    });
  });

  group('AssessmentTimeline without trend report', () {
    testWidgets('falls back to pairwise trend classification', (tester) async {
      final older = Assessment(
        id: 'a1',
        createdAt: DateTime(2026, 3, 1),
        movements: const [],
        compensations: const [
          Compensation(
            type: CompensationType.ankleRestriction,
            joint: 'ankle',
            confidence: ConfidenceLevel.high,
            value: 15.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      final newer = Assessment(
        id: 'a2',
        createdAt: DateTime(2026, 4, 1),
        movements: const [],
        compensations: const [
          Compensation(
            type: CompensationType.ankleRestriction,
            joint: 'ankle',
            confidence: ConfidenceLevel.high,
            value: 10.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      // No trendReport passed — should still render delta chips.
      await tester.pumpWidget(_wrap(
        AssessmentTimeline(
          assessments: [newer, older],
          onTap: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ankle flexibility'), findsOneWidget);
      // Improving -> trending_down icon.
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });
  });
}
