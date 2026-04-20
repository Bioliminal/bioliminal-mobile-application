import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/mobile_action_button.dart';
import '../../landing/widgets/marketing_tokens.dart';
import '../../landing/widgets/premium_atmosphere.dart';

/// Picks which set to start. v0 ships only Bicep Curl; the layout is a
/// vertical list of movement blocks so adding more is a single tile addition.
/// Each block selects the arm side inline (no extra modal — fewer taps for
/// demo-day flow).
class SetPickerView extends StatelessWidget {
  const SetPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketingPalette.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AtmosphereGlow(
                color: SectionTint.emerald,
                center: Alignment(-0.85, 0.9),
                peak: 0.06,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PageHeader(),
                const _Hairline(),
                Expanded(
                  child: ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: _movements.length,
                    separatorBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _Hairline(),
                    ),
                    itemBuilder: (context, i) =>
                        _MovementBlock(spec: _movements[i]),
                  ),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: FilmGrainOverlay()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => _goBack(context),
            padding: EdgeInsets.zero,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.arrow_back, color: MarketingPalette.muted),
            tooltip: 'Back',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Choose a set',
              style: mktDisplay(
                36,
                weight: FontWeight.w500,
                letterSpacing: -1.4,
                height: 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Movement block — title, caption, two side-pick buttons
// ---------------------------------------------------------------------------

class _MovementBlock extends StatelessWidget {
  const _MovementBlock({required this.spec});
  final _MovementSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.title,
            style: mktDisplay(
              26,
              weight: FontWeight.w500,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            spec.caption,
            style: mktMono(
              10,
              color: MarketingPalette.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MobileActionButton(
                  label: 'LEFT ARM',
                  onTap: () => context.go('${spec.route}?side=left'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileActionButton(
                  label: 'RIGHT ARM',
                  filled: true,
                  onTap: () => context.go('${spec.route}?side=right'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: MarketingPalette.hairline);
}

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/history');
  }
}

// ---------------------------------------------------------------------------
// Movement catalog
// ---------------------------------------------------------------------------

class _MovementSpec {
  const _MovementSpec({
    required this.title,
    required this.caption,
    required this.route,
  });
  final String title;
  final String caption;
  final String route;
}

const _movements = <_MovementSpec>[
  _MovementSpec(
    title: 'Bicep curl',
    caption: 'SINGLE ARM · EMG FATIGUE · FORM COACHING',
    route: '/bicep-curl',
  ),
];
