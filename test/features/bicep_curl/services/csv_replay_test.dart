import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/services/envelope_derivator.dart';
import 'package:bioliminal/features/bicep_curl/services/fatigue_algorithm.dart';

/// **Smoke gate** for the algorithm against real data.
///
/// Runs Rajiv's 27-rep-to-failure session through the software envelope +
/// fatigue algorithm. The CSV's rep boundaries are derived from BOOT
/// button presses, which carry significant timing noise (the handshake
/// itself flags this as a known issue) — so per-rep peaks swing wildly
/// and the algorithm fires *more* cues here than the handshake predicted
/// for clean data. **Production uses camera-derived rep boundaries from
/// elbow-angle inflection, which will be much tighter.**
///
/// We therefore assert the algorithm's *shape*, not the precise rep
/// numbers from the handshake's idealized expected:
/// - No cues during calibration window (reps 1..N)
/// - At least one fatigue cue fires before failure
/// - STOP fires by the end (Rajiv hit failure at rep 27)
///
/// If this test fails, the algorithm regressed in shape (e.g., calibration
/// silence broken). Tighter behavioral assertions belong in
/// fatigue_algorithm_test.dart against fabricated peak sequences.
///
/// CSV format (per `docs/hardware_integration/`):
/// - `S,t_us,raw,rect,env`  — one sample row at 2 kHz
/// - `R,t_us,rep_num`       — rep onset marker (BOOT button press)
/// - `X,t_us,final_rep`     — session end
/// - `# ...` lines are comments
void main() {
  test('Rajiv\'s 27-rep failure session shape sanity', () {
    final csvPath =
        '${Directory.current.path}/docs/hardware_integration/'
        'session_Rajiv47_20260417_211321.csv';
    final file = File(csvPath);
    expect(file.existsSync(), isTrue,
        reason: 'fixture missing at $csvPath');

    final reps = _loadAndComputePeaks(file);
    expect(reps.length, 27,
        reason: 'expected 27 rep markers in the Rajiv session');

    final profile = CueProfile.intermediate();
    final cues = <_FiredCue>[];
    var lastCueRep = -999;
    final peaks = <double>[];

    for (var i = 0; i < reps.length; i++) {
      peaks.add(reps[i]);
      final decision = FatigueAlgorithm.evaluate(
        peaks: peaks,
        currentRepNum: i + 1,
        lastCueRep: lastCueRep,
        profile: profile,
        compensationActive: false,
      );
      if (decision != null) {
        cues.add(_FiredCue(repNum: i + 1, content: decision.content));
        lastCueRep = i + 1;
      }
    }

    // Pretty-print so a regression's diagnosis is one read away.
    // ignore: avoid_print
    print('Replay cue sequence: '
        '${cues.map((c) => '${c.repNum}:${c.content.name}').join(', ')}');
    // ignore: avoid_print
    print('Per-rep peaks: '
        '${peaks.asMap().entries.map((e) => '${e.key + 1}=${e.value.toStringAsFixed(0)}').join(' ')}');

    // Calibration silence — invariant regardless of data noise.
    expect(cues.where((c) => c.repNum <= profile.calibrationReps), isEmpty,
        reason:
            'reps 1..${profile.calibrationReps} must be silent (calibration window)');

    // At least one fatigue cue fires before the failure rep.
    final hasFatigueCue = cues.any((c) =>
        c.content == CueContent.fatigueFade ||
        c.content == CueContent.fatigueUrgent);
    expect(hasFatigueCue, isTrue,
        reason: 'algorithm fired no fatigue cues across a failure set');

    // STOP fires by the end (Rajiv collapsed at rep 27).
    expect(cues.any((c) => c.content == CueContent.fatigueStop), isTrue,
        reason: 'STOP must fire by end of failure set');
  });
}

/// Reads the CSV, derives the software envelope from RAW samples, and
/// returns the per-rep peak envelope value. Rep N's window is `[R_N.t_us,
/// R_{N+1}.t_us)`; the last rep's window ends at the X marker.
List<double> _loadAndComputePeaks(File file) {
  final lines = file.readAsLinesSync();

  final repBoundaries = <int>[]; // t_us
  int? sessionEndTUs;
  // Pre-allocate a flat sample buffer. Each rep is a few seconds × 2 kHz =
  // ~6000 samples; 27 reps ≈ 200K total. Cheaper than re-iterating.
  final sampleTimes = <int>[];
  final sampleRaws = <int>[];

  for (final line in lines) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(',');
    if (parts.length < 2) continue;
    final tUs = int.tryParse(parts[1]);
    if (tUs == null) continue; // header row "S,t_us,raw,rect,env"
    final tag = parts[0];

    if (tag == 'S' && parts.length >= 3) {
      sampleTimes.add(tUs);
      sampleRaws.add(int.parse(parts[2]));
    } else if (tag == 'R') {
      repBoundaries.add(tUs);
    } else if (tag == 'X') {
      sessionEndTUs = tUs;
    }
  }

  expect(sessionEndTUs, isNotNull, reason: 'CSV missing X session-end row');

  // Run the envelope filter once across all samples; map back to per-rep
  // peaks via the boundary timestamps.
  final derivator = EnvelopeDerivator();
  final envelope = List<double>.filled(sampleRaws.length, 0);
  for (var i = 0; i < sampleRaws.length; i++) {
    envelope[i] = derivator.processSample(sampleRaws[i]);
  }

  final peaks = <double>[];
  for (var r = 0; r < repBoundaries.length; r++) {
    final start = repBoundaries[r];
    final end = r + 1 < repBoundaries.length
        ? repBoundaries[r + 1]
        : sessionEndTUs!;
    var maxV = 0.0;
    // Linear scan — sampleTimes is sorted, but binary search isn't worth
    // the complexity for a one-shot test fixture.
    for (var i = 0; i < sampleTimes.length; i++) {
      final t = sampleTimes[i];
      if (t < start) continue;
      if (t >= end) break;
      if (envelope[i] > maxV) maxV = envelope[i];
    }
    peaks.add(maxV);
  }
  return peaks;
}

class _FiredCue {
  _FiredCue({required this.repNum, required this.content});
  final int repNum;
  final CueContent content;
  @override
  String toString() => '$repNum:${content.name}';
}
