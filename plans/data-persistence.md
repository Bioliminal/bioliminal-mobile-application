# Data Persistence
Story: story-1298
Agent: architect

## Context
Local-first data persistence with Firestore cloud sync and anonymous Firebase authentication. Users never create accounts — the app silently authenticates on first launch, giving each device a stable UID that scopes all reads and writes. Assessments and reports are cached locally as JSON files (via path_provider) for offline use, then synced to Firestore in the background when connectivity is available. Generated PDFs are uploaded to Firebase Storage. If the user reinstalls, the anonymous UID changes and prior data is inaccessible — acceptable for capstone, solved by real accounts in Phase 2.

Depends: story-1297 (Report — provides Assessment and Report models with PDF generation)
Blocks: none

Files:
- lib/core/services/auth_service.dart
- lib/core/services/local_storage_service.dart
- lib/core/services/firestore_service.dart

## What changes
| File | Change |
|---|---|
| `lib/core/services/auth_service.dart` | New. Wraps `FirebaseAuth.instance.signInAnonymously()`. Exposes current UID, auth state stream, and sign-out. Auto-signs-in on first access. |
| `lib/core/services/local_storage_service.dart` | New. JSON file-based local cache using `path_provider`. Saves/loads/deletes `Assessment` objects as JSON files in the app documents directory. Lists all cached assessments sorted by creation date. |
| `lib/core/services/firestore_service.dart` | New. Reads/writes assessments and reports to Firestore under the authenticated UID. Uploads PDFs to Firebase Storage. Handles background sync of locally-cached assessments when online. |

## Architecture (Claude)

**Auth flow**: `AuthService` calls `signInAnonymously()` once and caches the result. Downstream services read the UID from `AuthService.uid`. The UID is stable across app sessions (same install). Auth state is exposed as a `Stream<String?>` so providers can react to sign-in completion.

**Local storage layout**:
```
{appDocDir}/assessments/{id}.json    — serialized Assessment
{appDocDir}/reports/{id}.json        — serialized Report
{appDocDir}/pdfs/{id}.pdf            — generated PDF file
```

**Firestore collections** (UID-scoped):
```
assessments/{uid}/sessions/{id}      — assessment data
reports/{uid}/sessions/{id}          — report data + pdfUrl
```

**Firebase Storage paths**:
```
reports/{uid}/{assessmentId}.pdf     — uploaded PDF files
```

**Sync strategy**: Local-first. On save, write to local JSON immediately, then attempt Firestore write. If offline, Firestore SDK queues the write automatically (built-in offline persistence). For PDFs, upload to Firebase Storage and write the download URL back to the Firestore report document. On app launch, `FirestoreService` checks for any locally-cached assessments that lack a Firestore timestamp and syncs them.

**Why not just Firestore offline SDK?** Firestore's built-in cache is opaque — you can't enumerate cached documents or build UI off it reliably when offline for extended periods. The explicit JSON cache gives us full control: list assessments, show them in UI, delete individual ones. Firestore offline persistence handles the write queue; our local cache handles the read side.

<!-- CODER_ONLY -->
## Read-only context
- presearch/bioliminal-product.md
- lib/domain/models.dart (from story-1293 — Assessment, Report, Movement, Compensation, Finding, Citation classes + all enums)
- lib/features/report/services/pdf_generator.dart (from story-1297 — generates PDF bytes from a Report)

## Tasks
1. **AuthService class** — Create `lib/core/services/auth_service.dart`. Class wraps `FirebaseAuth`. Constructor takes `FirebaseAuth` instance (for testability — inject `FirebaseAuth.instance` in production, mock in tests). Methods:
   - `Future<String> signIn()` — calls `signInAnonymously()`, returns the UID. If already signed in, returns current UID without re-authenticating.
   - `String? get uid` — returns current user's UID or null if not signed in.
   - `Stream<String?> get authStateChanges` — maps `FirebaseAuth.authStateChanges()` to emit UID strings (or null on sign-out).
   - `Future<void> signOut()` — calls `FirebaseAuth.signOut()`. Primarily for testing/debug.
   - `bool get isSignedIn` — convenience getter, `uid != null`.

