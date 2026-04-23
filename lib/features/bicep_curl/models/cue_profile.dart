/// Per-user cue policy. Drives the fatigue algorithm (thresholds + windows)
/// and the dispatcher (which channels fire). v0 ships only [intermediate];
/// [beginner] and [advanced] exist so the long-press debug toggle on the
/// rep counter can flip profiles mid-demo without touching the algorithm.
///
/// Rationale lives in `docs/hardware_integration/practitioner-notes-lawson.md`
/// (user-level × channel matrix).
class CueProfile {
  const CueProfile({
    required this.thresholds,
    required this.compensation,
    required this.cooldownReps,
    required this.calibrationReps,
    required this.baselineWindow,
    required this.haptic,
    required this.visual,
    required this.verbal,
    required this.timing,
    required this.label,
  });

  final FatigueThresholds thresholds;
  final CompensationThresholds compensation;
  final int cooldownReps;
  final int calibrationReps;
  final int baselineWindow;
  final ChannelConfig haptic;
  final ChannelConfig visual;
  final ChannelConfig verbal;
  final TimingMode timing;
  final String label;

  /// v0 defaults from `haptic-cueing-handshake.md` §"The algorithm".
  ///
  /// Compensation thresholds were raised (7°/10° → 14°/20°) when the
  /// detector moved from mean-across-rep to signed PEAK deltas: the old
  /// values were tuned against a wash-out average, so applying them to a
  /// peak would fire ~2× as often. TODO: retune empirically once a pass
  /// of bench sessions lands against the new algorithm.
  factory CueProfile.intermediate() => const CueProfile(
        label: 'intermediate',
        thresholds: FatigueThresholds(fade: 0.15, urgent: 0.25, stop: 0.50),
        compensation: CompensationThresholds(
          shoulderDriftDeg: 14.0,
          torsoPitchDeltaDeg: 20.0,
        ),
        cooldownReps: 2,
        calibrationReps: 5,
        baselineWindow: 5,
        haptic: ChannelConfig(enabled: true),
        visual: ChannelConfig(enabled: true),
        verbal: ChannelConfig(enabled: false),
        timing: TimingMode.preRep,
      );

  /// Per Lawson: beginners get fewer, later cues; the post-set debrief is
  /// the primary feedback mechanism. Less aggressive thresholds, longer
  /// cooldown, longer calibration, live channels muted.
  factory CueProfile.beginner() => const CueProfile(
        label: 'beginner',
        thresholds: FatigueThresholds(fade: 0.20, urgent: 0.30, stop: 0.55),
        compensation: CompensationThresholds(
          shoulderDriftDeg: 18.0,
          torsoPitchDeltaDeg: 24.0,
        ),
        cooldownReps: 4,
        calibrationReps: 8,
        baselineWindow: 5,
        haptic: ChannelConfig(enabled: false),
        visual: ChannelConfig(enabled: false),
        verbal: ChannelConfig(enabled: false),
        timing: TimingMode.postSet,
      );

  /// Advanced users tolerate denser, earlier cues and benefit from verbal
  /// stabilizer prompts. Tighter thresholds, shorter cooldown, all
  /// channels live.
  factory CueProfile.advanced() => const CueProfile(
        label: 'advanced',
        thresholds: FatigueThresholds(fade: 0.10, urgent: 0.20, stop: 0.45),
        compensation: CompensationThresholds(
          shoulderDriftDeg: 10.0,
          torsoPitchDeltaDeg: 16.0,
        ),
        cooldownReps: 1,
        calibrationReps: 3,
        baselineWindow: 5,
        haptic: ChannelConfig(enabled: true),
        visual: ChannelConfig(enabled: true),
        verbal: ChannelConfig(enabled: true),
        timing: TimingMode.midRep,
      );

  /// v0 persists only the preset label — custom profile tuning isn't a
  /// runtime feature yet. Loading rebuilds via the factory.
  Map<String, dynamic> toJson() => {'label': label};

  factory CueProfile.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String;
    switch (label) {
      case 'beginner':
        return CueProfile.beginner();
      case 'advanced':
        return CueProfile.advanced();
      case 'intermediate':
      default:
        return CueProfile.intermediate();
    }
  }
}

class FatigueThresholds {
  const FatigueThresholds({
    required this.fade,
    required this.urgent,
    required this.stop,
  });

  final double fade;
  final double urgent;
  final double stop;
}

class CompensationThresholds {
  const CompensationThresholds({
    required this.shoulderDriftDeg,
    required this.torsoPitchDeltaDeg,
  });

  final double shoulderDriftDeg;
  final double torsoPitchDeltaDeg;
}

class ChannelConfig {
  const ChannelConfig({required this.enabled});

  final bool enabled;
}

enum TimingMode { preRep, midRep, postSet }
