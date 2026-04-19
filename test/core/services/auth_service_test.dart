import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService privacy guarantees', () {
    test(
      'auth_service.dart does not call FirebaseAuth.instance at top level',
      () {
        // Static analysis: the service file should accept FirebaseAuth as a
        // constructor parameter and only touch .instance inside the factory.
        final projectRoot = _findProjectRoot();
        final file = File('$projectRoot/lib/core/services/auth_service.dart');
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();
        final lines = content.split('\n');

        // Count occurrences of FirebaseAuth.instance in non-comment lines.
        final codeLines = lines.where((l) => !l.trimLeft().startsWith('//'));
        final instanceCount = codeLines
            .where((l) => l.contains('FirebaseAuth.instance'))
            .length;

        // Exactly one occurrence (the factory constructor).
        expect(
          instanceCount,
          1,
          reason:
              'FirebaseAuth.instance should appear exactly once (in the factory)',
        );
      },
    );

    test('AuthService constructor accepts injected FirebaseAuth', () {
      final projectRoot = _findProjectRoot();
      final file = File('$projectRoot/lib/core/services/auth_service.dart');
      final content = file.readAsStringSync();

      // The primary constructor takes FirebaseAuth, not .instance.
      expect(content, contains('AuthService(this._auth)'));
    });
  });
}

String _findProjectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}
