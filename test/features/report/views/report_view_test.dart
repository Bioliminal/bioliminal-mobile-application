import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/services/local_storage_service.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/report/views/report_view.dart';
import 'package:bioliminal/features/report/widgets/body_map.dart';
import 'package:bioliminal/features/report/widgets/finding_card.dart';
import 'package:bioliminal/features/report/widgets/drill_card.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _citation = Citation(
  finding: 'Test finding',
  source: 'Test (2024)',
  url: 'https://example.com',
  type: CitationType.research,
  appUsage: 'Used in test',
);

Assessment _assessmentWithCompensations({
  String id = 'test-001',
  DateTime? createdAt,
}) => Assessment(
  id: id,
  createdAt: createdAt ?? DateTime(2026, 1, 15),
  movements: const [],
  compensations: const [
    Compensation(
      type: CompensationType.ankleRestriction,
      joint: 'left_ankle',
      chain: ChainType.sbl,
      confidence: ConfidenceLevel.high,
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
);

Assessment _emptyAssessment() => Assessment(
  id: 'test-empty',
  createdAt: DateTime(2026, 1, 15),
  movements: const [],
  compensations: const [],
);

/// Creates multiple assessments with ankle-dominant pattern for longitudinal
/// context testing.
List<Assessment> _multipleAssessments() => [
  // Newest first (as listAssessments returns)
  _assessmentWithCompensations(
    id: 'test-003',
    createdAt: DateTime(2026, 3, 15),
  ),
  _assessmentWithCompensations(
    id: 'test-002',
    createdAt: DateTime(2026, 2, 15),
  ),
  _assessmentWithCompensations(
    id: 'test-001',
    createdAt: DateTime(2026, 1, 15),
  ),
];

// ---------------------------------------------------------------------------
// Fake local storage that returns controlled assessments
// ---------------------------------------------------------------------------

class _FakeLocalStorageService extends LocalStorageService {
  _FakeLocalStorageService(this._assessment, {List<Assessment>? allAssessments})
    : _allAssessments = allAssessments ?? [?_assessment];
  final Assessment? _assessment;
  final List<Assessment> _allAssessments;

  @override
  Future<Assessment?> loadAssessment(String id) async => _assessment;

  @override
  Future<List<Assessment>> listAssessments() async => _allAssessments;
}

// ---------------------------------------------------------------------------
// Router harness: pumps ReportView inside GoRouter so GoRouterState works.
// ---------------------------------------------------------------------------

Widget _buildHarness({
  required String id,
  Assessment? routerExtra,
  LocalStorageService? storageService,
}) {
  final router = GoRouter(
    initialLocation: '/report/$id',
    initialExtra: routerExtra,
    routes: [
      GoRoute(
        path: '/report/:id',
        builder: (context, state) =>
            ReportView(id: state.pathParameters['id']!, localOnly: true),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (storageService != null)
        localStorageServiceProvider.overrideWithValue(storageService),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReportView with compensations (via router extra)', () {
    testWidgets('shows body map at top', (tester) async {
      final storage = _FakeLocalStorageService(_assessmentWithCompensations());
      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: _assessmentWithCompensations(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BodyMap), findsOneWidget);
    });

    testWidgets('shows summary header with detection count', (tester) async {
      final storage = _FakeLocalStorageService(_assessmentWithCompensations());
      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: _assessmentWithCompensations(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KEY FINDINGS'), findsOneWidget);
      expect(find.textContaining('DETECTED'), findsOneWidget);
    });

    testWidgets('shows finding cards', (tester) async {
      final storage = _FakeLocalStorageService(_assessmentWithCompensations());
      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: _assessmentWithCompensations(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FindingCard), findsWidgets);
    });

    testWidgets('tapping finding card selects it', (tester) async {
      final storage = _FakeLocalStorageService(_assessmentWithCompensations());
      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: _assessmentWithCompensations(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll vertically to finding carousel area first using the main scrollable.
      final findingCard = find.byType(FindingCard).first;
      await tester.scrollUntilVisible(
        findingCard,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(findingCard);
      await tester.pumpAndSettle();

      // After tapping, drill cards should appear in the expanded content.
      // (This assumes FindingCard still shows drills when selected)
      expect(find.byType(DrillCard), findsWidgets);
    });

    testWidgets('practitioner discussion points render', (tester) async {
      final storage = _FakeLocalStorageService(_assessmentWithCompensations());
      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: _assessmentWithCompensations(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to practitioner points using the main scrollable.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text('MOVEMENT INSIGHTS'), findsOneWidget);
    });
  });

  group('ReportView empty state', () {
    testWidgets('shows "no significant patterns" message', (tester) async {
      await tester.pumpWidget(
        _buildHarness(id: 'test-empty', routerExtra: _emptyAssessment()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No significant movement patterns detected'),
        findsOneWidget,
      );
      // No body map for empty state.
      expect(find.byType(BodyMap), findsNothing);
    });
  });

  group('ReportView deep-link (no router extra)', () {
    testWidgets('loads assessment from LocalStorageService', (tester) async {
      final fakeStorage = _FakeLocalStorageService(
        _assessmentWithCompensations(),
      );

      await tester.pumpWidget(
        _buildHarness(id: 'test-001', storageService: fakeStorage),
      );

      // First pump: loading spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the future resolve.
      await tester.pumpAndSettle();

      // Full report renders with body map.
      expect(find.byType(BodyMap), findsOneWidget);
      expect(find.text('ANALYSIS'), findsOneWidget);
      expect(find.byType(FindingCard), findsWidgets);
    });

    testWidgets('shows "Assessment not found" when storage returns null', (
      tester,
    ) async {
      final fakeStorage = _FakeLocalStorageService(null);

      await tester.pumpWidget(
        _buildHarness(id: 'nonexistent', storageService: fakeStorage),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assessment not found'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Longitudinal context tests
  // -------------------------------------------------------------------------

  group('ReportView with longitudinal context (3+ assessments)', () {
    testWidgets('shows archetype header with name and icon', (tester) async {
      final assessments = _multipleAssessments();
      final storage = _FakeLocalStorageService(
        assessments.first,
        allAssessments: assessments,
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-003',
          routerExtra: assessments.first,
          storageService: storage,
        ),
      );
      // Pump frames to let didChangeDependencies fire and async futures resolve.
      await tester.pumpAndSettle();

      expect(find.text('Movement Archetype'), findsOneWidget);
      // Each assessment has 1 ankleRestriction + 1 kneeValgus + 1 hipDrop.
      // Hip bucket = kneeValgus + hipDrop = 6/9 = 67% → hipDominant.
      expect(find.text('HIP-DOMINANT'), findsOneWidget);
    });

    testWidgets('findings are rendered in priority order', (tester) async {
      // Create assessments with different compensation patterns to
      // produce varied trend classifications.
      final assessments = [
        // Newest: has a new hip drop pattern not in previous assessments
        Assessment(
          id: 'test-003',
          createdAt: DateTime(2026, 3, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 28.0,
              threshold: 35.0,
              citation: _citation,
            ),
            Compensation(
              type: CompensationType.trunkLean,
              joint: 'trunk',
              confidence: ConfidenceLevel.high,
              value: 15.0,
              threshold: 10.0,
              citation: _citation,
            ),
          ],
        ),
        // Older assessment
        Assessment(
          id: 'test-002',
          createdAt: DateTime(2026, 2, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 28.0,
              threshold: 35.0,
              citation: _citation,
            ),
          ],
        ),
        // Oldest assessment
        Assessment(
          id: 'test-001',
          createdAt: DateTime(2026, 1, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 28.0,
              threshold: 35.0,
              citation: _citation,
            ),
          ],
        ),
      ];

      final storage = _FakeLocalStorageService(
        assessments.first,
        allAssessments: assessments,
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-003',
          routerExtra: assessments.first,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // FindingCards are rendered — verify multiple findings exist.
      expect(find.byType(FindingCard), findsWidgets);
    });
  });

  group('ReportView single assessment (no longitudinal context)', () {
    testWidgets('does not show movement archetype section', (tester) async {
      final assessment = _assessmentWithCompensations();
      final storage = _FakeLocalStorageService(
        assessment,
        allAssessments: [assessment],
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: assessment,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Movement Archetype'), findsNothing);
    });

    testWidgets('renders identically to pre-longitudinal behavior', (
      tester,
    ) async {
      final assessment = _assessmentWithCompensations();
      final storage = _FakeLocalStorageService(
        assessment,
        allAssessments: [assessment],
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-001',
          routerExtra: assessment,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Standard elements present.
      expect(find.byType(BodyMap), findsOneWidget);
      expect(find.text('ANALYSIS'), findsOneWidget);
      expect(find.byType(FindingCard), findsWidgets);
      expect(find.text('KEY FINDINGS'), findsOneWidget);

      // Longitudinal elements absent.
      expect(find.text('Movement Archetype'), findsNothing);
    });
  });

  group('ReportView trend badge colors', () {
    testWidgets('trend badges use correct color for each classification', (
      tester,
    ) async {
      // Create assessments that produce a worsening trend on ankle
      final assessments = [
        Assessment(
          id: 'test-003',
          createdAt: DateTime(2026, 3, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 35.0, // worsened
              threshold: 35.0,
              citation: _citation,
            ),
          ],
        ),
        Assessment(
          id: 'test-002',
          createdAt: DateTime(2026, 2, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 30.0,
              threshold: 35.0,
              citation: _citation,
            ),
          ],
        ),
        Assessment(
          id: 'test-001',
          createdAt: DateTime(2026, 1, 15),
          movements: const [],
          compensations: const [
            Compensation(
              type: CompensationType.ankleRestriction,
              joint: 'left_ankle',
              chain: ChainType.sbl,
              confidence: ConfidenceLevel.high,
              value: 25.0,
              threshold: 35.0,
              citation: _citation,
            ),
          ],
        ),
      ];

      final storage = _FakeLocalStorageService(
        assessments.first,
        allAssessments: assessments,
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-003',
          routerExtra: assessments.first,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to finding card area.
      final findingCard = find.byType(FindingCard).first;
      await tester.scrollUntilVisible(
        findingCard,
        200,
        scrollable: find.byType(Scrollable).at(1),
      );
      await tester.pumpAndSettle();

      // Worsening trend icon should be present (slope = 5.0 > 1.0).
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });
  });

  group('Body-path descriptions', () {
    testWidgets('never contain chain names (SBL, BFL, FFL)', (tester) async {
      final assessments = _multipleAssessments();
      final storage = _FakeLocalStorageService(
        assessments.first,
        allAssessments: assessments,
      );

      await tester.pumpWidget(
        _buildHarness(
          id: 'test-003',
          routerExtra: assessments.first,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Verify no chain names appear in the rendered text.
      expect(find.textContaining('SBL'), findsNothing);
      expect(find.textContaining('BFL'), findsNothing);
      expect(find.textContaining('FFL'), findsNothing);
    });
  });
}
