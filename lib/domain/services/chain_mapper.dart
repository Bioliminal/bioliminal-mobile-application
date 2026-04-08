import '../models.dart';

/// Takes joint angles, applies published thresholds, detects
/// co-occurring compensation patterns, maps to SBL/BFL/FFL chains,
/// identifies upstream driver (CC) vs symptom site (CP).
///
/// CC/CP logic: detect compensation at CP -> trace upstream along
/// chain -> identify CC -> recommend at CC.
abstract class ChainMapper {
  List<Compensation> mapCompensations(List<JointAngle> angles);
}
