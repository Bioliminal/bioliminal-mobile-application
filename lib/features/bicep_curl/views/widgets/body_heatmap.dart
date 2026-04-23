import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../landing/widgets/marketing_tokens.dart';
import '../../models/compensation_reference.dart';
import '../../models/cue_decision.dart';
import '../../models/session_log.dart';

/// Per-frame MEASURED bicep activation, normalized to `[0, 1]`. The
/// inferred channels that used to ride alongside this (shoulder / trap /
/// erector glow) are gone — pose is one signed peak per rep per signal,
/// which a bar chart renders honestly and a heatmap overstates. See
/// [_FormOverTimeStrip] for the replacement surface.
class BicepActivation {
  const BicepActivation({required this.bicep});

  final double bicep;

  static const zero = BicepActivation(bicep: 0);

  /// Decodes an absolute sample index (0..log.reps.length*samplesPerRep-1)
  /// into a bicep activation value. Reads envelope samples directly when
  /// present; synthesizes a half-sine peaked mid-rep for legacy reps that
  /// predate the continuous-heatmap commit. No visibility floor: if EMG
  /// never arrived the bicep stays dark — a quiet signal beats a lying one.
  static BicepActivation fromLog({
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
    final bicepNorm = maxSampleValue > 0
        ? (rawBicep / maxSampleValue).clamp(0.0, 1.0)
        : 0.0;

    return BicepActivation(bicep: bicepNorm);
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

/// Debrief panel for bicep-curl form. Stacks MEASURED (real-EMG glow on
/// a silhouette) on top of FORM OVER TIME (per-rep signed bar charts for
/// shoulder-rise + forward-lean), with a shared scrub bar wired to both.
///
/// Why a bar chart under MEASURED: the underlying pose data is one signed
/// peak per rep per signal. A heatmap-style glow on a silhouette pretends
/// to be spatial and continuous; it isn't. A bar chart reveals the
/// sequence (fatigue-driven drift across reps, sporadic bad reps) that a
/// per-frame glow hides.
///
/// Sessions saved before the continuous-heatmap commit have null
/// envelopeSamples; debrief synthesizes a half-sine peaked mid-rep from
/// the stored peakEnv so old sessions still animate the MEASURED panel.
class BicepCurlFormSection extends StatefulWidget {
  const BicepCurlFormSection({super.key, required this.log});
  final SessionLog log;

  @override
  State<BicepCurlFormSection> createState() => _BicepCurlFormSectionState();
}

class _BicepCurlFormSectionState extends State<BicepCurlFormSection> {
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
  void didUpdateWidget(covariant BicepCurlFormSection oldWidget) {
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

  int get _totalSamples => widget.log.reps.length * _samplesPerRep;

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
      if (_playing) _startAutoPlay();
    });
  }

  /// Tapping a bar on the form strip scrubs to the START of that rep and
  /// pauses auto-play. The explicit pause is important: if auto-play keeps
  /// running the selection would race away from the bar the user just
  /// tapped before they can read it.
  void _jumpToRep(int repIdx) {
    setState(() {
      _absoluteSample =
          (repIdx * _samplesPerRep).clamp(0, _totalSamples - 1);
      _playing = false;
      _autoPlay?.cancel();
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
    final activation = BicepActivation.fromLog(
      log: widget.log,
      absoluteSample: _absoluteSample,
      maxSampleValue: _maxSampleValue,
      samplesPerRep: _samplesPerRep,
    );
    final (rep: currentRep, within: _) = _decode(_absoluteSample);
    final hasEmgSignal = _maxSampleValue > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelLabeled(
          index: '01',
          title: 'MEASURED',
          subtitle: hasEmgSignal
              ? 'REAL EMG · BICEPS BRACHII'
              : 'NO EMG · CV-ONLY SESSION',
          aspectRatio: 1.6,
          child: BodyHeatmapPanel(
            activation: activation,
            armSide: widget.log.armSide,
          ),
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
        const SizedBox(height: 18),
        _FormOverTimeStrip(
          log: widget.log,
          currentRep: currentRep,
          onRepTap: _jumpToRep,
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
    this.aspectRatio,
  });

  final String index;
  final String title;
  final String subtitle;
  final Widget child;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(index: index, title: title, subtitle: subtitle),
        const SizedBox(height: 10),
        if (aspectRatio != null)
          AspectRatio(aspectRatio: aspectRatio!, child: child)
        else
          child,
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: MarketingPalette.hairline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: content,
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
      ],
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
// BodyHeatmapPanel — silhouette + bicep glow
// ---------------------------------------------------------------------------

class BodyHeatmapPanel extends StatelessWidget {
  const BodyHeatmapPanel({
    super.key,
    required this.activation,
    required this.armSide,
  });

  final BicepActivation activation;
  final ArmSide armSide;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodyHeatmapPainter(
        activation: activation,
        armSide: armSide,
      ),
      size: Size.infinite,
    );
  }
}

class _BodyHeatmapPainter extends CustomPainter {
  _BodyHeatmapPainter({
    required this.activation,
    required this.armSide,
  });

  final BicepActivation activation;
  final ArmSide armSide;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    _drawSilhouette(canvas, size, outline);

    final mirror = armSide == ArmSide.right ? 1.0 : -1.0;
    final bicep = Offset(0.5 + 0.18 * mirror, 0.42);
    _drawGlow(canvas, size, bicep, activation.bicep);
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
    double intensity,
  ) {
    if (intensity <= 0.05) return;
    final center = Offset(
      normalizedCenter.dx * size.width,
      normalizedCenter.dy * size.height,
    );
    final radius = 0.13 * size.width;
    final core = BioliminalTheme.accent;

    final halo = Paint()
      ..color = core.withValues(alpha: intensity * 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 1.6, halo);

    final coreFill = Paint()
      ..color = core.withValues(alpha: intensity * 0.85);
    canvas.drawCircle(center, radius, coreFill);
  }

  @override
  bool shouldRepaint(covariant _BodyHeatmapPainter old) =>
      old.activation.bicep != activation.bicep || old.armSide != armSide;
}

// ---------------------------------------------------------------------------
// Form-over-time strip — per-rep signed bar charts for pose compensation
// ---------------------------------------------------------------------------

/// Pure classification for a single rep's signed peak delta against the
/// profile threshold. Exposed so tests can exercise the bucketing
/// directly without reaching into the painter. Bars bucketed here are
/// drawn by [_SignedRepBarChart].
///
/// Semantics: positive bars (compensation direction — shoulder up /
/// torso forward) bucket by threshold multiplier. Negative bars (slump /
/// back-lean) are never compensation; they bucket to [negative] and draw
/// below the axis in muted grey regardless of magnitude.
enum BarBucket {
  /// No pose data for this rep (calibration window or frame gap).
  missing,

