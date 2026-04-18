import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final isPremium = ref.watch(isPremiumProvider);
    final hardwareState = ref.watch(hardwareControllerProvider);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETTINGS', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 40),

              const _SectionHeader('ACCOUNT'),
              _Row(
                title: 'User Profile',
                value: profile?.name ?? 'Not signed in',
                onTap: () => context.push('/profile'),
              ),
              _Row(
                title: 'Cloud Backup',
                value: profile != null
                    ? 'Synced'
                    : 'Disabled (Local only)',
                onTap: () => context.push('/login'),
              ),
              const SizedBox(height: 40),

              const _SectionHeader('PREMIUM & HARDWARE'),
              _Row(
                title: 'Premium Mode',
                subtitle: 'Unlock clinical kinetics',
                trailing: Switch(
                  value: isPremium,
                  onChanged: (_) =>
                      ref.read(isPremiumProvider.notifier).toggle(),
                  activeThumbColor: theme.colorScheme.secondary,
                ),
              ),
              _Row(
                title: 'Hardware Simulation',
                subtitle: 'Stream mock sEMG data',
                trailing: Switch(
                  value: hardwareState == HardwareConnectionState.connected,
                  onChanged: (val) {
                    final controller = ref.read(
                      hardwareControllerProvider.notifier,
                    );
                    if (val) {
                      controller.startMockData();
                    } else {
                      controller.stopMockData();
                    }
                  },
                  activeThumbColor: theme.colorScheme.secondary,
                ),
              ),
              _Row(
                title: 'BLE Debug',
                subtitle: 'Scan, inspect services, send/receive',
                onTap: () => context.push('/ble-debug'),
              ),
              const SizedBox(height: 40),

              const _SectionHeader('ANALYSIS'),
              _Row(
                title: 'Camera Calibration',
                value: 'Framing check',
                onTap: () => context.push('/calibration'),
              ),
              const SizedBox(height: 40),

              const _SectionHeader('ABOUT'),
              _Row(
                title: 'Bioliminal Version',
                value: isPremium ? '1.1.0-premium' : '1.1.0-free',
              ),
              _Row(
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context, theme),
              ),
              const SizedBox(height: 48),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/disclaimer'),
                  child: Text(
                    'RE-WATCH ONBOARDING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('PRIVACY POLICY'),
        content: const SingleChildScrollView(
          child: Text(
            'Your biometric data and screening recordings are processed locally on your device. '
            'If Cloud Backup is disabled, no skeletal data or video ever leaves your hardware. '
            'We use state-of-the-art pose estimation models to calculate joint angles in real-time. '
            'By using Bioliminal, you agree to local data processing for the purpose of mobility assessment.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 2.0,
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget right;
    if (trailing != null) {
      right = trailing!;
    } else if (value != null && value!.isNotEmpty) {
      right = Text(
        value!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.4),
        ),
      );
    } else if (onTap != null) {
      right = Icon(
        Icons.chevron_right,
        size: 18,
        color: Colors.white.withValues(alpha: 0.3),
      );
    } else {
      right = const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            right,
          ],
        ),
      ),
    );
  }
}
