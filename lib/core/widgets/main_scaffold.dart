import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hardwareState = ref.watch(hardwareControllerProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'BIOLIMINAL',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 4.0,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _HardwareStatusIndicator(state: hardwareState),
          const SizedBox(width: 16),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BioliminalTheme.glassEffect.copyWith(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
              ),
              child: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: theme.colorScheme.secondary,
                unselectedItemColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'HISTORY',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'SETTINGS',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HardwareStatusIndicator extends ConsumerWidget {
  const _HardwareStatusIndicator({required this.state});
  final HardwareConnectionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final Color color;
    final IconData icon;
    final String label;

    switch (state) {
      case HardwareConnectionState.connected:
        color = theme.colorScheme.secondary;
        icon = Icons.bluetooth_connected;
        label = 'CONNECTED';
      case HardwareConnectionState.scanning:
      case HardwareConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.bluetooth_searching;
        label = 'SEARCHING';
      case HardwareConnectionState.disconnected:
        color = theme.colorScheme.onSurface.withValues(alpha: 0.2);
        icon = Icons.bluetooth_disabled;
        label = 'OFFLINE';
    }

    return InkWell(
      onTap: state == HardwareConnectionState.disconnected
          ? () => ref.read(hardwareControllerProvider.notifier).startScan()
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
