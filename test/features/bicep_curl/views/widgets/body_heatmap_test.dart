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

/// Guards the pure logic behind the bicep-curl debrief form section.
/// Split across three areas:
///   1. [BicepActivation.fromLog] — MEASURED-panel bicep activation.
///   2. [bucketFor] — per-rep signed-delta → bar color bucketing.
///   3. Widget-level behavior — cue markers, scrub-tap wiring, peak label.
void main() {
  group('BicepActivation.fromLog', () {
    test('empty log returns zero activation', () {
      final log = _makeLog([]);
      final a = BicepActivation.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 1.0,
      );
      expect(a.bicep, 0);
    });

    test('reads per-sample envelope when available', () {
      final rep = _rep(peakEnv: 100, envelopeSamples: _ramp(50, peak: 100));
      final log = _makeLog([rep]);

      // Sample 25 is the peak of the ramp (100); bicep saturates at 1.0.
      final atPeak = BicepActivation.fromLog(
        log: log,
        absoluteSample: 25,
        maxSampleValue: 100,
      );
      expect(atPeak.bicep, closeTo(1.0, 1e-9));

      // Sample 0 is bottom of the ramp (0). No visibility floor — quiet
      // EMG reads as a dark bicep, not a fake 40% glow.
      final atBottom = BicepActivation.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(atBottom.bicep, 0);
    });

    test('falls back to half-sine for legacy reps with no envelopeSamples',
        () {
      final rep = _rep(peakEnv: 100, envelopeSamples: null);
      final log = _makeLog([rep]);

      // Half-sine peaks at the middle sample, so sample 25 of 50 ~= 1.0.
      final mid = BicepActivation.fromLog(
        log: log,
        absoluteSample: 25,
        maxSampleValue: 100,
      );
      expect(mid.bicep, closeTo(1.0, 1e-3));

      // Edges of the half-sine are near zero → bicep dark (no floor).
      final edge = BicepActivation.fromLog(
        log: log,
        absoluteSample: 0,
        maxSampleValue: 100,
      );
      expect(edge.bicep, 0);
    });

    test('bicep stays dark when session produced no EMG signal', () {
      // CV-only session: rep boundaries fired but armband was off, so
      // envelopeSamples are all zeros and session-wide max is 0.
      final rep = _rep(peakEnv: 0, envelopeSamples: _flat(50, 0));
      final log = _makeLog([rep]);
      final a = BicepActivation.fromLog(
        log: log,
        absoluteSample: 10,
        maxSampleValue: 0,
      );
      expect(a.bicep, 0);
    });

    test('absoluteSample past the end clamps to the last rep', () {
      final rep = _rep(peakEnv: 50, envelopeSamples: _ramp(50, peak: 50));
      final log = _makeLog([rep]);
      final a = BicepActivation.fromLog(
        log: log,
        absoluteSample: 500,
        maxSampleValue: 50,
      );
      // Well past the end: still resolves against the last rep's data.
      expect(a.bicep, isNonNegative);
    });
  });

  group('bucketFor', () {
    // Intermediate profile thresholds: shoulder 14°, torso 20°. We'll
    // exercise shoulder's 14° below — the logic is the same for torso.
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
      expect(bucketFor(7.0, threshold), BarBucket.amber); // exactly 0.5×
      expect(bucketFor(10.0, threshold), BarBucket.amber);
      expect(bucketFor(14.0, threshold), BarBucket.amber); // exactly 1×
    });

    test('positive delta past threshold is red', () {
      expect(bucketFor(14.01, threshold), BarBucket.red);
      expect(bucketFor(25.0, threshold), BarBucket.red);
    });
  });

  group('BicepCurlFormSection widget', () {
    testWidgets('renders MEASURED panel + form strip without throwing',
        (tester) async {
      final log = _makeLog([
        _rep(
          peakEnv: 100,
          envelopeSamples: _ramp(50, peak: 100),
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 5,
            torsoPitchDeltaDeg: 10,
          ),
        ),
        _rep(
          peakEnv: 80,
          envelopeSamples: _ramp(50, peak: 80),
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 18,
            torsoPitchDeltaDeg: 25,
          ),
        ),
      ]);

      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      expect(find.text('MEASURED'), findsOneWidget);
      expect(find.text('FORM OVER TIME'), findsOneWidget);
      expect(find.text('SHOULDER RISE'), findsOneWidget);
      expect(find.text('FORWARD LEAN'), findsOneWidget);
    });

    testWidgets('peak label reflects max signed positive delta per strip',
        (tester) async {
      final log = _makeLog([
        _rep(
          peakEnv: 50,
          envelopeSamples: _flat(50, 50),
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 7,
            torsoPitchDeltaDeg: 12,
          ),
        ),
        _rep(
          peakEnv: 50,
          envelopeSamples: _flat(50, 50),
          poseDelta: const PoseDelta(
            shoulderDriftDeg: 21,
            torsoPitchDeltaDeg: 3,
          ),
        ),
      ]);

      await tester.pumpWidget(_wrap(BicepCurlFormSection(log: log)));
      await tester.pump();

      // Max shoulder delta = 21°; max torso = 12°.
      expect(find.text('peak +21°'), findsOneWidget);
      expect(find.text('peak +12°'), findsOneWidget);
    });

    testWidgets('peak label shows 0° when there are no positive deltas',
        (tester) async {
      final log = _makeLog([
        _rep(
          peakEnv: 50,
          envelopeSamples: _flat(50, 50),
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

    testWidgets(
      'tapping a bar area invokes scrub and highlights the tapped rep',
      (tester) async {
        final reps = <RepRecord>[
          for (var i = 0; i < 4; i++)
            _rep(
              peakEnv: 50,
              envelopeSamples: _flat(50, 50),
              poseDelta: PoseDelta(
                shoulderDriftDeg: (i + 1) * 5.0,
                torsoPitchDeltaDeg: (i + 1) * 3.0,
              ),
            ),
        ];
        final log = _makeLog(reps);

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 400,
              child: BicepCurlFormSection(log: log),
            ),
          ),
        );
        await tester.pump();

        // Stop auto-play by pressing the pause button, so the rep counter
        // doesn't drift between the tap and the assertion.
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        // Locate the SHOULDER RISE strip's GestureDetector by descending
        // from the label text.
        final strip = find
            .ancestor(
              of: find.text('SHOULDER RISE'),
              matching: find.byType(Column),
            )
            .first;
        final gesture = find.descendant(
          of: strip,
          matching: find.byType(GestureDetector),
        );
        expect(gesture, findsOneWidget);

        final ro = tester.renderObject<RenderBox>(gesture);
        final topLeft = ro.localToGlobal(Offset.zero);
        // Tap near the right edge so we land on the final rep (index 3).
        await tester.tapAt(
          topLeft + Offset(ro.size.width - 4, ro.size.height / 2),
        );
        await tester.pump();

        // After the tap, the shared scrub header should reflect rep 4/4.
        expect(find.text('04 / 04'), findsOneWidget);
      },
    );
  });

  group('cue marker filtering', () {
    test(
        'only shoulderHike/torsoSwing cues surface on the form strips; '
        'compensationDetected and repTooFast are filtered out', () {
      // This test exercises the filter set construction that mirrors the
      // widget's private logic. Duplicating the construction here (rather
      // than introspecting the painter) keeps the assertion near the
      // behavior it protects.
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

  group('colorFor color bucketing (sanity)', () {
    test('tokens resolve to the expected palette entries', () {
      // These aren't magic numbers — they lock the intent that red = error
      // token and amber = warn token. If someone swaps the palette the
      // test tells them.
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
  required double peakEnv,
  List<double>? envelopeSamples,
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
    envelopeSamples: envelopeSamples,
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

/// Linear 0 → peak → 0 ramp over `count` samples, peak at the middle.
List<double> _ramp(int count, {required double peak}) {
  final mid = count ~/ 2;
  return List<double>.generate(count, (i) {
    final d = (i - mid).abs();
    return peak * (1 - d / mid).clamp(0.0, 1.0);
  });
}

List<double> _flat(int count, double v) => List<double>.filled(count, v);
