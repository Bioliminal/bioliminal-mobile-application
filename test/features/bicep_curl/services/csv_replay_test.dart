import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/bicep_curl/models/cue_decision.dart';
import 'package:bioliminal/features/bicep_curl/models/cue_profile.dart';
import 'package:bioliminal/features/bicep_curl/services/envelope_derivator.dart';
import 'package:bioliminal/features/bicep_curl/services/fatigue_algorithm.dart';

/// **Snapshot regression guard** for the envelope+algorithm pipeline against
/// real data.
///
/// Runs Rajiv's 27-rep-to-failure session through the software envelope +
/// fatigue algorithm and asserts the exact cue sequence against a checked-in
/// snapshot. The CSV's rep boundaries come from BOOT button presses, which
/// are noisy — peaks swing wildly and the algorithm fires *more* cues here
/// than the handshake predicted for clean data. **Production uses
/// camera-derived rep boundaries from elbow-angle inflection, which will be
/// tighter.** So the snapshot isn't a spec for production behavior; it's a
/// tripwire for regressions in the envelope filter, the fatigue algorithm,
/// or the fixture itself.
///
/// If this test fails because you intentionally changed the filter or the
/// algorithm, rerun, inspect the printed replay, and update the snapshot.
/// If you haven't touched either, something upstream drifted.
///
/// Shape invariants cross-check the snapshot (calibration silence, STOP
/// terminates the set). Pure-algorithm behavior lives in
/// fatigue_algorithm_test.dart against fabricated peak sequences.
///
/// CSV format (per `docs/hardware_integration/`):
/// - `S,t_us,raw,rect,env`  — one sample row at 2 kHz
/// - `R,t_us,rep_num`       — rep onset marker (BOOT button press)
/// - `X,t_us,final_rep`     — session end
/// - `# ...` lines are comments
void main() {
  // Locked-in cue sequence for the current {envelope coefficients, algorithm,
  // CueProfile.intermediate(), Rajiv fixture}. Update deliberately after
  // confirming a legitimate upstream change.
  const expectedCueSequence = <(int, CueContent)>[
    (7, CueContent.fatigueUrgent),
    (11, CueContent.fatigueUrgent),
    (14, CueContent.fatigueUrgent),
    (19, CueContent.fatigueStop),
    (21, CueContent.fatigueUrgent),
    (24, CueContent.fatigueUrgent),
    (25, CueContent.fatigueStop),
    (26, CueContent.fatigueStop),
    (27, CueContent.fatigueStop),
  ];

  test('Rajiv\'s 27-rep failure session — snapshot + shape', () {
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

    // --- Snapshot check (primary regression guard) ---
    final actualSequence = cues
        .map((c) => (c.repNum, c.content))
        .toList(growable: false);
    expect(
      actualSequence,
      expectedCueSequence,
      reason: 'Cue sequence drifted from snapshot. If you changed the '
          'envelope filter, fatigue algorithm, or fixture, inspect the '
          'printed replay above and update `expectedCueSequence` in this '
          'file. Otherwise something upstream regressed.',
    );

    // --- Shape invariants (cross-checks; must always hold) ---

    // 1. Calibration silence — no cues until the calibration window closes.
    expect(cues.where((c) => c.repNum <= profile.calibrationReps), isEmpty,
        reason:
            'reps 1..${profile.calibrationReps} must be silent (calibration window)');

    // 2. STOP terminates the failure set and is the final cue.
    expect(cues.last.content, CueContent.fatigueStop,
        reason: 'last cue on a failure set must be fatigueStop');
    expect(cues.last.repNum, reps.length,
        reason: 'final STOP should land on the terminal rep');

    // 3. At least one fatigue cue (FADE or URGENT) fires before the first
    //    STOP — i.e., the algorithm warned before halting.
    final firstStopIdx =
        cues.indexWhere((c) => c.content == CueContent.fatigueStop);
    final hasWarningBeforeStop = cues.sublist(0, firstStopIdx).any((c) =>
        c.content == CueContent.fatigueFade ||
        c.content == CueContent.fatigueUrgent);
    expect(hasWarningBeforeStop, isTrue,
        reason: 'algorithm jumped straight to STOP without FADE/URGENT warning');
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
