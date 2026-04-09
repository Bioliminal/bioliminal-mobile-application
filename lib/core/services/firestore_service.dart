import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

/// Cloud persistence layer. Opt-in only — not part of the default provider
/// graph. Only instantiated after explicit user opt-in to cloud sync. No
/// Firebase SDK calls occur until this service is created. When
/// [cloudSyncEnabled] is false, all public methods throw [StateError].
/// See [cloudSyncEnabledProvider] in providers.dart.
class FirestoreService {
  FirestoreService(
    this._firestore,
    this._storage,
    this._auth, {
    this.cloudSyncEnabled = false,
  });

  /// Creates a [FirestoreService] using the default Firebase instances.
  /// This is the only call site that touches [FirebaseFirestore.instance]
  /// and [FirebaseStorage.instance], ensuring those SDKs are not initialized
  /// until opt-in.
  factory FirestoreService.withFirebase(AuthService auth) => FirestoreService(
        FirebaseFirestore.instance,
        FirebaseStorage.instance,
        auth,
        cloudSyncEnabled: true,
      );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuthService _auth;
  final bool cloudSyncEnabled;

  void _requireCloudSync() {
    if (!cloudSyncEnabled) {
      throw StateError(
        'Cloud sync is disabled. Enable it in settings before '
        'calling FirestoreService methods.',
      );
    }
  }

  String get _uid {
    final uid = _auth.uid;
    if (uid == null) {
      throw StateError('FirestoreService requires an authenticated user');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _assessments =>
      _firestore.collection('assessments').doc(_uid).collection('sessions');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports').doc(_uid).collection('sessions');

  // ---------------------------------------------------------------------------
  // Firestore-specific map conversion
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _assessmentToFirestore(Assessment a) {
    final json = assessmentToJson(a);
    // Swap ISO string to Firestore Timestamp
    json['createdAt'] = Timestamp.fromDate(a.createdAt);
    return json;
  }

  Assessment _assessmentFromFirestore(Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    // Swap Firestore Timestamp back to ISO string for the shared deserializer
    final createdAt = json['createdAt'];
    if (createdAt is Timestamp) {
      json['createdAt'] = createdAt.toDate().toIso8601String();
    }
    return assessmentFromJson(json);
  }

  Map<String, dynamic> _reportToFirestore(Report r) {
    return reportToJson(r);
  }

  Report _reportFromFirestore(Map<String, dynamic> data) {
    return reportFromJson(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // Assessments
  // ---------------------------------------------------------------------------

  Future<void> saveAssessment(Assessment assessment) async {
    _requireCloudSync();
    await _assessments
        .doc(assessment.id)
        .set(_assessmentToFirestore(assessment));
  }

  Future<Assessment?> loadAssessment(String id) async {
    _requireCloudSync();
    final doc = await _assessments.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _assessmentFromFirestore(doc.data()!);
  }

  Future<List<Assessment>> listAssessments() async {
    _requireCloudSync();
    final snapshot =
        await _assessments.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => _assessmentFromFirestore(doc.data()))
        .toList();
  }

  Future<void> deleteAssessment(String id) async {
    _requireCloudSync();
    await _assessments.doc(id).delete();
    await _reports.doc(id).delete();

    try {
      await _storage.ref('reports/$_uid/$id.pdf').delete();
    } on FirebaseException catch (_) {
      // PDF may not exist — ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<void> saveReport(String assessmentId, Report report) async {
    _requireCloudSync();
    await _reports.doc(assessmentId).set(_reportToFirestore(report));
  }

  Future<Report?> loadReport(String assessmentId) async {
    _requireCloudSync();
    final doc = await _reports.doc(assessmentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _reportFromFirestore(doc.data()!);
  }

  // ---------------------------------------------------------------------------
  // PDF upload
  // ---------------------------------------------------------------------------

  Future<String> uploadPdf(String assessmentId, List<int> bytes) async {
    _requireCloudSync();
    final ref = _storage.ref('reports/$_uid/$assessmentId.pdf');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'application/pdf'),
    );
    final url = await ref.getDownloadURL();

    // Update the report document with the download URL
    final reportDoc = await _reports.doc(assessmentId).get();
    if (reportDoc.exists) {
      await _reports.doc(assessmentId).update({'pdfUrl': url});
    }

    return url;
  }

  // ---------------------------------------------------------------------------
  // Background sync
  // ---------------------------------------------------------------------------

  Future<void> syncLocalAssessments(LocalStorageService localStorage) async {
    _requireCloudSync();
    final localAssessments = await localStorage.listAssessments();

    for (final assessment in localAssessments) {
      try {
        final doc = await _assessments.doc(assessment.id).get();
        if (doc.exists) continue;

        await saveAssessment(assessment);

        final report = await localStorage.loadReport(assessment.id);
        if (report != null) {
          await saveReport(assessment.id, report);
        }

        final pdfFile = await localStorage.getPdf(assessment.id);
        if (pdfFile != null) {
          final bytes = await pdfFile.readAsBytes();
          await uploadPdf(assessment.id, bytes);
        }
      } catch (e) {
        developer.log(
          'Failed to sync assessment ${assessment.id}',
          error: e,
          name: 'FirestoreService',
        );
      }
    }
  }
}
