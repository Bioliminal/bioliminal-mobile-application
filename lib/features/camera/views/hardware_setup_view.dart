import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';
import 'package:bioliminal/features/camera/services/sync_calibration_service.dart';
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
    final setupStep = ref.watch(hardwareSetupStepProvider);
    final hardwareState = ref.watch(hardwareControllerProvider);
    final signalStatus = ref.watch(latestSignalStatusProvider);
    final syncResult = ref.watch(syncCalibrationServiceProvider);

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
                _stepLabel(setupStep),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _stepDescription(setupStep),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: setupStep == HardwareSetupStep.syncing 
                  ? _SyncStompUI(syncResult: syncResult)
                  : Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: PlacementGhostSkeleton(),
                    ),
                    const SizedBox(width: 24),
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
              _ActionButtons(
                step: setupStep,
                connectionState: hardwareState,
                syncResult: syncResult,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel(HardwareSetupStep step) {
    return switch (step) {
      HardwareSetupStep.scanning => 'STEP 1: CONNECTION',
      HardwareSetupStep.placing => 'STEP 2: PLACEMENT',
      HardwareSetupStep.syncing => 'STEP 3: SYNCHRONIZATION',
      HardwareSetupStep.ready => 'STEP 4: COMPLETE',
    };
  }

  String _stepDescription(HardwareSetupStep step) {
    return switch (step) {
      HardwareSetupStep.scanning => 'Searching for your Bioliminal ESP32-S3 sensor hub...',
      HardwareSetupStep.placing => 'Attach the 10 sEMG electrodes to the pulsing target areas.',
      HardwareSetupStep.syncing => 'Stand still, then perform one sharp foot stomp when the indicator appears.',
      HardwareSetupStep.ready => 'Sensors connected and time-aligned. You are ready to begin.',
    };
  }
}

class _SyncStompUI extends StatelessWidget {
  const _SyncStompUI({required this.syncResult});
  final SyncResult? syncResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSynced = syncResult != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isSynced ? theme.colorScheme.secondary : Colors.orange)
                  .withValues(alpha: 0.1),
              border: Border.all(
                color: isSynced ? theme.colorScheme.secondary : Colors.orange,
                width: 2,
              ),
            ),
            child: Icon(
              isSynced ? Icons.check : Icons.bolt,
              size: 64,
              color: isSynced ? theme.colorScheme.secondary : Colors.orange,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            isSynced ? 'SYNC SUCCESSFUL' : 'STOMP NOW',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isSynced ? theme.colorScheme.secondary : Colors.orange,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isSynced) ...[
            const SizedBox(height: 12),
            Text(
              'Offset: ${syncResult!.offsetMs}ms',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.step,
    required this.connectionState,
    required this.syncResult,
  });

  final HardwareSetupStep step;
  final HardwareConnectionState connectionState;
  final SyncResult? syncResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (step == HardwareSetupStep.scanning) {
      if (connectionState == HardwareConnectionState.disconnected) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => ref.read(hardwareControllerProvider.notifier).startScan(),
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('SCAN FOR SENSOR HUB'),
          ),
        );
      } else if (connectionState == HardwareConnectionState.connected) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(hardwareSetupStepProvider.notifier).value = HardwareSetupStep.placing,
            child: const Text('CONTINUE TO PLACEMENT'),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (step == HardwareSetupStep.placing) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => ref.read(hardwareSetupStepProvider.notifier).value = HardwareSetupStep.syncing,
          child: const Text('PROCEED TO SYNC'),
        ),
      );
    }

    if (step == HardwareSetupStep.syncing) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: syncResult != null
              ? () => ref.read(hardwareSetupStepProvider.notifier).value = HardwareSetupStep.ready
              : null,
          child: const Text('FINALIZE CALIBRATION'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          ref.read(useHardwareModeProvider.notifier).value = true;
          context.go('/screening');
        },
        child: const Text('BEGIN SCREENING'),
      ),
    );
  }
}
