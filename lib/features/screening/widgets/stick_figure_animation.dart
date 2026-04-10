import 'package:flutter/material.dart';

import '../data/movement_keyframes.dart';
import '../../../domain/models.dart';

/// Maps each [MovementType] to its keyframe sequence.
List<PoseFrame> keyframesFor(MovementType type) {
  return switch (type) {
    MovementType.overheadSquat => overheadSquatKeyframes,
    MovementType.singleLegBalance => singleLegBalanceKeyframes,
    MovementType.overheadReach => overheadReachKeyframes,
    MovementType.forwardFold => forwardFoldKeyframes,
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
        final pose = interpolateKeyframes(keyframes, _controller.value);
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
PoseFrame interpolateKeyframes(List<PoseFrame> keyframes, double t) {
  if (keyframes.length == 1) return keyframes.first;

  final segments = keyframes.length - 1;
  final scaledT = t * segments;
  final segmentIndex = scaledT.floor().clamp(0, segments - 1);
  final segmentT = scaledT - segmentIndex;

  return PoseFrame.lerp(
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

  final PoseFrame pose;
  final Color color;
  final double strokeWidth;
  final double jointRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final joints = pose.all;
    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw connections.
    for (final (start, end) in stickFigureConnections) {
      final a = Offset(joints[start].dx * size.width, joints[start].dy * size.height);
      final b = Offset(joints[end].dx * size.width, joints[end].dy * size.height);
      canvas.drawLine(a, b, segmentPaint);
    }

    // Draw joints.
    for (final joint in joints) {
      final pt = Offset(joint.dx * size.width, joint.dy * size.height);
      canvas.drawCircle(pt, jointRadius, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) {
    return !identical(oldDelegate.pose, pose) ||
        oldDelegate.color != color;
  }
}
