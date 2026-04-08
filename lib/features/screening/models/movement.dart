import '../../../domain/models.dart';

class MovementConfig {
  const MovementConfig({
    required this.type,
    required this.name,
    required this.instruction,
    this.duration = const Duration(seconds: 60),
    required this.targetReps,
    required this.primaryJoint,
    required this.peakIsMinimum,
  });

  final MovementType type;
  final String name;
  final String instruction;
  final Duration duration;
  final int targetReps;
  final String primaryJoint;
  final bool peakIsMinimum;
}

const screeningMovements = <MovementConfig>[
  MovementConfig(
    type: MovementType.overheadSquat,
    name: 'Overhead Squat',
    instruction:
        'Stand with feet shoulder-width apart. Raise arms overhead. Squat as deep as comfortable.',
    targetReps: 5,
    primaryJoint: 'leftKnee',
    peakIsMinimum: true,
  ),
  MovementConfig(
    type: MovementType.singleLegBalance,
    name: 'Single-Leg Balance',
    instruction:
        'Stand on your right leg. Hold for as long as comfortable. We\'ll check both sides.',
    targetReps: 3,
    primaryJoint: 'leftHip',
    peakIsMinimum: false,
  ),
  MovementConfig(
    type: MovementType.overheadReach,
    name: 'Overhead Reach',
    instruction:
        'Stand tall. Reach both arms as high as you can, then lower.',
    targetReps: 5,
    primaryJoint: 'leftShoulder',
    peakIsMinimum: false,
  ),
  MovementConfig(
    type: MovementType.forwardFold,
    name: 'Forward Fold',
    instruction:
        'Stand with feet together. Bend forward at the hips, reaching toward the floor.',
    targetReps: 3,
    primaryJoint: 'leftHip',
    peakIsMinimum: true,
  ),
];