  /// Negative signed delta — drawn downward in muted grey. Not scored.
  negative,

  /// `[0, 0.5×)` threshold. Clean; dim grey.
  clean,

  /// `[0.5×, 1×]` threshold. Approaching; amber.
  amber,

  /// `> 1×` threshold. Cue-firing range; red.
  red,
}

/// Classifies a signed delta against a positive threshold. Keep the
/// logic branching explicit — it drives both bar color and test
/// assertions.
BarBucket bucketFor(double? signed, double threshold) {
  if (signed == null) return BarBucket.missing;
  if (signed < 0) return BarBucket.negative;
  if (signed > threshold) return BarBucket.red;
  if (signed >= threshold * 0.5) return BarBucket.amber;
  return BarBucket.clean;
}

class _FormOverTimeStrip extends StatelessWidget {
  const _FormOverTimeStrip({
    required this.log,
    required this.currentRep,
    required this.onRepTap,
  });

  final SessionLog log;
  final int currentRep;
  final ValueChanged<int> onRepTap;

  @override
  Widget build(BuildContext context) {
    final shoulderSeries = <double?>[
      for (final r in log.reps) r.poseDelta?.shoulderDriftDeg,
    ];
    final leanSeries = <double?>[
      for (final r in log.reps) r.poseDelta?.torsoPitchDeltaDeg,
    ];

    final shoulderCueReps = <int>{
      for (final e in log.cueEvents)
        if (e.content == CueContent.shoulderHike) e.repNum - 1,
    };
    final leanCueReps = <int>{
      for (final e in log.cueEvents)
        if (e.content == CueContent.torsoSwing) e.repNum - 1,
    };

    final thresholds = log.profile.compensation;

    return _PanelLabeled(
      index: '02',
      title: 'FORM OVER TIME',
      subtitle: 'POSE-INFERRED · PER REP',
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SignedRepBarChart(
              label: 'SHOULDER RISE',
              signedValues: shoulderSeries,
              threshold: thresholds.shoulderDriftDeg,
              cueMarkerReps: shoulderCueReps,
              selectedRep: currentRep,
              onTap: onRepTap,
            ),
            const SizedBox(height: 20),
            _SignedRepBarChart(
              label: 'FORWARD LEAN',
              signedValues: leanSeries,
              threshold: thresholds.torsoPitchDeltaDeg,
              cueMarkerReps: leanCueReps,
              selectedRep: currentRep,
              onTap: onRepTap,
            ),
            const SizedBox(height: 12),
            _RepAxisLabel(repCount: log.reps.length),
          ],
        ),
      ),
    );
  }
}

