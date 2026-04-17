import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../widgets/auth_form_scaffold.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
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
      await auth.createAccount(
        email: email,
        password: password,
        displayName: name,
      );
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
      'email-already-in-use' =>
        'An account with this email already exists. Sign in instead.',
      'weak-password' => 'Password is too weak. Try something stronger.',
      'invalid-email' => 'That email address is not valid.',
      'operation-not-allowed' =>
        'Email sign-up is disabled. Contact support.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => 'Sign-up failed. ${e.message ?? ''}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthFormScaffold(
      eyebrow: 'NEW ACCOUNT',
      title: 'Create\nAccount',
      fields: [
        _LabeledField(
          label: 'DISPLAY NAME',
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 20),
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
          hint: 'at least 6 characters',
          autofillHints: const [AutofillHints.newPassword],
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
              : const Text('CREATE ACCOUNT'),
        ),
      ),
      secondary: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _showGoogleComingSoon(context),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('SIGN UP WITH GOOGLE'),
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
            onPressed: () => context.pushReplacement('/sign-in'),
            child: Text(
              'ALREADY HAVE AN ACCOUNT? SIGN IN',
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
    this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hint;
  final TextCapitalization textCapitalization;
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
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.25),
            ),
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
