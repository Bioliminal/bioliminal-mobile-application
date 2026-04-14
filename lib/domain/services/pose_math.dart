import 'dart:math' as math;

import '../models.dart';

/// Pure rotation math — no native dependencies.
/// Returns the rotation in degrees to apply to a camera image
/// based on sensor orientation and whether it's a front-facing camera.
int rotationDegreesForSensor(
  int sensorOrientation, {
  required bool isFrontCamera,
}) {
  if (isFrontCamera) {
    return (360 - sensorOrientation) % 360;
  }
  return sensorOrientation;
}

/// Angle in degrees at landmark [b], formed by segments b→a and b→c.
/// Uses all three axes so sagittal-plane motion (squats, folds) is
/// captured from a front-facing camera.
double angleBetweenLandmarks(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
  final abx = a.x - b.x, aby = a.y - b.y, abz = a.z - b.z;
  final cbx = c.x - b.x, cby = c.y - b.y, cbz = c.z - b.z;
  final dot = abx * cbx + aby * cby + abz * cbz;
  final magAB = math.sqrt(abx * abx + aby * aby + abz * abz);
  final magCB = math.sqrt(cbx * cbx + cby * cby + cbz * cbz);
  if (magAB == 0 || magCB == 0) return 0;
  final cosAngle = (dot / (magAB * magCB)).clamp(-1.0, 1.0);
  return math.acos(cosAngle) * 180.0 / math.pi;
}

/// Normalize a raw landmark position to [0,1] coordinates
/// given the source image dimensions. Returns a zero-visibility
/// landmark if the input is null.
PoseLandmark normalizeLandmark({
  required double? x,
  required double? y,
  required double? z,
  required double? visibility,
  required double? presence,
  required double imageWidth,
  required double imageHeight,
}) {
  if (x == null || y == null) {
    return const PoseLandmark(x: 0, y: 0, z: 0, visibility: 0, presence: 0);
  }
  return PoseLandmark(
    x: x / imageWidth,
    y: y / imageHeight,
    z: (z ?? 0) / imageWidth,
    visibility: visibility ?? 0,
    presence: presence ?? 0,
  );
}

/// Normalize a list of raw landmark tuples into [PoseLandmark] objects.
/// Each tuple is (x, y, z, visibility, presence) — null entries produce zero landmarks.
List<PoseLandmark> normalizeRawLandmarks({
  required List<
    ({double? x, double? y, double? z, double? visibility, double? presence})
  >
  raw,
  required double imageWidth,
  required double imageHeight,
}) {
  return raw
      .map(
        (r) => normalizeLandmark(
          x: r.x,
          y: r.y,
          z: r.z,
          visibility: r.visibility,
          presence: r.presence,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        ),
      )
      .toList();
}
