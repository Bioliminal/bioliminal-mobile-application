import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';
import 'package:bioliminal/core/services/sample_batch.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/features/bicep_curl/controllers/bicep_curl_controller.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/services/pose_math.dart';
import 'package:bioliminal/features/bicep_curl/services/rep_decision_policy.dart';

/// Integration test for [BicepCurlController]. Overrides the BLE and
/// pose providers with controllable fakes, then drives the controller
/// through the full state machine to verify the wiring.
///
/// What this catches that the unit tests miss:
/// - Subscription plumbing (rawEmgStream → envelope buffer; landmarks →
///   rep detector; rep boundaries → state transitions).
/// - State machine transitions (Idle → Setup → Calibrating → Active →
///   Complete) with real rep events flowing.
/// - BLE-drop-mid-set degradation (emgOnline flag).
///
/// What it intentionally does NOT cover:
/// - Cue dispatch / TTS — verified separately.
/// - Algorithm correctness — pure-function tested in
///   fatigue_algorithm_test.dart against fabricated peak sequences.
/// - View rendering — out of scope.
void main() {
  group('BicepCurlController integration', () {
    test(
      'walks Idle → Setup → Calibrating → Active with real rep events',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);

        final controller = harness.controller;

        // Sanity: starts at Idle.
        expect(harness.state, isA<BicepCurlIdle>());

        await controller.startSession(side: ArmSide.right);
        expect(harness.state, isA<BicepCurlSetup>());

        // View signals framing-check passed.
        controller.markFramingComplete();
        expect(harness.state, isA<BicepCurlCalibrating>());

        // Walk five complete reps. Each rep emits both a stream of
        // synthetic SampleBatches (so the envelope buffer fills) and a
        // sequence of pose frames (so the rep detector fires a boundary).
        for (var rep = 0; rep < 5; rep++) {
          await harness.runRep(repIdx: rep);
        }

        // Five calibration reps complete → transition to Active with a
        // compensation reference built from the calibration frames.
        expect(harness.state, isA<BicepCurlActive>());
        final active = harness.state as BicepCurlActive;
        expect(active.reps.length, 5);
        expect(active.ref.armSide, ArmSide.right);

        // Each rep's envelope segment should be present and 50 samples.
        for (final r in active.reps) {
          expect(r.envelopeSamples, isNotNull);
          expect(r.envelopeSamples!.length, 50);
        }

        // One more rep — Active should accumulate a 6th rep.
        await harness.runRep(repIdx: 5);
        final after = harness.state as BicepCurlActive;
        expect(after.reps.length, 6);
      },
    );

    test(
      'endSession produces a Complete state with the accumulated log',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);

        await harness.controller.startSession(side: ArmSide.right);
        harness.controller.markFramingComplete();
        for (var rep = 0; rep < 5; rep++) {
          await harness.runRep(repIdx: rep);
        }

        await harness.controller.endSession();

        expect(harness.state, isA<BicepCurlComplete>());
        final complete = harness.state as BicepCurlComplete;
        expect(complete.log.reps.length, 5);
        expect(complete.log.armSide, ArmSide.right);
        expect(complete.log.bleDroppedDuringSet, isFalse);
      },
    );

    test(
      'repReconciliation flips to disagreeing when hw drifts ≥2 from cv',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);

        await harness.controller.startSession(side: ArmSide.right);
        harness.controller.markFramingComplete();

        final notifier = harness.controller.repReconciliation;

        // Drive a CV rep. runRep emits SampleBatches carrying repCount=0, so
        // hw stays at 0 while cv ticks to 1 — delta=1 (below threshold).
        await harness.runRep(repIdx: 0);
        expect(notifier.value.cv, 1);
        expect(notifier.value.hw, 0);
        expect(notifier.value.disagreeing, isFalse);

        // Firmware races ahead while the user is mid-rep — emit a bare
        // SampleBatch carrying repCount=5, bypassing the full runRep flow.
        harness.fakeHardware.emitBatch(
          SampleBatch(
            seqNum: 200,
            tUsStart: 5000000,
            channelCount: 3,
            samplesPerChannel: 50,
            flags: 0,
            repCount: 5,
            cueEvent: 0,
            raw: Uint16List(50),
            rect: Uint16List(50),
            env: Uint16List(50),
          ),
        );
        await _microflush();
        expect(notifier.value.hw, 5);
        expect(notifier.value.cv, 1);
        expect(notifier.value.disagreeing, isTrue,
            reason: 'cv=1 hw=5 delta=4 >= threshold');

        // CV catches up within 1 of hw — back to agreed.
        await harness.runRep(repIdx: 1);
        await harness.runRep(repIdx: 2);
        await harness.runRep(repIdx: 3);
        // runRep's SampleBatches set hw to the new repIdx on the way through;
        // its last rep is idx=3 so repCount in the sample batches = 3, leaving
        // hw=3 when the CV count reaches 4. Emit one more same-count packet so
        // hw doesn't regress.
        harness.fakeHardware.emitBatch(
          SampleBatch(
            seqNum: 201,
            tUsStart: 10000000,
            channelCount: 3,
            samplesPerChannel: 50,
            flags: 0,
            repCount: 5,
            cueEvent: 0,
            raw: Uint16List(50),
            rect: Uint16List(50),
            env: Uint16List(50),
          ),
        );
        await _microflush();
        expect(notifier.value.cv, 4);
        expect(notifier.value.hw, 5);
        expect(notifier.value.disagreeing, isFalse,
            reason: 'delta=1 is within noise band');
      },
    );

    test(
      'BLE drop mid-set flips emgOnline=false but session continues',
      () async {
        final harness = _ControllerHarness();
        addTearDown(harness.dispose);

        await harness.controller.startSession(side: ArmSide.right);
        harness.controller.markFramingComplete();
        for (var rep = 0; rep < 5; rep++) {
          await harness.runRep(repIdx: rep);
        }
        expect((harness.state as BicepCurlActive).emgOnline, isTrue);

        // Simulate BLE drop; controller's connection-state listener should
        // mark emgOnline=false.
        harness.fakeHardware.simulateDisconnect();
        await Future<void>.delayed(Duration.zero);

        // Run one more rep to trigger a state copyWith that picks up the
        // new emgOnline value.
        await harness.runRep(repIdx: 5);
        expect((harness.state as BicepCurlActive).emgOnline, isFalse);
      },
    );
  });
}

