import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auralink/core/theme.dart';
import 'package:auralink/core/providers.dart';

class AIModelSettingsView extends ConsumerWidget {
  const AIModelSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedModel = ref.watch(selectedAIModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI ENGINE'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _modelOption(
            'Pose Detection v2',
            'High-precision tracking optimized for clinical analysis. Recommended for most users.',
            'v2.4.1',
            theme,
            selectedModel,
            (val) => ref.read(selectedAIModelProvider.notifier).set(val),
          ),
          _modelOption(
            'Legacy Engine v1',
            'Lower compute requirements for older devices. May reduce tracking accuracy.',
            'v1.0.8',
            theme,
            selectedModel,
            (val) => ref.read(selectedAIModelProvider.notifier).set(val),
          ),
          _modelOption(
            'Experimental v3 (Beta)',
            'New architecture with faster frame rates but potentially unstable joint confidence.',
            'v3.0.0-alpha',
            theme,
            selectedModel,
            (val) => ref.read(selectedAIModelProvider.notifier).set(val),
          ),
          const SizedBox(height: 48),
          Text(
            'Engine version affects landmark visibility thresholds and angle calculation precision.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _modelOption(
    String name,
    String desc,
    String version,
    ThemeData theme,
    String selectedModel,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = selectedModel == name;

    return GestureDetector(
      onTap: () => onSelect(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: isSelected
            ? AuraLinkTheme.glassEffect.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 1,
                ),
              )
            : AuraLinkTheme.glassEffect,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        version,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.24,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}
