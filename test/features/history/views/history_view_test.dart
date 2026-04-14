import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/services/local_storage_service.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/history/views/history_view.dart';
import 'package:bioliminal/features/history/widgets/assessment_timeline.dart';

const _testCitation = Citation(
  finding: 'test',
  source: 'test',
  url: 'http://test',
  type: CitationType.research,
  appUsage: 'test',
);

class _FakeLocalStorageService extends LocalStorageService {
  _FakeLocalStorageService(this._assessments);

  final List<Assessment> _assessments;

  @override
  Future<List<Assessment>> listAssessments() async => _assessments;
}

Widget _buildTestApp({required List<Assessment> assessments}) {
  final List<String> navigatedRoutes = [];

  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryView(),
      ),
      GoRoute(
        path: '/hardware-setup',
        builder: (context, state) {
          navigatedRoutes.add('/hardware-setup');
          return const Scaffold(body: Text('Hardware Setup'));
        },
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          navigatedRoutes.add('/report/${state.pathParameters['id']}');
          return Scaffold(body: Text('Report ${state.pathParameters['id']}'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(
        _FakeLocalStorageService(assessments),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Three assessments with ankle-dominant compensations for archetype/trend tests.
List<Assessment> _threeAssessments() {
  return [
    // Newest first (matches listAssessments sort order).
    Assessment(
      id: 'assess-003',
      createdAt: DateTime(2026, 4, 15),
      movements: const [],
      compensations: const [
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          confidence: ConfidenceLevel.high,
          value: 8.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          confidence: ConfidenceLevel.high,
          value: 12.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ],
    ),
    Assessment(
      id: 'assess-002',
      createdAt: DateTime(2026, 4, 1),
      movements: const [],
      compensations: const [
        Compensation(
          type: CompensationType.ankleRestriction,
          joint: 'ankle',
          confidence: ConfidenceLevel.medium,
          value: 12.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
        Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          confidence: ConfidenceLevel.high,
          value: 13.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ],
    ),
    Assessment(
      id: 'assess-001',
      createdAt: DateTime(2026, 3, 15),
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
      ],
    ),
  ];
}

void main() {
  group('HistoryView empty state', () {
    testWidgets(
      'shows empty message and screening button when no assessments',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(assessments: []));
        await tester.pumpAndSettle();

        expect(
          find.text('Complete your first screening to start tracking progress'),
          findsOneWidget,
        );
        expect(find.text('Start Screening'), findsOneWidget);
        expect(find.byIcon(Icons.timeline), findsOneWidget);
      },
    );

    testWidgets('empty state button navigates to /hardware-setup', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Screening'));
      await tester.pumpAndSettle();

      expect(find.text('Hardware Setup'), findsOneWidget);
    });
  });

  group('HistoryView populated state', () {
    final singleAssessment = Assessment(
      id: 'assess-001',
      createdAt: DateTime(2026, 4, 1),
      movements: const [],
      compensations: const [
        Compensation(
          type: CompensationType.kneeValgus,
          joint: 'knee',
          confidence: ConfidenceLevel.high,
          value: 14.0,
          threshold: 10.0,
          citation: _testCitation,
        ),
      ],
    );

    testWidgets('shows timeline with one assessment', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: [singleAssessment]));
      await tester.pumpAndSettle();

      expect(find.byType(AssessmentTimeline), findsOneWidget);
      expect(find.text('Apr 1, 2026'), findsOneWidget);
      expect(find.text('1 finding'), findsOneWidget);
    });

    testWidgets('tapping assessment navigates to report', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: [singleAssessment]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apr 1, 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Report assess-001'), findsOneWidget);
    });
  });

  group('HistoryView summary header', () {
    testWidgets('shows archetype hero with 3+ assessments', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: _threeAssessments()));
      await tester.pumpAndSettle();

      // Ankle-dominant because ankle compensations appear in all 3.
      // Now in uppercase hero text.
      expect(find.text('ANKLE-DOMINANT'), findsOneWidget);
      expect(find.text('CURRENT PROFILE'), findsOneWidget);
    });

    testWidgets('shows trend grid with 3+ assessments', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: _threeAssessments()));
      await tester.pumpAndSettle();

      // Ankle: 15 -> 12 -> 8, slope = -3.5, improving
      // Knee: 14 -> 13 -> 12, slope = -1.0, improving
      // Both improving.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('IMPROVING'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
      expect(find.text('REGRESSING'), findsOneWidget);
    });

    testWidgets('does not show summary header for empty state', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: []));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT PROFILE'), findsNothing);
      expect(find.text('IMPROVING'), findsNothing);
    });

    testWidgets('shows Balanced hero with single assessment', (tester) async {
      final single = Assessment(
        id: 'assess-001',
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

      await tester.pumpWidget(_buildTestApp(assessments: [single]));
      await tester.pumpAndSettle();

      // Single assessment -> ArchetypeClassifier returns balanced.
      expect(find.text('BALANCED'), findsOneWidget);
    });
  });

  group('HistoryView confidence badges', () {
    testWidgets('shows confidence badge per assessment', (tester) async {
      final assessment = Assessment(
        id: 'assess-low',
        createdAt: DateTime(2026, 4, 5),
        movements: const [],
        compensations: const [
          Compensation(
            type: CompensationType.ankleRestriction,
            joint: 'ankle',
            confidence: ConfidenceLevel.low,
            value: 7.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(assessments: [assessment]));
      await tester.pumpAndSettle();

      expect(find.text('Low'), findsOneWidget);
    });
  });
}
