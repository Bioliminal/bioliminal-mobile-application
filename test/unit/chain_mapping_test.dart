import 'package:flutter_test/flutter_test.dart';

import 'package:auralink/domain/models.dart';
import 'package:auralink/domain/services/rule_based_angle_calculator.dart';
import 'package:auralink/domain/services/rule_based_chain_mapper.dart';

void main() {
  late RuleBasedChainMapper mapper;

  setUp(() {
    mapper = RuleBasedChainMapper();
  });

  List<JointAngle> anglesFor(CompensationProfile profile) {
    final calc = RuleBasedAngleCalculator(profile: profile);
    // Build landmarks with specific visibility to test confidence propagation.
    final landmarks = List.generate(
      33,
      (_) => const PoseLandmark(
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.95,
        presence: 0.95,
      ),
    );
    return calc.calculateAngles(landmarks);
  }

  group('SBL pattern', () {
    test('produces ankle + knee + hip compensations on SBL chain', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.sblPattern),
      );

      expect(compensations, isNotEmpty);
      expect(
        compensations.any(
          (c) =>
              c.type == CompensationType.ankleRestriction &&
              c.chain == ChainType.sbl,
        ),
        isTrue,
      );
      expect(
        compensations.any(
          (c) =>
              c.type == CompensationType.kneeValgus && c.chain == ChainType.sbl,
        ),
        isTrue,
      );
      expect(
        compensations.any(
          (c) => c.type == CompensationType.hipDrop && c.chain == ChainType.sbl,
        ),
        isTrue,
      );
    });

    test('ankle findings never get high confidence', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.sblPattern),
      );
      final ankleFindings = compensations.where(
        (c) => c.type == CompensationType.ankleRestriction,
      );

      for (final finding in ankleFindings) {
        expect(finding.confidence, isNot(ConfidenceLevel.high));
      }
    });
  });

  group('BFL pattern', () {
    test('produces shoulder + hip compensations on BFL chain', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.bflPattern),
      );

      expect(compensations, isNotEmpty);
      expect(compensations.any((c) => c.chain == ChainType.bfl), isTrue);
      expect(
        compensations.any((c) => c.type == CompensationType.trunkLean),
        isTrue,
      );
      expect(
        compensations.any((c) => c.type == CompensationType.hipDrop),
        isTrue,
      );
    });
  });

  group('FFL pattern', () {
    test('produces ankle + knee + hip compensations on FFL chain', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.fflPattern),
      );

      expect(compensations, isNotEmpty);
      expect(compensations.any((c) => c.chain == ChainType.ffl), isTrue);
      expect(
        compensations.any((c) => c.type == CompensationType.ankleRestriction),
        isTrue,
      );
      expect(
        compensations.any((c) => c.type == CompensationType.hipDrop),
        isTrue,
      );
    });
  });

  group('Healthy pattern', () {
    test('produces no compensations', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.healthy),
      );
      expect(compensations, isEmpty);
    });
  });

  group('Hypermobile pattern', () {
    test('produces knee ER compensation with null chain', () {
      final compensations = mapper.mapCompensations(
        anglesFor(CompensationProfile.hypermobile),
      );

      expect(compensations, isNotEmpty);
      expect(compensations.first.type, CompensationType.kneeValgus);
      expect(compensations.first.chain, isNull);
    });
  });

  group('Confidence propagation', () {
    test('low visibility landmarks produce lower confidence', () {
      final calc = RuleBasedAngleCalculator(
        profile: CompensationProfile.sblPattern,
      );
      // Create landmarks with low visibility at ankles (indices 27, 28).
      final landmarks = List.generate(33, (i) {
        if (i == 27 || i == 28) {
          return const PoseLandmark(
            x: 0.5,
            y: 0.5,
            z: 0.0,
            visibility: 0.4,
            presence: 0.4,
          );
        }
        return const PoseLandmark(
          x: 0.5,
          y: 0.5,
          z: 0.0,
          visibility: 0.95,
          presence: 0.95,
        );
      });
      final angles = calc.calculateAngles(landmarks);
      final compensations = mapper.mapCompensations(angles);
      final ankleFindings = compensations.where(
        (c) => c.type == CompensationType.ankleRestriction,
      );

      for (final finding in ankleFindings) {
        expect(finding.confidence, ConfidenceLevel.low);
      }
    });
  });

  group('ConfidenceLevel enum', () {
    test('worstOf returns lowest confidence', () {
      expect(
        ConfidenceLevel.worstOf([
          ConfidenceLevel.high,
          ConfidenceLevel.medium,
          ConfidenceLevel.low,
        ]),
        ConfidenceLevel.low,
      );
    });

    test('worstOf with all high returns high', () {
      expect(
        ConfidenceLevel.worstOf([ConfidenceLevel.high, ConfidenceLevel.high]),
        ConfidenceLevel.high,
      );
    });

    test('isWorseThan works correctly', () {
      expect(ConfidenceLevel.low.isWorseThan(ConfidenceLevel.high), isTrue);
      expect(ConfidenceLevel.high.isWorseThan(ConfidenceLevel.low), isFalse);
      expect(
        ConfidenceLevel.medium.isWorseThan(ConfidenceLevel.medium),
        isFalse,
      );
    });
  });
}
