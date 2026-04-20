import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_event.dart';
import 'package:bioliminal/features/bicep_curl/views/widgets/peak_chart.dart';

/// Two surfaces worth guarding on PeakChart:
/// - empty-peaks placeholder (easy to regress into a crash/blank chart)
/// - cue-dot color mapping — the first-fade-ambiguity fix (8f05920)
///   depends on FADE and URGENT being visually distinct. A well-meaning
///   palette tweak must fail this test loudly.
///
/// The fl_chart internals paint dots via a callback we can't easily
/// assert against in a widget test, so color mapping is covered by
/// calling [peakChartCueColor] directly.
void main() {
  group('PeakChart', () {
    testWidgets('renders placeholder when peaks list is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeakChart(
              peaks: <double>[],
              baseline: <double>[],
              cueEvents: <CueEvent>[],
            ),
          ),
        ),
      );
      expect(find.text('NO REPS RECORDED'), findsOneWidget);
    });

    testWidgets('renders chart scaffold (no placeholder) with peaks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeakChart(
              peaks: const [100, 120, 140, 160, 180],
              baseline: const [100, 120, 140, 160, 180],
              cueEvents: [
                CueEvent(
                  repNum: 5,
                  content: CueContent.fatigueFade,
                  firedAt: DateTime(2026, 4, 18),
                  channelsFired: const {'visual'},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('NO REPS RECORDED'), findsNothing);
    });
  });

  group('peakChartCueColor', () {
    test('FADE and URGENT map to distinct colors (first-fade ambiguity fix)',
        () {
      final fade = peakChartCueColor(CueContent.fatigueFade);
      final urgent = peakChartCueColor(CueContent.fatigueUrgent);
      expect(fade, BioliminalTheme.confidenceMedium);
      expect(urgent, BioliminalTheme.confidenceLow);
      expect(fade, isNot(equals(urgent)),
          reason: 'FADE and URGENT dots must read as different at a glance');
    });

    test('STOP is redAccent — the strongest signal in the set', () {
      expect(peakChartCueColor(CueContent.fatigueStop), Colors.redAccent);
    });

    test('compensation and stabilizer colors are non-fatigue hues', () {
      expect(peakChartCueColor(CueContent.compensationDetected),
          Colors.purpleAccent);
      expect(peakChartCueColor(CueContent.stabilizerWarning),
          Colors.orangeAccent);
    });
  });
}
