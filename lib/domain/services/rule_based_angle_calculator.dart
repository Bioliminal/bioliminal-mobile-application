import '../models.dart';
import '../services/angle_calculator.dart';

/// Controls which compensation profile is returned by RuleBasedAngleCalculator.
enum CompensationProfile {
  sblPattern,
  bflPattern,
  fflPattern,
  healthy,
  hypermobile,
}

/// Returns deterministic joint angles that trigger specific compensation
/// patterns. Each profile produces angles matching published thresholds
/// from scout data so RuleBasedChainMapper can apply real rules against them.
class RuleBasedAngleCalculator implements AngleCalculator {
  RuleBasedAngleCalculator({this.profile = CompensationProfile.healthy});

  final CompensationProfile profile;

  @override
  List<JointAngle> calculateAngles(List<PoseLandmark> landmarks) {
    // Derive confidence from landmark visibility at relevant joints.
    // MediaPipe indices: 23/24=hips, 25/26=knees, 27/28=ankles, 11/12=shoulders
    final hipConfidence = _confidenceFromVisibility(
      _avgVisibility(landmarks, [23, 24]),
    );
    final kneeConfidence = _confidenceFromVisibility(
      _avgVisibility(landmarks, [25, 26]),
    );
    final ankleConfidence = _confidenceFromVisibility(
      _avgVisibility(landmarks, [27, 28]),
    );
    final shoulderConfidence = _confidenceFromVisibility(
      _avgVisibility(landmarks, [11, 12]),
    );

    switch (profile) {
      case CompensationProfile.sblPattern:
        return _sblAngles(
          hipConfidence: hipConfidence,
          kneeConfidence: kneeConfidence,
          ankleConfidence: ankleConfidence,
          shoulderConfidence: shoulderConfidence,
        );
      case CompensationProfile.bflPattern:
        return _bflAngles(
          hipConfidence: hipConfidence,
          kneeConfidence: kneeConfidence,
          ankleConfidence: ankleConfidence,
          shoulderConfidence: shoulderConfidence,
        );
      case CompensationProfile.fflPattern:
        return _fflAngles(
          hipConfidence: hipConfidence,
          kneeConfidence: kneeConfidence,
          ankleConfidence: ankleConfidence,
          shoulderConfidence: shoulderConfidence,
        );
      case CompensationProfile.healthy:
        return _healthyAngles(
          hipConfidence: hipConfidence,
          kneeConfidence: kneeConfidence,
          ankleConfidence: ankleConfidence,
          shoulderConfidence: shoulderConfidence,
        );
      case CompensationProfile.hypermobile:
        return _hypermobileAngles(
          hipConfidence: hipConfidence,
          kneeConfidence: kneeConfidence,
          ankleConfidence: ankleConfidence,
          shoulderConfidence: shoulderConfidence,
        );
    }
  }

  /// SBL pattern: knee valgus 15 deg (>10 threshold), ankle dorsiflexion
  /// 7 deg (<10 threshold = restriction), hip drop (gluteus medius
  /// asymmetry >10 deg).
  List<JointAngle> _sblAngles({
    required ConfidenceLevel hipConfidence,
    required ConfidenceLevel kneeConfidence,
    required ConfidenceLevel ankleConfidence,
    required ConfidenceLevel shoulderConfidence,
  }) {
    return [
      JointAngle(
        joint: 'left_knee_valgus',
        angleDegrees: 15.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_valgus',
        angleDegrees: 13.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_dorsiflexion',
        angleDegrees: 7.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_dorsiflexion',
        angleDegrees: 8.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_abduction',
        angleDegrees: 18.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_abduction',
        angleDegrees: 6.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'trunk_lateral_lean',
        angleDegrees: 3.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_shoulder_elevation',
        angleDegrees: 170.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'right_shoulder_elevation',
        angleDegrees: 172.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'left_knee_external_rotation',
        angleDegrees: 12.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_external_rotation',
        angleDegrees: 10.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_plantarflexion',
        angleDegrees: 12.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_plantarflexion',
        angleDegrees: 10.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_flexion',
        angleDegrees: 20.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_flexion',
        angleDegrees: 18.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'thoracic_rotation',
        angleDegrees: 40.0,
        confidence: shoulderConfidence,
      ),
    ];
  }

  /// BFL pattern: shoulder depression (asymmetry >8 deg), thoracic
  /// rotation limited (<35 deg), contralateral hip abduction weakness
  /// (asymmetry >10 deg).
  List<JointAngle> _bflAngles({
    required ConfidenceLevel hipConfidence,
    required ConfidenceLevel kneeConfidence,
    required ConfidenceLevel ankleConfidence,
    required ConfidenceLevel shoulderConfidence,
  }) {
    return [
      JointAngle(
        joint: 'left_shoulder_elevation',
        angleDegrees: 160.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'right_shoulder_elevation',
        angleDegrees: 172.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'thoracic_rotation',
        angleDegrees: 28.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'left_hip_abduction',
        angleDegrees: 8.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_abduction',
        angleDegrees: 20.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_knee_valgus',
        angleDegrees: 6.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_valgus',
        angleDegrees: 5.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_dorsiflexion',
        angleDegrees: 15.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_dorsiflexion',
        angleDegrees: 14.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'trunk_lateral_lean',
        angleDegrees: 2.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_knee_external_rotation',
        angleDegrees: 10.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_external_rotation',
        angleDegrees: 11.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_plantarflexion',
        angleDegrees: 10.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_plantarflexion',
        angleDegrees: 11.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_flexion',
        angleDegrees: 18.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_flexion',
        angleDegrees: 20.0,
        confidence: hipConfidence,
      ),
    ];
  }

