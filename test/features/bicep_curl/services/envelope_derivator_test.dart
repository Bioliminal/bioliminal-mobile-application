import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/services/sample_batch.dart';
import 'package:bioliminal/features/bicep_curl/services/envelope_derivator.dart';

void main() {
  group('EnvelopeDerivator', () {
    // The handshake's IIR coefficients have a DC gain of ~2.407
    // (sum(b)/sum(a)). Absolute envelope values are scaled accordingly;
    // the fatigue algorithm uses *relative* drops (peak/baseline), so the
    // gain cancels out and cue decisions are unaffected. These tests
    // validate filter shape, not absolute magnitude.
    const dcGain = 2.4075;

    test('reaches a steady envelope value for a sustained DC offset', () {
      final d = EnvelopeDerivator();
      double last = 0;
      for (var i = 0; i < 4000; i++) {
        last = d.processSample(2148);
      }
      expect(last, closeTo(100.0 * dcGain, 1.0));
    });

    test('200 Hz sine is well attenuated', () {
      // Cutoff is ~50 Hz (see EnvelopeDerivator class docstring). 200 Hz
      // is 2 octaves above and should be heavily damped.
      final d = EnvelopeDerivator();
      double maxOut = 0;
      double minOut = double.infinity;
      double sumOut = 0;
      var n = 0;
      for (var i = 0; i < 4000; i++) {
        final phase = 2 * math.pi * 200.0 * i / 2000.0;
        final sample = 2048 + (100 * math.sin(phase)).round();
        final out = d.processSample(sample);
        if (i > 2000) {
          if (out > maxOut) maxOut = out;
          if (out < minOut) minOut = out;
          sumOut += out;
          n++;
        }
      }
      final mean = sumOut / n;
      final ripple = (maxOut - minOut) / mean;
      expect(ripple, lessThan(0.05),
          reason: 'unexpectedly large 200 Hz ripple: $ripple');
    });

    test('reset clears IIR state', () {
      final d = EnvelopeDerivator();
      for (var i = 0; i < 1000; i++) {
        d.processSample(3000);
      }
      d.reset();
      // After reset, processing a midpoint sample (0 rectified) should
      // produce ~0.
      final out = d.processSample(2048);
      expect(out.abs(), lessThan(0.01));
    });

    test('processBatch returns one envelope value per raw sample', () {
      final batch = SampleBatch(
        seqNum: 0,
        tUsStart: 0,
        channelCount: 3,
        samplesPerChannel: 50,
        flags: 0,
        raw: Uint16List.fromList(List<int>.filled(50, 2048)),
        rect: Uint16List(50),
        env: Uint16List(50),
      );
      final out = EnvelopeDerivator().processBatch(batch);
      expect(out.length, 50);
    });
  });
}
