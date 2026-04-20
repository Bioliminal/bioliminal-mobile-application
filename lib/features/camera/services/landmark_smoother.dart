import '../../../domain/models.dart';
import 'one_euro_filter.dart';

abstract class LandmarkSmoother {
  List<PoseLandmark> smooth(List<PoseLandmark> landmarks, {required int tUs});
  void reset();
}

class OneEuroLandmarkSmoother implements LandmarkSmoother {
  OneEuroLandmarkSmoother({
    double minCutoff = 1.0,
    double beta = 0.01,
    double dCutoff = 1.0,
  }) : _filters = List.generate(
          33 * 3,
          (_) => OneEuroFilter(
            minCutoff: minCutoff,
            beta: beta,
            dCutoff: dCutoff,
          ),
          growable: false,
        );

  final List<OneEuroFilter> _filters;

  @override
  List<PoseLandmark> smooth(List<PoseLandmark> landmarks, {required int tUs}) {
    if (landmarks.length != 33) return landmarks;
    return List<PoseLandmark>.generate(33, (i) {
      final fx = _filters[i * 3];
      final fy = _filters[i * 3 + 1];
      final fz = _filters[i * 3 + 2];
      final l = landmarks[i];
      return PoseLandmark(
        x: fx.filter(tUs: tUs, value: l.x),
        y: fy.filter(tUs: tUs, value: l.y),
        z: fz.filter(tUs: tUs, value: l.z),
        visibility: l.visibility,
        presence: l.presence,
      );
    }, growable: false);
  }

  @override
  void reset() {
    for (final f in _filters) {
      f.reset();
    }
  }
}
