import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../widgets/auth_form_scaffold.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      ref.read(cloudSyncEnabledProvider.notifier).enable();
      final auth = ref.read(authServiceProvider);
      if (auth == null) {
        throw StateError('AuthService failed to initialize.');
      }
      await auth.signInWithEmail(email: email, password: password);
      if (mounted) context.go('/history');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _mapError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Try again.';
        });
      }
    }
  }

  String _mapError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No account found with that email.',
      'wrong-password' || 'invalid-credential' =>
        'Email or password is incorrect.',
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Try again in a moment.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => 'Sign-in failed. ${e.message ?? ''}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthFormScaffold(
      eyebrow: 'WELCOME BACK',
      title: 'Sign in',
      fields: [
        _LabeledField(
          label: 'EMAIL',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 20),
        _LabeledField(
          label: 'PASSWORD',
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
        ),
      ],
      error: _error,
      primaryButton: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SIGN IN'),
        ),
      ),
      secondary: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _showGoogleComingSoon(context),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('SIGN IN WITH GOOGLE'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pushReplacement('/sign-up'),
            child: Text(
              "DON'T HAVE AN ACCOUNT? CREATE ONE",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoogleComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In is coming soon.'),
        backgroundColor: BioliminalTheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2.0,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.secondary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
