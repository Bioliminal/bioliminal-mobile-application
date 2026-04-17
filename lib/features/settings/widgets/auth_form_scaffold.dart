import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';

/// Shared chrome for sign-up and sign-in views. Top-left back arrow,
/// in-content eyebrow + headline, field stack, primary button, and
/// secondary area (alternate provider + switch-mode link).
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.fields,
    required this.primaryButton,
    required this.secondary,
    this.error,
  });

  final String eyebrow;
  final String title;
  final List<Widget> fields;
  final Widget primaryButton;
  final Widget secondary;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: () => context.pop(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 40),
                    ...fields,
                    if (error != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    primaryButton,
                    const SizedBox(height: 24),
                    secondary,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
