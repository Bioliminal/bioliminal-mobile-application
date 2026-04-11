import 'dart:ui';

/// A single pose in a movement animation — normalized [0,1] joint positions.
/// Uses the simplified 13-point skeleton: head, left/right shoulder, elbow,
/// wrist, hip, knee, ankle.
class PoseFrame {
  const PoseFrame({
    required this.head,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftElbow,
    required this.rightElbow,
    required this.leftWrist,
    required this.rightWrist,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
    required this.leftAnkle,
    required this.rightAnkle,
  });

  /// An empty pose with all points at zero.
  static const empty = PoseFrame(
    head: Offset.zero,
    leftShoulder: Offset.zero,
    rightShoulder: Offset.zero,
    leftElbow: Offset.zero,
    rightElbow: Offset.zero,
    leftWrist: Offset.zero,
    rightWrist: Offset.zero,
    leftHip: Offset.zero,
    rightHip: Offset.zero,
    leftKnee: Offset.zero,
    rightKnee: Offset.zero,
    leftAnkle: Offset.zero,
    rightAnkle: Offset.zero,
  );

  final Offset head;
  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftElbow;
  final Offset rightElbow;
  final Offset leftWrist;
  final Offset rightWrist;
  final Offset leftHip;
  final Offset rightHip;
  final Offset leftKnee;
  final Offset rightKnee;
  final Offset leftAnkle;
  final Offset rightAnkle;

  List<Offset> get all => [
    head,
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
  ];

  /// Linearly interpolate between two poses.
  static PoseFrame lerp(PoseFrame a, PoseFrame b, double t) {
    return PoseFrame(
      head: Offset.lerp(a.head, b.head, t)!,
      leftShoulder: Offset.lerp(a.leftShoulder, b.leftShoulder, t)!,
      rightShoulder: Offset.lerp(a.rightShoulder, b.rightShoulder, t)!,
      leftElbow: Offset.lerp(a.leftElbow, b.leftElbow, t)!,
      rightElbow: Offset.lerp(a.rightElbow, b.rightElbow, t)!,
      leftWrist: Offset.lerp(a.leftWrist, b.leftWrist, t)!,
      rightWrist: Offset.lerp(a.rightWrist, b.rightWrist, t)!,
      leftHip: Offset.lerp(a.leftHip, b.leftHip, t)!,
      rightHip: Offset.lerp(a.rightHip, b.rightHip, t)!,
      leftKnee: Offset.lerp(a.leftKnee, b.leftKnee, t)!,
      rightKnee: Offset.lerp(a.rightKnee, b.rightKnee, t)!,
      leftAnkle: Offset.lerp(a.leftAnkle, b.leftAnkle, t)!,
      rightAnkle: Offset.lerp(a.rightAnkle, b.rightAnkle, t)!,
    );
  }
}

/// Connections between joints for drawing the stick figure.
/// Indices into [PoseFrame.all].
const stickFigureConnections = <(int, int)>[
  // Head to shoulders
  (0, 1), // head -> left shoulder
  (0, 2), // head -> right shoulder
  // Shoulders
  (1, 2), // left shoulder -> right shoulder
  // Left arm
  (1, 3), // left shoulder -> left elbow
  (3, 5), // left elbow -> left wrist
  // Right arm
  (2, 4), // right shoulder -> right elbow
  (4, 6), // right elbow -> right wrist
  // Torso
  (1, 7), // left shoulder -> left hip
  (2, 8), // right shoulder -> right hip
  (7, 8), // left hip -> right hip
  // Left leg
  (7, 9), // left hip -> left knee
  (9, 11), // left knee -> left ankle
  // Right leg
  (8, 10), // right hip -> right knee
  (10, 12), // right knee -> right ankle
];

// ---------------------------------------------------------------------------
// Standing neutral — shared starting pose
// ---------------------------------------------------------------------------

const _standing = PoseFrame(
  head: Offset(0.50, 0.10),
  leftShoulder: Offset(0.42, 0.22),
  rightShoulder: Offset(0.58, 0.22),
  leftElbow: Offset(0.38, 0.35),
  rightElbow: Offset(0.62, 0.35),
  leftWrist: Offset(0.38, 0.45),
  rightWrist: Offset(0.62, 0.45),
  leftHip: Offset(0.45, 0.50),
  rightHip: Offset(0.55, 0.50),
  leftKnee: Offset(0.45, 0.68),
  rightKnee: Offset(0.55, 0.68),
  leftAnkle: Offset(0.45, 0.88),
  rightAnkle: Offset(0.55, 0.88),
);

// ---------------------------------------------------------------------------
// Overhead Squat
// ---------------------------------------------------------------------------

