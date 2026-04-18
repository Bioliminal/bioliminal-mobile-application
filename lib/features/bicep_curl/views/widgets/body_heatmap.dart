import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../models/compensation_reference.dart';
import '../../models/rep_record.dart';
import '../../models/session_log.dart';

/// Per-rep muscle engagement values, normalized to `[0, 1]`. Drives the
/// brightness of each muscle region in [BodyHeatmapPanel].
class MuscleActivations {
  const MuscleActivations({
    required this.bicep,
    required this.shoulder,
    required this.trap,
    required this.erector,
  });

  final double bicep; // measured (real EMG)
  final double shoulder; // inferred from pose
  final double trap; // inferred from pose
  final double erector; // inferred from pose

  static const zero = MuscleActivations(
    bicep: 0,
    shoulder: 0,
    trap: 0,
    erector: 0,
  );
}

enum HeatmapMode { measured, inferred }

/// Side-by-side measured + inferred body heatmap panels with a shared
/// rep-scrub bar. Auto-plays through the set on mount; tap a rep on the
/// scrub bar to jump.
///
/// Honest labeling is non-negotiable here. The MEASURED panel shows real
/// bicep EMG; the INFERRED panel shows kinematic estimates derived from
/// pose drift (not actual muscle measurements). Visual treatments are
/// distinct (solid vs dotted glow rings) so the two read differently.
/// When v2 hardware lands additional EMG channels, the INFERRED panel
/// gets retired and those muscles move to the MEASURED side using the
/// same painter.
class BicepCurlHeatmapSection extends StatefulWidget {
  const BicepCurlHeatmapSection({super.key, required this.log});
  final SessionLog log;

  @override
  State<BicepCurlHeatmapSection> createState() =>
      _BicepCurlHeatmapSectionState();
}

