import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] used as the verbal channel by
/// [CueDispatcher]. Lazy-initializes on first speak; safe to call
/// repeatedly. Failures are logged, never thrown — verbal cues are an
/// enhancement, not a correctness signal.
class TtsSpeaker {
  TtsSpeaker();

  FlutterTts? _tts;
  bool _initFailed = false;

  Future<void> _ensureInit() async {
    if (_tts != null || _initFailed) return;
    try {
      final tts = FlutterTts();
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.5);
      await tts.setVolume(0.9);
      await tts.setPitch(1.0);
      _tts = tts;
    } catch (e) {
      _initFailed = true;
      developer.log('flutter_tts init failed', error: e, name: 'TtsSpeaker');
    }
  }

  Future<void> speak(String phrase) async {
    await _ensureInit();
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.stop(); // cut off any in-progress utterance
      await tts.speak(phrase);
    } catch (e) {
      developer.log('flutter_tts speak failed', error: e, name: 'TtsSpeaker');
    }
  }

  Future<void> dispose() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _tts = null;
  }
}
