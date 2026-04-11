import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/features/history/services/archetype_classifier.dart';

const _testCitation = Citation(
  finding: 'test',
  source: 'test',
  url: 'http://test',
  type: CitationType.research,
  appUsage: 'test',
);

Assessment _makeAssessment({
  required String id,
  required List<Compensation> compensations,
}) {
  return Assessment(
    id: id,
    createdAt: DateTime(2026, 1, 1),
    movements: const [],
    compensations: compensations,
  );
}

Compensation _makeCompensation(
  CompensationType type, {
  double value = 10.0,
  ChainType? chain,
}) {
  return Compensation(
    type: type,
    joint: 'test',
    chain: chain,
    confidence: ConfidenceLevel.high,
    value: value,
    threshold: 10.0,
    citation: _testCitation,
  );
}

void main() {
  group('ArchetypeClassifier.classify', () {
    test('returns balanced for empty assessment list', () {
      expect(ArchetypeClassifier.classify([]), MobilityArchetype.balanced);
    });

    test('returns balanced for single assessment', () {
      final assessment = _makeAssessment(
        id: 'a1',
        compensations: [_makeCompensation(CompensationType.ankleRestriction)],
      );

      expect(
        ArchetypeClassifier.classify([assessment]),
        MobilityArchetype.balanced,
      );
    });

    test('returns ankleDominant when ankleRestriction >= 40%', () {
      // Assessment 1: 2 ankle + 1 hip = 3
      // Assessment 2: 2 ankle = 2
      // Assessment 3: 1 ankle + 1 trunk = 2
      // Total: 7. Ankle = 5/7 = 71%.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.hipDrop),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.ankleRestriction),
          ],
        ),
        _makeAssessment(
          id: 'a3',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.trunkLean),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.ankleDominant,
      );
    });

    test('returns hipDominant when hipDrop + kneeValgus >= 40%', () {
      // Assessment 1: 1 hipDrop + 1 kneeValgus = 2
      // Assessment 2: 1 hipDrop + 1 ankle = 2
      // Total: 4. Hip bucket = 3/4 = 75%.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.hipDrop),
            _makeCompensation(CompensationType.kneeValgus),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.hipDrop),
            _makeCompensation(CompensationType.ankleRestriction),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.hipDominant,
      );
    });

    test('returns trunkDominant when trunkLean >= 40%', () {
      // Assessment 1: 2 trunk + 1 ankle = 3
      // Assessment 2: 2 trunk = 2
      // Total: 5. Trunk = 4/5 = 80%.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.trunkLean),
            _makeCompensation(CompensationType.trunkLean),
            _makeCompensation(CompensationType.ankleRestriction),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.trunkLean),
            _makeCompensation(CompensationType.trunkLean),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.trunkDominant,
      );
    });

    test('returns hypermobile when low-value chain-null compensations '
        'in >= 50% of assessments', () {
      // 3 of 4 assessments have a comp with value < 5 and chain == null.
      // 3/4 = 75% >= 50%.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction, value: 3.0),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.hipDrop, value: 3.0),
          ],
        ),
        _makeAssessment(
          id: 'a3',
          compensations: [
            _makeCompensation(CompensationType.trunkLean, value: 3.0),
          ],
        ),
        _makeAssessment(
          id: 'a4',
          compensations: [
            _makeCompensation(
              CompensationType.ankleRestriction,
              value: 12.0,
              chain: ChainType.sbl,
            ),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.hypermobile,
      );
    });

    test('returns balanced when no type reaches 40%', () {
      // Each assessment has 1 ankle, 1 hip, 1 trunk = even distribution.
      // Each bucket = 3/9 = 33%.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.hipDrop),
            _makeCompensation(CompensationType.trunkLean),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.hipDrop),
            _makeCompensation(CompensationType.trunkLean),
          ],
        ),
        _makeAssessment(
          id: 'a3',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction),
            _makeCompensation(CompensationType.hipDrop),
            _makeCompensation(CompensationType.trunkLean),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.balanced,
      );
    });

    test('hypermobility check takes priority over frequency', () {
      // All assessments have hypermobility indicators AND ankle dominance.
      // Hypermobility is checked first, so it wins.
      final assessments = [
        _makeAssessment(
          id: 'a1',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction, value: 3.0),
            _makeCompensation(CompensationType.ankleRestriction),
          ],
        ),
        _makeAssessment(
          id: 'a2',
          compensations: [
            _makeCompensation(CompensationType.ankleRestriction, value: 4.0),
            _makeCompensation(CompensationType.ankleRestriction),
          ],
        ),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.hypermobile,
      );
    });

    test('returns balanced for assessments with no compensations', () {
      final assessments = [
        _makeAssessment(id: 'a1', compensations: []),
        _makeAssessment(id: 'a2', compensations: []),
        _makeAssessment(id: 'a3', compensations: []),
      ];

      expect(
        ArchetypeClassifier.classify(assessments),
        MobilityArchetype.balanced,
      );
    });
  });
}