Future<void> _microflush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

// ---------------------------------------------------------------------------
// Harness — wires fakes + helpers
// ---------------------------------------------------------------------------

class _ControllerHarness {
  _ControllerHarness() {
    container = ProviderContainer(
      overrides: [
        hardwareControllerProvider.overrideWith(_FakeHardwareController.new),
        currentLandmarksProvider.overrideWith(
          (ref) => ref.watch(_testLandmarksProvider),
        ),
        // Pose frames arrive within microseconds of each other in this
        // harness — relax the duration and stalled gates so synthetic reps
        // don't trip them. ROM + jitter floor stay at production values.
        repDecisionPolicyFactoryProvider.overrideWithValue(
          () => ExtremaAmplitudeGatePolicy(
            angleFn: elbowAngleDeg,
            minRepDurationUs: 0,
            maxRepDurationUs: 1 << 60,
          ),
        ),
      ],
    );
    landmarks = container.read(_testLandmarksProvider.notifier);
    // Mimic BicepCurlView's watch on the controller. Without an active
    // listener on the controller, Riverpod cancels it and tears down its
    // outgoing subscriptions (including the one on currentLandmarksProvider
    // wired in build()), at which point landmark updates stop flowing.
    _ctrlSub = container.listen(bicepCurlControllerProvider, (_, _) {});
    controller = container.read(bicepCurlControllerProvider.notifier);
    fakeHardware =
        container.read(hardwareControllerProvider.notifier)
            as _FakeHardwareController;
  }

  late final ProviderContainer container;
  late final BicepCurlController controller;
  late final _FakeHardwareController fakeHardware;
  late final _TestLandmarksNotifier landmarks;
  late final ProviderSubscription<BicepCurlState> _ctrlSub;

  BicepCurlState get state => container.read(bicepCurlControllerProvider);

