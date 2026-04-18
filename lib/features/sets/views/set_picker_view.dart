import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';

/// Picks which set to start. v0 ships only Bicep Curl; the layout is a
/// vertical list of cards so adding more movements later is a single
/// tile addition. Each tile selects the arm side inline (no extra modal
/// — fewer taps for demo-day flow).
class SetPickerView extends StatelessWidget {
  const SetPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('CHOOSE A SET'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SetCard(
            title: 'BICEP CURL',
            subtitle: 'Single arm · EMG fatigue + form coaching',
            actions: [
              _SideButton(
                label: 'LEFT ARM',
                onPressed: () => context.go('/bicep-curl?side=left'),
              ),
              _SideButton(
                label: 'RIGHT ARM',
                onPressed: () => context.go('/bicep-curl?side=right'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: BioliminalTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: actions[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BioliminalTheme.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: const TextStyle(letterSpacing: 1.5, fontSize: 12),
      ),
    );
  }
}
