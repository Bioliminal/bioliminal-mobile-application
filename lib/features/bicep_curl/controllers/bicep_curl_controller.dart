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
  }) => BicepCurlActive(
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
// Rep-count reconciliation
// ---------------------------------------------------------------------------

/// Snapshot of CV-vs-firmware rep count. CV is authoritative; hardware
/// count is diagnostic. [disagreeing] flips when the gap crosses the
/// controller's threshold — drives a subtle UI indicator near the rep
/// counter and a `developer.log` line under name `RepCountReconciler`.
class RepCountReconciliation {
  const RepCountReconciliation.agreed({required this.cv, required this.hw})
      : disagreeing = false;
  const RepCountReconciliation.disagreed({required this.cv, required this.hw})
      : disagreeing = true;

  final int cv;
  final int hw;
  final bool disagreeing;
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
  /// Bus for transient cue-fire events the live view subscribes to (badge
  /// flashes, fatigue-bar pulses). Always reflects the most recent event;
  /// view filters by recency when rendering.
  final ValueNotifier<CueEvent?> visualBus = ValueNotifier(null);

  /// Rep-count reconciliation state. CV is authoritative (Aaron's
  /// RepDecisionPolicy pipeline); firmware's rep_count field on FF02 is
  /// supplemental. When the two drift by [_repDisagreementThreshold] or
  /// more, this notifier flips to disagreeing — drives a subtle UI
  /// indicator next to the rep counter. Also see [_onHardwareRepCount].
  final ValueNotifier<RepCountReconciliation> repReconciliation =
      ValueNotifier(const RepCountReconciliation.agreed(cv: 0, hw: 0));

  /// Drift threshold for surfacing a disagreement: a gap of 1 is routine
  /// packet-boundary noise (firmware counter ticks over half a packet ahead
  /// of the CV boundary), ≥2 is a real divergence worth showing.
  static const int _repDisagreementThreshold = 2;

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
  // Hardware-led mode: listen to the firmware's autonomous cue event (bit0
  // in the FF02 cue_event byte) and translate it into a visualBus pulse so
  // the on-screen flash fires in sync with the motor.
  StreamSubscription<void>? _hardwareCueSub;
  // CV rep-start boundary (from RepDetector.onRepStart). Clears the per-rep
  // pose frame buffer so the current rep doesn't leak frames from the prior
  // one.
  StreamSubscription<int>? _repStartSub;
  // Reps dropped by a gate (short-ROM, momentum, stalled). Log-only today;
  // downstream briefs route these to form cues + server diagnostics.
  StreamSubscription<RepSuppressedEvent>? _repSuppressedSub;
  // NOTE: firmware rep_count is consumed directly inside [_onSample] (from
  // the FF02 packet header), not via HardwareController.repCountStream.
  // The dedicated stream is redundant — SampleBatch.repCount is the same
  // signal before HardwareController's rising-edge filter — and using the
  // raw value here keeps reconciliation in a single place.

  // Wall-clock buffer of envelope samples (for per-rep peak extraction).
  final Queue<_TimedEnvelope> _envelopeBuffer = Queue<_TimedEnvelope>();
  static const int _envelopeBufferRetentionUs = 10 * 1000 * 1000;

  // Pose frames captured during the current rep window — used to build the
  // compensation reference (stable-resting-frame filter applied inside
  // CompensationDetector.buildReference across pooled calibration reps 1–3)
  // and per-rep signed peak deltas during Active.
  final List<List<PoseLandmark>> _currentRepFrames = <List<PoseLandmark>>[];
  final List<List<PoseLandmark>> _calibrationFramesForRef =
      <List<PoseLandmark>>[];

  // Session bookkeeping.
  ArmSide _side = ArmSide.right;
  CueProfile _profile = CueProfile.intermediate();
  DateTime? _sessionStartedAt;
  bool _bleDroppedDuringSet = false;

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
    if (state is! BicepCurlIdle &&
        state is! BicepCurlComplete &&
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
    _bleDroppedDuringSet = hardwareState != HardwareConnectionState.connected;
    _envelope = EnvelopeDerivator();
    final policyFactory = ref.read(repDecisionPolicyFactoryProvider);
    _repDetector = RepDetector(policyFactory: policyFactory);
    _envelopeBuffer.clear();
    _currentRepFrames.clear();
    _calibrationFramesForRef.clear();
    _cueLog.clear();
    _lastCueRep = -999;
    _bleEpochUs = null;
    _wallEpochUs = null;
    _cvRepCount = 0;
    _lastHardwareRepCount = 0;
    repReconciliation.value =
        const RepCountReconciliation.agreed(cv: 0, hw: 0);

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
    _hardwareCueSub = hardware.cueEventStream.listen((_) => _onHardwareCue());
    _repStartSub = _repDetector!.onRepStart.listen(_onRepStart);
    _repSuppressedSub = _repDetector!.suppressed.listen(_onRepSuppressed);

    await hardware.setSessionState(0); // 0 = Idle on firmware
    state = const BicepCurlSetup();
  }

  /// Fires when the autonomous firmware sets bit0 of the packet's cue_event
  /// byte. Drives the full-screen flash; the cue was already logged by the
  /// dispatcher (if any on-device decision preceded it) or is an
  /// untagged firmware-originated event. The visual layer doesn't care
  /// which source triggered it — the flash is the flash.
  void _onHardwareCue() {
    final event = CueEvent(
      repNum: _lastHardwareRepCount,
      content: CueContent.fatigueUrgent,
      firedAt: DateTime.now(),
      channelsFired: const {'haptic', 'visual'},
    );
    visualBus.value = event;
  }

  /// Firmware-reported rep count from the latest FF02 packet header.
  /// Advisory only — CV is authoritative.
  int _lastHardwareRepCount = 0;

  /// Cumulative CV rep count over the session (calibration + active reps).
  /// Bumped on every [_onRepBoundary]; authoritative per the architectural
  /// decision documented on [repReconciliation].
  int _cvRepCount = 0;

  void _updateReconciliation() {
    final cv = _cvRepCount;
    final hw = _lastHardwareRepCount;
    final delta = (cv - hw).abs();
    final disagreeing = delta >= _repDisagreementThreshold;
    if (disagreeing) {
      developer.log(
        'rep count disagreement cv=$cv hw=$hw delta=$delta',
        name: 'RepCountReconciler',
      );
      repReconciliation.value =
          RepCountReconciliation.disagreed(cv: cv, hw: hw);
    } else {
      repReconciliation.value =
          RepCountReconciliation.agreed(cv: cv, hw: hw);
    }
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
    // Hardware-led mode: single FF04 write on session end tells firmware to
    // gate off sampling. Firmware's own onDisconnect/Idle path stops any
    // in-flight motor; no separate stopHaptic() needed.
    await hardware.setSessionState(0);
    await _teardown(keepVisualBus: true);
    state = BicepCurlComplete(log: log);
  }

  /// Drop the session without producing a log (e.g., user backed out).
  Future<void> cancel() async {
    final hardware = ref.read(hardwareControllerProvider.notifier);
    await hardware.setSessionState(0);
    await _teardown();
    state = const BicepCurlIdle();
  }

  // ---------- internal stream handlers ----------

  void _onSample(SampleBatch batch) {
    if (batch.repCount != _lastHardwareRepCount) {
      _lastHardwareRepCount = batch.repCount;
      _updateReconciliation();
    }
    final env = _envelope;
    if (env == null) return;
    _bleEpochUs ??= batch.tUsStart;
    _wallEpochUs ??= DateTime.now().microsecondsSinceEpoch;

    final values = env.processBatch(batch);
    for (var i = 0; i < values.length; i++) {
      final wallTUs = _wallEpochUs! + (batch.tUsAt(i) - _bleEpochUs!);
      _envelopeBuffer.add(_TimedEnvelope(wallTUs, values[i]));
    }
    final cutoff =
        DateTime.now().microsecondsSinceEpoch - _envelopeBufferRetentionUs;
    while (_envelopeBuffer.isNotEmpty && _envelopeBuffer.first.tUs < cutoff) {
      _envelopeBuffer.removeFirst();
    }
  }

  void _onLandmarks(List<PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return;
    final s = state;
    if (s is! BicepCurlCalibrating && s is! BicepCurlActive) return;
    final tUs = DateTime.now().microsecondsSinceEpoch;
    _repDetector?.addPoseFrame(tUs, landmarks);
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

  void _onRepStart(int tStartUs) {
    _currentRepFrames.clear();
  }

  void _onRepSuppressed(RepSuppressedEvent e) {
    developer.log(
      'rep suppressed reason=${e.reason.name} '
      'amplitude=${e.amplitudeDeg.toStringAsFixed(1)}° '
      'duration=${(e.durationUs / 1000).round()}ms',
      name: 'RepDetector',
    );
    if (e.reason == RepInvalidReason.tooFast) {
      final repNum = switch (state) {
        BicepCurlActive(:final reps) => reps.length + 1,
        BicepCurlCalibrating(:final repsCompleted) => repsCompleted + 1,
        _ => 0,
      };
      _dispatcher?.dispatch(
        CueDecision(content: CueContent.repTooFast, repNum: repNum),
      );
    }
    _currentRepFrames.clear();
  }

  void _onRepBoundary(RepBoundary b) {
    final summary = _summarizeWindow(b.tStartUs, b.tEndUs);
    final s = state;
    if (s is BicepCurlCalibrating) {
      _handleCalibrationRep(s, b, summary.peak, summary.samples);
    } else if (s is BicepCurlActive) {
      _handleActiveRep(s, b, summary.peak, summary.samples);
    }
    // CV rep boundary means the authoritative counter just ticked.
    // Bump and re-reconcile against the firmware's last reported count.
    _cvRepCount += 1;
    _updateReconciliation();
    _currentRepFrames.clear();
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
      // Hardware-led mode: firmware self-advances Calibrating → Active after
      // its own 5 s internal timer. We no longer write SET_SESSION_STATE(2).
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

    // Walk the rep's pose frames once to compute signed peak deltas
    // (shoulder rise, forward lean) against the stable-resting-frame
    // reference. Averaging across the rep — the old behavior — washed out
    // the concentric peak where compensation actually occurs.
    final perRep = _currentRepFrames.isEmpty
        ? null
        : CompensationDetector.computePerRepDeltas(
            _currentRepFrames,
            b.side,
            s.ref,
          );
    final peakPoseDelta = perRep?.asPeakPoseDelta();
    // Signed-peak thresholds: fire only when a signal went POSITIVE past
    // its profile threshold (shoulder hiked up / leaned forward). Both
    // cues can fire independently on the same rep — compensation isn't
    // one thing, it's two different failure modes the user can make
    // simultaneously.
    final shoulderHike = perRep != null &&
        perRep.peakShoulderRiseDeg > _profile.compensation.shoulderDriftDeg;
    final torsoSwing = perRep != null &&
        perRep.peakForwardLeanDeg > _profile.compensation.torsoPitchDeltaDeg;
    final compensating = shoulderHike || torsoSwing;

    final record = RepRecord(
      repNum: repNum,
      tStartUs: b.tStartUs,
      tPeakUs: b.tPeakUs,
      tEndUs: b.tEndUs,
      peakEnv: peakEnv,
      poseDelta: peakPoseDelta,
      envelopeSamples: envelopeSamples,
    );
    final reps = [...s.reps, record];
    final peaks = [for (final r in reps) r.peakEnv];

    final emgOnline = !_bleDroppedDuringSet;
    // Fatigue cues from the EMG envelope (only when BLE is live). The
    // algorithm returns null while compensation is active on this rep so
    // the form cues below aren't crowded out.
    final fatigueDecision = emgOnline
        ? FatigueAlgorithm.evaluate(
            peaks: peaks,
            currentRepNum: repNum,
            lastCueRep: _lastCueRep,
            profile: _profile,
            compensationActive: compensating,
          )
        : null;

    final dropFraction = _latestDropFraction(peaks);

    if (fatigueDecision != null) {
      _dispatcher?.dispatch(fatigueDecision);
      // Only fatigue cues bump cooldown; form cues fire independently of
      // the cooldown clock. fatigueStop is included so the stop event is
      // logged exactly once per threshold crossing.
      if (fatigueDecision.content == CueContent.fatigueFade ||
          fatigueDecision.content == CueContent.fatigueUrgent ||
          fatigueDecision.content == CueContent.fatigueStop) {
        _lastCueRep = repNum;
      }
    }

    // Form cues dispatched independently from the pose path. Both can
    // fire on the same rep — the user may hike their shoulder AND lean
    // forward simultaneously. No cooldown; the detector already only
    // evaluates the rep's signed peak, not the whole window, so repeated
    // firings across reps are intentional.
    if (shoulderHike) {
      _dispatcher?.dispatch(
        CueDecision(content: CueContent.shoulderHike, repNum: repNum),
      );
    }
    if (torsoSwing) {
      _dispatcher?.dispatch(
        CueDecision(content: CueContent.torsoSwing, repNum: repNum),
      );
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
    final samples = List<double>.filled(_envelopeBucketsPerRep, 0.0);
    var peak = 0.0;
    if (tEndUs <= tStartUs) return (peak: peak, samples: samples);
    final binSize = (tEndUs - tStartUs) / _envelopeBucketsPerRep;
    for (final s in _envelopeBuffer) {
      if (s.tUs < tStartUs) continue;
      if (s.tUs >= tEndUs) break;
      if (s.value > peak) peak = s.value;
      final bin = ((s.tUs - tStartUs) / binSize).floor().clamp(
        0,
        _envelopeBucketsPerRep - 1,
      );
      if (s.value > samples[bin]) samples[bin] = s.value;
    }
    return (peak: peak, samples: samples);
  }

  double _latestDropFraction(List<double> peaks) {
    if (peaks.length < 2) return 0.0;
    final windowStart = peaks.length - _profile.baselineWindow < 0
        ? 0
        : peaks.length - _profile.baselineWindow;
    var baseline = peaks[windowStart];
    for (var i = windowStart + 1; i < peaks.length; i++) {
      if (peaks[i] > baseline) baseline = peaks[i];
    }
    if (baseline <= 0) return 0.0;
    return (1.0 - peaks.last / baseline).clamp(0.0, 1.0);
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
    // Use cached _smoother — ref.read is forbidden in onDispose callbacks.
    _smoother?.reset();
    await _sampleSub?.cancel();
    _sampleSub = null;
    await _repSub?.cancel();
    _repSub = null;
    await _hardwareCueSub?.cancel();
    _hardwareCueSub = null;
    await _repStartSub?.cancel();
    _repStartSub = null;
    await _repSuppressedSub?.cancel();
    _repSuppressedSub = null;
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
    if (!keepVisualBus) {
      visualBus.value = null;
      repReconciliation.value =
          const RepCountReconciliation.agreed(cv: 0, hw: 0);
    }
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

/// Authoritative CV rep count surfaced to UI widgets (RepCounter). Derived
/// from the controller's state so calibration reps and active reps both
/// contribute. Hardware rep count is intentionally NOT read here — it lives
/// on [repReconciliationProvider] for the disagreement indicator.
final cvRepCountProvider = Provider<int>((ref) {
  final s = ref.watch(bicepCurlControllerProvider);
  if (s is BicepCurlCalibrating) return s.repsCompleted;
  if (s is BicepCurlActive) return s.reps.length;
  if (s is BicepCurlComplete) return s.log.reps.length;
  return 0;
});

/// Live snapshot of rep-count reconciliation state (CV vs firmware). Flips
/// to `disagreeing=true` when the two counters drift past the controller's
/// threshold. Consumed by the RepCounter's subtle amber-dot indicator.
final repReconciliationProvider =
    Provider<ValueListenable<RepCountReconciliation>>(
  (ref) => ref.watch(bicepCurlControllerProvider.notifier).repReconciliation,
);
