import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../models/cue_decision.dart';
import '../../models/cue_event.dart';

class CueTimeline extends StatelessWidget {
  const CueTimeline({super.key, required this.events});

  final List<CueEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No cues fired this set.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in events) _row(e),
      ],
    );
  }

  Widget _row(CueEvent e) {
    final color = _cueColor(e.content);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            'REP ${e.repNum}',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _label(e.content),
            style: TextStyle(
              color: color,
              letterSpacing: 1.5,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (e.channelsFired.isNotEmpty)
            Text(
              e.channelsFired.join(' · ').toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

String _label(CueContent c) {
  switch (c) {
    case CueContent.fatigueFade:
      return 'FADE';
    case CueContent.fatigueUrgent:
      return 'URGENT';
    case CueContent.fatigueStop:
      return 'STOP';
    case CueContent.compensationDetected:
      return 'COMPENSATION';
    case CueContent.stabilizerWarning:
      return 'STABILIZER';
  }
}

Color _cueColor(CueContent content) {
  switch (content) {
    case CueContent.fatigueFade:
      return BioliminalTheme.confidenceMedium;
    case CueContent.fatigueUrgent:
      return BioliminalTheme.confidenceLow;
    case CueContent.fatigueStop:
      return Colors.redAccent;
    case CueContent.compensationDetected:
      return Colors.purpleAccent;
    case CueContent.stabilizerWarning:
      return Colors.orangeAccent;
  }
}
