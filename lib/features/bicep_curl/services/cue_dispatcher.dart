import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/hardware_controller.dart';
import '../models/cue_decision.dart';
import '../models/cue_event.dart';
import '../models/cue_profile.dart';

/// Maps semantic [CueContent] values to wire-level [Cue] payloads. Today
/// this is vibration-only; v2 (TSA pressure hardware) adds pressure cues
/// without touching the algorithm or dispatcher contract.
const Map<CueContent, Cue> _hapticCueByContent = {
  CueContent.fatigueFade: Cue.fadeBurst,
  CueContent.fatigueUrgent: Cue.urgentBurst,
  // fatigueStop: silent on haptic by design — algorithm logs it; UI handles.
  // compensationDetected: v0 silent on haptic; visual badge only (per
  //   haptic-cueing-handshake.md §"Compensation-cue semantics for v0").
  // stabilizerWarning: parked until 2nd EMG channel lands.
};

/// Fans every algorithm decision across the active channels per the user's
/// [CueProfile]. **Always appends a [CueEvent] to the session log
/// regardless of which channels fire** — that property lets the post-set
/// debrief tell the full story even when no live channel was active
/// (beginner profile) or when haptic dropped mid-set (BLE failure).
class CueDispatcher {
  CueDispatcher({
    required this.profile,
    required this.hardware,
    required this.onLog,
    required this.visualBus,
    Future<void> Function(String)? speak,
  }) : _speak = speak ?? _defaultSpeak;

  CueProfile profile;
  final HardwareController hardware;
  final void Function(CueEvent) onLog;
  final ValueNotifier<CueEvent?> visualBus;
  final Future<void> Function(String) _speak;

  Future<void> dispatch(CueDecision decision) async {
    final fired = <String>{};

    // Hardware-led mode: the ESP32 fires haptic cues autonomously based on
    // its own fatigue tracking, so the app no longer writes PULSE_BURST to
    // FF04. We still log the dispatcher's decision (for session debrief
    // parity) and record "haptic" as a fired channel when the profile has
    // haptic enabled, since the hardware event will arrive via the
    // cue_event bit in the FF02 packet. The visual flash is driven by the
    // hardware cue event (see bicep_curl_controller cueEventStream), not
    // by this dispatcher.
    if (profile.haptic.enabled &&
        _hapticCueByContent.containsKey(decision.content)) {
      fired.add('haptic');
    }

    if (profile.visual.enabled) fired.add('visual');

    if (profile.verbal.enabled) {
      final phrase = _verbalPhrase(decision.content);
      if (phrase != null) {
        await _speak(phrase);
        fired.add('verbal');
      }
    }

    final event = CueEvent(
      repNum: decision.repNum,
      content: decision.content,
      firedAt: decision.decidedAt,
      channelsFired: Set.unmodifiable(fired),
    );
    if (profile.visual.enabled) visualBus.value = event;
    onLog(event);
  }
}

String? _verbalPhrase(CueContent content) {
  switch (content) {
    case CueContent.fatigueFade:
      return 'Tighten up';
    case CueContent.fatigueUrgent:
      return 'Last rep honest';
    case CueContent.fatigueStop:
      return null; // Visual-only; verbal would feel patronizing.
    case CueContent.compensationDetected:
      return 'Watch your form';
    case CueContent.repTooFast:
      return 'Slow down';
    case CueContent.stabilizerWarning:
      return null; // v1+
  }
}

Future<void> _defaultSpeak(String _) async {
  // Stub. flutter_tts wires in commit 5 alongside the live view.
}
