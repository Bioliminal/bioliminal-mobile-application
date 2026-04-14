import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bioliminal/core/theme.dart';

class AuthOptionsView extends StatelessWidget {
  const AuthOptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Branding / Logo Placeholder
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'BIOLIMINAL',
                style: theme.textTheme.headlineLarge?.copyWith(
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Precision movement analysis and clinical biopotential sensing.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/login'), // We'll update login to handle both
                  child: const Text('CREATE ACCOUNT'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/login'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'LOG IN',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.go('/history'),
                child: Text(
                  'CONTINUE WITHOUT ACCOUNT',
                  style: const TextStyle(
                    color: Colors.white30,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white10,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
