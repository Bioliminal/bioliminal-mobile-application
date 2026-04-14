import 'package:flutter/material.dart';

import '../data/movement_keyframes.dart';
import '../../../domain/models.dart';

/// Maps each [MovementType] to its keyframe sequence.
List<AnimationPoseFrame> keyframesFor(MovementType type) {
  return switch (type) {
    MovementType.overheadSquat => overheadSquatKeyframes,
    MovementType.singleLegSquat => singleLegSquatKeyframes,
    MovementType.pushUp => pushUpKeyframes,
    MovementType.rollup => rollupKeyframes,
  };
}

// ---------------------------------------------------------------------------
// Looping stick-figure animation widget
// ---------------------------------------------------------------------------

class StickFigureAnimation extends StatefulWidget {
  const StickFigureAnimation({
    super.key,
    required this.movementType,
    this.cycleDuration = const Duration(seconds: 3),
    this.color = Colors.white,
    this.strokeWidth = 3.0,
    this.jointRadius = 5.0,
  });

  final MovementType movementType;
  final Duration cycleDuration;
  final Color color;
  final double strokeWidth;
  final double jointRadius;

  @override
  State<StickFigureAnimation> createState() => _StickFigureAnimationState();
}

class _StickFigureAnimationState extends State<StickFigureAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(StickFigureAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleDuration != widget.cycleDuration) {
      _controller.duration = widget.cycleDuration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyframes = keyframesFor(widget.movementType);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Use a sine curve for smoother looping movement
        final curvedValue = Curves.easeInOutSine.transform(_controller.value);
        final pose = interpolateKeyframes(keyframes, curvedValue);
        return CustomPaint(
          painter: _StickFigurePainter(
            pose: pose,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            jointRadius: widget.jointRadius,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Given a list of keyframes and a normalized [t] in [0,1], returns the
/// interpolated pose. Distributes time evenly across keyframe segments.
AnimationPoseFrame interpolateKeyframes(
  List<AnimationPoseFrame> keyframes,
  double t,
) {
  if (keyframes.isEmpty) return AnimationPoseFrame.empty;
  if (keyframes.length == 1) return keyframes.first;

  final segments = keyframes.length - 1;
  final scaledT = t * segments;
  final segmentIndex = scaledT.floor().clamp(0, segments - 1);
  final segmentT = scaledT - segmentIndex;

  return AnimationPoseFrame.lerp(
    keyframes[segmentIndex],
    keyframes[segmentIndex + 1],
    segmentT,
  );
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _StickFigurePainter extends CustomPainter {
  const _StickFigurePainter({
    required this.pose,
    required this.color,
    required this.strokeWidth,
    required this.jointRadius,
  });

  final AnimationPoseFrame pose;
  final Color color;
  final double strokeWidth;
  final double jointRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final joints = pose.all;
    if (joints.isEmpty) return;

    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..style = PaintingStyle.fill;

    // Draw connections.
    for (final (start, end) in stickFigureConnections) {
      if (start >= joints.length || end >= joints.length) continue;
      final a = Offset(
        joints[start].dx * size.width,
        joints[start].dy * size.height,
      );
      final b = Offset(
        joints[end].dx * size.width,
        joints[end].dy * size.height,
      );
      canvas.drawLine(a, b, segmentPaint);
    }

    // Draw joints with glow.
    for (final joint in joints) {
      final pt = Offset(joint.dx * size.width, joint.dy * size.height);
      canvas.drawCircle(pt, jointRadius + 2, glowPaint);
      canvas.drawCircle(pt, jointRadius, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) {
    return !identical(oldDelegate.pose, pose) || oldDelegate.color != color;
  }
}
