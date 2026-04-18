import '../../../core/services/hardware_controller.dart';

/// A semantic decision emitted by the fatigue algorithm or compensation
/// detector. The dispatcher converts a [CueDecision] into zero or more
/// concrete [Cue]s based on the active profile + channel matrix.
class CueDecision {
  CueDecision({
    required this.content,
    required this.repNum,
    this.meta = const {},
    DateTime? decidedAt,
  }) : decidedAt = decidedAt ?? DateTime.now();

  final CueContent content;
  final int repNum;
  final Map<String, dynamic> meta;
  final DateTime decidedAt;
}

enum CueContent {
  /// 15% drop from rolling baseline — soft "tighten up" cue.
  fatigueFade,

  /// 25% drop — stronger "last rep honest" cue.
  fatigueUrgent,

  /// 50% drop — past useful intervention; algorithm logs it but cues fall
  /// silent. Used by the controller to consider auto-end.
  fatigueStop,

  /// Pose drift past CompensationThresholds. v0 suppresses haptic on this;
  /// visual badge only. v1+ may fire a distinct FORM staccato burst.
  compensationDetected,

  /// Reserved for v1 — multi-channel synergist warnings (parked behind
  /// 2nd EMG channel landing per project-status §"Phase 3").
  stabilizerWarning,
}

/// A wire-level cue. Sealed so the dispatcher can fan one [CueDecision] out
/// to multiple modalities (vibration today; pressure ramps in v2 with TSA
/// hardware) without the algorithm or dispatcher needing to know the
/// payload encoding.
sealed class Cue {
  const Cue();

  Future<void> writeTo(HardwareController hardware);

  // Pre-defined v0 vibration cues from haptic-cueing-handshake.md §"BLE protocol".
  static const Cue fadeBurst = VibrationPulseBurst(
    motorIdx: 0,
    duty: 0xB4,
    pulseCount: 2,
    onMs: 200,
    offMs: 150,
  );

  static const Cue urgentBurst = VibrationPulseBurst(
    motorIdx: 0,
    duty: 0xE6,
    pulseCount: 2,
    onMs: 200,
    offMs: 150,
  );

  static const Cue formStaccato = VibrationPulseBurst(
    motorIdx: 0,
    duty: 0xE6,
    pulseCount: 3,
    onMs: 100,
    offMs: 80,
  );
}

/// FF04 opcode 0x10 — fire `pulseCount` pulses of `onMs` at PWM `duty`,
/// separated by `offMs` gaps, on motor `motorIdx`. Overrides any currently-
/// running burst on the same motor.
class VibrationPulseBurst extends Cue {
  const VibrationPulseBurst({
    required this.motorIdx,
    required this.duty,
    required this.pulseCount,
    required this.onMs,
    required this.offMs,
  });

  final int motorIdx;
  final int duty;
  final int pulseCount;
  final int onMs;
  final int offMs;

  List<int> encode() => [
        0x10,
        motorIdx,
        duty,
        pulseCount,
        onMs & 0xFF,
        (onMs >> 8) & 0xFF,
        offMs & 0xFF,
        (offMs >> 8) & 0xFF,
      ];

  @override
  Future<void> writeTo(HardwareController hardware) =>
      hardware.sendCommand(encode());
}
