import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../core/theme.dart';

class LandingPageView extends StatefulWidget {
  const LandingPageView({super.key});

  @override
  State<LandingPageView> createState() => _LandingPageViewState();
}

class _LandingPageViewState extends State<LandingPageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: AdaptiveLiquidGlassLayer(
        child: GlassMotionScope(
          // Specular highlights follow the scroll position
          lightAngle: _scrollController.hasClients
              ? Stream.value(_scrollController.offset / 1000.0)
              : const Stream.empty(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const _StickyNavbar(),
              SliverToBoxAdapter(
                child: ResponsiveBuilder(
                  builder: (context, sizingInformation) {
                    return Column(
                      children: [
                        _HeroSection(controller: _scrollController),
                        _VisionSection(controller: _scrollController),
                        _InsightSection(controller: _scrollController),
                        _TrustSection(controller: _scrollController),
                        const _FinalCTA(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyNavbar extends StatelessWidget {
  const _StickyNavbar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: GlassAppBar(
        useOwnLayer: true,
        backgroundColor: BioliminalTheme.screenBackground.withValues(alpha: 0.5),
        title: Row(
          children: [
            Text(
              'BIOLIMINAL',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const _NavButton(label: 'Features'),
            const _NavButton(label: 'Research'),
            const SizedBox(width: 16),
            GlassButton.custom(
              onTap: () {},
              width: 120,
              height: 40,
              child: const Text('GET THE APP',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  const _NavButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ScrollController controller;
  const _HeroSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Animate(
      adapter: ScrollAdapter(controller, begin: 0, end: 500),
      effects: [
        const FadeEffect(begin: 1, end: 0),
        const ScaleEffect(begin: Offset(1, 1), end: Offset(1.2, 1.2)),
      ],
      child: Container(
        height: 800,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/reference_images/overhead_squat.jpg'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'REDEFINE MOVEMENT.',
                textAlign: TextAlign.center,
                style: GoogleFonts.oswald(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              const Text(
                'Vision Beyond Sight.',
                style: TextStyle(
                    fontSize: 24,
                    color: BioliminalTheme.accent,
                    letterSpacing: 4),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisionSection extends StatelessWidget {
  final ScrollController controller;
  const _VisionSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Animate(
            adapter: ScrollAdapter(controller, begin: 400, end: 800),
            effects: const [
              FadeEffect(),
              SlideEffect(begin: Offset(0, 0.2), end: Offset.zero)
            ],
            child: Text(
              'THE VISION',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: BioliminalTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 100),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                title: 'Real-Time Pose',
                description: 'Clinical-grade data at 30+ FPS.',
                icon: Icons.accessibility_new,
                controller: controller,
                begin: 600,
              ),
              _FeatureCard(
                title: 'Joint Kinetics',
                description: 'Proprietary rule-based engine.',
                icon: Icons.calculate,
                controller: controller,
                begin: 700,
              ),
              _FeatureCard(
                title: 'Tactile Feedback',
                description: 'Pattern retraining mid-rep.',
                icon: Icons.vibration,
                controller: controller,
                begin: 800,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final ScrollController controller;
  const _InsightSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'THE INSIGHT',
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: BioliminalTheme.accent,
            ),
          ),
          const SizedBox(height: 100),
          GlassPanel(
            width: 1000,
            height: 600,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Beyond Joint Metrics',
                          style: GoogleFonts.oswald(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Bioliminal identifies the upstream drivers of movement dysfunction by mapping patterns to established fascial chains.',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white70, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 400,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/reference_images/overhead_reach.jpg'),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(adapter: ScrollAdapter(controller, begin: 1200, end: 1600))
            ..scale(begin: const Offset(0.8, 0.8))
            ..fadeIn(),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final ScrollController controller;
  final double begin;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.controller,
    required this.begin,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      adapter: ScrollAdapter(controller, begin: begin, end: begin + 300),
      effects: const [
        FadeEffect(),
        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
      ],
      child: GlassCard(
        width: 320,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: BioliminalTheme.accent, size: 40),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.white60, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  final ScrollController controller;
  const _TrustSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.white10),
          const SizedBox(height: 48),
          Text(
            'CLINICAL-GRADE LOGIC',
            style: GoogleFonts.oswald(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate(adapter: ScrollAdapter(controller, begin: 1800, end: 2200))
            ..blur(begin: const Offset(10, 10), end: Offset.zero)
            ..fadeIn(),
        ],
      ),
    );
  }
}

class _FinalCTA extends StatelessWidget {
  const _FinalCTA();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'READY TO BEGIN?',
            style: GoogleFonts.oswald(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassButton.custom(
                onTap: () {},
                width: 160,
                height: 56,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple),
                    SizedBox(width: 8),
                    Text('App Store'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GlassButton.custom(
                onTap: () {},
                width: 160,
                height: 56,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.android),
                    SizedBox(width: 8),
                    Text('Play Store'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
