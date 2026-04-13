import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';

class MuscleActivationSidebar extends ConsumerWidget {
  const MuscleActivationSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emgData = ref.watch(latestEMGDataProvider);
    final theme = Theme.of(context);

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Text(
            'sEMG',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _EMGBarPainter(
                    data: emgData,
                    color: theme.colorScheme.secondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EMGBarPainter extends CustomPainter {
  const _EMGBarPainter({required this.data, required this.color});

  final EMGData data;
  final Color color;

  static const List<String> _labels = [
    'LG', 'LS', 'RG', 'RS', 'LVM', 'RVM', 'LGM', 'RGM', 'LES', 'RES'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = size.height / 10;

    for (var i = 0; i < 10; i++) {
      final y = i * spacing + (spacing / 2);
      final value = data.channels[i].clamp(0.0, 1.0);
      
      // Draw background track
      final bgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y - 4, size.width, 8),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // Draw active bar
      final activePaint = Paint()
        ..color = color.withValues(alpha: 0.3 + (value * 0.7))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y - 4, size.width * value, 8),
          const Radius.circular(4),
        ),
        activePaint,
      );

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: const TextStyle(color: Colors.white38, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(0, y - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _EMGBarPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
