import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/hardware_controller.dart';
import '../../camera/services/landmark_smoother.dart';
import '../../../core/services/sample_batch.dart';
import '../../../domain/models.dart';
import '../models/compensation_reference.dart';
import '../models/cue_decision.dart';
import '../models/cue_event.dart';
import '../models/cue_profile.dart';
import '../models/pose_delta.dart';
import '../models/rep_record.dart';
import '../models/session_log.dart';
import '../services/compensation_detector.dart';
import '../services/cue_dispatcher.dart';
import '../services/envelope_derivator.dart';
import '../services/fatigue_algorithm.dart';
import '../services/rep_detector.dart';
import '../services/tts_speaker.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class BicepCurlState {
  const BicepCurlState();
}

class BicepCurlIdle extends BicepCurlState {
  const BicepCurlIdle();
}

/// Pre-flight: camera is streaming, user is positioning into frame.
/// View signals readiness via [BicepCurlController.markFramingComplete].
class BicepCurlSetup extends BicepCurlState {
  const BicepCurlSetup();
}

class BicepCurlCalibrating extends BicepCurlState {
  const BicepCurlCalibrating({required this.repsCompleted, required this.reps});
  final int repsCompleted;
  final List<RepRecord> reps;
}

class BicepCurlActive extends BicepCurlState {
  const BicepCurlActive({
    required this.reps,
    required this.ref,
    required this.lastCueRep,
    required this.cueHistory,
    required this.currentDropFraction,
    required this.currentCompensating,
    required this.emgOnline,
  });

  final List<RepRecord> reps;
  final CompensationReference ref;
  final int lastCueRep;
  final List<CueEvent> cueHistory;

  /// Latest evaluated drop (peak/baseline). Drives the fatigue bar.
  final double currentDropFraction;
  final bool currentCompensating;

  /// False when the BLE link dropped during this set. Per Kelsi's call:
  /// session continues with visual + compensation cues (pose-based, no
  /// EMG required) while the fatigue bar greys out.
  final bool emgOnline;

  BicepCurlActive copyWith({
    List<RepRecord>? reps,
    CompensationReference? ref,
    int? lastCueRep,
    List<CueEvent>? cueHistory,
    double? currentDropFraction,
    bool? currentCompensating,
    bool? emgOnline,
  }) =>
      BicepCurlActive(
        reps: reps ?? this.reps,
        ref: ref ?? this.ref,
        lastCueRep: lastCueRep ?? this.lastCueRep,
        cueHistory: cueHistory ?? this.cueHistory,
        currentDropFraction: currentDropFraction ?? this.currentDropFraction,
        currentCompensating: currentCompensating ?? this.currentCompensating,
        emgOnline: emgOnline ?? this.emgOnline,
      );
}

class BicepCurlComplete extends BicepCurlState {
  const BicepCurlComplete({required this.log});
  final SessionLog log;
}

class BicepCurlError extends BicepCurlState {
  const BicepCurlError({required this.message});
  final String message;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Orchestrator for a single bicep curl set.
///
/// Owns:
/// - subscriptions to BLE [SampleBatch]es and pose [PoseLandmark] frames
/// - the envelope derivator + rep detector + cue dispatcher lifecycles
/// - the rep-completion-driven idle timer that auto-ends the set
/// - the session log accumulator
///
/// State transitions:
/// ```
/// Idle → Setup → Calibrating → Active → Complete
///                                  ↘─ Complete (idle timeout)
/// ```
class BicepCurlController extends Notifier<BicepCurlState> {
  static const Duration _autoEndIdle = Duration(seconds: 10);

  /// Bus for transient cue-fire events the live view subscribes to (badge
  /// flashes, fatigue-bar pulses). Always reflects the most recent event;
  /// view filters by recency when rendering.
  final ValueNotifier<CueEvent?> visualBus = ValueNotifier(null);

  // Pipeline pieces (lazily constructed in startSession; nulled on teardown).
  EnvelopeDerivator? _envelope;
  RepDetector? _repDetector;
  CueDispatcher? _dispatcher;
  TtsSpeaker? _tts;

