import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../widgets/marketing_tokens.dart';
import '../widgets/site_footer.dart';
import '../widgets/top_nav.dart';

class CodeView extends StatelessWidget {
  const CodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: CustomScrollView(
        slivers: [
          TopNav(currentPath: '/code', source: WaitlistSource.demo),
          SliverToBoxAdapter(child: _Hero()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _ReposSection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: _LicenseSection()),
          SliverToBoxAdapter(child: MarketingDivider()),
          SliverToBoxAdapter(child: SiteFooter(source: WaitlistSource.demo)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 72 : 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('CODE'),
          SizedBox(height: narrow ? 28 : 44),
          Text(
            'Three repositories.\nOne system.',
            style: mktDisplay(
              narrow ? 56 : 108,
              italic: true,
              letterSpacing: -2.5,
              height: 0.95,
            ),
          ),
          SizedBox(height: narrow ? 28 : 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Bioliminal is open source. The Flutter app is one part of a larger system that '
              'includes ESP32 firmware for the sEMG garment and a shared research hub for '
              'hardware, ML, and team docs. Dev happens on GitLab; these are the public mirrors.',
              style: mktBody(
                narrow ? 17 : 20,
                color: MarketingPalette.muted,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReposSection extends StatelessWidget {
  const _ReposSection();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 56 : 100,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RepoCard(
            number: '01',
            name: 'bioliminal-mobile-application',
            tagline: 'Flutter app — this surface.',
            description:
                'iOS, Android, and web client. MediaPipe BlazePose pose estimation, joint-angle '
                'logic, and the fascial-chain reasoning engine run on-device. Optional cloud '
                'sync via Firestore is opt-in.',
            language: 'Dart',
            url: BioliminalRepos.mobileApp,
          ),
          SizedBox(height: 32),
          _RepoCard(
            number: '02',
            name: 'esp32-firmware',
            tagline: 'sEMG capture + haptic cueing.',
            description:
                'Firmware for the ESP32-based sEMG garment. Captures muscle activation, '
                'streams over BLE, drives haptic cueing for real-time form feedback. '
                'Phase 2 hardware — ships after the v1 app validates the reasoning layer.',
            language: 'C++',
            url: BioliminalRepos.esp32,
          ),
          SizedBox(height: 32),
          _RepoCard(
            number: '03',
            name: 'ML_RandD_Server',
            tagline:
                'Hardware research, ML training, and cross-team docs.',
            description:
                'The multidisciplinary hub. Sensor architecture decisions, the BOM, ML training '
                'pipelines and datasets, the research synthesis, and the mobile-handover '
                'integration contract all live here.',
            language: 'Python / docs',
            url: BioliminalRepos.mlServer,
          ),
        ],
      ),
    );
  }
}

class _RepoCard extends StatefulWidget {
  const _RepoCard({
    required this.number,
    required this.name,
    required this.tagline,
    required this.description,
    required this.language,
    required this.url,
  });

  final String number;
  final String name;
  final String tagline;
  final String description;
  final String language;
  final String url;

  @override
  State<_RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends State<_RepoCard> {
  bool _hover = false;

  Future<void> _open() async {
    await launchUrl(Uri.parse(widget.url),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    final borderColor = _hover ? MarketingPalette.signal : MarketingPalette.hairline;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(narrow ? 28 : 40),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _cardContents(narrow: true),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(widget.number,
                          style: mktMono(12,
                              color: MarketingPalette.signal,
                              letterSpacing: 3,
                              weight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.name,
                                style: mktMono(
                                  20,
                                  color: _hover
                                      ? MarketingPalette.signal
                                      : MarketingPalette.text,
                                  letterSpacing: 0.6,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '↗',
                                style: mktMono(18,
                                    color: _hover
                                        ? MarketingPalette.signal
                                        : MarketingPalette.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(widget.tagline,
                              style: mktBody(17,
                                  weight: FontWeight.w500,
                                  color: MarketingPalette.text,
                                  height: 1.4)),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Text(widget.description,
                                style: mktBody(16,
                                    color: MarketingPalette.muted, height: 1.55)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(widget.language.toUpperCase(),
                                  style: mktMono(
                                    10,
                                    color: MarketingPalette.subtle,
                                    letterSpacing: 2.4,
                                    weight: FontWeight.w600,
                                  )),
                              const SizedBox(width: 20),
                              Text(
                                widget.url.replaceFirst('https://', ''),
                                style: mktMono(
                                  10,
                                  color: MarketingPalette.subtle,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _cardContents({required bool narrow}) {
    return [
      Row(
        children: [
          Text(widget.number,
              style: mktMono(11,
                  color: MarketingPalette.signal,
                  letterSpacing: 3,
                  weight: FontWeight.w600)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.name,
              style: mktMono(
                15,
                color: _hover ? MarketingPalette.signal : MarketingPalette.text,
                letterSpacing: 0.6,
                weight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '↗',
            style: mktMono(15,
                color: _hover
                    ? MarketingPalette.signal
                    : MarketingPalette.muted),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(widget.tagline,
          style: mktBody(15,
              weight: FontWeight.w500,
              color: MarketingPalette.text,
              height: 1.4)),
      const SizedBox(height: 12),
      Text(widget.description,
          style: mktBody(14,
              color: MarketingPalette.muted, height: 1.55)),
      const SizedBox(height: 16),
      Text(widget.language.toUpperCase(),
          style: mktMono(
            10,
            color: MarketingPalette.subtle,
            letterSpacing: 2.4,
            weight: FontWeight.w600,
          )),
    ];
  }
}

class _LicenseSection extends StatelessWidget {
  const _LicenseSection();

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 56 : 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketingSectionLabel('LICENSE & CONTRIBUTIONS'),
          SizedBox(height: narrow ? 24 : 36),
          Text(
            'Use it. Fork it.\nTell us what breaks.',
            style: mktDisplay(narrow ? 38 : 64,
                italic: true, letterSpacing: -1.5, height: 1.02),
          ),
          SizedBox(height: narrow ? 28 : 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Each repo ships with its own LICENSE. Development happens on GitLab; these '
              'GitHub repos are push-mirrored on a schedule. Issues and PRs opened here are '
              'monitored and responded to.',
              style: mktBody(narrow ? 15 : 17,
                  color: MarketingPalette.muted, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
