import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../controllers/camera_controller.dart';

// ---------------------------------------------------------------------------
// BlazePose topology — 33-landmark connections
// ---------------------------------------------------------------------------

/// Standard BlazePose 33-point landmark connections.
/// Each tuple is (startIndex, endIndex).
const List<(int, int)> blazePoseConnections = [
  // Face
  (0, 1), // nose -> left eye inner
  (1, 2), // left eye inner -> left eye
  (2, 3), // left eye -> left eye outer
  (3, 7), // left eye outer -> left ear
  (0, 4), // nose -> right eye inner
  (4, 5), // right eye inner -> right eye
  (5, 6), // right eye -> right eye outer
  (6, 8), // right eye outer -> right ear
  (9, 10), // mouth left -> mouth right
  // Torso
  (11, 12), // left shoulder -> right shoulder
  (11, 23), // left shoulder -> left hip
  (12, 24), // right shoulder -> right hip
  (23, 24), // left hip -> right hip
  // Left arm
  (11, 13), // left shoulder -> left elbow
  (13, 15), // left elbow -> left wrist
  (15, 17), // left wrist -> left pinky
  (15, 19), // left wrist -> left index
  (15, 21), // left wrist -> left thumb
  // Right arm
  (12, 14), // right shoulder -> right elbow
  (14, 16), // right elbow -> right wrist
  (16, 18), // right wrist -> right pinky
  (16, 20), // right wrist -> right index
  (16, 22), // right wrist -> right thumb
  // Left leg
  (23, 25), // left hip -> left knee
  (25, 27), // left knee -> left ankle
  (27, 29), // left ankle -> left heel
  (27, 31), // left ankle -> left foot index
  (29, 31), // left heel -> left foot index
  // Right leg
  (24, 26), // right hip -> right knee
  (26, 28), // right knee -> right ankle
  (28, 30), // right ankle -> right heel
  (28, 32), // right ankle -> right foot index
  (30, 32), // right heel -> right foot index
];

// ---------------------------------------------------------------------------
// Coordinate transform
// ---------------------------------------------------------------------------

/// Convert a normalized [0,1] landmark to canvas pixel coordinates.
/// Mirrors horizontally when [mirror] is true (front camera).
Offset transformLandmark(Landmark lm, Size canvasSize, bool mirror) {
  final x = mirror ? (1.0 - lm.x) * canvasSize.width : lm.x * canvasSize.width;
  final y = lm.y * canvasSize.height;
  return Offset(x, y);
}

// ---------------------------------------------------------------------------
// SkeletonPainter — CustomPainter for landmarks + connections
// ---------------------------------------------------------------------------

class SkeletonPainter extends CustomPainter {
  const SkeletonPainter({
    required this.landmarks,
    required this.previewSize,
    this.isFrontCamera = false,
  });

  final List<Landmark> landmarks;
  final Size previewSize;
  final bool isFrontCamera;

  static const double _landmarkRadius = 6.0;
  static const double _segmentStrokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Draw segments first (behind landmarks).
    for (final (startIdx, endIdx) in blazePoseConnections) {
      if (startIdx >= landmarks.length || endIdx >= landmarks.length) continue;

      final startLm = landmarks[startIdx];
      final endLm = landmarks[endIdx];
      final startPt = transformLandmark(startLm, size, isFrontCamera);
      final endPt = transformLandmark(endLm, size, isFrontCamera);

      // Segment color = lower confidence of its two endpoints.
      final minVisibility = startLm.visibility < endLm.visibility
          ? startLm.visibility
          : endLm.visibility;
      final segmentColor = AuraLinkTheme.confidenceColor(minVisibility);

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = _segmentStrokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPt, endPt, paint);
    }

    // Draw landmark circles on top.
    for (final lm in landmarks) {
      final pt = transformLandmark(lm, size, isFrontCamera);
      final color = AuraLinkTheme.confidenceColor(lm.visibility);

      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final outline = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pt, _landmarkRadius, fill);
      canvas.drawCircle(pt, _landmarkRadius + 2, outline);
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return !identical(oldDelegate.landmarks, landmarks) ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}

// ---------------------------------------------------------------------------
// SkeletonOverlay — ConsumerWidget wrapping the CustomPainter
// ---------------------------------------------------------------------------

class SkeletonOverlay extends ConsumerWidget {
  const SkeletonOverlay({super.key, this.isFrontCamera = false});

  final bool isFrontCamera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landmarks = ref.watch(currentLandmarksProvider);

    if (landmarks.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: size,
          painter: SkeletonPainter(
            landmarks: landmarks,
            previewSize: size,
            isFrontCamera: isFrontCamera,
          ),
        );
      },
    );
  }
}