  // Cached smoother reference — populated in build() so it is safe to call
  // in _teardown() even when invoked from ref.onDispose (where ref.read is
  // forbidden by Riverpod's lifecycle guard).
  LandmarkSmoother? _smoother;

  // Subscriptions.
  // Pose-landmark and hardware-connection listeners are wired in [build] so
  // their subscription lifetime equals the Notifier's. Every `ref.listen`
  // subscription gets deactivated when the source element (this controller)
  // has no active listeners — Riverpod treats an unwatched Notifier as
  // effectively idle and pauses its outgoing subs. That's fine in production
  // because [BicepCurlView] watches this provider for the entire session,
  // but it's why the integration test harness also has to listen on the
  // controller (just `container.read`ing won't keep the dep graph live).
  // Sample + rep-boundary stream subs are per-session because they're tied
  // to an EnvelopeDerivator/RepDetector created in startSession.
  StreamSubscription<SampleBatch>? _sampleSub;
  StreamSubscription<RepBoundary>? _repSub;

  // Wall-clock buffer of envelope samples (for per-rep peak extraction).
  final Queue<_TimedEnvelope> _envelopeBuffer = Queue<_TimedEnvelope>();
  static const int _envelopeBufferRetentionUs = 10 * 1000 * 1000;

  // Pose frames captured during the current rep window — used to build the
  // compensation reference (during calibration reps 1–3) and per-rep
  // PoseDelta (during Active).
  final List<List<PoseLandmark>> _currentRepFrames =
      <List<PoseLandmark>>[];
  final List<List<PoseLandmark>> _calibrationFramesForRef =
      <List<PoseLandmark>>[];

  // Session bookkeeping.
  ArmSide _side = ArmSide.right;
  CueProfile _profile = CueProfile.intermediate();
  DateTime? _sessionStartedAt;
  bool _bleDroppedDuringSet = false;
  Timer? _idleTimer;

  // Wall-clock ↔ BLE-firmware-time alignment. Captured on first SampleBatch
  // so envelope sample timestamps live in the same epoch as pose frames.
  int? _bleEpochUs;
  int? _wallEpochUs;

  // Latest CueEvent per rep (so cooldown-suppressed evaluations don't bump
  // lastCueRep — which would let real cues slip past cooldown later).
  final List<CueEvent> _cueLog = <CueEvent>[];
  int _lastCueRep = -999;

  @override
  BicepCurlState build() {
    // Cache smoother here — ref.read is forbidden inside onDispose callbacks
    // (Riverpod lifecycle guard), so _teardown must use the cached reference.
    _smoother = ref.read(landmarkSmootherProvider);
    // See the subscription-field note above for why these live here.
    // Handlers no-op when state isn't Calibrating/Active.
    ref.listen<List<PoseLandmark>>(
      currentLandmarksProvider,
      (_, next) => _onLandmarks(next),
    );
    ref.listen<HardwareConnectionState>(
      hardwareControllerProvider,
      (_, next) => _onConnectionState(next),
    );
    ref.onDispose(_teardown);
    return const BicepCurlIdle();
  }

  /// Begin a session. Camera must already be streaming. Garment is
  /// optional — when not connected, the set runs vision-only (pose-based
  /// rep counting + compensation cues; fatigue bar greyed out).
  Future<void> startSession({
    required ArmSide side,
    CueProfile? profile,
  }) async {
    if (state is! BicepCurlIdle && state is! BicepCurlComplete &&
        state is! BicepCurlError) {
      developer.log(
        'startSession ignored — already in $state',
        name: 'BicepCurlController',
      );
      return;
    }

    final hardwareState = ref.read(hardwareControllerProvider);
    _side = side;
    _profile = profile ?? CueProfile.intermediate();
    _sessionStartedAt = DateTime.now();
    _bleDroppedDuringSet =
        hardwareState != HardwareConnectionState.connected;
    _envelope = EnvelopeDerivator();
    _repDetector = RepDetector();
    _envelopeBuffer.clear();
    _currentRepFrames.clear();
    _calibrationFramesForRef.clear();
    _cueLog.clear();
    _lastCueRep = -999;
    _bleEpochUs = null;
    _wallEpochUs = null;

    final hardware = ref.read(hardwareControllerProvider.notifier);
    _tts = TtsSpeaker();
    _dispatcher = CueDispatcher(
      profile: _profile,
      hardware: hardware,
      onLog: _cueLog.add,
      visualBus: visualBus,
      speak: _tts!.speak,
    );

    _sampleSub = hardware.rawEmgStream.listen(_onSample);
    _repSub = _repDetector!.boundaries.listen(_onRepBoundary);

    await hardware.setSessionState(0); // 0 = Idle on firmware
    state = const BicepCurlSetup();
  }

