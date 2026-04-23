import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../../core/providers.dart';

// ---------------------------------------------------------------------------
// BlazePose topology — 33-landmark connections
// ---------------------------------------------------------------------------

const List<(int, int)> blazePoseConnections = [
  // Face
  (0, 1), (1, 2), (2, 3), (3, 7),
  (0, 4), (4, 5), (5, 6), (6, 8),
  (9, 10),
  // Torso
  (11, 12), (11, 23), (12, 24), (23, 24),
  // Left arm
  (11, 13), (13, 15), (15, 17), (15, 19), (15, 21),
  // Right arm
  (12, 14), (14, 16), (16, 18), (16, 20), (16, 22),
  // Left leg
  (23, 25), (25, 27), (27, 29), (27, 31), (29, 31),
  // Right leg
  (24, 26), (26, 28), (28, 30), (28, 32), (30, 32),
];

// ---------------------------------------------------------------------------
// Coordinate transform
// ---------------------------------------------------------------------------

Offset transformLandmark(PoseLandmark lm, Size canvasSize) {
  return Offset(lm.x * canvasSize.width, lm.y * canvasSize.height);
}

// ---------------------------------------------------------------------------
// SkeletonPainter
// ---------------------------------------------------------------------------

class SkeletonPainter extends CustomPainter {
  const SkeletonPainter({
    required this.landmarks,
    required this.previewSize,
    this.isPremium = false,
  });

  final List<PoseLandmark> landmarks;
  final Size previewSize;
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
      final startPt = transformLandmark(startLm, size);
      final endPt = transformLandmark(endLm, size);

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

    for (final lm in landmarks) {
      final pt = transformLandmark(lm, size);
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
  const SkeletonOverlay({super.key});

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
            isPremium: isPremium,
          ),
        );
      },
    );
  }
}
