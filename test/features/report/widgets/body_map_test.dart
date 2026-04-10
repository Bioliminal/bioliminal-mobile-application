import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/features/report/widgets/body_map.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _citation = Citation(
  finding: 'Test finding',
  source: 'Test (2024)',
  url: 'https://example.com',
  type: CitationType.research,
  appUsage: 'Used in test',
);

List<Finding> _sblFindings() => const [
      Finding(
        bodyPathDescription:
            'Your ankle, knee, and hip compensate together along your back body',
        compensations: [
          Compensation(
            type: CompensationType.ankleRestriction,
            joint: 'left_ankle',
            chain: ChainType.sbl,
            confidence: ConfidenceLevel.medium,
            value: 28.0,
            threshold: 35.0,
            citation: _citation,
          ),
          Compensation(
            type: CompensationType.kneeValgus,
            joint: 'left_knee',
            chain: ChainType.sbl,
            confidence: ConfidenceLevel.high,
            value: 12.0,
            threshold: 10.0,
            citation: _citation,
          ),
          Compensation(
            type: CompensationType.hipDrop,
            joint: 'left_hip',
            chain: ChainType.sbl,
            confidence: ConfidenceLevel.high,
            value: 8.0,
            threshold: 5.0,
            citation: _citation,
          ),
        ],
        upstreamDriver: 'left_ankle ankle restriction',
        recommendation: 'Prioritize ankle and hip mobility work',
        citations: [_citation],
        drills: [
          MobilityDrill(
            name: 'Ankle Circles',
            targetArea: 'ankle',
            durationSeconds: 60,
            compensationType: CompensationType.ankleRestriction,
            steps: ['Step 1', 'Step 2'],
          ),
        ],
      ),
    ];

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BodyMap', () {
    testWidgets('renders CustomPaint with findings', (tester) async {
      await tester.pumpWidget(_wrap(
        BodyMap(findings: _sblFindings()),
      ));

      expect(find.byType(BodyMap), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with empty findings list', (tester) async {
      await tester.pumpWidget(_wrap(
        const BodyMap(findings: []),
      ));

      expect(find.byType(BodyMap), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('onRegionTap fires when tapping a joint region',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(_wrap(
        BodyMap(
          findings: _sblFindings(),
          onRegionTap: (i) => tappedIndex = i,
        ),
      ));

      // Tap at normalized position for left_ankle (0.38, 0.92).
      // The GestureDetector wraps a SizedBox with width=size.width
      // and height=width*1.4. We tap within that area.
      final gestureFinder = find.byType(GestureDetector);
      final gestureBox =
          tester.renderObject(gestureFinder.first) as RenderBox;
      final gestureSize = gestureBox.size;

      final tapX = gestureSize.width * 0.38;
      final tapY = gestureSize.height * 0.92;

      await tester.tapAt(gestureBox.localToGlobal(Offset(tapX, tapY)));
      await tester.pump();

      expect(tappedIndex, 0);
    });

    testWidgets('tapping outside regions does not fire callback',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(_wrap(
        BodyMap(
          findings: _sblFindings(),
          onRegionTap: (i) => tappedIndex = i,
        ),
      ));

      // Tap at head area (0.5, 0.1) — no compensation region there.
      final gestureFinder = find.byType(GestureDetector);
      final gestureBox =
          tester.renderObject(gestureFinder.first) as RenderBox;
      final gestureSize = gestureBox.size;

      final tapX = gestureSize.width * 0.50;
      final tapY = gestureSize.height * 0.10;

      await tester.tapAt(gestureBox.localToGlobal(Offset(tapX, tapY)));
      await tester.pump();

      expect(tappedIndex, isNull);
    });

    testWidgets('selectedFindingIndex updates repaint', (tester) async {
      await tester.pumpWidget(_wrap(
        BodyMap(
          findings: _sblFindings(),
          selectedFindingIndex: 0,
        ),
      ));

      // No assertion beyond "it renders without error" when selection is set.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('multiple findings with different chains render',
        (tester) async {
      final findings = [
        ..._sblFindings(),
        const Finding(
          bodyPathDescription:
              'Your shoulder and opposite hip are connected through your back',
          compensations: [
            Compensation(
              type: CompensationType.trunkLean,
              joint: 'left_shoulder',
              chain: ChainType.bfl,
              confidence: ConfidenceLevel.high,
              value: 15.0,
              threshold: 10.0,
              citation: _citation,
            ),
            Compensation(
              type: CompensationType.hipDrop,
              joint: 'right_hip',
              chain: ChainType.bfl,
              confidence: ConfidenceLevel.medium,
              value: 7.0,
              threshold: 5.0,
              citation: _citation,
            ),
          ],
          upstreamDriver: 'left_shoulder trunk lean',
          recommendation: 'Discuss this pattern with a movement professional',
          citations: [_citation],
        ),
      ];

      await tester.pumpWidget(_wrap(
        BodyMap(findings: findings),
      ));

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
