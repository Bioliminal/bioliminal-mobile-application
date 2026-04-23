import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../landing/widgets/marketing_tokens.dart';
import '../../models/cue_decision.dart';
import '../../models/cue_event.dart';

class CueTimeline extends StatelessWidget {
  const CueTimeline({super.key, required this.events});

  final List<CueEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: MarketingPalette.subtle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'NO CUES FIRED',
            style: mktMono(
              10,
              color: MarketingPalette.subtle,
              letterSpacing: 2.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < events.length; i++) {
      if (i > 0) {
        rows.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: MarketingPalette.hairline,
        ));
      }
      rows.add(_row(events[i], index: i + 1));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _row(CueEvent e, {required int index}) {
    final color = _cueColor(e.content);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: mktMono(
                10,
                color: MarketingPalette.subtle,
                letterSpacing: 1.4,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'REP ${e.repNum.toString().padLeft(2, '0')}',
            style: mktMono(
              11,
              color: MarketingPalette.text,
              letterSpacing: 1.4,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              _label(e.content),
              style: mktMono(
                10,
                color: color,
                letterSpacing: 2.8,
                weight: FontWeight.w700,
              ),
            ),
          ),
          if (e.channelsFired.isNotEmpty)
            Text(
              e.channelsFired.join(' · ').toUpperCase(),
              style: mktMono(
                9,
                color: MarketingPalette.subtle,
                letterSpacing: 1.8,
              ),
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
      // Deprecated — only reached when replaying sessions persisted before
      // the form-cue split. Generic "FORM" keeps the old entry legible
      // without pretending we can classify it as shoulder vs torso.
      return 'FORM';
    case CueContent.shoulderHike:
      return 'SHOULDER HIKE';
    case CueContent.torsoSwing:
      return 'TORSO SWING';
    case CueContent.repTooFast:
      return 'TOO FAST';
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
      // Deprecated — grey for replayed legacy sessions so it reads as
      // historical, not live form data.
      return Colors.grey;
    case CueContent.shoulderHike:
      return Colors.purpleAccent;
    case CueContent.torsoSwing:
      return Colors.deepPurpleAccent;
    case CueContent.repTooFast:
      return Colors.amberAccent;
    case CueContent.stabilizerWarning:
      return Colors.orangeAccent;
  }
}
