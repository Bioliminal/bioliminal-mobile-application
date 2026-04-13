import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Non-skippable educational disclaimer required by FDA wellness/CDS guidance.
/// User must scroll to bottom and tap "I Understand" before proceeding.
class DisclaimerView extends StatefulWidget {
  const DisclaimerView({super.key});

  @override
  State<DisclaimerView> createState() => _DisclaimerViewState();
}

class _DisclaimerViewState extends State<DisclaimerView> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _hasScrolledToBottom = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              const _OnboardingSlide(
                icon: Icons.auto_awesome,
                title: 'Clinical-Grade\nMotion Analysis',
                body:
                    'Bioliminal uses advanced computer vision to analyze your movement patterns and identify the underlying drivers of compensation.',
              ),
              const _OnboardingSlide(
                icon: Icons.shield_outlined,
                title: 'Secure & Private\nArchitecture',
                body:
                    'Your raw video never leaves your device. Only anonymized movement landmarks are sent to our secure clinical server for processing.',
              ),
              _DisclaimerSlide(
                onScrollToBottom: () =>
                    setState(() => _hasScrolledToBottom = true),
                hasScrolled: _hasScrolledToBottom,
              ),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                if (_currentPage < 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => _dot(i == _currentPage, theme),
                    ),
                  ),
                const SizedBox(height: 32),
                if (_currentPage < 2)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('CONTINUE'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _hasScrolledToBottom
                          ? () => context.go('/hardware-setup')
                          : null,
                      child: Text(
                        _hasScrolledToBottom
                            ? 'BEGIN ANALYSIS'
                            : 'PLEASE READ DISCLAIMER',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.secondary : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.secondary),
          const SizedBox(height: 48),
          Text(
            title,
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DisclaimerSlide extends StatelessWidget {
  const _DisclaimerSlide({
    required this.onScrollToBottom,
    required this.hasScrolled,
  });
  final VoidCallback onScrollToBottom;
  final bool hasScrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPORTANT NOTICE',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.maxScrollExtent == 0 ||
                      n.metrics.pixels >= n.metrics.maxScrollExtent - 20) {
                    onScrollToBottom();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        'Educational Purpose',
                        'Bioliminal is for educational use only. It is not a medical device and does not diagnose injuries or prescribe treatment. The analysis provided is based on computer vision patterns and does not constitute medical advice.',
                        theme,
                      ),
                      _section(
                        'Professional Consultation',
                        'Always consult a qualified health professional before starting a new exercise program, especially if you have pre-existing conditions, chronic pain, or are recovering from an injury.',
                        theme,
                      ),
                      _section(
                        'Usage Agreement',
                        'By using this app, you acknowledge that you are moving at your own risk. You understand that findings are observations based on movement patterns and not clinical diagnoses.',
                        theme,
                      ),
                      _section(
                        'Data Privacy & Cloud Processing',
                        'Analysis is performed on our secure clinical server. Only anonymized landmark data is transmitted. Your raw video never leaves your device.',
                        theme,
                      ),
                      _section(
                        'Liability',
                        'Bioliminal and its developers are not liable for any injuries or damages resulting from the use of this application or the implementation of any movement suggestions.',
                        theme,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'By tapping "BEGIN ANALYSIS", you confirm you have read and accepted these terms.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