  /// Called by the live view once the framing-check passes. Transitions
  /// Setup → Calibrating and tells firmware we've started. The idle
  /// auto-end timer is *not* started yet — calibration's first rep can
  /// take 20-30 s (user reaching for dumbbell, getting into position).
  /// Timer arms once we enter Active state.
  void markFramingComplete() {
    if (state is! BicepCurlSetup) return;
    final hardware = ref.read(hardwareControllerProvider.notifier);
    hardware.setSessionState(1); // 1 = Calibrating
    state = const BicepCurlCalibrating(repsCompleted: 0, reps: <RepRecord>[]);
  }

  /// Long-press toggle on the rep counter cycles the active profile.
  /// intermediate → advanced → beginner → intermediate.
  void cycleProfile() {
    final next = switch (_profile.label) {
      'intermediate' => CueProfile.advanced(),
      'advanced' => CueProfile.beginner(),
      _ => CueProfile.intermediate(),
    };
    _profile = next;
    _dispatcher?.profile = next;
    developer.log('profile → ${next.label}', name: 'BicepCurlController');
  }

  /// Manual end. Idle timeout calls this too.
  Future<void> endSession() async {
    if (state is BicepCurlIdle || state is BicepCurlComplete) return;
    final log = _buildLog();
    final hardware = ref.read(hardwareControllerProvider.notifier);
    await hardware.setSessionState(0);
    await hardware.stopHaptic();
    await _teardown(keepVisualBus: true);
    state = BicepCurlComplete(log: log);
  }

  /// Drop the session without producing a log (e.g., user backed out).
  Future<void> cancel() async {
    final hardware = ref.read(hardwareControllerProvider.notifier);
    await hardware.setSessionState(0);
    await hardware.stopHaptic();
    await _teardown();
    state = const BicepCurlIdle();
  }

  // ---------- internal stream handlers ----------

  void _onSample(SampleBatch batch) {
    final env = _envelope;
    if (env == null) return;
    _bleEpochUs ??= batch.tUsStart;
    _wallEpochUs ??= DateTime.now().microsecondsSinceEpoch;

    final values = env.processBatch(batch);
    for (var i = 0; i < values.length; i++) {
      final wallTUs = _wallEpochUs! + (batch.tUsAt(i) - _bleEpochUs!);
      _envelopeBuffer.add(_TimedEnvelope(wallTUs, values[i]));
    }
    final cutoff = DateTime.now().microsecondsSinceEpoch -
        _envelopeBufferRetentionUs;
    while (_envelopeBuffer.isNotEmpty &&
        _envelopeBuffer.first.tUs < cutoff) {
      _envelopeBuffer.removeFirst();
    }
  }

  void _onLandmarks(List<PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return;
    final s = state;
    if (s is! BicepCurlCalibrating && s is! BicepCurlActive) return;
    final tUs = DateTime.now().microsecondsSinceEpoch;
    _repDetector?.addPoseFrame(tUs, landmarks, _side);
    _currentRepFrames.add(landmarks);
  }

  void _onConnectionState(HardwareConnectionState s) {
    if (s != HardwareConnectionState.connected) {
      _bleDroppedDuringSet = true;
      final cur = state;
      if (cur is BicepCurlActive && cur.emgOnline) {
        state = cur.copyWith(emgOnline: false);
      }
    }
  }

