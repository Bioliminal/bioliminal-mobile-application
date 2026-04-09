import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/core/providers.dart';

void main() {
  group('CloudSyncNotifier', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cloudSyncEnabledProvider), isFalse);
    });

    test('enable() sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cloudSyncEnabledProvider.notifier).enable();
      expect(container.read(cloudSyncEnabledProvider), isTrue);
    });

    test('disable() sets state back to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cloudSyncEnabledProvider.notifier).enable();
      container.read(cloudSyncEnabledProvider.notifier).disable();
      expect(container.read(cloudSyncEnabledProvider), isFalse);
    });
  });

  group('Cloud-only providers throw when sync disabled', () {
    test('authServiceProvider throws when cloud sync disabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod wraps provider errors in ProviderException.
      expect(
        () => container.read(authServiceProvider),
        throwsA(anything),
      );
    });

    test('firestoreServiceProvider throws when cloud sync disabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(firestoreServiceProvider),
        throwsA(anything),
      );
    });
  });

  group('No Firebase imports in providers.dart', () {
    test('providers.dart does not import Firebase packages', () {
      // Static analysis: read the source file and verify no Firebase imports.
      final projectRoot = _findProjectRoot();
      final providersFile =
          File('$projectRoot/lib/core/providers.dart');
      expect(providersFile.existsSync(), isTrue,
          reason: 'providers.dart must exist');

      final content = providersFile.readAsStringSync();

      expect(
        content.contains("import 'package:firebase_auth/"),
        isFalse,
        reason: 'providers.dart must not import firebase_auth',
      );
      expect(
        content.contains("import 'package:cloud_firestore/"),
        isFalse,
        reason: 'providers.dart must not import cloud_firestore',
      );
      expect(
        content.contains("import 'package:firebase_storage/"),
        isFalse,
        reason: 'providers.dart must not import firebase_storage',
      );
    });
  });
}

/// Walk up from the test file to find the project root (where pubspec.yaml is).
String _findProjectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  // Fallback: tests are typically run from project root.
  return Directory.current.path;
}
