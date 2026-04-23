import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../../core/providers.dart';

// ---------------------------------------------------------------------------
// BlazePose topology — upper-body subset
//
// Bicep curl is an arm exercise, so the overlay draws only shoulders, arms,
// hands, and the torso trapezoid to hips. Face (0-10) and legs (25-32) are
// still computed by BlazePose but intentionally not rendered — they add
// visual noise and aren't used in rep counting.
// ---------------------------------------------------------------------------

const List<(int, int)> blazePoseConnections = [
  // Torso trapezoid — shoulders to hips, anchors the figure
  (11, 12), (11, 23), (12, 24), (23, 24),
  // Left arm
  (11, 13), (13, 15), (15, 17), (15, 19), (15, 21),
  // Right arm
  (12, 14), (14, 16), (16, 18), (16, 20), (16, 22),
];

/// Landmark indices rendered as dots. Matches the topology above.
const Set<int> renderedLandmarks = {
  11, 12, 13, 14, 15, 16,           // shoulders, elbows, wrists
  17, 18, 19, 20, 21, 22,           // hand sub-landmarks
  23, 24,                           // hips (torso anchor)
};

// ---------------------------------------------------------------------------
// Coordinate transform
// ---------------------------------------------------------------------------

Offset transformLandmark(PoseLandmark lm, Size canvasSize, bool mirror) {
  final x = mirror ? (1.0 - lm.x) * canvasSize.width : lm.x * canvasSize.width;
  final y = lm.y * canvasSize.height;
  return Offset(x, y);
}

// ---------------------------------------------------------------------------
// SkeletonPainter
// ---------------------------------------------------------------------------

class SkeletonPainter extends CustomPainter {
  const SkeletonPainter({
    required this.landmarks,
    required this.previewSize,
    this.isFrontCamera = false,
    this.isPremium = false,
  });

  final List<PoseLandmark> landmarks;
  final Size previewSize;
  final bool isFrontCamera;
  final bool isPremium;

  static const double _landmarkRadius = 6.0;
  static const double _segmentStrokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    for (var i = 0; i < blazePoseConnections.length; i++) {
      final connection = blazePoseConnections[i];
      if (connection.$1 >= landmarks.length ||
          connection.$2 >= landmarks.length) {
        continue;
      }

      final startLm = landmarks[connection.$1];
      final endLm = landmarks[connection.$2];
      final startPt = transformLandmark(startLm, size, isFrontCamera);
      final endPt = transformLandmark(endLm, size, isFrontCamera);

      final minVisibility = startLm.visibility < endLm.visibility
          ? startLm.visibility
          : endLm.visibility;
      final segmentColor = BioliminalTheme.confidenceColor(minVisibility);

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = _segmentStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPt, endPt, paint);
    }

    for (var i = 0; i < landmarks.length; i++) {
      if (!renderedLandmarks.contains(i)) continue;
      final lm = landmarks[i];
      final pt = transformLandmark(lm, size, isFrontCamera);
      final color = BioliminalTheme.confidenceColor(lm.visibility);

      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, _landmarkRadius, fill);
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return !identical(oldDelegate.landmarks, landmarks) ||
        oldDelegate.isPremium != isPremium;
  }
}

// ---------------------------------------------------------------------------
// SkeletonOverlay
// ---------------------------------------------------------------------------

class SkeletonOverlay extends ConsumerWidget {
  const SkeletonOverlay({super.key, this.isFrontCamera = false});

  final bool isFrontCamera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landmarks = ref.watch(currentLandmarksProvider);
    final isPremium = ref.watch(isPremiumProvider);

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
            isPremium: isPremium,
          ),
        );
      },
    );
  }
}
