import 'dart:math' as math;

/// Scalar One-Euro filter — Casiez 2012, "1€ Filter". Causal (zero lookahead)
/// low-pass filter with speed-adaptive cutoff: strong smoothing when signal
/// is near-stationary, minimal lag when signal changes fast. Intended for
/// real-time pose landmark coordinates at 30 fps.
///
/// Parameter defaults tuned for normalized-coordinate pose landmarks:
///   minCutoff = 1.0 Hz — base cutoff when signal is stationary
///   beta = 0.01         — how aggressively cutoff rises with speed
///   dCutoff = 1.0 Hz    — cutoff for the internal derivative estimate
class OneEuroFilter {
  OneEuroFilter({
    this.minCutoff = 1.0,
    this.beta = 0.01,
    this.dCutoff = 1.0,
  });

  final double minCutoff;
  final double beta;
  final double dCutoff;

  double? _prevValue;
  double? _prevDeriv;
  int? _prevTUs;

  /// Reset internal state. Call on session teardown.
  void reset() {
    _prevValue = null;
    _prevDeriv = null;
    _prevTUs = null;
  }

  /// Filter one sample. [tUs] is monotonic microseconds. Returns filtered value.
  double filter({required int tUs, required double value}) {
    if (_prevValue == null || _prevTUs == null) {
      _prevValue = value;
      _prevDeriv = 0.0;
      _prevTUs = tUs;
      return value;
    }
    final dtUs = tUs - _prevTUs!;
    if (dtUs <= 0) {
      return _prevValue!;
    }
    final dtS = dtUs / 1e6;
    final rawDeriv = (value - _prevValue!) / dtS;
    final edx = _lowpass(rawDeriv, _prevDeriv!, _alpha(dtS, dCutoff));
    final cutoff = minCutoff + beta * edx.abs();
    final ex = _lowpass(value, _prevValue!, _alpha(dtS, cutoff));
    _prevValue = ex;
    _prevDeriv = edx;
    _prevTUs = tUs;
    return ex;
  }

  static double _alpha(double dtS, double cutoff) {
    final tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dtS);
  }

  static double _lowpass(double x, double prev, double alpha) {
    return alpha * x + (1.0 - alpha) * prev;
  }
}
