import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:auralink/core/theme.dart';

/// Non-skippable educational disclaimer required by FDA wellness/CDS guidance.
/// User must scroll to bottom and tap "I Understand" before proceeding.
class DisclaimerView extends StatefulWidget {
  const DisclaimerView({super.key});

  @override
  State<DisclaimerView> createState() => _DisclaimerViewState();
}

class _DisclaimerViewState extends State<DisclaimerView> {
  bool _hasScrolledToBottom = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AuraLinkTheme.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Before We Begin',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 20) {
                    setState(() => _hasScrolledToBottom = true);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        'What This Tool Does',
                        'AuraLink is an educational movement screening tool. '
                            'It uses your phone camera to observe how you move '
                            'during four simple exercises, then generates a '
                            'personalized report highlighting areas that may '
                            'benefit from attention.',
                        theme,
                      ),
                      _section(
                        'What This Tool Is NOT',
                        'This is not a medical device, diagnostic tool, or '
                            'substitute for professional evaluation. It does '
                            'not diagnose injuries, predict injury risk, or '
                            'prescribe treatment. Findings are educational '
                            'observations, not clinical assessments.',
                        theme,
                      ),
                      _section(
                        'How To Use Your Results',
                        'Your report includes discussion points designed to '
                            'start a conversation with a qualified practitioner '
                            '(physical therapist, athletic trainer, etc.). '
                            'Every finding cites its evidence source so you '
                            'and your practitioner can evaluate it together.',
                        theme,
                      ),
                      _section(
                        'Your Privacy',
                        'All movement analysis happens on your device. No '
                            'video is stored or transmitted. By default, your '
                            'data stays on your device. You can optionally '
                            'enable cloud backup in settings. You control '
                            'whether to save or share your report.',
                        theme,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By continuing you agree to our ',
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openLink(
                                        'https://auralink.app/privacy',
                                      ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openLink(
                                        'https://auralink.app/terms',
                                      ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _hasScrolledToBottom
                      ? () => context.go('/screening')
                      : null,
                  child: Text(
                    _hasScrolledToBottom
                        ? 'I Understand — Begin Screening'
                        : 'Please read the full disclaimer',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLink(String url) {
    // TODO: launch URL via url_launcher once added to pubspec
    debugPrint('Open: $url');
  }

  Widget _section(String title, String body, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
