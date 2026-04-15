import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../../waitlist/widgets/waitlist_capture.dart';
import 'marketing_tokens.dart';

// Site footer for all marketing pages except home (home has its own footer).
// Bundles the inline waitlist capture + 3 GitHub repo links + legal strip.

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.source});
  final WaitlistSource source;

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Container(
      color: MarketingPalette.bg,
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline waitlist capture block.
          Container(
            padding: EdgeInsets.all(narrow ? 28 : 44),
            decoration: BoxDecoration(
              border: Border.all(color: MarketingPalette.hairline, width: 1),
            ),
            child: WaitlistCapture(source: source, compact: true),
          ),
          SizedBox(height: narrow ? 56 : 80),
          // Repo links grid.
          const _FooterLabel(label: '// CODE'),
          const SizedBox(height: 24),
          narrow
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RepoRow(
                      name: 'bioliminal-mobile-application',
                      purpose: 'Flutter app — this surface.',
                      url: BioliminalRepos.mobileApp,
                    ),
                    SizedBox(height: 20),
                    _RepoRow(
                      name: 'esp32-firmware',
                      purpose: 'sEMG capture + haptic cueing.',
                      url: BioliminalRepos.esp32,
                    ),
                    SizedBox(height: 20),
                    _RepoRow(
                      name: 'ML_RandD_Server',
                      purpose:
                          'Hardware research, ML training, team docs.',
                      url: BioliminalRepos.mlServer,
                    ),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RepoRow(
                        name: 'bioliminal-mobile-application',
                        purpose: 'Flutter app — this surface.',
                        url: BioliminalRepos.mobileApp,
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: _RepoRow(
                        name: 'esp32-firmware',
                        purpose: 'sEMG capture + haptic cueing.',
                        url: BioliminalRepos.esp32,
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: _RepoRow(
                        name: 'ML_RandD_Server',
                        purpose:
                            'Hardware research, ML training, team docs.',
                        url: BioliminalRepos.mlServer,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: narrow ? 56 : 80),
          // Legal strip.
          Container(height: 1, color: MarketingPalette.hairline),
          const SizedBox(height: 24),
          narrow
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegalText('BIOLIMINAL · 2026'),
                    SizedBox(height: 10),
                    _LegalText('NOT A MEDICAL DEVICE'),
                    SizedBox(height: 10),
                    _LegalText('FDA GENERAL WELLNESS POLICY'),
                  ],
                )
              : const Row(
                  children: [
                    _LegalText('BIOLIMINAL · 2026'),
                    SizedBox(width: 32),
                    _LegalText('NOT A MEDICAL DEVICE'),
                    Spacer(),
                    _LegalText('FDA GENERAL WELLNESS POLICY'),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FooterLabel extends StatelessWidget {
  const _FooterLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: mktMono(
        11,
        color: MarketingPalette.subtle,
        letterSpacing: 2.6,
        weight: FontWeight.w500,
      ),
    );
  }
}

class _RepoRow extends StatefulWidget {
  const _RepoRow({
    required this.name,
    required this.purpose,
    required this.url,
  });

  final String name;
  final String purpose;
  final String url;

  @override
  State<_RepoRow> createState() => _RepoRowState();
}

class _RepoRowState extends State<_RepoRow> {
  bool _hover = false;

  Future<void> _open() async {
    final uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final nameColor =
        _hover ? MarketingPalette.signal : MarketingPalette.text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: mktMono(
                    13,
                    color: nameColor,
                    weight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '↗',
                  style: mktMono(12, color: nameColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.purpose,
              style: mktBody(
                13,
                color: MarketingPalette.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: mktMono(
        10,
        color: MarketingPalette.subtle,
        letterSpacing: 2.4,
      ),
    );
  }
}