  /// FFL pattern: ankle plantarflexion dominant (>20 deg), knee
  /// extension bias, hip flexion elevated (>30 deg standing).
  List<JointAngle> _fflAngles({
    required ConfidenceLevel hipConfidence,
    required ConfidenceLevel kneeConfidence,
    required ConfidenceLevel ankleConfidence,
    required ConfidenceLevel shoulderConfidence,
  }) {
    return [
      JointAngle(
        joint: 'left_ankle_plantarflexion',
        angleDegrees: 25.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_plantarflexion',
        angleDegrees: 22.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_knee_valgus',
        angleDegrees: 4.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_valgus',
        angleDegrees: 3.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_knee_extension',
        angleDegrees: 5.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_extension',
        angleDegrees: 6.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_hip_flexion',
        angleDegrees: 35.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_flexion',
        angleDegrees: 32.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_dorsiflexion',
        angleDegrees: 14.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_dorsiflexion',
        angleDegrees: 13.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_shoulder_elevation',
        angleDegrees: 168.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'right_shoulder_elevation',
        angleDegrees: 170.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'thoracic_rotation',
        angleDegrees: 42.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'left_hip_abduction',
        angleDegrees: 14.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_abduction',
        angleDegrees: 15.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'trunk_lateral_lean',
        angleDegrees: 1.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_knee_external_rotation',
        angleDegrees: 10.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_external_rotation',
        angleDegrees: 9.0,
        confidence: kneeConfidence,
      ),
    ];
  }

  /// Healthy: all angles within normal thresholds, no compensations.
  List<JointAngle> _healthyAngles({
    required ConfidenceLevel hipConfidence,
    required ConfidenceLevel kneeConfidence,
    required ConfidenceLevel ankleConfidence,
    required ConfidenceLevel shoulderConfidence,
  }) {
    return [
      JointAngle(
        joint: 'left_knee_valgus',
        angleDegrees: 5.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_valgus',
        angleDegrees: 4.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_dorsiflexion',
        angleDegrees: 15.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_dorsiflexion',
        angleDegrees: 14.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_abduction',
        angleDegrees: 14.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_abduction',
        angleDegrees: 13.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'trunk_lateral_lean',
        angleDegrees: 2.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_shoulder_elevation',
        angleDegrees: 172.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'right_shoulder_elevation',
        angleDegrees: 170.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'left_knee_external_rotation',
        angleDegrees: 12.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_external_rotation',
        angleDegrees: 11.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_plantarflexion',
        angleDegrees: 10.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_plantarflexion',
        angleDegrees: 11.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_flexion',
        angleDegrees: 18.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_flexion',
        angleDegrees: 17.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'thoracic_rotation',
        angleDegrees: 42.0,
        confidence: shoulderConfidence,
      ),
    ];
  }

  /// Hypermobile: knee ER 50 deg (>45 threshold), knee valgus 3 deg
  /// (<5 threshold). Triggers reversed threshold interpretation.
  List<JointAngle> _hypermobileAngles({
    required ConfidenceLevel hipConfidence,
    required ConfidenceLevel kneeConfidence,
    required ConfidenceLevel ankleConfidence,
    required ConfidenceLevel shoulderConfidence,
  }) {
    return [
      JointAngle(
        joint: 'left_knee_valgus',
        angleDegrees: 3.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_valgus',
        angleDegrees: 2.5,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_knee_external_rotation',
        angleDegrees: 50.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'right_knee_external_rotation',
        angleDegrees: 48.0,
        confidence: kneeConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_dorsiflexion',
        angleDegrees: 20.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_dorsiflexion',
        angleDegrees: 18.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_abduction',
        angleDegrees: 16.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_abduction',
        angleDegrees: 15.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'trunk_lateral_lean',
        angleDegrees: 1.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'left_shoulder_elevation',
        angleDegrees: 175.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'right_shoulder_elevation',
        angleDegrees: 174.0,
        confidence: shoulderConfidence,
      ),
      JointAngle(
        joint: 'left_ankle_plantarflexion',
        angleDegrees: 12.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'right_ankle_plantarflexion',
        angleDegrees: 11.0,
        confidence: ankleConfidence,
      ),
      JointAngle(
        joint: 'left_hip_flexion',
        angleDegrees: 15.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'right_hip_flexion',
        angleDegrees: 14.0,
        confidence: hipConfidence,
      ),
      JointAngle(
        joint: 'thoracic_rotation',
        angleDegrees: 45.0,
        confidence: shoulderConfidence,
      ),
    ];
  }

  double _avgVisibility(List<PoseLandmark> landmarks, List<int> indices) {
    if (landmarks.isEmpty) return 0.9;
    var sum = 0.0;
    var count = 0;
    for (final idx in indices) {
      if (idx < landmarks.length) {
        sum += landmarks[idx].visibility;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.9;
  }

  ConfidenceLevel _confidenceFromVisibility(double visibility) {
    if (visibility > 0.9) return ConfidenceLevel.high;
    if (visibility >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}
