import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/providers.dart';

class HardwareSetupView extends ConsumerWidget {
  const HardwareSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('HARDWARE SETUP')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hardware Setup Placeholder'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(useHardwareModeProvider.notifier).value = false;
                context.go('/screening');
              },
              child: const Text('SKIP (CAMERA ONLY)'),
            ),
          ],
        ),
      ),
    );
  }
}
