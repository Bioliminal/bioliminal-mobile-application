import 'package:flutter/material.dart';

enum SignalStatus { disconnected, clean, saturated }

class SignalLED extends StatelessWidget {
  const SignalLED({super.key, required this.status, required this.label});

  final SignalStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color;
    bool pulsing = false;

    switch (status) {
      case SignalStatus.clean:
        color = const Color(0xFF00D4AA); // Aqua
      case SignalStatus.saturated:
        color = Colors.orange;
        pulsing = true;
      case SignalStatus.disconnected:
        color = Colors.white10;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LEDIndicator(color: color, pulsing: pulsing),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LEDIndicator extends StatefulWidget {
  const _LEDIndicator({required this.color, required this.pulsing});
  final Color color;
  final bool pulsing;

  @override
  State<_LEDIndicator> createState() => _LEDIndicatorState();
}

class _LEDIndicatorState extends State<_LEDIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_LEDIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !oldWidget.pulsing) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && oldWidget.pulsing) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = widget.pulsing ? 0.3 + (_controller.value * 0.7) : 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              if (widget.color != Colors.white10)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4 * opacity),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
            ],
          ),
        );
      },
    );
  }
}
