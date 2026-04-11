import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:auralink/core/providers.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Enable cloud sync first to initialize Firebase services
      ref.read(cloudSyncEnabledProvider.notifier).enable();

      final auth = ref.read(authServiceProvider);
      if (auth == null) {
        throw StateError('AuthService failed to initialize.');
      }
      await auth.signIn(); // Using existing anonymous or future email/pass

      if (mounted) context.go('/history');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ACCOUNT'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_done_outlined,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Secure Cloud Backup',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sync your assessments across devices and never lose your movement history.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSecondary,
                        ),
                      )
                    : const Text('ENABLE CLOUD SYNC'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Text(
                'CONTINUE OFFLINE',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
