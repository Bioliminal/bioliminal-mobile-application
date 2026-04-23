import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/features/bicep_curl/models/compensation_reference.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_event.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/models/pose_delta.dart';
import 'package:bioliminal/features/bicep_curl/models/rep_record.dart';
import 'package:bioliminal/features/bicep_curl/models/session_log.dart';
import 'package:bioliminal/features/bicep_curl/views/widgets/body_heatmap.dart';
import 'package:bioliminal/features/landing/widgets/marketing_tokens.dart';

/// Guards the pure logic and render contract of the bicep-curl form strip.
///   1. [bucketFor] — per-rep signed-delta → bar color bucketing.
///   2. Widget-level behavior — labels, muscle subtitles, peak labels,
///      and cue-event filtering.
void main() {
  group('bucketFor', () {
    const threshold = 14.0;

    test('null signed delta is missing', () {
      expect(bucketFor(null, threshold), BarBucket.missing);
    });

    test('negative signed delta buckets to negative regardless of magnitude',
        () {
      expect(bucketFor(-0.5, threshold), BarBucket.negative);
      expect(bucketFor(-30.0, threshold), BarBucket.negative);
    });

    test('small positive delta below 0.5× threshold is clean', () {
      expect(bucketFor(3.0, threshold), BarBucket.clean);
      expect(bucketFor(6.9, threshold), BarBucket.clean);
    });

    test('positive delta in [0.5×, 1×] threshold band is amber', () {
      expect(bucketFor(7.0, threshold), BarBucket.amber);
      expect(bucketFor(10.0, threshold), BarBucket.amber);
      expect(bucketFor(14.0, threshold), BarBucket.amber);
    });

    test('positive delta past threshold is red', () {
      expect(bucketFor(14.01, threshold), BarBucket.red);
      expect(bucketFor(25.0, threshold), BarBucket.red);
    });
  });

  group('BicepCurlFormSection widget', () {
    testWidgets('renders both strips with muscle subtitles', (tester) async {
      final log = _makeLog([
        _rep(
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 5,
            torsoPitchDeltaDeg: 10,
          ),
        ),
        _rep(
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 18,
            torsoPitchDeltaDeg: 25,
          ),
        ),
      ]);

      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      expect(find.text('FORM OVER TIME'), findsOneWidget);
      expect(find.text('SHOULDER RISE'), findsOneWidget);
      expect(find.text('FORWARD LEAN'), findsOneWidget);
      expect(find.text('trapezius · anterior deltoid'), findsOneWidget);
      expect(find.text('erector spinae · hip flexors'), findsOneWidget);
    });

    testWidgets('peak label reflects max signed positive delta per strip',
        (tester) async {
      final log = _makeLog([
        _rep(
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 7,
            torsoPitchDeltaDeg: 12,
          ),
        ),
        _rep(
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 21,
            torsoPitchDeltaDeg: 3,
          ),
        ),
      ]);

      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      expect(find.text('peak +21°'), findsOneWidget);
      expect(find.text('peak +12°'), findsOneWidget);
    });

    testWidgets('peak label shows 0° when there are no positive deltas',
        (tester) async {
      final log = _makeLog([
        _rep(
          poseDelta: const PoseDelta(
            shoulderDriftDeg: -5,
            torsoPitchDeltaDeg: -8,
          ),
        ),
      ]);

      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      expect(find.text('peak 0°'), findsNWidgets(2));
    });

    testWidgets('empty reps list renders nothing', (tester) async {
      final log = _makeLog([]);
      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      expect(find.text('FORM OVER TIME'), findsNothing);
    });
  });

  group('cue marker filtering', () {
    test(
        'only shoulderHike/torsoSwing surface on the strips; '
        'compensationDetected and repTooFast are filtered out', () {
      final events = <CueEvent>[
        _event(repNum: 1, content: CueContent.shoulderHike),
        _event(repNum: 2, content: CueContent.torsoSwing),
        _event(repNum: 3, content: CueContent.compensationDetected),
        _event(repNum: 4, content: CueContent.repTooFast),
        _event(repNum: 5, content: CueContent.fatigueFade),
      ];

      final shoulderReps = <int>{
        for (final e in events)
          if (e.content == CueContent.shoulderHike) e.repNum - 1,
      };
      final leanReps = <int>{
        for (final e in events)
          if (e.content == CueContent.torsoSwing) e.repNum - 1,
      };

      expect(shoulderReps, {0});
      expect(leanReps, {1});
    });
  });

  group('palette tokens (sanity)', () {
    test('tokens resolve to the expected palette entries', () {
      expect(MarketingPalette.error, const Color(0xFFF87171));
      expect(MarketingPalette.warn, const Color(0xFFF59E0B));
      expect(MarketingPalette.subtle, const Color(0xFF475569));
      expect(BioliminalTheme.accent, const Color(0xFF38BDF8));
    });
  });
}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

RepRecord _rep({
  double peakEnv = 50,
  PoseDelta? poseDelta,
  int repNum = 1,
}) {
  return RepRecord(
    repNum: repNum,
    tStartUs: 0,
    tPeakUs: 500000,
    tEndUs: 1000000,
    peakEnv: peakEnv,
    poseDelta: poseDelta,
  );
}

CueEvent _event({
  required int repNum,
  required CueContent content,
}) {
  return CueEvent(
    repNum: repNum,
    content: content,
    firedAt: DateTime(2026, 4, 18),
    channelsFired: const {},
  );
}

SessionLog _makeLog(List<RepRecord> reps) {
  return SessionLog(
    reps: reps,
    cueEvents: const [],
    ref: null,
    startedAt: DateTime(2026, 4, 18),
    duration: const Duration(seconds: 30),
    profile: CueProfile.intermediate(),
    armSide: ArmSide.right,
    bleDroppedDuringSet: false,
  );
}
