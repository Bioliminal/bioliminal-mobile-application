import 'dart:math' as math;

import '../../../domain/models.dart';
import '../models/compensation_reference.dart';

/// BlazePose 33-landmark indices (subset we care about).
const int kLeftShoulder = 11;
const int kRightShoulder = 12;
const int kLeftElbow = 13;
const int kRightElbow = 14;
const int kLeftWrist = 15;
const int kRightWrist = 16;
const int kLeftHip = 23;
const int kRightHip = 24;

/// Interior angle at vertex `b`, in degrees, computed in 2D (x,y).
double angleDeg(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final v1x = a.x - b.x;
  final v1y = a.y - b.y;
  final v2x = c.x - b.x;
  final v2y = c.y - b.y;

  final dot = v1x * v2x + v1y * v2y;
  final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
  final mag2 = math.sqrt(v2x * v2x + v2y * v2y);
  if (mag1 == 0 || mag2 == 0) return 0;

  final cos = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
  return math.acos(cos) * 180.0 / math.pi;
}

/// Elbow angle (shoulder–elbow–wrist) for the curling arm. Returns degrees
/// in `[0, 180]`. ~170° fully extended, ~30–60° fully contracted.
double elbowAngleDeg(List<PoseLandmark> landmarks, ArmSide side) {
  final shoulder = side == ArmSide.left ? kLeftShoulder : kRightShoulder;
  final elbow = side == ArmSide.left ? kLeftElbow : kRightElbow;
  final wrist = side == ArmSide.left ? kLeftWrist : kRightWrist;
  return angleDeg(landmarks[shoulder], landmarks[elbow], landmarks[wrist]);
}

/// Torso pitch in degrees from vertical. Line midShoulder→midHip; 0° means
/// upright; positive means the user is leaning forward. v0 uses absolute
/// magnitude; sign is preserved for future debrief annotations.
double torsoPitchDeg(List<PoseLandmark> landmarks) {
  final midShoulderX =
      (landmarks[kLeftShoulder].x + landmarks[kRightShoulder].x) / 2.0;
  final midShoulderY =
      (landmarks[kLeftShoulder].y + landmarks[kRightShoulder].y) / 2.0;
  final midHipX = (landmarks[kLeftHip].x + landmarks[kRightHip].x) / 2.0;
  final midHipY = (landmarks[kLeftHip].y + landmarks[kRightHip].y) / 2.0;

  final dx = midHipX - midShoulderX;
  final dy = midHipY - midShoulderY;
  if (dy == 0) return 90.0;

  // atan2 gives angle from vertical: 0 when (dx==0, dy>0), positive when
  // hips are forward of shoulders (user pitching back), negative otherwise.
  return math.atan2(dx, dy) * 180.0 / math.pi;
}

/// Normalized y-coordinate of the curling-arm shoulder, used as the
/// reference for shoulder-drift compensation tracking.
double shoulderY(List<PoseLandmark> landmarks, ArmSide side) {
  final idx = side == ArmSide.left ? kLeftShoulder : kRightShoulder;
  return landmarks[idx].y;
}
