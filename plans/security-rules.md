# Security Rules — Schema Validation and Storage Limits
Story: story-1305
Agent: architect

## Context
Current Firestore and Storage rules only check `request.auth != null && request.auth.uid == uid`. This story adds schema validation to Firestore writes (field allowlists, type checks) and enforces size/content-type limits on Storage uploads. These rules apply when cloud sync is opted in (story-1299 handles opt-in); they are defense-in-depth against malformed data reaching the backend.

Depends: story-1298 (Data Persistence — defines Firestore paths and serialization format)
Blocks: none

Files:
- firestore.rules
- storage.rules

## What changes
| File | Change |
|---|---|
| `firestore.rules` | Replace blanket `allow write` with `allow create, update` guarded by schema validation functions. Keep `allow read` and `allow delete` as auth-only. Add helper functions: `isValidAssessment()`, `isValidReport()` that check top-level field names (allowlist via `hasOnly`), required field presence (`hasAll`), and field types. |
| `storage.rules` | Add `request.resource.size < 10 * 1024 * 1024` (10MB) and `request.resource.contentType == 'application/pdf'` to the write rule. Restrict path to single file (no wildcard subdirectories). |

## Architecture (Claude)

### Firestore validation depth
Firestore security rules can't recursively validate arbitrary-depth nested structures without hitting expression complexity limits. The validation strategy is:

- **Top-level fields**: Strict allowlist and type checks. No extra fields allowed.
- **First-level nested objects** (e.g., items within `movements` list, items within `compensations` list): Validate that the field is a `list` type. Do NOT attempt to validate the schema of individual list items — Firestore rules can't iterate lists to check each element's shape without `get()` per-index, which is both fragile and hits read limits.
- **Report map**: Validate it's a `map` (or null) with expected top-level keys when present.

This is the standard Firestore approach. Deep validation of nested objects belongs in application-layer code or Cloud Functions, not security rules.

### Assessment document schema (`/assessments/{uid}/sessions/{doc}`)
Expected fields from `_assessmentToFirestore()`:
- `id` — string
- `createdAt` — timestamp (Firestore Timestamp, converted from DateTime by the service)
- `movements` — list
- `compensations` — list
- `report` — map or null

### Report document schema (`/reports/{uid}/sessions/{doc}`)
Expected fields from `_reportToFirestore()` (which calls `reportToJson()`):
- `findings` — list
- `practitionerPoints` — list
- `pdfUrl` — string or null

### Storage path
Only `reports/{uid}/{assessmentId}.pdf`. The current rules use `{allPaths=**}` wildcard — tighten to a single filename segment `{fileName}` and validate the `.pdf` extension.

<!-- CODER_ONLY -->
## Read-only context
- lib/core/services/firestore_service.dart — `_assessmentToFirestore()` (line 36) shows the exact field map written to Firestore; `_reportToFirestore()` (line 53) delegates to `reportToJson()`
- lib/core/services/local_storage_service.dart — `assessmentToJson()` (line 133) and `reportToJson()` (line 118) show the exact field names and types serialized

## Tasks
1. **Firestore assessment validation function** — In `firestore.rules`, add a `function isValidAssessment(data)` inside the `match /databases/{database}/documents` block. Checks:
   - `data.keys().hasOnly(['id', 'createdAt', 'movements', 'compensations', 'report'])` — no extra fields
   - `data.keys().hasAll(['id', 'createdAt', 'movements', 'compensations'])` — required fields present (`report` is optional)
   - `data.id is string`
   - `data.createdAt is timestamp`
   - `data.movements is list`
   - `data.compensations is list`
   - `data.report == null || data.report is map` — nullable map

2. **Firestore report validation function** — Add `function isValidReport(data)` in the same scope. Checks:
   - `data.keys().hasOnly(['findings', 'practitionerPoints', 'pdfUrl'])` — no extra fields
   - `data.keys().hasAll(['findings', 'practitionerPoints'])` — required fields present (`pdfUrl` is optional)
   - `data.findings is list`
   - `data.practitionerPoints is list`
   - `!('pdfUrl' in data.keys()) || data.pdfUrl == null || data.pdfUrl is string` — key absent, null, or string are all valid

3. **Assessment write rule** — Replace `allow read, write: if ...` for the assessments match with:
   - `allow read, delete: if request.auth != null && request.auth.uid == uid;`
   - `allow create, update: if request.auth != null && request.auth.uid == uid && isValidAssessment(request.resource.data);`

