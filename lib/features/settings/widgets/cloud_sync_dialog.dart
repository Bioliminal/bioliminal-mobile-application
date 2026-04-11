import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/core/providers.dart';

/// High-friction opt-in dialog for cloud sync. The user must type "SYNC" to
/// confirm, ensuring no accidental data upload. Shows what data is synced and
/// that the action is reversible.
class CloudSyncDialog extends ConsumerStatefulWidget {
  const CloudSyncDialog({super.key});

  /// Show the dialog and return `true` if the user confirmed opt-in.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CloudSyncDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends ConsumerState<CloudSyncDialog> {
  final _controller = TextEditingController();
  bool _isConfirmEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final enabled = _controller.text.trim().toUpperCase() == 'SYNC';
    if (enabled != _isConfirmEnabled) {
      setState(() => _isConfirmEnabled = enabled);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    ref.read(cloudSyncEnabledProvider.notifier).enable();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Enable Cloud Sync'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By default, all your data stays on this device. Enabling cloud '
              'sync will upload the following to secure cloud storage:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _bulletPoint('Assessment session data'),
            _bulletPoint('Generated reports'),
            _bulletPoint('PDF exports'),
            const SizedBox(height: 12),
            Text(
              'What is NOT synced:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _bulletPoint('Camera footage or images'),
            _bulletPoint('Raw pose estimation data'),
            const SizedBox(height: 16),
            Text(
              'This action is reversible — you can disable cloud sync at any '
              'time in settings, and request deletion of your cloud data.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Type SYNC below to confirm:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'SYNC',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmEnabled ? _onConfirm : null,
          child: const Text('Enable Cloud Sync'),
        ),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u2022 '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
