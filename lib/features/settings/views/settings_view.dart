import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auralink/core/theme.dart';
import 'package:auralink/core/providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final aiModel = ref.watch(selectedAIModelProvider);

    return Scaffold(
      backgroundColor: AuraLinkTheme.screenBackground,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(theme, 'ACCOUNT'),
            _item(
              Icons.person_outline,
              'User Profile',
              profile.name,
              theme,
              onTap: () => context.push('/profile'),
            ),
            _item(
              Icons.cloud_outlined,
              'Cloud Backup',
              'Disabled (Local only)',
              theme,
              onTap: () => context.push('/login'),
            ),
            const SizedBox(height: 32),
            _sectionHeader(theme, 'ANALYSIS'),
            _item(
              Icons.videocam_outlined,
              'Camera Calibration',
              'Auto-calibrate',
              theme,
              onTap: () => context.push('/calibration'),
            ),
            _item(
              Icons.precision_manufacturing_outlined,
              'AI Model',
              aiModel,
              theme,
              onTap: () => context.push('/ai-settings'),
            ),
            const SizedBox(height: 32),
            _sectionHeader(theme, 'ABOUT'),
            _item(
              Icons.info_outline,
              'AuraLink Version',
              '1.0.0-premium',
              theme,
            ),
            _item(
              Icons.policy_outlined,
              'Privacy Policy',
              '',
              theme,
              onTap: () => _showPrivacyPolicy(context, theme),
            ),
            const SizedBox(height: 48),
            Center(
              child: TextButton(
                onPressed: () => context.go('/disclaimer'),
                child: const Text(
                  'RE-WATCH ONBOARDING',
                  style: TextStyle(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 120), // Bottom padding for glass nav
          ],
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
            'By using AuraLink, you agree to local data processing for the purpose of mobility assessment.',
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

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.5,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    String value,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: AuraLinkTheme.glassEffect,
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
            if (value.isNotEmpty)
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
