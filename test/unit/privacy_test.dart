import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bioliminal/core/providers.dart';
import 'package:bioliminal/core/services/local_storage_service.dart';
import 'package:bioliminal/domain/models.dart';

void main() {
  group('Cloud sync disabled by default', () {
    test('cloudSyncEnabledProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cloudSyncEnabledProvider), isFalse);
    });

    test('authServiceProvider returns null when cloud sync disabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), isNull);
    });

    test('firestoreServiceProvider returns null when cloud sync disabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(firestoreServiceProvider), isNull);
    });
  });

  group('LocalStorageService works offline', () {
    test('save and load assessment without auth', () async {
      final tempDir = await Directory.systemTemp.createTemp('bioliminal_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final service = LocalStorageService(directory: tempDir);

      final assessment = Assessment(
        id: 'privacy-test-001',
        createdAt: DateTime(2026, 4, 8),
        movements: const [],
        compensations: const [],
      );

      await service.saveAssessment(assessment);
      final loaded = await service.loadAssessment('privacy-test-001');

      expect(loaded, isNotNull);
      expect(loaded!.id, 'privacy-test-001');
    });

    test('save and load report without auth', () async {
      final tempDir = await Directory.systemTemp.createTemp('bioliminal_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final service = LocalStorageService(directory: tempDir);

      const report = Report(
        findings: [],
        practitionerPoints: ['Test point'],
        pdfUrl: null,
      );

      await service.saveReport('test-id', report);
      final loaded = await service.loadReport('test-id');

      expect(loaded, isNotNull);
      expect(loaded!.practitionerPoints.first, 'Test point');
    });

    test('list assessments works without auth', () async {
      final tempDir = await Directory.systemTemp.createTemp('bioliminal_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final service = LocalStorageService(directory: tempDir);

      await service.saveAssessment(
        Assessment(
          id: 'list-test-001',
          createdAt: DateTime(2026, 4, 8),
          movements: const [],
          compensations: const [],
        ),
      );
      await service.saveAssessment(
        Assessment(
          id: 'list-test-002',
          createdAt: DateTime(2026, 4, 9),
          movements: const [],
          compensations: const [],
        ),
      );

      final list = await service.listAssessments();
      expect(list.length, 2);
      // Sorted by createdAt descending.
      expect(list.first.id, 'list-test-002');
    });

    test('delete assessment works without auth', () async {
      final tempDir = await Directory.systemTemp.createTemp('bioliminal_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final service = LocalStorageService(directory: tempDir);

      await service.saveAssessment(
        Assessment(
          id: 'delete-test',
          createdAt: DateTime(2026, 4, 8),
          movements: const [],
          compensations: const [],
        ),
      );

      await service.deleteAssessment('delete-test');
      final loaded = await service.loadAssessment('delete-test');
      expect(loaded, isNull);
    });
  });
}
