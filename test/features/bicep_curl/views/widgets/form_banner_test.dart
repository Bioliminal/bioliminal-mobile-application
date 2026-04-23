import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_event.dart';
import 'package:bioliminal/features/bicep_curl/views/bicep_curl_overlays.dart';

/// Guards the FormBanner filter contract — the banner must render only for
/// shoulderHike / torsoSwing cues, and must render the per-cue copy for
/// each so verbal-channel-disabled users still see WHY the form cue fired.
///
/// The slide+fade animation itself is shared with RepTooFastBanner; what's
/// worth locking in here is (a) the content filter and (b) the text
/// mapping, since a well-meaning copy tweak or enum reshuffle could
/// silently land on the wrong string.
void main() {
  group('FormBanner', () {
    testWidgets('renders the shoulder-hike copy on shoulderHike cues',
        (tester) async {
      final bus = ValueNotifier<CueEvent?>(null);
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormBanner(bus: bus)),
        ),
      );

      bus.value = CueEvent(
        repNum: 7,
        content: CueContent.shoulderHike,
        firedAt: DateTime(2026, 4, 23),
        channelsFired: const {'visual'},
      );
      // Pump through the slide-in portion of the animation so the banner
      // text lands in the tree; use pump (not pumpAndSettle) because the
      // banner runs a 2.2 s animation we don't need to wait out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Shoulders up — keep them relaxed'), findsOneWidget);
    });

    testWidgets('renders the torso-swing copy on torsoSwing cues',
        (tester) async {
      final bus = ValueNotifier<CueEvent?>(null);
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormBanner(bus: bus)),
        ),
      );

      bus.value = CueEvent(
        repNum: 9,
        content: CueContent.torsoSwing,
        firedAt: DateTime(2026, 4, 23),
        channelsFired: const {'visual'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Body swinging — keep your torso still'),
        findsOneWidget,
      );
    });

    testWidgets('ignores cues that are not shoulderHike / torsoSwing',
        (tester) async {
      final bus = ValueNotifier<CueEvent?>(null);
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormBanner(bus: bus)),
        ),
      );

      // Fatigue cues should be handled by the flash indicator / fatigue
      // bar, not the form banner. The banner must stay invisible.
      bus.value = CueEvent(
        repNum: 11,
        content: CueContent.fatigueFade,
        firedAt: DateTime(2026, 4, 23),
        channelsFired: const {'visual'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Shoulders up — keep them relaxed'), findsNothing);
      expect(
        find.text('Body swinging — keep your torso still'),
        findsNothing,
      );
    });

    testWidgets('ignores the deprecated compensationDetected cue '
        '(legacy cue replays render through the timeline, not the banner)',
        (tester) async {
      final bus = ValueNotifier<CueEvent?>(null);
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormBanner(bus: bus)),
        ),
      );

      bus.value = CueEvent(
        repNum: 3,
        content: CueContent.compensationDetected,
        firedAt: DateTime(2026, 4, 23),
        channelsFired: const {'visual'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Shoulders up — keep them relaxed'), findsNothing);
      expect(
        find.text('Body swinging — keep your torso still'),
        findsNothing,
      );
    });
  });
}