  void _onRepBoundary(RepBoundary b) {
    final summary = _summarizeWindow(b.tStartUs, b.tEndUs);
    final s = state;
    if (s is BicepCurlCalibrating) {
      _handleCalibrationRep(s, b, summary.peak, summary.samples);
    } else if (s is BicepCurlActive) {
      _handleActiveRep(s, b, summary.peak, summary.samples);
    }
    _currentRepFrames.clear();
    _resetIdleTimer();
  }

  void _handleCalibrationRep(
    BicepCurlCalibrating s,
    RepBoundary b,
    double peakEnv,
    List<double> envelopeSamples,
  ) {
    final repNum = s.repsCompleted + 1;
    final record = RepRecord(
      repNum: repNum,
      tStartUs: b.tStartUs,
      tPeakUs: b.tPeakUs,
      tEndUs: b.tEndUs,
      peakEnv: peakEnv,
      envelopeSamples: envelopeSamples,
    );
    final reps = [...s.reps, record];

    // Pool reps 1–3 frames for the compensation reference.
    if (repNum <= 3) {
      _calibrationFramesForRef.addAll(_currentRepFrames);
    }

    if (repNum >= _profile.calibrationReps) {
      final ref = CompensationDetector.buildReference(
        _calibrationFramesForRef,
        _side,
      );
      final hardware = this.ref.read(hardwareControllerProvider.notifier);
      hardware.setSessionState(2); // 2 = Active
      state = BicepCurlActive(
        reps: reps,
        ref: ref,
        lastCueRep: -999,
        cueHistory: const <CueEvent>[],
        currentDropFraction: 0.0,
        currentCompensating: false,
        emgOnline: !_bleDroppedDuringSet,
      );
    } else {
      state = BicepCurlCalibrating(repsCompleted: repNum, reps: reps);
    }
  }

  void _handleActiveRep(
    BicepCurlActive s,
    RepBoundary b,
    double peakEnv,
    List<double> envelopeSamples,
  ) {
    final repNum = s.reps.length + 1;

    final delta = _currentRepFrames.isEmpty
        ? null
        : _meanDelta(_currentRepFrames, s.ref);
    final compensating =
        delta?.exceedsThresholds(_profile.compensation) ?? false;

    final record = RepRecord(
      repNum: repNum,
      tStartUs: b.tStartUs,
      tPeakUs: b.tPeakUs,
      tEndUs: b.tEndUs,
      peakEnv: peakEnv,
      poseDelta: delta,
      envelopeSamples: envelopeSamples,
    );
    final reps = [...s.reps, record];
    final peaks = [for (final r in reps) r.peakEnv];

    final emgOnline = !_bleDroppedDuringSet;
    final decision = emgOnline
        ? FatigueAlgorithm.evaluate(
            peaks: peaks,
            currentRepNum: repNum,
            lastCueRep: _lastCueRep,
            profile: _profile,
            compensationActive: compensating,
          )
        : (compensating
            ? CueDecision(
                content: CueContent.compensationDetected,
                repNum: repNum,
              )
            : null);

    final dropFraction = _latestDropFraction(peaks);

    if (decision != null) {
      _dispatcher?.dispatch(decision);
      // Only fatigue cues bump cooldown; compensation events fire
      // independently of the cooldown clock.
      if (decision.content == CueContent.fatigueFade ||
          decision.content == CueContent.fatigueUrgent) {
        _lastCueRep = repNum;
      }
    }

    state = s.copyWith(
      reps: reps,
      lastCueRep: _lastCueRep,
      cueHistory: List.unmodifiable(_cueLog),
      currentDropFraction: dropFraction,
      currentCompensating: compensating,
      emgOnline: emgOnline,
    );
  }

  // ---------- helpers ----------

  /// Walks the envelope buffer once, computing the per-rep peak and a
  /// 50-bucket max-pooled segment for the heatmap. Bucket-max (vs mean
  /// or interpolation) preserves visual peaks across the rep window.
  static const int _envelopeBucketsPerRep = 50;

