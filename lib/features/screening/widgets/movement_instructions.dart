import 'package:flutter/material.dart';

import '../models/movement.dart';

class MovementInstructions extends StatelessWidget {
  const MovementInstructions({
    super.key,
    required this.config,
    required this.remaining,
  });

  final MovementConfig config;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGetReady = remaining.inSeconds > (config.duration.inSeconds - 3);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCC000000),
              Color(0x00000000),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: isGetReady
              ? Center(
                  child: Text(
                    'Get Ready...',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      config.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.instruction,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(remaining),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
