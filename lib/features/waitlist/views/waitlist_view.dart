import 'package:flutter/material.dart';

import '../../landing/widgets/marketing_tokens.dart';
import '../../landing/widgets/premium_atmosphere.dart';
import '../../landing/widgets/scroll_reveal.dart';
import '../../landing/widgets/site_footer.dart';
import '../../landing/widgets/top_nav.dart';
import '../services/waitlist_service.dart';
import '../widgets/waitlist_capture.dart';

// Dedicated /waitlist page — the shareable surface for the waitlist CTA.
// The modal in the nav stays for in-site flows; this is the link-anywhere URL.
const _tint = SectionTint.indigo;

class WaitlistView extends StatelessWidget {
  const WaitlistView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              TopNav(currentPath: '/waitlist', source: WaitlistSource.waitlist),
              SliverToBoxAdapter(child: _Hero()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: _PromiseSection()),
              SliverToBoxAdapter(child: MarketingDivider()),
              SliverToBoxAdapter(child: SiteFooter(source: WaitlistSource.waitlist)),
            ],
          ),
          Positioned.fill(child: FilmGrainOverlay()),
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
    return Stack(
      children: [
        const Positioned.fill(
          child: AtmosphereGlow(color: _tint),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mktGutter(context),
            vertical: narrow ? 64 : 120,
          ),
          child: const ScrollReveal(
            child: WaitlistCapture(source: WaitlistSource.waitlist),
          ),
        ),
      ],
    );
  }
}

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  static const _one = _Promise(
    index: '01',
    title: 'One email. That\'s it.',
    body:
        'We ping you once when the full app ships. No drip campaign, no '
        'referral asks, no newsletter you didn\'t sign up for.',
  );

  static const _two = _Promise(
    index: '02',
    title: 'Early access before the store listing.',
    body:
        'Waitlist gets the build a few weeks before public launch — '
        'enough time to give us feedback while it still matters.',
  );

  static const _three = _Promise(
    index: '03',
    title: 'No tracking pixels, no resale.',
    body:
        'Your address lives in a single Firestore collection we read by '
        'hand. We don\'t sell it, we don\'t hand it to anyone else.',
  );

  @override
  Widget build(BuildContext context) {
    final narrow = mktNarrow(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mktGutter(context),
        vertical: narrow ? 56 : 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScrollReveal(child: MarketingSectionLabel('THE DEAL')),
          SizedBox(height: narrow ? 28 : 44),
          if (narrow)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _one,
                SizedBox(height: 36),
                _two,
                SizedBox(height: 36),
                _three,
              ],
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _one),
                SizedBox(width: 40),
                Expanded(child: _two),
                SizedBox(width: 40),
                Expanded(child: _three),
              ],
            ),
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          index,
          style: mktMono(
            11,
            color: MarketingPalette.signal,
            letterSpacing: 2.6,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: mktDisplay(
            22,
            italic: true,
            weight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: mktBody(
            14,
            color: MarketingPalette.muted,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
