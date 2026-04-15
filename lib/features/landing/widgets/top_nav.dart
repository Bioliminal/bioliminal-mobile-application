import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../waitlist/services/waitlist_service.dart';
import '../../waitlist/widgets/waitlist_capture.dart';
import 'marketing_tokens.dart';

// Sticky top nav shared by SYSTEM / SCIENCE / DEMO / CODE pages. The home page
// keeps its own private version for now; when that gets refactored, it can
// drop in here too.

class TopNav extends StatelessWidget {
  const TopNav({
    super.key,
    required this.currentPath,
    required this.source,
  });

  final String currentPath; // e.g. '/system' — used to dim the active nav item
  final WaitlistSource source; // tags which page a waitlist signup came from

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TopNavDelegate(currentPath: currentPath, source: source),
    );
  }
}

class _TopNavDelegate extends SliverPersistentHeaderDelegate {
  _TopNavDelegate({required this.currentPath, required this.source});
  final String currentPath;
  final WaitlistSource source;

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final narrow = mktNarrow(context);
    return Container(
      color: MarketingPalette.bg.withValues(alpha: 0.92),
      padding: EdgeInsets.symmetric(horizontal: mktGutter(context)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _Wordmark(onTap: () => context.go('/')),
                const SizedBox(width: 48),
                if (!narrow) ...[
                  _NavLink(
                    label: 'SYSTEM',
                    active: currentPath == '/system',
                    onTap: () => context.go('/system'),
                  ),
                  _NavLink(
                    label: 'SCIENCE',
                    active: currentPath == '/science',
                    onTap: () => context.go('/science'),
                  ),
                  _NavLink(
                    label: 'DEMO',
                    active: currentPath == '/demo',
                    onTap: () => context.go('/demo'),
                  ),
                  _NavLink(
                    label: 'CODE',
                    active: currentPath == '/code',
                    onTap: () => context.go('/code'),
                  ),
                ],
                const Spacer(),
                _WaitlistButton(compact: narrow, source: source),
              ],
            ),
          ),
          Container(height: 1, color: MarketingPalette.hairline),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TopNavDelegate old) =>
      old.currentPath != currentPath || old.source != source;
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          'BIOLIMINAL',
          style: mktMono(
            13,
            color: MarketingPalette.text,
            weight: FontWeight.w600,
            letterSpacing: 3.2,
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active || _hover
        ? MarketingPalette.signal
        : MarketingPalette.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            widget.label,
            style: mktMono(
              11,
              color: color,
              letterSpacing: 2.4,
              weight: widget.active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitlistButton extends StatefulWidget {
  const _WaitlistButton({required this.compact, required this.source});
  final bool compact;
  final WaitlistSource source;

  @override
  State<_WaitlistButton> createState() => _WaitlistButtonState();
}

class _WaitlistButtonState extends State<_WaitlistButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hover ? MarketingPalette.text : MarketingPalette.signal;
    final label = widget.compact ? 'WAITLIST' : 'JOIN WAITLIST';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => showMarketingWaitlistDialog(context, source: widget.source),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: mktMono(
              10,
              color: color,
              letterSpacing: 2.6,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showMarketingWaitlistDialog(
  BuildContext context, {
  required WaitlistSource source,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _MarketingWaitlistDialog(source: source),
  );
}

class _MarketingWaitlistDialog extends StatelessWidget {
  const _MarketingWaitlistDialog({required this.source});
  final WaitlistSource source;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MarketingPalette.bg,
      insetPadding: const EdgeInsets.all(24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: MarketingPalette.hairline, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _DialogClose(onTap: () => Navigator.of(context).pop()),
              ),
              WaitlistCapture(source: source, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogClose extends StatefulWidget {
  const _DialogClose({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DialogClose> createState() => _DialogCloseState();
}

class _DialogCloseState extends State<_DialogClose> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hover ? MarketingPalette.text : MarketingPalette.subtle;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            '×',
            style: TextStyle(
              color: color,
              fontFamily: 'IBMPlexMono',
              fontSize: 22,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