  /// Drives one rep through the controller: emits a synthetic envelope
  /// segment via the BLE stream, then walks the pose detector through a
  /// full extended → contracted → extended cycle. Returns once the rep
  /// boundary has propagated through async listeners and updated state.
  Future<void> runRep({required int repIdx}) async {
    final tStartUs = repIdx * 3000000;

    // Emit ~3 s worth of SampleBatches (40 Hz × 3 s = 120 batches).
    // Each batch has the same constant excursion — the envelope shape
    // doesn't matter for the state transitions we're testing here.
    for (var b = 0; b < 120; b++) {
      fakeHardware.emitBatch(
        SampleBatch(
          seqNum: (repIdx * 120 + b) & 0xFF,
          tUsStart: tStartUs + b * 25000, // 25 ms apart
          channelCount: 3,
          samplesPerChannel: 50,
          flags: 0,
          repCount: repIdx,
          cueEvent: 0,
          raw: Uint16List.fromList(
            List<int>.filled(50, 2548),
          ), // 500 above midpoint
          rect: Uint16List(50),
          env: Uint16List(50),
        ),
      );
    }
    await _flush();

    // Walk pose: 3 frames extended → 11 frames descending → 11 ascending.
    void push(double angle) {
      landmarks.push(_armAtAngle(angle));
    }

    for (var i = 0; i < 3; i++) {
      push(170);
      await _flush();
    }
    for (var i = 0; i < 11; i++) {
      push(170 - i * 11.0);
      await _flush();
    }
    for (var i = 0; i < 11; i++) {
      push(60 + i * 11.0);
      await _flush();
    }
    await _flush();
  }

  Future<void> _flush() async {
    // Two microtask flushes — first lets the stream listener queue
    // setState; the next lets Riverpod propagate.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  void dispose() {
    _ctrlSub.close();
    container.dispose();
  }
}

// ---------------------------------------------------------------------------
// Fake hardware controller
// ---------------------------------------------------------------------------

class _FakeHardwareController extends HardwareController {
  final _stream = StreamController<SampleBatch>.broadcast();
  final _repStream = StreamController<int>.broadcast();
  final _cueStream = StreamController<void>.broadcast();

  @override
  HardwareConnectionState build() {
    ref.onDispose(() {
      _stream.close();
      _repStream.close();
      _cueStream.close();
    });
    return HardwareConnectionState.connected;
  }

  @override
  Stream<SampleBatch> get rawEmgStream => _stream.stream;

  @override
  Stream<int> get repCountStream => _repStream.stream;

  @override
  Stream<void> get cueEventStream => _cueStream.stream;

  @override
  Future<void> sendCommand(List<int> bytes) async {}

  @override
  Future<void> setSessionState(int sessionState) async {}

  @override
  Future<void> stopHaptic([int motorIdx = 0]) async {}

  void emitBatch(SampleBatch batch) => _stream.add(batch);

  void simulateDisconnect() {
    state = HardwareConnectionState.disconnected;
  }
}

// ---------------------------------------------------------------------------
// Pose helpers
// ---------------------------------------------------------------------------

class _TestLandmarksNotifier extends Notifier<List<PoseLandmark>> {
  @override
  List<PoseLandmark> build() => const [];
  void push(List<PoseLandmark> next) => state = next;
}

final _testLandmarksProvider =
    NotifierProvider<_TestLandmarksNotifier, List<PoseLandmark>>(
      _TestLandmarksNotifier.new,
    );

List<PoseLandmark> _armAtAngle(double angleDeg) {
  // Right arm: shoulder at (0,0), elbow at (1,0), wrist swings around the
  // elbow so the interior angle at the elbow == angleDeg.
  final theta = (180 - angleDeg) * math.pi / 180.0;
  final landmarks = List.filled(
    33,
    const PoseLandmark(x: 0, y: 0, z: 0, visibility: 1, presence: 1),
  );
  landmarks[kRightShoulder] = const PoseLandmark(
    x: 0,
    y: 0,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  landmarks[kRightElbow] = const PoseLandmark(
    x: 1,
    y: 0,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  landmarks[kRightWrist] = PoseLandmark(
    x: 1.0 + math.cos(theta),
    y: math.sin(theta),
    z: 0,
    visibility: 1,
    presence: 1,
  );
  // Hips needed for torso pitch math during compensation reference build.
  landmarks[kLeftShoulder] = const PoseLandmark(
    x: -0.5,
    y: 0,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  landmarks[kLeftHip] = const PoseLandmark(
    x: -0.5,
    y: 1,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  landmarks[kRightHip] = const PoseLandmark(
    x: 0.5,
    y: 1,
    z: 0,
    visibility: 1,
    presence: 1,
  );
  return landmarks;
}
