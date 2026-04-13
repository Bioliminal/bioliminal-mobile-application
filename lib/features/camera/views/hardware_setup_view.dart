import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';
import '../widgets/placement_ghost_skeleton.dart';
import '../widgets/signal_led.dart';

class HardwareSetupView extends ConsumerWidget {
  const HardwareSetupView({super.key});

  static const List<String> _muscleLabels = [
    'L-Gastrocnemius', 'L-Soleus',
    'R-Gastrocnemius', 'R-Soleus',
    'L-Vastus Medialis', 'R-Vastus Medialis',
    'L-Gluteus Medius', 'R-Gluteus Medius',
    'L-Erector Spinae', 'R-Erector Spinae'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hardwareState = ref.watch(hardwareControllerProvider);
    final signalStatus = ref.watch(latestSignalStatusProvider);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('HARDWARE SETUP'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(useHardwareModeProvider.notifier).value = false;
              context.go('/screening');
            },
            child: const Text('SKIP', style: TextStyle(color: Colors.white30)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SENSOR PLACEMENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Attach the 10 sEMG electrodes to the pulsing target areas shown below.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  children: [
                    // Ghost Skeleton Placement Guide
                    const Expanded(
                      flex: 2,
                      child: PlacementGhostSkeleton(),
                    ),
                    const SizedBox(width: 24),
                    // Signal Status LEDs
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, i) {
                            return SignalLED(
                              status: signalStatus[i] ?? SignalStatus.disconnected,
                              label: _muscleLabels[i],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (hardwareState == HardwareConnectionState.disconnected)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => ref.read(hardwareControllerProvider.notifier).startScan(),
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('SCAN FOR SENSOR HUB'),
                  ),
                )
              else if (hardwareState == HardwareConnectionState.connected)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(useHardwareModeProvider.notifier).value = true;
                      context.go('/screening');
                    },
                    child: const Text('BEGIN SCREENING'),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