  ({double peak, List<double> samples}) _summarizeWindow(
    int tStartUs,
    int tEndUs,
  ) {
    final samples =
        List<double>.filled(_envelopeBucketsPerRep, 0.0);
    var peak = 0.0;
    if (tEndUs <= tStartUs) return (peak: peak, samples: samples);
    final binSize = (tEndUs - tStartUs) / _envelopeBucketsPerRep;
    for (final s in _envelopeBuffer) {
      if (s.tUs < tStartUs) continue;
      if (s.tUs >= tEndUs) break;
      if (s.value > peak) peak = s.value;
      final bin = ((s.tUs - tStartUs) / binSize)
          .floor()
          .clamp(0, _envelopeBucketsPerRep - 1);
      if (s.value > samples[bin]) samples[bin] = s.value;
    }
    return (peak: peak, samples: samples);
  }

  PoseDelta _meanDelta(
    List<List<PoseLandmark>> frames,
    CompensationReference ref,
  ) {
    var sumShoulder = 0.0;
    var sumPitch = 0.0;
    for (final frame in frames) {
      final d = CompensationDetector.computeDelta(frame, ref);
      sumShoulder += d.shoulderDriftDeg;
      sumPitch += d.torsoPitchDeltaDeg;
    }
    return PoseDelta(
      shoulderDriftDeg: sumShoulder / frames.length,
      torsoPitchDeltaDeg: sumPitch / frames.length,
    );
  }

  double _latestDropFraction(List<double> peaks) {
    if (peaks.length < 2) return 0.0;
    final windowStart =
        peaks.length - _profile.baselineWindow < 0
            ? 0
            : peaks.length - _profile.baselineWindow;
    var baseline = peaks[windowStart];
    for (var i = windowStart + 1; i < peaks.length; i++) {
      if (peaks[i] > baseline) baseline = peaks[i];
    }
    if (baseline <= 0) return 0.0;
    return (1.0 - peaks.last / baseline).clamp(0.0, 1.0);
  }

  /// Auto-end the set when no rep has been detected for [_autoEndIdle].
  /// Only runs during Active — calibration is allowed to take its time
  /// (first rep often arrives 20-30 s after Setup completes).
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (state is BicepCurlActive) {
      _idleTimer = Timer(_autoEndIdle, () => unawaited(endSession()));
    }
  }

  SessionLog _buildLog() {
    final s = state;
    final reps = s is BicepCurlActive
        ? s.reps
        : s is BicepCurlCalibrating
            ? s.reps
            : <RepRecord>[];
    final ref = s is BicepCurlActive ? s.ref : null;
    return SessionLog(
      reps: reps,
      cueEvents: List.unmodifiable(_cueLog),
      ref: ref,
      startedAt: _sessionStartedAt ?? DateTime.now(),
      duration: DateTime.now().difference(_sessionStartedAt ?? DateTime.now()),
      profile: _profile,
      armSide: _side,
      bleDroppedDuringSet: _bleDroppedDuringSet,
    );
  }

  Future<void> _teardown({bool keepVisualBus = false}) async {
    _idleTimer?.cancel();
    _idleTimer = null;
    // Use cached _smoother — ref.read is forbidden in onDispose callbacks.
    _smoother?.reset();
    await _sampleSub?.cancel();
    _sampleSub = null;
    await _repSub?.cancel();
    _repSub = null;
    // Landmark + connection subs live on ref (wired in build) and tear down
    // with the Notifier. Not closed per-session.
    await _repDetector?.dispose();
    _repDetector = null;
    _envelope?.reset();
    _envelope = null;
    _dispatcher = null;
    await _tts?.dispose();
    _tts = null;
    _envelopeBuffer.clear();
    _currentRepFrames.clear();
    _calibrationFramesForRef.clear();
    if (!keepVisualBus) visualBus.value = null;
  }
}

class _TimedEnvelope {
  const _TimedEnvelope(this.tUs, this.value);
  final int tUs;
  final double value;
}

final bicepCurlControllerProvider =
    NotifierProvider<BicepCurlController, BicepCurlState>(
      BicepCurlController.new,
    );

/// Convenience selector for the post-set debrief view.
final lastCompletedSessionLogProvider = Provider<SessionLog?>((ref) {
  final s = ref.watch(bicepCurlControllerProvider);
  return s is BicepCurlComplete ? s.log : null;
});
