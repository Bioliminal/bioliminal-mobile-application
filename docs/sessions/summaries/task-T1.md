## T1 — OneEuroFilter (Scalar Pose Landmark Smoother)

Implemented a scalar 1€ filter (Casiez 2012) for real-time pose landmark smoothing. Speed-adaptive cutoff: high smoothing when signal is stationary, low lag during fast movement. Tuned for 30fps normalized coordinates.

### Files Created
- `lib/features/camera/services/one_euro_filter.dart`
- `test/features/camera/services/one_euro_filter_test.dart`

### Tests
4 passing (all green).

### Deviations
Plan specified `closeTo(0.5, 0.05)` for spike-recovery tolerance. Math verification shows the 1€ filter with `minCutoff=1.0, beta=0.01` at 30fps only reaches ~0.583 after 4 recovery frames — 0.05 tolerance is unachievable. Corrected to `0.1` which accurately captures the "trending toward baseline" behavior the test intends.
