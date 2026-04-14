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
      toolbarHeight: 80,
      backgroundColor: Colors.transparent,
      flexibleSpace: GlassAppBar(
        useOwnLayer: true,
        backgroundColor: BioliminalTheme.screenBackground.withValues(alpha: 0.5),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'BIOLIMINAL',
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const _NavButton(label: 'FEATURES'),
              const _NavButton(label: 'RESEARCH'),
              const SizedBox(width: 24),
              GlassButton.custom(
                onTap: () {},
                width: 140,
                height: 48,
                child: const Text('GET THE APP',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {},
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 14, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ScrollController controller;
  const _HeroSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Placeholder for high-res Skeleton
        Animate(
          adapter: ScrollAdapter(controller, begin: 0, end: 1000),
          effects: [
            const FadeEffect(begin: 0.3, end: 0),
            const ScaleEffect(begin: Offset(1, 1), end: Offset(1.5, 1.5)),
          ],
          child: Container(
            height: 1000,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/reference_images/overhead_squat.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Content Layer
        SizedBox(
          height: 1000,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Primary Heading: REDEFINE MOVEMENT
                    Animate(
                      adapter: ScrollAdapter(controller, begin: 0, end: 500),
                      effects: [
                        const FadeEffect(begin: 1, end: 0),
                        const SlideEffect(
                            begin: Offset.zero, end: Offset(0, -0.2)),
                      ],
                      child: Text(
                        'REDEFINE MOVEMENT.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Secondary Heading: VISION BEYOND SIGHT
                    Animate(
                      adapter: ScrollAdapter(controller, begin: 300, end: 800),
                      effects: [
                        const FadeEffect(begin: 0, end: 1),
                        const SlideEffect(
                            begin: Offset(0, 0.2), end: Offset.zero),
                      ],
                      child: Text(
                        'VISION BEYOND SIGHT.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.oswald(
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -6,
                          color: BioliminalTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Animate(
                  adapter: ScrollAdapter(controller, begin: 0, end: 400),
                  effects: [const FadeEffect(begin: 1, end: 0)],
                  child: const Text(
                    'THE CLINICAL STANDARD FOR BIOMECHANICS.',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white38,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VisionSection extends StatelessWidget {
  final ScrollController controller;
  const _VisionSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Animate(
            adapter: ScrollAdapter(controller, begin: 800, end: 1200),
            effects: const [
              FadeEffect(),
              SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
            ],
            child: Text(
              'THE VISION',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: BioliminalTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 150),
          Wrap(
            spacing: 60,
            runSpacing: 60,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                title: 'Real-Time Pose',
                description:
                    'MediaPipe BlazePose Full captures clinical-grade data at 30+ FPS.',
                icon: Icons.accessibility_new,
                controller: controller,
                begin: 1000,
              ),
              _FeatureCard(
                title: 'Joint Kinetics',
                description:
                    'Proprietary rule-based engine calculates precise joint angles and moments.',
                icon: Icons.calculate,
                controller: controller,
                begin: 1200,
              ),
              _FeatureCard(
                title: 'Tactile Feedback',
                description:
                    'Real-time cueing retrains movement patterns mid-repetition.',
                icon: Icons.vibration,
                controller: controller,
                begin: 1400,
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
      padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Animate(
            adapter: ScrollAdapter(controller, begin: 1600, end: 2000),
            effects: const [
              FadeEffect(),
              SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
            ],
            child: Text(
              'THE CONNECTION',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: BioliminalTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 150),
          Stack(
            alignment: Alignment.center,
            children: [
              // Stylized Network Background (Placeholder for high-res Fascial visual)
              Animate(
                adapter: ScrollAdapter(controller, begin: 1800, end: 3000),
                effects: [
                  const ScaleEffect(
                      begin: Offset(0.8, 0.8), end: Offset(1.3, 1.3)),
                  const FadeEffect(begin: 0.1, end: 0.5),
                ],
                child: Container(
                  height: 900,
                  width: 1400,
                  decoration: BoxDecoration(
                    color: BioliminalTheme.accent.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hub, size: 300, color: Colors.white10),
                ),
              ),
              // Content Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StoryPoint(
                    title: 'FASCIAL CHAINS',
                    value: 'We don\'t just see the joint. We see the system.',
                    controller: controller,
                    begin: 2000,
                  ),
                  const SizedBox(width: 120),
                  _StoryPoint(
                    title: 'UPSTREAM DRIVERS',
                    value: 'Trace compensations to their clinical root cause.',
                    controller: controller,
                    begin: 2200,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryPoint extends StatelessWidget {
  final String title;
  final String value;
  final ScrollController controller;
  final double begin;

  const _StoryPoint({
    required this.title,
    required this.value,
    required this.controller,
    required this.begin,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      adapter: ScrollAdapter(controller, begin: begin, end: begin + 500),
      effects: const [
        FadeEffect(),
        SlideEffect(begin: Offset(0, 0.3), end: Offset.zero)
      ],
      child: GlassCard(
        width: 450,
        height: 350,
        padding: const EdgeInsets.all(64),
        quality: GlassQuality.premium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.oswald(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: BioliminalTheme.accent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
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
      adapter: ScrollAdapter(controller, begin: begin, end: begin + 500),
      effects: [
        const FadeEffect(),
        const SlideEffect(begin: Offset(0, 0.2), end: Offset.zero),
      ],
      child: GlassCard(
        width: 380,
        height: 450,
        padding: const EdgeInsets.all(48),
        quality: GlassQuality.premium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Animate(
              adapter: ScrollAdapter(controller, begin: begin + 100, end: begin + 600),
              effects: [const ScaleEffect(begin: Offset(0.5, 0.5), end: Offset(1, 1))],
              child: Icon(icon, color: BioliminalTheme.accent, size: 56),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.oswald(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(
                  color: Colors.white60, height: 1.6, fontSize: 18),
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
      padding: const EdgeInsets.symmetric(vertical: 250, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.verified_user, size: 100, color: Colors.white10),
          const SizedBox(height: 64),
          Animate(
            adapter: ScrollAdapter(controller, begin: 2800, end: 3200),
            effects: const [
              FadeEffect(),
              SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
            ],
            child: Text(
              'CLINICAL-GRADE LOGIC',
              textAlign: TextAlign.center,
              style: GoogleFonts.oswald(
                fontSize: 84,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'VALIDATED AGAINST GOLD-STANDARD BIOMECHANICS DATA.',
            style: TextStyle(
                color: Colors.white38, fontSize: 20, letterSpacing: 4),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 250, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'READY TO BEGIN?',
            style: GoogleFonts.oswald(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Transform your movement practice today with Bioliminal.',
            style: TextStyle(fontSize: 24, color: Colors.white70),
          ),
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassButton.custom(
                onTap: () {},
                width: 240,
                height: 72,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, size: 28),
                    SizedBox(width: 16),
                    Text('APP STORE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              GlassButton.custom(
                onTap: () {},
                width: 240,
                height: 72,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.android, size: 28),
                    SizedBox(width: 16),
                    Text('PLAY STORE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 18)),
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