4. **Report write rule** — Same pattern for the reports match:
   - `allow read, delete: if request.auth != null && request.auth.uid == uid;`
   - `allow create, update: if request.auth != null && request.auth.uid == uid && isValidReport(request.resource.data);`
   - Additionally: the `pdfUrl` update path (line 125 of firestore_service.dart) uses `.update({'pdfUrl': url})` which is a partial update. Firestore `update()` triggers the `update` rule, and `request.resource.data` contains the full document after the merge, so `isValidReport()` will still see all fields. No special handling needed.

5. **Storage rules — size and type limits** — Replace the storage rules:
   - Change the match from `match /reports/{uid}/{allPaths=**}` to `match /reports/{uid}/{fileName}` — removes ability to write into subdirectories
   - Write rule: `allow write: if request.auth != null && request.auth.uid == uid && request.resource.size < 10 * 1024 * 1024 && request.resource.contentType == 'application/pdf';`
   - Read/delete rule: `allow read, delete: if request.auth != null && request.auth.uid == uid;`
   - Optionally validate that `fileName` ends with `.pdf`: `&& fileName.matches('.*\\.pdf$')` — adds defense against non-PDF paths

## Final file contents

### firestore.rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isValidAssessment(data) {
      return data.keys().hasOnly(['id', 'createdAt', 'movements', 'compensations', 'report'])
          && data.keys().hasAll(['id', 'createdAt', 'movements', 'compensations'])
          && data.id is string
          && data.createdAt is timestamp
          && data.movements is list
          && data.compensations is list
          && (data.report == null || data.report is map);
    }

    function isValidReport(data) {
      return data.keys().hasOnly(['findings', 'practitionerPoints', 'pdfUrl'])
          && data.keys().hasAll(['findings', 'practitionerPoints'])
          && data.findings is list
          && data.practitionerPoints is list
          && (!('pdfUrl' in data.keys()) || data.pdfUrl == null || data.pdfUrl is string);
    }

    match /assessments/{uid}/sessions/{doc} {
      allow read, delete: if request.auth != null && request.auth.uid == uid;
      allow create, update: if request.auth != null
                            && request.auth.uid == uid
                            && isValidAssessment(request.resource.data);
    }

    match /reports/{uid}/sessions/{doc} {
      allow read, delete: if request.auth != null && request.auth.uid == uid;
      allow create, update: if request.auth != null
                            && request.auth.uid == uid
                            && isValidReport(request.resource.data);
    }
  }
}
```

### storage.rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{uid}/{fileName} {
      allow read, delete: if request.auth != null && request.auth.uid == uid;
      allow write: if request.auth != null
                   && request.auth.uid == uid
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType == 'application/pdf'
                   && fileName.matches('.*\\.pdf$');
    }
  }
}
```
<!-- END_CODER_ONLY -->

## Acceptance criteria
- Firestore rejects assessment writes that contain fields outside `{id, createdAt, movements, compensations, report}`
- Firestore rejects assessment writes missing any of `{id, createdAt, movements, compensations}`
- Firestore rejects assessment writes where `id` is not a string, `createdAt` is not a timestamp, `movements` is not a list, or `compensations` is not a list
- Firestore rejects assessment writes where `report` is present but is neither null nor a map
- Firestore rejects report writes that contain fields outside `{findings, practitionerPoints, pdfUrl}`
- Firestore rejects report writes missing `findings` or `practitionerPoints`
- Firestore rejects report writes where `findings` is not a list or `practitionerPoints` is not a list
- Firestore rejects report writes where `pdfUrl` is present and not a string
- Firestore allows deletes with only auth check (no schema validation on delete)
- Storage rejects uploads larger than 10MB
- Storage rejects uploads with content type other than `application/pdf`
- Storage rejects uploads to paths that don't match `reports/{uid}/{fileName}.pdf`
- Storage rejects writes to subdirectories under `reports/{uid}/` (no nested paths)
- All existing reads and deletes continue to work with auth-only checks
- The `FirestoreService.uploadPdf()` partial update (`update({'pdfUrl': url})`) still succeeds because the merged document satisfies `isValidReport()`

## Verification
- Confirm `firestore.rules` contains `isValidAssessment` and `isValidReport` functions
- Confirm assessment match splits `read, delete` from `create, update`
- Confirm report match splits `read, delete` from `create, update`
- Confirm storage match uses `{fileName}` not `{allPaths=**}`
- Confirm storage write rule includes size < 10MB, contentType == 'application/pdf', and fileName regex
- No changes outside `firestore.rules` and `storage.rules`

## Test plan
test_files: N/A — Firestore/Storage rules are tested via Firebase emulator integration tests, not Dart unit tests. Validation against acceptance criteria should use `firebase emulators:exec` with the Rules Unit Testing library (`@firebase/rules-unit-testing`).
