import 'dart:async';
import 'dart:developer' as developer;

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

    final hapticCue = _hapticCueByContent[decision.content];
    if (profile.haptic.enabled && hapticCue != null) {
      try {
        await hapticCue.writeTo(hardware);
        fired.add('haptic');
      } catch (e) {
        developer.log('haptic dispatch failed', error: e, name: 'CueDispatcher');
      }
    }

    final event = CueEvent(
      repNum: decision.repNum,
      content: decision.content,
      firedAt: decision.decidedAt,
      channelsFired: fired,
    );

    if (profile.visual.enabled) {
      visualBus.value = event;
      fired.add('visual');
    }

    if (profile.verbal.enabled) {
      final phrase = _verbalPhrase(decision.content);
      if (phrase != null) {
        await _speak(phrase);
        fired.add('verbal');
      }
    }

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
    case CueContent.stabilizerWarning:
      return null; // v1+
  }
}

Future<void> _defaultSpeak(String _) async {
  // Stub. flutter_tts wired in commit 5 alongside the live view.
}