const _overheadSquatArmsUp = PoseFrame(
  head: Offset(0.50, 0.10),
  leftShoulder: Offset(0.42, 0.22),
  rightShoulder: Offset(0.58, 0.22),
  leftElbow: Offset(0.38, 0.14),
  rightElbow: Offset(0.62, 0.14),
  leftWrist: Offset(0.38, 0.04),
  rightWrist: Offset(0.62, 0.04),
  leftHip: Offset(0.45, 0.50),
  rightHip: Offset(0.55, 0.50),
  leftKnee: Offset(0.45, 0.68),
  rightKnee: Offset(0.55, 0.68),
  leftAnkle: Offset(0.45, 0.88),
  rightAnkle: Offset(0.55, 0.88),
);

const _overheadSquatBottom = PoseFrame(
  head: Offset(0.50, 0.22),
  leftShoulder: Offset(0.42, 0.34),
  rightShoulder: Offset(0.58, 0.34),
  leftElbow: Offset(0.38, 0.26),
  rightElbow: Offset(0.62, 0.26),
  leftWrist: Offset(0.38, 0.16),
  rightWrist: Offset(0.62, 0.16),
  leftHip: Offset(0.43, 0.58),
  rightHip: Offset(0.57, 0.58),
  leftKnee: Offset(0.40, 0.72),
  rightKnee: Offset(0.60, 0.72),
  leftAnkle: Offset(0.45, 0.88),
  rightAnkle: Offset(0.55, 0.88),
);

const overheadSquatKeyframes = <PoseFrame>[
  _standing,
  _overheadSquatArmsUp,
  _overheadSquatBottom,
  _overheadSquatArmsUp,
  _standing,
];

// ---------------------------------------------------------------------------
// Single-Leg Balance
// ---------------------------------------------------------------------------

const _singleLegBalanceUp = PoseFrame(
  head: Offset(0.50, 0.10),
  leftShoulder: Offset(0.42, 0.22),
  rightShoulder: Offset(0.58, 0.22),
  leftElbow: Offset(0.34, 0.30),
  rightElbow: Offset(0.66, 0.30),
  leftWrist: Offset(0.30, 0.38),
  rightWrist: Offset(0.70, 0.38),
  leftHip: Offset(0.45, 0.50),
  rightHip: Offset(0.55, 0.50),
  leftKnee: Offset(0.48, 0.56),
  rightKnee: Offset(0.55, 0.68),
  leftAnkle: Offset(0.52, 0.62),
  rightAnkle: Offset(0.55, 0.88),
);

const singleLegBalanceKeyframes = <PoseFrame>[
  _standing,
  _singleLegBalanceUp,
  _singleLegBalanceUp, // hold
  _standing,
];

// ---------------------------------------------------------------------------
// Overhead Reach
// ---------------------------------------------------------------------------

const _overheadReachUp = PoseFrame(
  head: Offset(0.50, 0.10),
  leftShoulder: Offset(0.42, 0.22),
  rightShoulder: Offset(0.58, 0.22),
  leftElbow: Offset(0.40, 0.12),
  rightElbow: Offset(0.60, 0.12),
  leftWrist: Offset(0.42, 0.02),
  rightWrist: Offset(0.58, 0.02),
  leftHip: Offset(0.45, 0.50),
  rightHip: Offset(0.55, 0.50),
  leftKnee: Offset(0.45, 0.68),
  rightKnee: Offset(0.55, 0.68),
  leftAnkle: Offset(0.45, 0.88),
  rightAnkle: Offset(0.55, 0.88),
);

const overheadReachKeyframes = <PoseFrame>[
  _standing,
  _overheadReachUp,
  _standing,
];

// ---------------------------------------------------------------------------
// Forward Fold
// ---------------------------------------------------------------------------

const _forwardFoldDown = PoseFrame(
  head: Offset(0.50, 0.42),
  leftShoulder: Offset(0.44, 0.38),
  rightShoulder: Offset(0.56, 0.38),
  leftElbow: Offset(0.44, 0.50),
  rightElbow: Offset(0.56, 0.50),
  leftWrist: Offset(0.45, 0.62),
  rightWrist: Offset(0.55, 0.62),
  leftHip: Offset(0.45, 0.50),
  rightHip: Offset(0.55, 0.50),
  leftKnee: Offset(0.45, 0.68),
  rightKnee: Offset(0.55, 0.68),
  leftAnkle: Offset(0.45, 0.88),
  rightAnkle: Offset(0.55, 0.88),
);

const forwardFoldKeyframes = <PoseFrame>[
  _standing,
  _forwardFoldDown,
  _standing,
];
