import 'package:flutter/material.dart';

class PlacementGhostSkeleton extends StatefulWidget {
  const PlacementGhostSkeleton({super.key});

  @override
  State<PlacementGhostSkeleton> createState() => _PlacementGhostSkeletonState();
}

class _PlacementGhostSkeletonState extends State<PlacementGhostSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return CustomPaint(
          painter: _GhostSkeletonPainter(
            pulseValue: _pulseController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GhostSkeletonPainter extends CustomPainter {
  _GhostSkeletonPainter({required this.pulseValue});

  final double pulseValue;

  // Specific connections for our simplified ghost
  static const List<(int, int)> _ghostConnections = [
    (1, 2), (1, 3), (2, 4), (3, 4), (3, 5), (4, 6), (5, 7), (6, 8)
  ];

  // Anatomical target indices into relative offsets
  // Based on the 10-channel mapping: Gastroc, Soleus, VM, GluteMed, Erector
  List<Offset> _targetOffsets(Size size) {
    return [
      Offset(0.43 * size.width, 0.83 * size.height), // L-Gastroc
      Offset(0.43 * size.width, 0.87 * size.height), // L-Soleus
      Offset(0.57 * size.width, 0.83 * size.height), // R-Gastroc
      Offset(0.57 * size.width, 0.87 * size.height), // R-Soleus
      Offset(0.44 * size.width, 0.68 * size.height), // L-VM
      Offset(0.56 * size.width, 0.68 * size.height), // R-VM
      Offset(0.42 * size.width, 0.52 * size.height), // L-GluteMed
      Offset(0.58 * size.width, 0.52 * size.height), // R-GluteMed
      Offset(0.47 * size.width, 0.40 * size.height), // L-Erector
      Offset(0.53 * size.width, 0.40 * size.height), // R-Erector
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ghostPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw simplified ghost connections
    final joints = {
      1: Offset(0.42 * size.width, 0.25 * size.height),
      2: Offset(0.58 * size.width, 0.25 * size.height),
      3: Offset(0.45 * size.width, 0.55 * size.height),
      4: Offset(0.55 * size.width, 0.55 * size.height),
      5: Offset(0.43 * size.width, 0.75 * size.height),
      6: Offset(0.57 * size.width, 0.75 * size.height),
      7: Offset(0.45 * size.width, 0.90 * size.height),
      8: Offset(0.55 * size.width, 0.90 * size.height),
    };

    for (final conn in _ghostConnections) {
      final a = joints[conn.$1];
      final b = joints[conn.$2];
      if (a != null && b != null) {
        canvas.drawLine(a, b, ghostPaint);
      }
    }

    // Draw pulsing target indicators
    final targetPaint = Paint()
      ..color = const Color(0xFF00D4AA).withValues(alpha: 0.3 + (pulseValue * 0.4))
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF00D4AA).withValues(alpha: (1.0 - pulseValue) * 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    for (final target in _targetOffsets(size)) {
      canvas.drawCircle(target, 12.0 * (1.0 + pulseValue * 0.2), glowPaint);
      canvas.drawCircle(target, 6.0, targetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GhostSkeletonPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