class _BicepCurlHeatmapSectionState extends State<BicepCurlHeatmapSection> {
  int _currentRep = 0;
  Timer? _autoPlay;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    if (widget.log.reps.length > 1) _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _currentRep = (_currentRep + 1) % widget.log.reps.length;
      });
    });
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _startAutoPlay();
      } else {
        _autoPlay?.cancel();
      }
    });
  }

  void _jumpTo(int rep) {
    setState(() {
      _currentRep = rep;
      if (_playing) _startAutoPlay(); // restart timer from the new position
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.log.reps.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxPeak = widget.log.reps
        .map((r) => r.peakEnv)
        .fold<double>(0, math.max);
    final activations = _activationsFor(
      widget.log.reps[_currentRep],
      maxPeak,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PanelLabeled(
                title: 'MEASURED',
                subtitle: 'Real EMG · biceps brachii',
                child: BodyHeatmapPanel(
                  activations: activations,
                  mode: HeatmapMode.measured,
                  armSide: widget.log.armSide,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PanelLabeled(
                title: 'INFERRED',
                subtitle: 'Estimated from pose · synergists',
                child: BodyHeatmapPanel(
                  activations: activations,
                  mode: HeatmapMode.inferred,
                  armSide: widget.log.armSide,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ScrubRow(
          repCount: widget.log.reps.length,
          currentRep: _currentRep,
          playing: _playing,
          onTogglePlay: _togglePlay,
          onJump: _jumpTo,
        ),
      ],
    );
  }

  MuscleActivations _activationsFor(RepRecord rep, double maxPeak) {
    // Bicep (measured): per-rep peak normalized to set max so the brightest
    // rep glows fully; weakest rep dim. Applies a gentle floor so even
    // low-effort reps remain visible.
    final bicep =
        maxPeak == 0 ? 0.0 : (rep.peakEnv / maxPeak).clamp(0.0, 1.0);

    // Inferred channels (kinematic estimates):
    // - shoulder + trap from shoulder Y drift; the two co-fire because a
    //   shoulder hike is itself trap recruitment
    // - erector from torso pitch
    final delta = rep.poseDelta;
    final shoulder = delta == null
        ? 0.0
        : (delta.shoulderDriftDeg.abs() / 15.0).clamp(0.0, 1.0);
    final erector = delta == null
        ? 0.0
        : (delta.torsoPitchDeltaDeg.abs() / 20.0).clamp(0.0, 1.0);

    return MuscleActivations(
      bicep: math.max(bicep * 0.6 + 0.4, 0.4),
      shoulder: shoulder,
      trap: shoulder * 0.85,
      erector: erector,
    );
  }
}

class _PanelLabeled extends StatelessWidget {
  const _PanelLabeled({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
          const SizedBox(height: 8),
          AspectRatio(aspectRatio: 0.7, child: child),
        ],
      ),
    );
  }
}

class _ScrubRow extends StatelessWidget {
  const _ScrubRow({
    required this.repCount,
    required this.currentRep,
    required this.playing,
    required this.onTogglePlay,
    required this.onJump,
  });

  final int repCount;
  final int currentRep;
  final bool playing;
  final VoidCallback onTogglePlay;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 20),
          onPressed: onTogglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        Text(
          'REP ${currentRep + 1}/$repCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 1.5,
            fontFamily: 'IBMPlexMono',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: BioliminalTheme.accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: BioliminalTheme.accent,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: (repCount - 1).toDouble(),
              divisions: repCount > 1 ? repCount - 1 : null,
              value: currentRep.toDouble(),
              onChanged: (v) => onJump(v.round()),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BodyHeatmapPanel — the actual painter
// ---------------------------------------------------------------------------

class BodyHeatmapPanel extends StatelessWidget {
  const BodyHeatmapPanel({
    super.key,
    required this.activations,
    required this.mode,
    required this.armSide,
  });

  final MuscleActivations activations;
  final HeatmapMode mode;
  final ArmSide armSide;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodyHeatmapPainter(
        activations: activations,
        mode: mode,
        armSide: armSide,
      ),
      size: Size.infinite,
    );
  }
}

class _BodyHeatmapPainter extends CustomPainter {
  _BodyHeatmapPainter({
    required this.activations,
    required this.mode,
    required this.armSide,
  });

  final MuscleActivations activations;
  final HeatmapMode mode;
  final ArmSide armSide;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    _drawSilhouette(canvas, size, outline);

    final isCurlingRight = armSide == ArmSide.right;
    final mirror = isCurlingRight ? 1.0 : -1.0;

    // Region centers in normalized coords. Origin at top-left.
    final bicep = Offset(0.5 + 0.18 * mirror, 0.42);
    final shoulder = Offset(0.5 + 0.20 * mirror, 0.28);
    final trap = Offset(0.5 + 0.10 * mirror, 0.22);
    final erector = const Offset(0.5, 0.55);

    if (mode == HeatmapMode.measured) {
      _drawGlow(canvas, size, bicep, activations.bicep, solid: true);
    } else {
      _drawGlow(canvas, size, shoulder, activations.shoulder, solid: false);
      _drawGlow(canvas, size, trap, activations.trap, solid: false);
      _drawGlow(canvas, size, erector, activations.erector, solid: false);
    }
  }

  void _drawSilhouette(Canvas canvas, Size size, Paint outline) {
    Offset n(double x, double y) => Offset(x * size.width, y * size.height);

    // Head
    canvas.drawCircle(n(0.5, 0.10), size.width * 0.07, outline);
    // Neck
    canvas.drawLine(n(0.5, 0.135), n(0.5, 0.18), outline);
    // Shoulders
    canvas.drawLine(n(0.30, 0.22), n(0.70, 0.22), outline);
    // Torso
    canvas.drawLine(n(0.30, 0.22), n(0.34, 0.62), outline);
    canvas.drawLine(n(0.70, 0.22), n(0.66, 0.62), outline);
    // Hip line
    canvas.drawLine(n(0.34, 0.62), n(0.66, 0.62), outline);
    // Arms (down at sides)
    canvas.drawLine(n(0.30, 0.22), n(0.22, 0.42), outline);
    canvas.drawLine(n(0.22, 0.42), n(0.20, 0.62), outline);
    canvas.drawLine(n(0.70, 0.22), n(0.78, 0.42), outline);
    canvas.drawLine(n(0.78, 0.42), n(0.80, 0.62), outline);
    // Legs
    canvas.drawLine(n(0.40, 0.62), n(0.40, 0.92), outline);
    canvas.drawLine(n(0.60, 0.62), n(0.60, 0.92), outline);
  }

  void _drawGlow(
    Canvas canvas,
    Size size,
    Offset normalizedCenter,
    double intensity, {
    required bool solid,
  }) {
    if (intensity <= 0.05) return;
    final center = Offset(
      normalizedCenter.dx * size.width,
      normalizedCenter.dy * size.height,
    );
    final radius = (solid ? 0.13 : 0.10) * size.width;

    final core = solid ? BioliminalTheme.accent : Colors.purpleAccent;

    // Outer halo
    final halo = Paint()
      ..color = core.withValues(alpha: intensity * 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 1.6, halo);

    // Core
    final coreFill = Paint()
      ..color = core.withValues(alpha: intensity * (solid ? 0.85 : 0.55));
    canvas.drawCircle(center, radius, coreFill);

    // Inferred-mode dotted outer ring — distinct visual signature so
    // viewers aren't confused which channel is actually measured.
    if (!solid) {
      final ringPaint = Paint()
        ..color = core.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      _drawDottedCircle(canvas, center, radius * 1.25, ringPaint);
    }
  }

  void _drawDottedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashCount = 18;
    const arcAngle = 2 * math.pi / dashCount * 0.6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      final start = i * 2 * math.pi / dashCount;
      canvas.drawArc(rect, start, arcAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyHeatmapPainter old) =>
      old.activations.bicep != activations.bicep ||
      old.activations.shoulder != activations.shoulder ||
      old.activations.trap != activations.trap ||
      old.activations.erector != activations.erector ||
      old.mode != mode ||
      old.armSide != armSide;
}
