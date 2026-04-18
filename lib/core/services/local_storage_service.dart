import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';

/// On-device persistence for captured sessions and their server reports.
///
/// One JSON file per session at `session_records/{session_id}.json`. On web
/// builds, records live in an in-memory map for the duration of the page —
/// good enough for the demo hosted flow; not used by the mobile flow.
class LocalStorageService {
  LocalStorageService({Directory? directory}) : _overrideDir = directory;

  final Directory? _overrideDir;

  static final Map<String, Map<String, dynamic>> _webMemory = {};

  Future<Directory?> get _baseDir async {
    if (kIsWeb) return null;
    final override = _overrideDir;
    if (override != null) return override;
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> _sessionDir() async {
    final base = await _baseDir;
    final dir = Directory('${base!.path}/session_records');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> saveSessionRecord(SessionRecord record) async {
    if (kIsWeb) {
      _webMemory[record.sessionId] = record.toJson();
      return;
    }
    final dir = await _sessionDir();
    final file = File('${dir.path}/${record.sessionId}.json');
    await file.writeAsString(jsonEncode(record.toJson()));
  }

  Future<SessionRecord?> loadSessionRecord(String sessionId) async {
    if (kIsWeb) {
      final json = _webMemory[sessionId];
      if (json == null) return null;
      return SessionRecord.fromJson(json);
    }
    final dir = await _sessionDir();
    final file = File('${dir.path}/$sessionId.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return SessionRecord.fromJson(json);
  }

  Future<List<SessionRecord>> listSessionRecords() async {
    if (kIsWeb) {
      return _webMemory.values.map(SessionRecord.fromJson).toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    final dir = await _sessionDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    final records = <SessionRecord>[];
    for (final file in files) {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      records.add(SessionRecord.fromJson(json));
    }
    records.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return records;
  }

  Future<void> deleteSessionRecord(String sessionId) async {
    if (kIsWeb) {
      _webMemory.remove(sessionId);
      return;
    }
    final dir = await _sessionDir();
    final file = File('${dir.path}/$sessionId.json');
    if (file.existsSync()) await file.delete();
  }
}
