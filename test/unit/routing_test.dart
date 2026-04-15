import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bioliminal/core/router.dart';

void main() {
  group('GoRouter configuration', () {
    test('expected routes are configured', () {
      final routes = goRouter.configuration.routes;
      final paths = routes.whereType<GoRoute>().map((r) => r.path).toList();

      expect(paths, contains('/'));
      expect(paths, contains('/disclaimer'));
      expect(paths, contains('/capture'));
      expect(paths, contains('/screening'));
      expect(paths, contains('/report/:id'));
      expect(paths, contains('/login'));
      expect(paths, contains('/profile'));
    });

    test('expected number of top-level routes exist', () {
      // 11 GoRoutes + 1 StatefulShellRoute = 12
      expect(goRouter.configuration.routes.length, 12);
    });
  });
}