class _RepAxisLabel extends StatelessWidget {
  const _RepAxisLabel({required this.repCount});

  final int repCount;

  @override
  Widget build(BuildContext context) {
    final style = mktMono(
      9,
      color: MarketingPalette.subtle,
      letterSpacing: 2.2,
      weight: FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('REP 01', style: style),
        Text('REP ${repCount.toString().padLeft(2, '0')}', style: style),
      ],
    );
  }
}

class _SignedRepBarChart extends StatelessWidget {
  const _SignedRepBarChart({
    required this.label,
    required this.signedValues,
    required this.threshold,
    required this.cueMarkerReps,
    required this.selectedRep,
    required this.onTap,
  });

  final String label;
  final List<double?> signedValues;
  final double threshold;
  final Set<int> cueMarkerReps;
  final int selectedRep;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final positiveValues = signedValues
        .whereType<double>()
        .where((v) => v > 0)
        .toList();
    final negativeValues = signedValues
        .whereType<double>()
        .where((v) => v < 0)
        .toList();
    final observedMaxPos = positiveValues.isEmpty
        ? 0.0
        : positiveValues.reduce(math.max);
    final observedMaxNeg = negativeValues.isEmpty
        ? 0.0
        : negativeValues.map((v) => v.abs()).reduce(math.max);

