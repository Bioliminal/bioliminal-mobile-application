import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/features/bicep_curl/views/bicep_curl_overlays.dart';

/// Guards the FatigueBar's display-logic branches:
/// - emgOnline gating of text + progress
/// - threshold-tier color mapping (<10%, <25%, >=25%)
///
/// All assertions read the rendered widget tree — no mocks.
Future<void> _pump(
  WidgetTester tester, {
  required double dropFraction,
  required bool emgOnline,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FatigueBar(
          dropFraction: dropFraction,
          emgOnline: emgOnline,
        ),
      ),
    ),
  );
}

LinearProgressIndicator _progressIndicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
}

Color _progressColor(LinearProgressIndicator p) {
  return p.valueColor!.value!;
}

void main() {
  group('FatigueBar', () {
    testWidgets('emgOnline=false shows OFFLINE label and — instead of %',
        (tester) async {
      await _pump(tester, dropFraction: 0.42, emgOnline: false);

      expect(find.text('EMG OFFLINE'), findsOneWidget);
      expect(find.text('FATIGUE'), findsNothing);
      expect(find.text('—'), findsOneWidget);

      // Progress forced to 0 and color is the inactive/muted grey, so the
      // bar can't misrepresent fatigue when the signal's gone.
      final progress = _progressIndicator(tester);
      expect(progress.value, 0);
      expect(_progressColor(progress), Colors.white24);
    });

    testWidgets('emgOnline=true renders label + % from drop fraction',
        (tester) async {
      await _pump(tester, dropFraction: 0.42, emgOnline: true);

      expect(find.text('FATIGUE'), findsOneWidget);
      expect(find.text('EMG OFFLINE'), findsNothing);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('progress color: <10% = High, <25% = Medium, >=25% = Low',
        (tester) async {
      await _pump(tester, dropFraction: 0.05, emgOnline: true);
      expect(_progressColor(_progressIndicator(tester)),
          BioliminalTheme.confidenceHigh);

      await _pump(tester, dropFraction: 0.15, emgOnline: true);
      expect(_progressColor(_progressIndicator(tester)),
          BioliminalTheme.confidenceMedium);

      await _pump(tester, dropFraction: 0.40, emgOnline: true);
      expect(_progressColor(_progressIndicator(tester)),
          BioliminalTheme.confidenceLow);
    });

    testWidgets('% formatting clamps at 100 for absurd drop fractions',
        (tester) async {
      await _pump(tester, dropFraction: 3.0, emgOnline: true);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
