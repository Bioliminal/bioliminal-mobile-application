import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:auralink/core/providers.dart';
import 'package:auralink/core/services/local_storage_service.dart';
import 'package:auralink/domain/models.dart';
import 'package:auralink/features/history/views/history_view.dart';
import 'package:auralink/features/history/widgets/assessment_timeline.dart';

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

Widget _buildTestApp({
  required List<Assessment> assessments,
  String? lastNavigatedRoute,
}) {
  final List<String> navigatedRoutes = [];

  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryView(),
      ),
      GoRoute(
        path: '/screening',
        builder: (context, state) {
          navigatedRoutes.add('/screening');
          return const Scaffold(body: Text('Screening'));
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
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('HistoryView empty state', () {
    testWidgets('shows empty message and screening button when no assessments',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: []));
      await tester.pumpAndSettle();

      expect(
        find.text('Complete your first screening to start tracking progress'),
        findsOneWidget,
      );
      expect(find.text('Start Screening'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
    });

    testWidgets('empty state button navigates to /screening', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Screening'));
      await tester.pumpAndSettle();

      expect(find.text('Screening'), findsOneWidget);
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

    testWidgets('shows delta indicators with two assessments', (tester) async {
      final older = Assessment(
        id: 'assess-001',
        createdAt: DateTime(2026, 3, 1),
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

      final newer = Assessment(
        id: 'assess-002',
        createdAt: DateTime(2026, 4, 1),
        movements: const [],
        compensations: const [
          Compensation(
            type: CompensationType.kneeValgus,
            joint: 'knee',
            confidence: ConfidenceLevel.high,
            value: 10.0,
            threshold: 10.0,
            citation: _testCitation,
          ),
        ],
      );

      // Newest first — matches listAssessments() sort order.
      await tester.pumpWidget(_buildTestApp(assessments: [newer, older]));
      await tester.pumpAndSettle();

      // Delta indicator for the newer assessment comparing to older.
      expect(
        find.textContaining('14\u00B0 \u2192 10\u00B0'),
        findsOneWidget,
      );
      expect(find.textContaining('(improved)'), findsOneWidget);
    });

    testWidgets('tapping assessment navigates to report', (tester) async {
      await tester.pumpWidget(_buildTestApp(assessments: [singleAssessment]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apr 1, 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Report assess-001'), findsOneWidget);
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
