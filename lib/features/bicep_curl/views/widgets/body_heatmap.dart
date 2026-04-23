import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../landing/widgets/marketing_tokens.dart';
import '../../models/compensation_reference.dart';
import '../../models/session_log.dart';

/// Per-frame muscle engagement values, normalized to `[0, 1]`. Drives the
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

  /// Decodes an absolute sample index (0..log.reps.length*samplesPerRep-1)
  /// into an activation snapshot. Measured bicep reads envelope samples
  /// directly (or synthesizes a half-sine for legacy reps without
  /// per-sample data). Inferred channels step at rep boundaries off the
  /// per-rep signed peak pose delta; slumping / leaning-back (negative
  /// signed deltas) are not compensation, so they clamp to zero intensity
  /// rather than flipping sign. Inferred saturation is tied to the
  /// profile's compensation thresholds: at threshold the glow is ~67 %,
  /// at 1.5× threshold it saturates. Trap rides at 0.85× shoulder because
  /// trap engagement is a synergist of shoulder drift.
  static MuscleActivations fromLog({
    required SessionLog log,
    required int absoluteSample,
    required double maxSampleValue,
    int samplesPerRep = 50,
  }) {
    if (log.reps.isEmpty) return zero;
    final repIdx = (absoluteSample ~/ samplesPerRep)
        .clamp(0, log.reps.length - 1);
    final within = absoluteSample % samplesPerRep;
    final rep = log.reps[repIdx];

    final samples = rep.envelopeSamples;
    final rawBicep = samples != null && within < samples.length
        ? samples[within]
        : _syntheticSample(
            peakEnv: rep.peakEnv,
            withinRep: within,
            samplesPerRep: samplesPerRep,
          );
    // No visibility floor. If EMG never arrived the panel stays dark —
    // a quiet bicep beats a lying one.
    final bicepNorm = maxSampleValue > 0
        ? (rawBicep / maxSampleValue).clamp(0.0, 1.0)
        : 0.0;

    final thresholds = log.profile.compensation;
    final delta = rep.poseDelta;
    final shoulder = delta == null
        ? 0.0
        : (delta.shoulderDriftDeg / (thresholds.shoulderDriftDeg * 1.5))
            .clamp(0.0, 1.0);
    final erector = delta == null
        ? 0.0
        : (delta.torsoPitchDeltaDeg / (thresholds.torsoPitchDeltaDeg * 1.5))
            .clamp(0.0, 1.0);

    return MuscleActivations(
      bicep: bicepNorm,
      shoulder: shoulder,
      trap: shoulder * 0.85,
      erector: erector,
    );
  }

  static double _syntheticSample({
    required double peakEnv,
    required int withinRep,
    required int samplesPerRep,
  }) {
    final phase = (withinRep / (samplesPerRep - 1)) * math.pi;
    return peakEnv * math.sin(phase);
  }
}

enum HeatmapMode { measured, inferred }

/// Side-by-side measured + inferred body heatmap with a continuous
/// within-rep scrub bar. Auto-plays through the full session at ~14 ms
/// per envelope sample (50 samples per rep ≈ 700 ms per rep visually).
///
/// Honest labeling is non-negotiable. The MEASURED panel shows real
/// bicep EMG sample-by-sample within each rep (smooth concentric→peak→
/// eccentric trajectory); the INFERRED panel shows kinematic estimates
/// derived from per-rep pose drift, so it steps at rep boundaries
/// rather than animating within a rep — which is the truth: we only
/// have one pose summary per rep window.
///
/// Sessions saved before the continuous-heatmap commit have null
/// envelopeSamples; debrief synthesizes a half-sine peaked mid-rep
/// from the stored peakEnv so old sessions still animate.
class BicepCurlHeatmapSection extends StatefulWidget {
  const BicepCurlHeatmapSection({super.key, required this.log});
  final SessionLog log;

  @override
  State<BicepCurlHeatmapSection> createState() =>
      _BicepCurlHeatmapSectionState();
}

class _BicepCurlHeatmapSectionState extends State<BicepCurlHeatmapSection> {
  static const int _samplesPerRep = 50;
  static const Duration _frameInterval = Duration(milliseconds: 14);

  int _absoluteSample = 0;
  Timer? _autoPlay;
  bool _playing = true;
  late double _maxSampleValue;

