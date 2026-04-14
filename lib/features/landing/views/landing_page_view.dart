import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../core/theme.dart';

class LandingPageView extends StatelessWidget {
  const LandingPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _StickyNavbar(),
            ResponsiveBuilder(
              builder: (context, sizingInformation) {
                return const Column(
                  children: [
                    _HeroSection(),
                    _VisionSection(),
                    _InsightSection(),
                    _TrustSection(),
                    _FinalCTA(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyNavbar extends StatelessWidget {
  const _StickyNavbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BioliminalTheme.screenBackground.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'BIOLIMINAL',
            child: Text(
              'BIOLIMINAL',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const _NavButton(label: 'Features'),
          const _NavButton(label: 'Research'),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: BioliminalTheme.accent,
              foregroundColor: BioliminalTheme.screenBackground,
            ),
            child: const Text('GET THE APP'),
          ),
        ],
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
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/reference_images/overhead_squat.jpg'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'REDEFINE MOVEMENT.',
                child: Text(
                  'REDEFINE MOVEMENT.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oswald(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label:
                    'AI-powered biomechanics tracing compensations to their fascial root cause. Clinical-grade screening in your pocket.',
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: const Text(
                    'AI-powered biomechanics tracing compensations to their fascial root cause. Clinical-grade screening in your pocket.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('WATCH THE DEMO'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('EXPLORE RESEARCH'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisionSection extends StatelessWidget {
  const _VisionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: BioliminalTheme.surface,
      width: double.infinity,
      child: Column(
        children: [
          Semantics(
            label: 'THE VISION',
            child: Text(
              'THE VISION',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: BioliminalTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '33-Landmark High-Fidelity Tracking',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          const Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                title: 'Real-Time Pose',
                description: 'MediaPipe BlazePose Full captures clinical-grade data at 30+ FPS.',
                icon: Icons.accessibility_new,
              ),
              _FeatureCard(
                title: 'Joint Kinetics',
                description: 'Proprietary rule-based engine calculates precise joint angles and moments.',
                icon: Icons.calculate,
              ),
              _FeatureCard(
                title: 'Tactile Feedback',
                description: 'Real-time cueing retrains movement patterns mid-repetition.',
                icon: Icons.vibration,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Semantics(
            label: 'THE INSIGHT',
            child: Text(
              'THE INSIGHT',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: BioliminalTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fascial Chain Mapping',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 64),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ChainPoint(title: 'Superficial Back Line', value: 'Overhead Reach'),
                    SizedBox(height: 32),
                    _ChainPoint(title: 'Lateral Line', value: 'SLS Stability'),
                    SizedBox(height: 32),
                    _ChainPoint(title: 'Spiral Line', value: 'Rotational Power'),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              Container(
                height: 500,
                width: 300,
                decoration: BioliminalTheme.glassEffect.copyWith(
                  image: const DecorationImage(
                    image: AssetImage('assets/reference_images/overhead_reach.jpg'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.hub, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              const SizedBox(width: 64),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beyond Joint Metrics',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bioliminal doesn\'t just see the joint—it sees the system. By mapping compensation patterns to established fascial chains, we identify the upstream drivers of movement dysfunction.',
                      style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.6),
                    ),
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

class _ChainPoint extends StatelessWidget {
  final String title;
  final String value;
  const _ChainPoint({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(color: BioliminalTheme.accent, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 18)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BioliminalTheme.glassEffect,
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
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: BioliminalTheme.surface,
      width: double.infinity,
      child: const Column(
        children: [
          Icon(Icons.verified_user, size: 64, color: Colors.white10),
          SizedBox(height: 32),
          Text(
            'Clinical-Grade Logic',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Built on established clinical protocols and validated against gold-standard biomechanics data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
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
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'READY TO BEGIN?',
            style: GoogleFonts.oswald(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Transform your movement practice today with Bioliminal.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 48),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StoreButton(icon: Icons.apple, label: 'App Store'),
              SizedBox(width: 24),
              _StoreButton(icon: Icons.android, label: 'Play Store'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StoreButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
