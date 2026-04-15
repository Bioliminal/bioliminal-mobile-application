import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../../waitlist/widgets/waitlist_capture.dart';
import 'marketing_tokens.dart';

// Site footer for all marketing pages except home (home has its own footer).
// Bundles the inline waitlist capture + 3 GitHub repo links + legal strip.

class SiteFooter extends StatelessWidget {
  const SiteFooter({
    super.key,
    required this.source,
    this.showLaunchMarquee = false,
  });

  final WaitlistSource source;

  // Homepage surfaces the demo launch date at the top of the footer. Other
  // pages have their own demo CTAs so they skip it.
  final bool showLaunchMarquee;

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);

    const repoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterLabel(label: '// CODE'),
        SizedBox(height: 20),
        _RepoRow(
          name: 'bioliminal-mobile-application',
          purpose: 'Flutter app — this surface.',
          url: BioliminalRepos.mobileApp,
        ),
        SizedBox(height: 18),
        _RepoRow(
          name: 'esp32-firmware',
          purpose: 'sEMG capture + haptic cueing.',
          url: BioliminalRepos.esp32,
        ),
        SizedBox(height: 18),
        _RepoRow(
          name: 'ML_RandD_Server',
          purpose: 'Hardware research, ML training, team docs.',
          url: BioliminalRepos.mlServer,
        ),
      ],
    );

    const contactColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterLabel(label: '// CONTACT'),
        SizedBox(height: 20),
        _ContactLink(
          label: 'EMAIL',
          value: 'bioliminal@gmail.com',
          url: 'mailto:bioliminal@gmail.com',
        ),
        SizedBox(height: 18),
        _ContactLink(
          label: 'REDDIT',
          value: 'u/BioliminalTeam',
          url: 'https://www.reddit.com/user/BioliminalTeam',
        ),
        SizedBox(height: 18),
        _ContactLink(
          label: 'SUBSTACK',
          value: 'bioliminal.substack.com',
          url: 'https://bioliminal.substack.com',
        ),
      ],
    );

    return Container(
      color: MarketingPalette.bg,
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 56 : 88,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLaunchMarquee) ...[
            _LaunchMarquee(narrow: narrow),
            SizedBox(height: narrow ? 48 : 72),
            Container(height: 1, color: MarketingPalette.hairline),
            SizedBox(height: narrow ? 48 : 72),
          ],
          // Main row: waitlist + repos + contact. Stacked on narrow.
          if (narrow) ...[
            WaitlistCapture(source: source, compact: true),
            const SizedBox(height: 44),
            repoColumn,
            const SizedBox(height: 44),
            contactColumn,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: WaitlistCapture(source: source, compact: true),
                ),
                const SizedBox(width: 56),
                const Expanded(flex: 4, child: repoColumn),
                const SizedBox(width: 56),
                const Expanded(flex: 3, child: contactColumn),
              ],
            ),
          SizedBox(height: narrow ? 48 : 64),
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

// Homepage-only launch marquee: left = demo date + city, right = computed
// countdown so the band reads balanced at every viewport instead of leaving
// 80% dead canvas beside the date.
class _LaunchMarquee extends StatelessWidget {
  const _LaunchMarquee({required this.narrow});
  final bool narrow;

  static final _launch = DateTime(2026, 4, 20);

  @override
  Widget build(BuildContext context) {
    final daysOut = _launch.difference(DateTime.now()).inDays;
    final shipped = daysOut <= 0;
    final countLabel = shipped ? 'LIVE' : daysOut.toString().padLeft(2, '0');
    final countSub =
        shipped ? 'Demo is live — try it.' : 'Days until Austin demo day.';

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DEMO ↘',
          style: mktMono(
            11,
            color: MarketingPalette.subtle,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '04.20.26',
          style: mktDisplay(
            narrow ? 48 : 80,
            weight: FontWeight.w600,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Austin, Texas',
          style: mktDisplay(
            narrow ? 20 : 28,
            italic: true,
            weight: FontWeight.w400,
            letterSpacing: -0.5,
            color: MarketingPalette.muted,
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment:
          narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shipped ? '// STATUS' : '// T-MINUS',
          style: mktMono(
            11,
            color: MarketingPalette.subtle,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          countLabel,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: mktDisplay(
            narrow ? 48 : 80,
            weight: FontWeight.w600,
            letterSpacing: -2,
            height: 1,
            color:
                shipped ? MarketingPalette.signal : MarketingPalette.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          countSub,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: mktDisplay(
            narrow ? 20 : 28,
            italic: true,
            weight: FontWeight.w400,
            letterSpacing: -0.5,
            color: MarketingPalette.muted,
          ),
        ),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          const SizedBox(height: 40),
          right,
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [left, right],
        ),
      ),
    );
  }
}

class _ContactLink extends StatefulWidget {
  const _ContactLink({
    required this.label,
    required this.value,
    required this.url,
  });
  final String label;
  final String value;
  final String url;

  @override
  State<_ContactLink> createState() => _ContactLinkState();
}

class _ContactLinkState extends State<_ContactLink> {
  bool _hover = false;

  Future<void> _open() async {
    final uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: mktMono(
                10,
                color: MarketingPalette.subtle,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.value,
              style: mktBody(
                15,
                color:
                    _hover ? MarketingPalette.signal : MarketingPalette.text,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
