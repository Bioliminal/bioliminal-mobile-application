import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';

// ---------------------------------------------------------------------------
// JSON serialization helpers for domain models
// ---------------------------------------------------------------------------

Map<String, dynamic> _landmarkToJson(PoseLandmark l) => {
  'x': l.x,
  'y': l.y,
  'z': l.z,
  'visibility': l.visibility,
  'presence': l.presence,
};

PoseLandmark _landmarkFromJson(Map<String, dynamic> m) => PoseLandmark(
  x: (m['x'] as num).toDouble(),
  y: (m['y'] as num).toDouble(),
  z: (m['z'] as num).toDouble(),
  visibility: (m['visibility'] as num).toDouble(),
  presence:
      (m['presence'] as num?)?.toDouble() ??
      (m['visibility'] as num).toDouble(),
);

Map<String, dynamic> _poseFrameToJson(PoseFrame f) => {
  'timestamp_ms': f.timestampMs,
  'landmarks': f.landmarks.map(_landmarkToJson).toList(),
};

PoseFrame _poseFrameFromJson(Map<String, dynamic> m) => PoseFrame(
  timestampMs: m['timestamp_ms'] as int,
  landmarks: (m['landmarks'] as List)
      .map((l) => _landmarkFromJson(l as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _jointAngleToJson(JointAngle j) => {
  'joint': j.joint,
  'angleDegrees': j.angleDegrees,
  'confidence': j.confidence.name,
};

JointAngle _jointAngleFromJson(Map<String, dynamic> m) => JointAngle(
  joint: m['joint'] as String,
  angleDegrees: (m['angleDegrees'] as num).toDouble(),
  confidence: ConfidenceLevel.values.byName(m['confidence'] as String),
);

Map<String, dynamic> _citationToJson(Citation c) => {
  'finding': c.finding,
  'source': c.source,
  'url': c.url,
  'type': c.type.name,
  'appUsage': c.appUsage,
};

Citation _citationFromJson(Map<String, dynamic> m) => Citation(
  finding: m['finding'] as String,
  source: m['source'] as String,
  url: m['url'] as String,
  type: CitationType.values.byName(m['type'] as String),
  appUsage: m['appUsage'] as String,
);

Map<String, dynamic> _compensationToJson(Compensation c) => {
  'type': c.type.name,
  'joint': c.joint,
  'chain': c.chain?.name,
  'confidence': c.confidence.name,
  'value': c.value,
  'threshold': c.threshold,
  'citation': _citationToJson(c.citation),
};

Compensation _compensationFromJson(Map<String, dynamic> m) => Compensation(
  type: CompensationType.values.byName(m['type'] as String),
  joint: m['joint'] as String,
  chain: m['chain'] != null
      ? ChainType.values.byName(m['chain'] as String)
      : null,
  confidence: ConfidenceLevel.values.byName(m['confidence'] as String),
  value: (m['value'] as num).toDouble(),
  threshold: (m['threshold'] as num).toDouble(),
  citation: _citationFromJson(m['citation'] as Map<String, dynamic>),
);

Map<String, dynamic> _movementToJson(Movement m) => {
  'type': m.type.wire,
  'frames': m.frames.map(_poseFrameToJson).toList(),
  'keyframeAngles': m.keyframeAngles.map(_jointAngleToJson).toList(),
  'durationMs': m.duration.inMilliseconds,
};

Movement _movementFromJson(Map<String, dynamic> m) => Movement(
  type: MovementType.fromWire(m['type'] as String),
  frames: (m['frames'] as List)
      .map((f) => _poseFrameFromJson(f as Map<String, dynamic>))
      .toList(),
  keyframeAngles: (m['keyframeAngles'] as List)
      .map((j) => _jointAngleFromJson(j as Map<String, dynamic>))
      .toList(),
  duration: Duration(milliseconds: m['durationMs'] as int),
);

Map<String, dynamic> _sessionMetadataToJson(SessionMetadata m) => {
  'movement': m.movement.wire,
  'device': m.device,
  'model': m.model,
  'frame_rate': m.frameRate,
  'captured_at': m.capturedAt.toUtc().toIso8601String(),
};

SessionMetadata _sessionMetadataFromJson(Map<String, dynamic> m) =>
    SessionMetadata(
      movement: MovementType.fromWire(m['movement'] as String),
      device: m['device'] as String,
      model: m['model'] as String,
      frameRate: (m['frame_rate'] as num).toDouble(),
      capturedAt: DateTime.parse(m['captured_at'] as String),
    );

Map<String, dynamic> _sessionPayloadToJson(SessionPayload p) => {
  'metadata': _sessionMetadataToJson(p.metadata),
  'frames': p.frames.map(_poseFrameToJson).toList(),
};

SessionPayload _sessionPayloadFromJson(Map<String, dynamic> m) =>
    SessionPayload(
      metadata: _sessionMetadataFromJson(m['metadata'] as Map<String, dynamic>),
      frames: (m['frames'] as List)
          .map((f) => _poseFrameFromJson(f as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _mobilityDrillToJson(MobilityDrill d) => {
  'name': d.name,
  'targetArea': d.targetArea,
  'durationSeconds': d.durationSeconds,
  'steps': d.steps,
  'compensationType': d.compensationType.name,
};

MobilityDrill _mobilityDrillFromJson(Map<String, dynamic> m) => MobilityDrill(
  name: m['name'] as String,
  targetArea: m['targetArea'] as String,
  durationSeconds: m['durationSeconds'] as int,
  steps: (m['steps'] as List).cast<String>(),
  compensationType: CompensationType.values.byName(
    m['compensationType'] as String,
  ),
);

Map<String, dynamic> _findingToJson(Finding f) => {
  'bodyPathDescription': f.bodyPathDescription,
  'compensations': f.compensations.map(_compensationToJson).toList(),
  'upstreamDriver': f.upstreamDriver,
  'recommendation': f.recommendation,
  'citations': f.citations.map(_citationToJson).toList(),
  'drills': f.drills.map(_mobilityDrillToJson).toList(),
};

Finding _findingFromJson(Map<String, dynamic> m) => Finding(
  bodyPathDescription: m['bodyPathDescription'] as String,
  compensations: (m['compensations'] as List)
      .map((c) => _compensationFromJson(c as Map<String, dynamic>))
      .toList(),
  upstreamDriver: m['upstreamDriver'] as String?,
  recommendation: m['recommendation'] as String,
  citations: (m['citations'] as List)
      .map((c) => _citationFromJson(c as Map<String, dynamic>))
      .toList(),
  drills: m.containsKey('drills')
      ? (m['drills'] as List)
            .map((d) => _mobilityDrillFromJson(d as Map<String, dynamic>))
            .toList()
      : const [],
);

Map<String, dynamic> reportToJson(Report r) => {
  'findings': r.findings.map(_findingToJson).toList(),
  'practitionerPoints': r.practitionerPoints,
  'pdfUrl': r.pdfUrl,
};

Report reportFromJson(Map<String, dynamic> m) => Report(
  findings: (m['findings'] as List)
      .map((f) => _findingFromJson(f as Map<String, dynamic>))
      .toList(),
  practitionerPoints: (m['practitionerPoints'] as List).cast<String>(),
  pdfUrl: m['pdfUrl'] as String?,
);

Map<String, dynamic> assessmentToJson(Assessment a) => {
  'id': a.id,
  'createdAt': a.createdAt.toIso8601String(),
  'movements': a.movements.map(_movementToJson).toList(),
  'compensations': a.compensations.map(_compensationToJson).toList(),
  'report': a.report != null ? reportToJson(a.report!) : null,
  'payload': a.payload != null ? _sessionPayloadToJson(a.payload!) : null,
};

Assessment assessmentFromJson(Map<String, dynamic> m) => Assessment(
  id: m['id'] as String,
  createdAt: DateTime.parse(m['createdAt'] as String),
  movements: (m['movements'] as List)
      .map((mv) => _movementFromJson(mv as Map<String, dynamic>))
      .toList(),
  compensations: (m['compensations'] as List)
      .map((c) => _compensationFromJson(c as Map<String, dynamic>))
      .toList(),
  report: m['report'] != null
      ? reportFromJson(m['report'] as Map<String, dynamic>)
      : null,
  payload: m['payload'] != null
      ? _sessionPayloadFromJson(m['payload'] as Map<String, dynamic>)
      : null,
);

// ---------------------------------------------------------------------------
// LocalStorageService
// ---------------------------------------------------------------------------

class LocalStorageService {
  LocalStorageService({Directory? directory}) : _overrideDir = directory;

  final Directory? _overrideDir;

  // In-memory fallback for Web Demo
  static final Map<String, dynamic> _webMemory = {};

  Future<Directory?> get _baseDir async {
    if (kIsWeb) return null;
    final override = _overrideDir;
    if (override != null) return override;
    return getApplicationDocumentsDirectory();
  }

  Future<dynamic> _getDir(String name) async {
    if (kIsWeb) return name;
    final base = await _baseDir;
    final dir = Directory('${base!.path}/$name');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  // -- Assessments --

  Future<void> saveAssessment(Assessment assessment) async {
    if (kIsWeb) {
      _webMemory['assessments/${assessment.id}'] = assessmentToJson(assessment);
      return;
    }
    final dir = await _getDir('assessments') as Directory;
    final file = File('${dir.path}/${assessment.id}.json');
    final json = jsonEncode(assessmentToJson(assessment));
    await file.writeAsString(json);
  }

  Future<Assessment?> loadAssessment(String id) async {
    if (kIsWeb) {
      final json = _webMemory['assessments/$id'];
      if (json == null) return null;
      return assessmentFromJson(json as Map<String, dynamic>);
    }
    final dir = await _getDir('assessments') as Directory;
    final file = File('${dir.path}/$id.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return assessmentFromJson(json);
  }

  Future<List<Assessment>> listAssessments() async {
    if (kIsWeb) {
      return _webMemory.keys
          .where((k) => k.startsWith('assessments/'))
          .map((k) => assessmentFromJson(_webMemory[k] as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final dir = await _getDir('assessments') as Directory;
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );
    final assessments = <Assessment>[];
    for (final file in files) {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      assessments.add(assessmentFromJson(json));
    }
    assessments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return assessments;
  }

  Future<void> deleteAssessment(String id) async {
    if (kIsWeb) {
      _webMemory.remove('assessments/$id');
      _webMemory.remove('reports/$id');
      _webMemory.remove('pdfs/$id');
      return;
    }
    final assessDir = await _getDir('assessments') as Directory;
    final assessFile = File('${assessDir.path}/$id.json');
    if (assessFile.existsSync()) await assessFile.delete();

    final reportDir = await _getDir('reports') as Directory;
    final reportFile = File('${reportDir.path}/$id.json');
    if (reportFile.existsSync()) await reportFile.delete();

    final pdfDir = await _getDir('pdfs') as Directory;
    final pdfFile = File('${pdfDir.path}/$id.pdf');
    if (pdfFile.existsSync()) await pdfFile.delete();
  }

  // -- Reports --

  Future<void> saveReport(String assessmentId, Report report) async {
    if (kIsWeb) {
      _webMemory['reports/$assessmentId'] = reportToJson(report);
      return;
    }
    final dir = await _getDir('reports') as Directory;
    final file = File('${dir.path}/$assessmentId.json');
    final json = jsonEncode(reportToJson(report));
    await file.writeAsString(json);
  }

  Future<Report?> loadReport(String assessmentId) async {
    if (kIsWeb) {
      final json = _webMemory['reports/$assessmentId'];
      if (json == null) return null;
      return reportFromJson(json as Map<String, dynamic>);
    }
    final dir = await _getDir('reports') as Directory;
    final file = File('${dir.path}/$assessmentId.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return reportFromJson(json);
  }

  // -- Session records (new server-shaped persistence) --

  Future<void> saveSessionRecord(SessionRecord record) async {
    if (kIsWeb) {
      _webMemory['session_records/${record.sessionId}'] = record.toJson();
      return;
    }
    final dir = await _getDir('session_records') as Directory;
    final file = File('${dir.path}/${record.sessionId}.json');
    await file.writeAsString(jsonEncode(record.toJson()));
  }

  Future<SessionRecord?> loadSessionRecord(String sessionId) async {
    if (kIsWeb) {
      final json = _webMemory['session_records/$sessionId'];
      if (json == null) return null;
      return SessionRecord.fromJson(json as Map<String, dynamic>);
    }
    final dir = await _getDir('session_records') as Directory;
    final file = File('${dir.path}/$sessionId.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return SessionRecord.fromJson(json);
  }

  Future<List<SessionRecord>> listSessionRecords() async {
    if (kIsWeb) {
      return _webMemory.keys
          .where((k) => k.startsWith('session_records/'))
          .map(
            (k) => SessionRecord.fromJson(_webMemory[k] as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    final dir = await _getDir('session_records') as Directory;
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );
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
      _webMemory.remove('session_records/$sessionId');
      return;
    }
    final dir = await _getDir('session_records') as Directory;
    final file = File('${dir.path}/$sessionId.json');
    if (file.existsSync()) await file.delete();
  }

  // -- PDFs --

  Future<void> savePdf(String assessmentId, List<int> bytes) async {
    if (kIsWeb) {
      _webMemory['pdfs/$assessmentId'] = bytes;
      return;
    }
    final dir = await _getDir('pdfs') as Directory;
    final file = File('${dir.path}/$assessmentId.pdf');
    await file.writeAsBytes(bytes);
  }

  Future<dynamic> getPdf(String assessmentId) async {
    if (kIsWeb) {
      return _webMemory['pdfs/$assessmentId'];
    }
    final dir = await _getDir('pdfs') as Directory;
    final file = File('${dir.path}/$assessmentId.pdf');
    if (!file.existsSync()) return null;
    return file;
  }
}
