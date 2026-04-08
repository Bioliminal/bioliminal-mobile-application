import 'package:camera/camera.dart';

import '../models.dart';

/// Takes a camera frame, returns a stream of 33 landmarks with
/// x, y, z coordinates and visibility confidence scores.
///
/// CameraImage comes from the `camera` package. Each frame yields
/// 33 MediaPipe BlazePose landmarks in normalized coordinates (0.0-1.0).
abstract class PoseEstimationService {
  Stream<List<Landmark>> processFrame(CameraImage frame);
  void dispose();
}
