import '../../../domain/models.dart';

class ComparisonMetric {
  const ComparisonMetric({
    required this.joint,
    required this.compensationType,
    required this.oldValue,
    required this.newValue,
    required this.delta,
    required this.improved,
  });

  final String joint;
  final CompensationType compensationType;
  final double oldValue;
  final double newValue;
  final double delta;
  final bool improved;
}

class ComparisonService {
  ComparisonService._();

  static List<ComparisonMetric> compare(
    Assessment older,
    Assessment newer,
  ) {
    final metrics = <ComparisonMetric>[];

    for (final newComp in newer.compensations) {
      final oldComp = older.compensations
          .where((c) =>
              c.type == newComp.type && c.joint == newComp.joint)
          .firstOrNull;
      if (oldComp == null) continue;

      final delta = newComp.value - oldComp.value;
      // For all compensation types, lower value = improved.
      final improved = newComp.value < oldComp.value;

      metrics.add(ComparisonMetric(
        joint: newComp.joint,
        compensationType: newComp.type,
        oldValue: oldComp.value,
        newValue: newComp.value,
        delta: delta,
        improved: improved,
      ));
    }

    return metrics;
  }

  static String readableType(CompensationType type) {
    switch (type) {
      case CompensationType.kneeValgus:
        return 'Knee valgus';
      case CompensationType.hipDrop:
        return 'Hip drop';
      case CompensationType.ankleRestriction:
        return 'Ankle restriction';
      case CompensationType.trunkLean:
        return 'Trunk lean';
    }
  }
}