  @override
  void initState() {
    super.initState();
    _maxSampleValue = _computeMaxSampleValue();
    if (widget.log.reps.isNotEmpty) _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant BicepCurlHeatmapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.log != widget.log) {
      _maxSampleValue = _computeMaxSampleValue();
    }
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    super.dispose();
  }

  int get _totalSamples =>
      widget.log.reps.length * _samplesPerRep;

  void _startAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer.periodic(_frameInterval, (_) {
      if (!mounted) return;
      setState(() {
        _absoluteSample = (_absoluteSample + 1) % _totalSamples;
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

  void _jumpTo(int absoluteSample) {
    setState(() {
      _absoluteSample = absoluteSample.clamp(0, _totalSamples - 1);
      if (_playing) _startAutoPlay(); // restart timer from new position
    });
  }

  double _computeMaxSampleValue() {
    var max = 0.0;
    for (final rep in widget.log.reps) {
      final samples = rep.envelopeSamples;
      if (samples != null) {
        for (final v in samples) {
          if (v > max) max = v;
        }
      } else if (rep.peakEnv > max) {
        max = rep.peakEnv;
      }
    }
    return max;
  }

  /// Decodes an absolute sample index into (rep index, within-rep index).
  ({int rep, int within}) _decode(int absoluteSample) {
    final repIdx = (absoluteSample ~/ _samplesPerRep)
        .clamp(0, widget.log.reps.length - 1);
    final within = absoluteSample % _samplesPerRep;
    return (rep: repIdx, within: within);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.log.reps.isEmpty) {
      return const SizedBox.shrink();
    }
    final activations = MuscleActivations.fromLog(
      log: widget.log,
      absoluteSample: _absoluteSample,
      maxSampleValue: _maxSampleValue,
      samplesPerRep: _samplesPerRep,
    );
    final (rep: currentRep, within: _) = _decode(_absoluteSample);
    final hasEmgSignal = _maxSampleValue > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PanelLabeled(
                index: '01',
                title: 'MEASURED',
                subtitle: hasEmgSignal
                    ? 'REAL EMG · BICEPS BRACHII'
                    : 'NO EMG · CV-ONLY SESSION',
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
                index: '02',
                title: 'INFERRED',
                subtitle: 'POSE SYNERGISTS · ESTIMATED',
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
          totalSamples: _totalSamples,
          currentSample: _absoluteSample,
          repNumber: currentRep + 1,
          repCount: widget.log.reps.length,
          playing: _playing,
          onTogglePlay: _togglePlay,
          onJump: _jumpTo,
        ),
      ],
    );
  }
}

class _PanelLabeled extends StatelessWidget {
  const _PanelLabeled({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String index;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: MarketingPalette.hairline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  index,
                  style: mktMono(
                    10,
                    color: MarketingPalette.signal,
                    letterSpacing: 1.6,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 1,
                  color: MarketingPalette.signal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: mktMono(
                      11,
                      color: MarketingPalette.text,
                      letterSpacing: 2.6,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: mktMono(
                8,
                color: MarketingPalette.subtle,
                letterSpacing: 1.6,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            AspectRatio(aspectRatio: 0.7, child: child),
          ],
        ),
      ),
    );
  }
}

class _ScrubRow extends StatelessWidget {
  const _ScrubRow({
    required this.totalSamples,
    required this.currentSample,
    required this.repNumber,
    required this.repCount,
    required this.playing,
    required this.onTogglePlay,
    required this.onJump,
  });

  final int totalSamples;
  final int currentSample;
  final int repNumber;
  final int repCount;
  final bool playing;
  final VoidCallback onTogglePlay;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final repStr = repNumber.toString().padLeft(2, '0');
    final totalStr = repCount.toString().padLeft(2, '0');
    return Row(
      children: [
        IconButton(
          icon: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: MarketingPalette.text,
            size: 18,
          ),
          onPressed: onTogglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 10),
        Text(
          'REP',
          style: mktMono(
            9,
            color: MarketingPalette.subtle,
            letterSpacing: 2.2,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$repStr / $totalStr',
          style: mktMono(
            12,
            color: MarketingPalette.text,
            letterSpacing: 1.4,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: BioliminalTheme.accent,
              inactiveTrackColor: MarketingPalette.hairline,
              thumbColor: BioliminalTheme.accent,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: (totalSamples - 1).toDouble(),
              value: currentSample.toDouble().clamp(
                    0.0,
                    (totalSamples - 1).toDouble(),
                  ),
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
