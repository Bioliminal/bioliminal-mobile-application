import '../models.dart';

/// Takes 33 landmarks, returns joint angles for hip, knee, ankle,
/// and shoulder (both sides) using 2D screen-space trigonometry.
///
/// 3D upgrade path: same interface, swap implementation.
abstract class AngleCalculator {
  List<JointAngle> calculateAngles(List<PoseLandmark> landmarks);
}
