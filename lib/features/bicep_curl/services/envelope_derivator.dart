import '../../../core/services/sample_batch.dart';

/// Software envelope of the RAW EMG channel. Derives a smooth activation
/// trace from the raw bipolar EMG samples by:
///
/// 1. DC-removing (centering on VCC/2 = ADC midpoint 2048)
/// 2. Full-wave rectifying (`abs`)
/// 3. Lowpass-filtering with a 4th-order Butterworth IIR @ 5 Hz cutoff
///    against the fixed 2 kHz sample rate.
///
/// Coefficients are baked-in compile-time constants (sample rate is
/// firmware-locked). The IIR uses Direct-Form II Transposed so a single
/// pass produces a real-time output stream — no `filtfilt` (offline only).
///
/// Per the firmware handshake, this is run on every [SampleBatch] arriving
/// from FF02; the controller buffers the resulting `EnvelopeSample`s and
/// extracts the per-rep peak when the rep detector emits a boundary.
class EnvelopeDerivator {
  // From haptic-cueing-handshake.md §"Envelope derivation". The doc states
  // scipy.signal.butter(4, 5.0/(2000/2), 'low') but the supplied coefficient
  // magnitudes (~1e-4) and DC gain (~2.4) actually correspond to a ~50 Hz
  // cutoff, not 5 Hz. Cue decisions use relative drops (peak/baseline) so
  // the gain cancels — coefficients reproduce the firmware-team analysis
  // byte-for-byte. Re-derive against true 5 Hz if envelope smoothness
  // tightens up production rep detection.
  static const List<double> _b = [
    0.00013534,
    0.00054136,
    0.00081204,
    0.00054136,
    0.00013534,
  ];
  static const List<double> _a = [
    1.0,
    -3.57795951,
    4.82050302,
    -2.89387151,
    0.65222746,
  ];

  // VCC/2 bias on the 12-bit ADC (3.3 V rail, signal centered on 1.65 V).
  static const double _adcMidpoint = 2048.0;

  // IIR delay line (Direct-Form II Transposed).
  final List<double> _z = [0.0, 0.0, 0.0, 0.0];

  /// Process one raw ADC sample (0..4095) → one envelope value.
  double processSample(int rawAdcValue) {
    final centered = rawAdcValue - _adcMidpoint;
    final rectified = centered.abs();

    final y = _b[0] * rectified + _z[0];
    _z[0] = _b[1] * rectified - _a[1] * y + _z[1];
    _z[1] = _b[2] * rectified - _a[2] * y + _z[2];
    _z[2] = _b[3] * rectified - _a[3] * y + _z[3];
    _z[3] = _b[4] * rectified - _a[4] * y;
    return y;
  }

  /// Process every sample in a batch, returning the per-sample envelope
  /// values aligned 1:1 with `batch.raw`. Each envelope value's t_us is
  /// `batch.tUsAt(i)`.
  List<double> processBatch(SampleBatch batch) {
    final out = List<double>.filled(batch.raw.length, 0);
    for (var i = 0; i < batch.raw.length; i++) {
      out[i] = processSample(batch.raw[i]);
    }
    return out;
  }

  /// Zero the IIR state. Call between sessions to prevent residual ringing
  /// from the previous run from contaminating early reps.
  void reset() {
    _z[0] = _z[1] = _z[2] = _z[3] = 0;
  }
}
