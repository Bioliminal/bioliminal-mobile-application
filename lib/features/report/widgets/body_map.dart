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

  static const _driverColor = Color(0xFF00897B); // teal
  static const _symptomColor = Color(0xFFFF9800); // orange
  static const _silhouetteColor = Color(0xFFE0E0E0);
  static const _chainLineColor = Color(0x88607D8B);

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

    final w = size.width;
    final h = size.height;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.10),
        width: w * 0.12,
        height: h * 0.08,
      ),
      paint,
    );

    // Torso
    final torso = Path()
      ..moveTo(w * 0.38, h * 0.16)
      ..lineTo(w * 0.62, h * 0.16)
      ..lineTo(w * 0.60, h * 0.52)
      ..lineTo(w * 0.40, h * 0.52)
      ..close();
    canvas.drawPath(torso, paint);

    // Left arm
    final leftArm = Path()
      ..moveTo(w * 0.38, h * 0.18)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.40, h * 0.22)
      ..close();
    canvas.drawPath(leftArm, paint);

    // Right arm
    final rightArm = Path()
      ..moveTo(w * 0.62, h * 0.18)
      ..lineTo(w * 0.76, h * 0.42)
      ..lineTo(w * 0.72, h * 0.44)
      ..lineTo(w * 0.60, h * 0.22)
      ..close();
    canvas.drawPath(rightArm, paint);

    // Left leg
    final leftLeg = Path()
      ..moveTo(w * 0.40, h * 0.52)
      ..lineTo(w * 0.36, h * 0.95)
      ..lineTo(w * 0.42, h * 0.95)
      ..lineTo(w * 0.48, h * 0.52)
      ..close();
    canvas.drawPath(leftLeg, paint);

    // Right leg
    final rightLeg = Path()
      ..moveTo(w * 0.52, h * 0.52)
      ..lineTo(w * 0.58, h * 0.95)
      ..lineTo(w * 0.64, h * 0.95)
      ..lineTo(w * 0.60, h * 0.52)
      ..close();
    canvas.drawPath(rightLeg, paint);
  }

  void _drawChainLines(Canvas canvas, Size size) {
    // Collect active chains from all findings.
    final activeChains = <ChainType>{};
    for (final f in findings) {
      for (final c in f.compensations) {
        if (c.chain != null) activeChains.add(c.chain!);
      }
    }

    final paint = Paint()
      ..color = _chainLineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

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
    // Build a set of driver joints and symptom joints across all findings.
    final driverJoints = <String>{};
    final symptomJoints = <String>{};

    for (final finding in findings) {
      final driverJointName = _extractDriverJoint(finding);

      for (final comp in finding.compensations) {
        if (driverJointName != null && comp.joint == driverJointName) {
          driverJoints.add(comp.joint);
        } else {
          symptomJoints.add(comp.joint);
        }
      }
    }

    final driverPaint = Paint()
      ..color = _driverColor
      ..style = PaintingStyle.fill;

    final symptomPaint = Paint()
      ..color = _symptomColor
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Collect joints for selected finding so we can draw a selection ring.
    final selectedJoints = <String>{};
    if (selectedFindingIndex != null &&
        selectedFindingIndex! < findings.length) {
      for (final c in findings[selectedFindingIndex!].compensations) {
        selectedJoints.add(c.joint);
      }
    }

    final radius = size.width * _hitRadiusFraction;

    // Draw all regions.
    for (final entry in _regionCenters.entries) {
      final joint = entry.key;
      final center = Offset(
        entry.value.dx * size.width,
        entry.value.dy * size.height,
      );

      if (driverJoints.contains(joint)) {
        canvas.drawCircle(center, radius, driverPaint);
        _drawJointLabel(canvas, center, radius, joint, size);
      } else if (symptomJoints.contains(joint)) {
        canvas.drawCircle(center, radius, symptomPaint);
        _drawJointLabel(canvas, center, radius, joint, size);
      }

      // Selection ring.
      if (selectedJoints.contains(joint)) {
        canvas.drawCircle(center, radius + 3, selectedPaint);
      }
    }
  }

  void _drawJointLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String joint,
    Size size,
  ) {
    final label = _readableJointName(joint);
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: size.width * 0.028,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFF424242)))
      ..addText(label);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.2));

    canvas.drawParagraph(
      paragraph,
      Offset(
        center.dx - paragraph.maxIntrinsicWidth / 2,
        center.dy + radius + 2,
      ),
    );
  }

  static String? _extractDriverJoint(Finding finding) {
    if (finding.upstreamDriver == null) return null;
    // upstreamDriver format: "left_ankle ankle restriction"
    // Find the compensation whose joint appears at the start.
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