2. **LocalStorageService class** — Create `lib/core/services/local_storage_service.dart`. Uses `path_provider` to get the app documents directory. All operations are on JSON files. Constructor takes an optional `Directory` override (for testing). Methods:
   - `Future<void> saveAssessment(Assessment assessment)` — serializes to JSON, writes to `assessments/{assessment.id}.json`. Create subdirectory if needed.
   - `Future<Assessment?> loadAssessment(String id)` — reads and deserializes from `assessments/{id}.json`. Returns null if file doesn't exist.
   - `Future<List<Assessment>> listAssessments()` — reads all JSON files in `assessments/` directory, deserializes each, returns sorted by `createdAt` descending.
   - `Future<void> deleteAssessment(String id)` — deletes `assessments/{id}.json` if it exists. Also deletes associated report and PDF files.
   - `Future<void> saveReport(String assessmentId, Report report)` — serializes report to `reports/{assessmentId}.json`.
   - `Future<Report?> loadReport(String assessmentId)` — reads report JSON.
   - `Future<void> savePdf(String assessmentId, List<int> bytes)` — writes PDF bytes to `pdfs/{assessmentId}.pdf`.
   - `Future<File?> getPdf(String assessmentId)` — returns the PDF file if it exists, null otherwise.
   - Serialization: Add `toJson()` and `fromJson()` factory methods on model classes. If models from story-1293 don't have these yet, add them as extension methods or static helpers within this file.

3. **FirestoreService class** — Create `lib/core/services/firestore_service.dart`. Constructor takes `FirebaseFirestore`, `FirebaseStorage`, and `AuthService` instances. All Firestore paths are scoped under `AuthService.uid`. Methods:
   - `Future<void> saveAssessment(Assessment assessment)` — writes to `assessments/{uid}/sessions/{assessment.id}`. Converts Assessment to a Firestore-compatible map (Timestamps for DateTime, flat arrays for nested lists).
   - `Future<Assessment?> loadAssessment(String id)` — reads from `assessments/{uid}/sessions/{id}`.
   - `Future<List<Assessment>> listAssessments()` — queries `assessments/{uid}/sessions` ordered by `createdAt` desc.
   - `Future<void> deleteAssessment(String id)` — deletes the document and associated report/PDF.
   - `Future<void> saveReport(String assessmentId, Report report)` — writes to `reports/{uid}/sessions/{assessmentId}`.
   - `Future<Report?> loadReport(String assessmentId)` — reads from `reports/{uid}/sessions/{assessmentId}`.
   - `Future<String> uploadPdf(String assessmentId, List<int> bytes)` — uploads to Firebase Storage at `reports/{uid}/{assessmentId}.pdf`, returns the download URL. Updates the report document's `pdfUrl` field.
   - `Future<void> syncLocalAssessments(LocalStorageService localStorage)` — reads all local assessments, checks which are missing from Firestore (by document existence), and uploads them. Called on app start after auth completes.

4. **JSON serialization helpers** — Within `local_storage_service.dart` (or a shared helpers file if cleaner), implement `toJson()`/`fromJson()` conversion logic for: Assessment, Report, Finding, Compensation, Movement, JointAngle, Landmark, Citation. Handle enums via `.name`/string lookup. Handle DateTime via `.toIso8601String()`. Handle Duration via `.inMilliseconds`. These converters are also used by FirestoreService for Firestore map conversion (with Timestamp substitution for DateTime fields).

5. **Firestore map conversion** — In `firestore_service.dart`, implement private helpers `_assessmentToFirestore(Assessment)` and `_assessmentFromFirestore(Map<String, dynamic>)` that handle Firestore-specific types: `DateTime` <-> `Timestamp`, nested objects as maps. Similar helpers for Report. Reuse the JSON serialization logic from task 4 as the base, with a Firestore-specific layer that swaps DateTime/Timestamp.

6. **Background sync on startup** — In `FirestoreService.syncLocalAssessments()`, implement: get all local assessment IDs from `LocalStorageService.listAssessments()`, for each check if document exists in Firestore via `get()`, if not found then call `saveAssessment()` and `saveReport()` (if report exists locally) and `uploadPdf()` (if PDF exists locally). Catch and log errors per-assessment so one failure doesn't block the rest. This method should be called from `main.dart` or the root provider chain after auth completes.

7. **Provider wiring updates** — The bootstrap plan (story-1293) already declares `authServiceProvider`, `localStorageServiceProvider`, and `firestoreServiceProvider` as placeholder providers that throw `UnimplementedError`. The coder should override these in `lib/core/providers.dart` with real instances. `authServiceProvider` depends on `FirebaseAuth.instance`. `localStorageServiceProvider` depends on nothing (uses default app directory). `firestoreServiceProvider` depends on `FirebaseFirestore.instance`, `FirebaseStorage.instance`, and `authServiceProvider`.
<!-- END_CODER_ONLY -->

## Contract

### AuthService
```dart
class AuthService {
  AuthService(FirebaseAuth auth);

  Future<String> signIn();
  String? get uid;
  Stream<String?> get authStateChanges;
  Future<void> signOut();
  bool get isSignedIn;
}
```

