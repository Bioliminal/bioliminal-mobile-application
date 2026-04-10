import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models.dart';

// ---------------------------------------------------------------------------
// Normalized body region centers (0-1 coordinate space, front view).
// Keys match the joint naming from Compensation.joint.
// ---------------------------------------------------------------------------

const _regionCenters = <String, Offset>{
  'left_ankle': Offset(0.38, 0.92),
  'right_ankle': Offset(0.62, 0.92),
  'left_knee': Offset(0.40, 0.72),
  'right_knee': Offset(0.60, 0.72),
  'left_hip': Offset(0.42, 0.52),
  'right_hip': Offset(0.58, 0.52),
  'left_shoulder': Offset(0.32, 0.28),
  'right_shoulder': Offset(0.68, 0.28),
  'trunk': Offset(0.50, 0.40),
};

// Hit radius as a fraction of canvas width.
const _hitRadiusFraction = 0.06;

// Chain paths: ordered joint sequences to draw connection lines.
const _chainPaths = <ChainType, List<String>>{
  ChainType.sbl: ['left_ankle', 'left_knee', 'left_hip'],
  ChainType.ffl: ['right_ankle', 'right_knee', 'right_hip'],
  ChainType.bfl: ['left_shoulder', 'right_hip'],
};

// ---------------------------------------------------------------------------
// BodyMap widget
// ---------------------------------------------------------------------------

class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.findings,
    this.selectedFindingIndex,
    this.onRegionTap,
  });

  final List<Finding> findings;
  final int? selectedFindingIndex;
  final ValueChanged<int>? onRegionTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.4; // tall body proportion
        return GestureDetector(
          onTapDown: (details) => _handleTap(details, Size(width, height)),
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _BodyMapPainter(
                findings: findings,
                selectedFindingIndex: selectedFindingIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapDownDetails details, Size canvasSize) {
    if (onRegionTap == null) return;

    final tapX = details.localPosition.dx / canvasSize.width;
    final tapY = details.localPosition.dy / canvasSize.height;
    final hitRadius = _hitRadiusFraction;

    // Check each finding's joints for a hit.
    for (var i = 0; i < findings.length; i++) {
      final finding = findings[i];
      for (final comp in finding.compensations) {
        final center = _regionCenters[comp.joint];
        if (center == null) continue;
        final dx = tapX - center.dx;
        final dy = tapY - center.dy;
        if (dx * dx + dy * dy <= hitRadius * hitRadius) {
          onRegionTap!(i);
          return;
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _BodyMapPainter extends CustomPainter {
  _BodyMapPainter({
    required this.findings,
    this.selectedFindingIndex,
  });

  final List<Finding> findings;
  final int? selectedFindingIndex;

  static const _driverColor = Color(0xFF10B981); // Emerald
  static const _symptomColor = Color(0xFFF59E0B); // Amber
  static const _silhouetteColor = Color(0xFF1E293B); // Slate 800
  static const _silhouetteBorderColor = Color(0xFF334155); // Slate 700
  static const _chainLineColor = Color(0x4438BDF8); // Translucent Sky

  @override
  void paint(Canvas canvas, Size size) {
    _drawSilhouette(canvas, size);
    _drawChainLines(canvas, size);
    _drawRegions(canvas, size);
  }

  void _drawSilhouette(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _silhouetteColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _silhouetteBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    final path = Path();
    // Head
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.10),
      width: w * 0.12,
      height: h * 0.08,
    ));

    // Torso & Limbs (Simplified stylized silhouette)
    path.moveTo(w * 0.38, h * 0.16);
    path.lineTo(w * 0.62, h * 0.16);
    path.lineTo(w * 0.75, h * 0.40);
    path.lineTo(w * 0.70, h * 0.42);
    path.lineTo(w * 0.60, h * 0.22);
    path.lineTo(w * 0.60, h * 0.52);
    path.lineTo(w * 0.64, h * 0.95);
    path.lineTo(w * 0.52, h * 0.95);
    path.lineTo(w * 0.50, h * 0.60);
    path.lineTo(w * 0.48, h * 0.95);
    path.lineTo(w * 0.36, h * 0.95);
    path.lineTo(w * 0.40, h * 0.52);
    path.lineTo(w * 0.40, h * 0.22);
    path.lineTo(w * 0.30, h * 0.42);
    path.lineTo(w * 0.25, h * 0.40);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawChainLines(Canvas canvas, Size size) {
    final activeChains = <ChainType>{};
    for (final f in findings) {
      for (final c in f.compensations) {
        if (c.chain != null) activeChains.add(c.chain!);
      }
    }

    final paint = Paint()
      ..color = _chainLineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (final chain in activeChains) {
      final joints = _chainPaths[chain];
      if (joints == null || joints.length < 2) continue;

      final points = joints
          .map((j) => _regionCenters[j])
          .whereType<Offset>()
          .map((o) => Offset(o.dx * size.width, o.dy * size.height))
          .toList();

      if (points.length < 2) continue;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawRegions(Canvas canvas, Size size) {
    final radius = size.width * _hitRadiusFraction;

    for (var i = 0; i < findings.length; i++) {
      final finding = findings[i];
      final isSelected = selectedFindingIndex == i;
      final driverJointName = _extractDriverJoint(finding);

      for (final comp in finding.compensations) {
        final center = _regionCenters[comp.joint];
        if (center == null) continue;

        final offset = Offset(center.dx * size.width, center.dy * size.height);
        final isDriver = driverJointName != null && comp.joint == driverJointName;
        final color = isDriver ? _driverColor : _symptomColor;

        // Glow
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 12 : 6);
        canvas.drawCircle(offset, radius * (isSelected ? 1.5 : 1.2), glowPaint);

        // Node
        final nodePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, radius * 0.8, nodePaint);

        // Selection Ring
        if (isSelected) {
          final ringPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawCircle(offset, radius * 1.5, ringPaint);
        }

        _drawJointLabel(canvas, offset, radius, comp.joint, size, isSelected);
      }
    }
  }

  void _drawJointLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String joint,
    Size size,
    bool isSelected,
  ) {
    final label = _readableJointName(joint).toUpperCase();
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: size.width * (isSelected ? 0.035 : 0.028),
        fontWeight: isSelected ? ui.FontWeight.bold : ui.FontWeight.normal,
      ),
    )
      ..pushStyle(ui.TextStyle(color: isSelected ? Colors.white : Colors.white70))
      ..addText(label);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.3));

    canvas.drawParagraph(
      paragraph,
      Offset(
        center.dx - paragraph.maxIntrinsicWidth / 2,
        center.dy + radius * 1.8,
      ),
    );
  }

  static String? _extractDriverJoint(Finding finding) {
    if (finding.upstreamDriver == null) return null;
    for (final c in finding.compensations) {
      if (finding.upstreamDriver!.startsWith(c.joint)) {
        return c.joint;
      }
    }
    return null;
  }

  static String _readableJointName(String joint) {
    return joint.replaceAll('_', ' ');
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return oldDelegate.findings != findings ||
        oldDelegate.selectedFindingIndex != selectedFindingIndex;
  }
}
