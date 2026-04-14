import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../domain/models.dart';
import '../../../core/services/hardware_controller.dart';
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
// Anatomical Mapping: Connections -> sEMG Channels
// ---------------------------------------------------------------------------

/// Maps a connection index (in blazePoseConnections) to an EMG channel index.
int? _mapConnectionToEMG(int connectionIdx) {
  // connectionIdx is the index in blazePoseConnections list.
  switch (connectionIdx) {
    case 24: // (23, 25) Left Hip -> Left Knee (Lower Trunk/Upper Leg)
      return 4; // Left VM
    case 25: // (25, 27) Left Knee -> Left Ankle
      return 1; // Left Soleus (Proxy for calf group)
    case 29: // (24, 26) Right Hip -> Right Knee
      return 5; // Right VM
    case 30: // (26, 28) Right Knee -> Right Ankle
      return 3; // Right Soleus
    case 10: // (11, 23) Left Shoulder -> Left Hip
      return 8; // Left Erector Spinae
    case 11: // (12, 24) Right Shoulder -> Right Hip
      return 9; // Right Erector Spinae
    default:
      return null;
  }
}

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
    this.emgData,
    this.isFrontCamera = false,
    this.isPremium = false,
  });

  final List<PoseLandmark> landmarks;
  final Size previewSize;
  final EMGData? emgData;
  final bool isFrontCamera;
  final bool isPremium;

  static const double _landmarkRadius = 6.0;
  static const double _segmentStrokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Draw segments first
    for (var i = 0; i < blazePoseConnections.length; i++) {
      final connection = blazePoseConnections[i];
      if (connection.$1 >= landmarks.length ||
          connection.$2 >= landmarks.length)
        continue;

      final startLm = landmarks[connection.$1];
      final endLm = landmarks[connection.$2];
      final startPt = transformLandmark(startLm, size, isFrontCamera);
      final endPt = transformLandmark(endLm, size, isFrontCamera);

      // Default color based on landmark visibility
      final minVisibility = startLm.visibility < endLm.visibility
          ? startLm.visibility
          : endLm.visibility;
      var segmentColor = BioliminalTheme.confidenceColor(minVisibility);
      var strokeWidth = _segmentStrokeWidth;

      // Premium Anatomical Heatmapping
      if (isPremium && emgData != null) {
        final emgIdx = _mapConnectionToEMG(i);
        if (emgIdx != null) {
          final intensity = emgData!.channels[emgIdx];
          if (intensity > 0.1) {
            // Apply heatglow
            segmentColor = Color.lerp(
              segmentColor,
              const Color(0x00000000), // Bioliminal Aqua #00D4AA
              intensity,
            )!;
            strokeWidth += (intensity * 4.0); // Thicker glow for active muscles

            // Draw an outer glow
            final glowPaint = Paint()
              ..color = const Color(
                0xFF00D4AA,
              ).withValues(alpha: intensity * 0.3)
              ..strokeWidth = strokeWidth + 6.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
            canvas.drawLine(startPt, endPt, glowPaint);
          }
        }
      }

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPt, endPt, paint);
    }

    // Draw landmark circles on top
    for (final lm in landmarks) {
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
        oldDelegate.emgData != emgData ||
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
    final emgData = ref.watch(latestEMGDataProvider);

    if (landmarks.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: size,
          painter: SkeletonPainter(
            landmarks: landmarks,
            previewSize: size,
            emgData: emgData,
            isFrontCamera: isFrontCamera,
            isPremium: isPremium,
          ),
        );
      },
    );
  }
}