    final peakLabelValue = signedValues
        .whereType<double>()
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: mktMono(
                  10,
                  color: MarketingPalette.text,
                  letterSpacing: 2.4,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'peak ${_formatDeg(peakLabelValue)}',
              style: mktMono(
                9,
                color: MarketingPalette.muted,
                letterSpacing: 1.8,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                if (signedValues.isEmpty) return;
                final localX = d.localPosition.dx
                    .clamp(0.0, constraints.maxWidth - 1);
                final repIdx = ((localX / constraints.maxWidth) *
                        signedValues.length)
                    .floor()
                    .clamp(0, signedValues.length - 1);
                onTap(repIdx);
              },
              child: CustomPaint(
                size: Size(constraints.maxWidth, 78),
                painter: _RepBarPainter(
                  signedValues: signedValues,
                  threshold: threshold,
                  observedMaxPos: observedMaxPos,
                  observedMaxNeg: observedMaxNeg,
                  cueMarkerReps: cueMarkerReps,
                  selectedRep: selectedRep,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _formatDeg(double deg) {
  if (deg == 0) return '0°';
  final sign = deg > 0 ? '+' : '-';
  return '$sign${deg.abs().toStringAsFixed(0)}°';
}

class _RepBarPainter extends CustomPainter {
  _RepBarPainter({
    required this.signedValues,
    required this.threshold,
    required this.observedMaxPos,
    required this.observedMaxNeg,
    required this.cueMarkerReps,
    required this.selectedRep,
  });

  final List<double?> signedValues;
  final double threshold;
  final double observedMaxPos;
  final double observedMaxNeg;
  final Set<int> cueMarkerReps;
  final int selectedRep;

  // Reserved space above/below the chart for cue markers + peak overhead.
  static const double _markerGutter = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (signedValues.isEmpty) return;

    // Axis scales. Positive side covers the larger of 1.5× threshold or
    // the observed max, so a clean session still renders visible bars and
    // a heavy-compensation session doesn't clip. Negative side covers at
    // most the observed slump with a small floor so tiny back-leans don't
    // dominate the axis.
    final posMax = math.max(threshold * 1.5, observedMaxPos);
    final negMax = math.max(threshold * 0.5, observedMaxNeg);
    final totalRange = posMax + negMax;
    if (totalRange <= 0) return;

    final chartTop = _markerGutter;
    final chartBottom = size.height - 4;
    final chartHeight = chartBottom - chartTop;
    if (chartHeight <= 0) return;

    final axisY = chartTop + chartHeight * (posMax / totalRange);

    // Threshold hairline on the positive side.
    final thresholdY = axisY -
        (threshold / totalRange) * chartHeight;
    final hairline = Paint()
      ..color = MarketingPalette.hairline
      ..strokeWidth = 1;
    const dashLen = 4.0;
    const dashGap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset(math.min(x + dashLen, size.width), thresholdY),
        hairline,
      );
      x += dashLen + dashGap;
    }

    // Zero axis — solid hairline.
    canvas.drawLine(
      Offset(0, axisY),
      Offset(size.width, axisY),
      Paint()
        ..color = MarketingPalette.hairline
        ..strokeWidth = 1,
    );

    // Bars.
    final reps = signedValues.length;
    // Gap scales with density so 30 reps remain legible and 1–3 reps
    // don't render as monoliths.
    final gap = reps <= 8 ? 4.0 : (reps <= 16 ? 2.5 : 1.5);
    final totalGap = gap * (reps - 1).clamp(0, reps - 1);
    final barWidth = math.max(1.5, (size.width - totalGap) / reps);

    for (var i = 0; i < reps; i++) {
      final bucket = bucketFor(signedValues[i], threshold);
      if (bucket == BarBucket.missing) continue;

      final signed = signedValues[i]!;
      final barX = i * (barWidth + gap);

      // Selection highlight — soft outline behind the selected bar.
      if (i == selectedRep) {
        final outline = Paint()
          ..color = BioliminalTheme.accent.withValues(alpha: 0.18);
        canvas.drawRect(
          Rect.fromLTWH(
            barX - 1,
            chartTop - 2,
            barWidth + 2,
            chartHeight + 4,
          ),
          outline,
        );
      }

      final color = _colorFor(bucket);
      final fill = Paint()..color = color;

      if (bucket == BarBucket.negative) {
        final mag = signed.abs();
        final h = (mag / totalRange) * chartHeight;
        canvas.drawRect(
          Rect.fromLTWH(barX, axisY, barWidth, h),
          fill,
        );
      } else {
        final h = (signed / totalRange) * chartHeight;
        canvas.drawRect(
          Rect.fromLTWH(barX, axisY - h, barWidth, h),
          fill,
        );

        // Cue marker (small filled down-triangle above the bar) for
        // reps where the corresponding cue fired. Only present when the
        // rep is in the positive-delta range — cues never fire on
        // slumps by construction.
        if (cueMarkerReps.contains(i)) {
          _drawCueMarker(canvas, barX + barWidth / 2, axisY - h - 2);
        }
      }
    }
  }

  Color _colorFor(BarBucket bucket) {
    switch (bucket) {
      case BarBucket.clean:
        return MarketingPalette.subtle;
      case BarBucket.amber:
        return MarketingPalette.warn;
      case BarBucket.red:
        return MarketingPalette.error;
      case BarBucket.negative:
        return MarketingPalette.subtle.withValues(alpha: 0.55);
      case BarBucket.missing:
        return Colors.transparent;
    }
  }

  void _drawCueMarker(Canvas canvas, double cx, double tipY) {
    const half = 3.0;
    const height = 5.0;
    final path = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx - half, tipY - height)
      ..lineTo(cx + half, tipY - height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = MarketingPalette.error,
    );
  }

  @override
  bool shouldRepaint(covariant _RepBarPainter old) =>
      old.signedValues != signedValues ||
      old.threshold != threshold ||
      old.observedMaxPos != observedMaxPos ||
      old.observedMaxNeg != observedMaxNeg ||
      old.cueMarkerReps != cueMarkerReps ||
      old.selectedRep != selectedRep;
}
