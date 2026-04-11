import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auralink/core/providers.dart' as core_providers;

class CalibrationView extends ConsumerStatefulWidget {
  const CalibrationView({super.key});

  @override
  ConsumerState<CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends ConsumerState<CalibrationView> {
  bool _calibrating = false;
  double _progress = 0.0;
  String _status = 'Stand in front of the camera';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(core_providers.appCameraControllerProvider.notifier)
          .requestPermission();
    });
  }

  void _startCalibration() async {
    setState(() {
      _calibrating = true;
      _status = 'Analyzing environment...';
    });

    // Simulate calibration steps
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _progress = i / 100;
        if (i == 30) _status = 'Optimizing landmark thresholds...';
        if (i == 60) _status = 'Calibrating focal length...';
        if (i == 90) _status = 'Finalizing...';
      });
    }

    if (mounted) {
      setState(() {
        _status = 'Calibration Complete';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref
        .watch(core_providers.appCameraControllerProvider)
        .value;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (cameraState is core_providers.CameraStreaming ||
              cameraState is core_providers.CameraReady)
            Positioned.fill(
              child: _CameraPreviewWrapper(
                controller: cameraState is core_providers.CameraStreaming
                    ? (cameraState).controller
                    : (cameraState as core_providers.CameraReady).controller,
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFF0F172A),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CALIBRATION',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Scanning UI
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.5,
                        ),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_calibrating)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      theme.colorScheme.secondary.withValues(
                                        alpha: 0.2,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: [value - 0.1, value, value + 0.1],
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              if (_calibrating)
                                setState(() {}); // Loop animation
                            },
                          ),
                        Icon(
                          Icons.center_focus_strong,
                          size: 80,
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    _status,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_calibrating)
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.secondary,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Ensure you are in a well-lit area and your full body is visible.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),

                  const Spacer(),

                  if (!_calibrating)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _startCalibration,
                        child: const Text('START CALIBRATION'),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewWrapper extends StatelessWidget {
  const _CameraPreviewWrapper({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}
