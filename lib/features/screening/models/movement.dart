import '../../../domain/models.dart';

class MovementConfig {
  const MovementConfig({
    required this.type,
    required this.name,
    required this.instruction,
    required this.targetReps,
    required this.primaryJoint,
    required this.peakIsMinimum,
  });

  final MovementType type;
  final String name;
  final String instruction;
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
    type: MovementType.singleLegSquat,
    name: 'Single-Leg Squat',
    instruction:
        'Stand on one leg. Squat down while keeping your knee aligned with your foot.',
    targetReps: 3,
    primaryJoint: 'leftKnee',
    peakIsMinimum: true,
  ),
  MovementConfig(
    type: MovementType.pushUp,
    name: 'Push-up',
    instruction:
        'Maintain a plank position. Lower your chest to the floor and push back up.',
    targetReps: 5,
    primaryJoint: 'leftShoulder',
    peakIsMinimum: true,
  ),
  MovementConfig(
    type: MovementType.rollup,
    name: 'Rollup',
    instruction:
        'Lie on your back. Slowly roll up to a sitting position, articulating through each vertebra.',
    targetReps: 3,
    primaryJoint: 'leftHip',
    peakIsMinimum: false,
  ),
];
