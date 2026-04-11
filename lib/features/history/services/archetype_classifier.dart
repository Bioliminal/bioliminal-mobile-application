import '../../../domain/models.dart';

class ArchetypeClassifier {
  ArchetypeClassifier._();

  /// Classifies a user into a mobility archetype based on compensation
  /// patterns across multiple assessments.
  ///
  /// Returns [MobilityArchetype.balanced] for empty or single-assessment
  /// histories (insufficient data to establish a pattern).
  static MobilityArchetype classify(List<Assessment> assessments) {
    if (assessments.length <= 1) return MobilityArchetype.balanced;

    final allCompensations = assessments
        .expand((a) => a.compensations)
        .toList();
    if (allCompensations.isEmpty) return MobilityArchetype.balanced;

    // Hypermobility check (priority): count assessments containing any
    // compensation with value < 5.0 and no chain.
    final hypermobileCount = assessments
        .where(
          (a) => a.compensations.any((c) => c.value < 5.0 && c.chain == null),
        )
        .length;
    if (hypermobileCount >= assessments.length / 2) {
      return MobilityArchetype.hypermobile;
    }

    // Frequency check: bucket by compensation type.
    final total = allCompensations.length;
    var ankleCount = 0;
    var hipDropCount = 0;
    var kneeValgusCount = 0;
    var trunkCount = 0;

    for (final c in allCompensations) {
      switch (c.type) {
        case CompensationType.ankleRestriction:
          ankleCount++;
        case CompensationType.hipDrop:
          hipDropCount++;
        case CompensationType.kneeValgus:
          kneeValgusCount++;
        case CompensationType.trunkLean:
          trunkCount++;
      }
    }

    final hipCount = hipDropCount + kneeValgusCount;

    final anklePct = ankleCount / total;
    final hipPct = hipCount / total;
    final trunkPct = trunkCount / total;

    // Find dominant bucket.
    final maxPct = [
      anklePct,
      hipPct,
      trunkPct,
    ].reduce((a, b) => a >= b ? a : b);

    if (maxPct >= 0.4) {
      if (maxPct == anklePct) return MobilityArchetype.ankleDominant;
      if (maxPct == hipPct) return MobilityArchetype.hipDominant;
      return MobilityArchetype.trunkDominant;
    }

    return MobilityArchetype.balanced;
  }
}