### LocalStorageService
```dart
class LocalStorageService {
  LocalStorageService({Directory? directory});

  Future<void> saveAssessment(Assessment assessment);
  Future<Assessment?> loadAssessment(String id);
  Future<List<Assessment>> listAssessments();
  Future<void> deleteAssessment(String id);
  Future<void> saveReport(String assessmentId, Report report);
  Future<Report?> loadReport(String assessmentId);
  Future<void> savePdf(String assessmentId, List<int> bytes);
  Future<File?> getPdf(String assessmentId);
}
```

### FirestoreService
```dart
class FirestoreService {
  FirestoreService(FirebaseFirestore firestore, FirebaseStorage storage, AuthService auth);

  Future<void> saveAssessment(Assessment assessment);
  Future<Assessment?> loadAssessment(String id);
  Future<List<Assessment>> listAssessments();
  Future<void> deleteAssessment(String id);
  Future<void> saveReport(String assessmentId, Report report);
  Future<Report?> loadReport(String assessmentId);
  Future<String> uploadPdf(String assessmentId, List<int> bytes);
  Future<void> syncLocalAssessments(LocalStorageService localStorage);
}
```

## Acceptance criteria
- On first app launch, `AuthService.signIn()` completes and returns a non-null UID without user interaction
- Subsequent calls to `AuthService.signIn()` return the same UID without re-authenticating
- `AuthService.authStateChanges` emits the UID on sign-in and null on sign-out
- `LocalStorageService.saveAssessment()` writes a JSON file to disk and `loadAssessment()` returns an identical Assessment object
- `LocalStorageService.listAssessments()` returns all saved assessments sorted by `createdAt` descending
- `LocalStorageService.deleteAssessment()` removes the assessment JSON, associated report JSON, and PDF file
- `LocalStorageService.savePdf()` writes bytes to disk and `getPdf()` returns the file
- `FirestoreService.saveAssessment()` writes to `assessments/{uid}/sessions/{id}` and the document is readable via `loadAssessment()`
- `FirestoreService.saveReport()` writes to `reports/{uid}/sessions/{assessmentId}` with correct field mapping
- `FirestoreService.uploadPdf()` stores the file in Firebase Storage at `reports/{uid}/{assessmentId}.pdf` and returns a valid download URL
- `FirestoreService.syncLocalAssessments()` uploads locally-cached assessments that are missing from Firestore without duplicating existing ones
- All Firestore operations fail with a clear error if `AuthService.uid` is null (not signed in)
- JSON serialization round-trips all model types without data loss — enums, DateTimes, Durations, nested lists all survive serialize/deserialize

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
- AuthService wraps FirebaseAuth with constructor injection (testable)
- LocalStorageService uses path_provider and accepts Directory override (testable)
- FirestoreService uses constructor-injected dependencies (testable)
- JSON serialization covers all model types including nested objects
- Firestore paths match the specified collection structure
- Sync logic handles per-assessment errors without blocking the batch
<!-- TESTER_ONLY -->
test_files: test/core/services/auth_service_test.dart, test/core/services/firestore_service_test.dart

### auth_service_test.dart
- Test `signIn()` calls `signInAnonymously()` and returns UID from the UserCredential
- Test `signIn()` when already signed in returns existing UID without calling `signInAnonymously()` again
- Test `uid` returns null before sign-in and non-null after
- Test `isSignedIn` returns false before sign-in, true after
- Test `authStateChanges` emits UID on sign-in
- Test `signOut()` calls `FirebaseAuth.signOut()` and `uid` becomes null
- Mock `FirebaseAuth` — inject via constructor, never hit real Firebase

### firestore_service_test.dart
- Test `saveAssessment()` writes to correct Firestore path `assessments/{uid}/sessions/{id}`
- Test `loadAssessment()` returns null for non-existent document
- Test `loadAssessment()` round-trips an Assessment through save then load
- Test `listAssessments()` returns documents ordered by `createdAt` descending
- Test `saveReport()` writes to correct path `reports/{uid}/sessions/{assessmentId}`
- Test `uploadPdf()` uploads to correct Storage path and returns a download URL string
- Test `syncLocalAssessments()` uploads assessments that are missing from Firestore
- Test `syncLocalAssessments()` skips assessments that already exist in Firestore
- Test all methods throw when `AuthService.uid` is null
- Mock `FirebaseFirestore`, `FirebaseStorage`, `AuthService` — inject via constructor
<!-- END_TESTER_ONLY -->
