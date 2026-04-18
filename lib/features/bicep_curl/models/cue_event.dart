import 'cue_decision.dart';

/// Historical record of a [CueDecision] that the dispatcher saw. Always
/// appended to the session log regardless of which channels actually fired
/// — that's the property that lets the post-set debrief tell the full
/// story even for a beginner profile where every live channel was muted.
class CueEvent {
  const CueEvent({
    required this.repNum,
    required this.content,
    required this.firedAt,
    required this.channelsFired,
  });

  final int repNum;
  final CueContent content;
  final DateTime firedAt;

  /// Subset of {'haptic', 'visual', 'verbal'} that actually fired in real
  /// time. Empty set means decision was logged but suppressed (e.g.,
  /// beginner profile, or BLE drop suppressing haptic).
  final Set<String> channelsFired;
}
