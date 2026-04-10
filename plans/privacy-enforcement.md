# Privacy & Cloud Sync Enforcement
Story: story-1323
Agent: quick-fixer

## Context
The app claims "No data leaves your phone" in the disclaimer, but FirestoreService and AuthService are fully wired and importable. While they throw StateError when cloudSyncEnabled is false, the Firebase SDK packages are still initialized at app startup (FirebaseAuth.instance, FirebaseFirestore.instance are referenced in providers.dart). This is a trust contradiction — a premium health app cannot have any cloud infrastructure that activates without explicit, high-friction user consent.

## What changes
| File | Change |
|---|---|
| `lib/core/providers.dart` | Lazy-initialize Firebase instances: move FirebaseAuth.instance and FirebaseFirestore.instance/FirebaseStorage.instance from provider bodies into a dedicated _initFirebase() method that's only called when cloud sync is explicitly enabled. Guard with a confirmation flag. Remove top-level firebase imports that cause SDK initialization on app start. |
| `lib/core/services/auth_service.dart` | Accept FirebaseAuth as a constructor parameter (already does). No changes to API, but ensure the class doesn't import or reference Firebase at the top level beyond its constructor parameter type. |
| `lib/core/services/firestore_service.dart` | Accept FirebaseFirestore and FirebaseStorage as constructor parameters (already does). Ensure no top-level Firebase initialization. Add a comment documenting that this service is only instantiated after explicit user opt-in. |
| `lib/features/settings/widgets/cloud_sync_dialog.dart` | New. High-friction opt-in dialog: explains what data will be synced, requires typing "SYNC" to confirm (not just a toggle). On confirm, calls CloudSyncNotifier.enable(). Shows what gets synced (assessment data, not video/images). Includes a "Learn more" link to privacy policy. |

## Acceptance criteria
- App launches with zero Firebase SDK calls (no FirebaseAuth.instance, no FirebaseFirestore.instance accessed until user opts in)
- Attempting to read authServiceProvider or firestoreServiceProvider with cloud sync disabled throws StateError (existing behavior, verify preserved)
- Cloud sync opt-in requires user to type "SYNC" in the confirmation dialog before enabling
- After opt-in, Firebase services initialize and function correctly
- The confirmation dialog clearly states what data is synced and that it's reversible
- No Firebase imports at the top level of providers.dart trigger SDK initialization

## Architecture notes
- The key change in providers.dart is deferring Firebase.instance calls behind the cloudSyncEnabled check — currently the provider body references them but the StateError prevents the return. The issue is that simply referencing FirebaseAuth.instance can trigger SDK initialization depending on the Firebase plugin version.
- cloud_sync_dialog.dart lives in settings/ because it's a settings-level action, not onboarding
- The "SYNC" confirmation pattern is intentionally high-friction — this is a health data app where trust is paramount
