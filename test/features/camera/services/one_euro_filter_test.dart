import 'package:flutter_test/flutter_test.dart';
import 'package:bioliminal/features/camera/services/one_euro_filter.dart';

void main() {
  group('OneEuroFilter', () {
    test('passes first value through unchanged', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.01);
      expect(f.filter(tUs: 0, value: 5.0), closeTo(5.0, 1e-9));
    });

    test('attenuates a single-frame spike on an otherwise-constant signal', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.01);
      const frameUs = 33333; // 30 fps
      double last = 0.0;
      for (var i = 0; i < 10; i++) {
        last = f.filter(tUs: i * frameUs, value: 0.5);
      }
      expect(last, closeTo(0.5, 0.01));
      final duringSpike = f.filter(tUs: 10 * frameUs, value: 1.5);
      expect(duringSpike, lessThan(1.0));
      var after = duringSpike;
      for (var i = 11; i < 15; i++) {
        after = f.filter(tUs: i * frameUs, value: 0.5);
      }
      expect(after, closeTo(0.5, 0.1));
    });

    test('reset() clears state so next filter() passes input through', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.01);
      f.filter(tUs: 0, value: 10.0);
      f.filter(tUs: 33333, value: 10.0);
      f.reset();
      expect(f.filter(tUs: 0, value: 3.0), closeTo(3.0, 1e-9));
    });

    test('monotonic-time guard: identical tUs returns previous output', () {
      final f = OneEuroFilter(minCutoff: 1.0, beta: 0.01);
      f.filter(tUs: 0, value: 0.0);
      final v1 = f.filter(tUs: 33333, value: 1.0);
      final v2 = f.filter(tUs: 33333, value: 99.0);
      expect(v2, closeTo(v1, 1e-9));
    });
  });
}
