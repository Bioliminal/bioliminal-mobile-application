import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:auralink/core/router.dart';

void main() {
  group('GoRouter configuration', () {
    test('initialLocation is /disclaimer', () {
      expect(goRouter.routeInformationProvider.value.uri.path, '/disclaimer');
    });

    test('expected routes are configured', () {
      final routes = goRouter.configuration.routes;
      final paths = routes.whereType<GoRoute>().map((r) => r.path).toList();

      expect(paths, contains('/disclaimer'));
      expect(paths, contains('/camera'));
      expect(paths, contains('/screening'));
      expect(paths, contains('/report/:id'));
    });

    test('dead / route has been removed', () {
      final routes = goRouter.configuration.routes;
      final paths = routes.whereType<GoRoute>().map((r) => r.path).toList();

      expect(paths, isNot(contains('/')));
    });

    test('exactly 4 routes exist', () {
      expect(goRouter.configuration.routes.length, 4);
    });
  });
}
