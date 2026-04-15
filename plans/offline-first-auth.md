# Offline-First Auth & Privacy Disclaimer
Story: story-1299
Agent: architect

## Context
Remove the anonymous Firebase Auth dependency from the default app flow. The app becomes 100% offline-first -- all data stays on-device by default. Cloud sync is opt-in only, requiring explicit user consent and future account creation. AuthService stays in the codebase but leaves the provider graph until the user opts in. The privacy disclaimer must say "all data stays on your device by default" and link to privacy policy and terms of service.

Depends: story-1301 (renames MockChainMapper/MockAngleCalculator to RuleBasedChainMapper/RuleBasedAngleCalculator)
Cross-story: story-1309 tests that cloud sync does not fire without opt-in consent

Files:
- lib/core/providers.dart
- lib/features/onboarding/views/disclaimer_view.dart
- lib/core/services/auth_service.dart
- lib/core/services/firestore_service.dart
- pubspec.yaml (add `url_launcher` direct dependency)

## What changes
| File | Change |
|---|---|
| `lib/core/providers.dart` | Remove `authServiceProvider` and `firestoreServiceProvider` from the global provider graph. Add `cloudSyncEnabledProvider` (StateProvider<bool>, default false). Add lazy `authServiceProvider` and `firestoreServiceProvider` that are only usable when cloud sync is enabled. Update mock imports to use new paths from story-1301 (`RuleBasedChainMapper`, `RuleBasedAngleCalculator` from `domain/services/`). |
| `lib/features/onboarding/views/disclaimer_view.dart` | Update "Your Privacy" section to state "all data stays on your device by default". Add new "Data & Cloud Sync" section explaining opt-in cloud sync. Add tappable privacy policy and terms of service links (placeholder URLs). Keep existing scroll-to-bottom + "I Understand" gate. |
| `lib/core/services/auth_service.dart` | No structural changes to the class. Add doc comment clarifying this service is NOT auto-instantiated -- only created when user opts into cloud sync. Remove `signIn()` auto-call pattern; rename to `signInAnonymously()` is NOT needed since the class is already correct. Keep as-is with documentation update only. |
| `lib/core/services/firestore_service.dart` | Add `cloudSyncEnabled` guard to every public method. When cloud sync is not enabled, all operations throw `StateError('Cloud sync is not enabled')` or return early (no-op for writes, null/empty for reads). The guard checks a `bool` passed at construction or read from a callback. |
| `pubspec.yaml` | Add `url_launcher: ^6.2.0` to dependencies for privacy policy / terms links. |

## Architecture (Claude)

### Provider graph change

**Before** (current):
```
authServiceProvider ──────────────┐
                                  ▼
firestoreServiceProvider ←── FirebaseAuth.instance
                         ←── FirebaseFirestore.instance
                         ←── FirebaseStorage.instance
localStorageServiceProvider       (always available)
```

**After** (this story):
```
cloudSyncEnabledProvider (StateProvider<bool>, default false)

localStorageServiceProvider       (always available, primary persistence)

authServiceProvider ──── late, only created when cloudSyncEnabled == true
firestoreServiceProvider ── late, only created when cloudSyncEnabled == true
                            guards every public method with consent check
```

The `cloudSyncEnabledProvider` is a simple `StateProvider<bool>` defaulting to `false`. No `shared_preferences` dependency needed -- this is a runtime toggle. Persisting the preference across sessions is out of scope (future story for account creation + settings screen). For now, cloud sync is always off at app start and can only be toggled on by an explicit user action.

### FirestoreService guard pattern

Every public method in FirestoreService gains a leading guard:
```dart
void _requireCloudSync() {
  if (!_cloudSyncEnabled) {
    throw StateError('Cloud sync is not enabled — user has not opted in');
  }
}
```
The `_cloudSyncEnabled` flag is injected via constructor. When the provider is not in the graph (cloud sync off), the service instance doesn't exist at all -- but the guard is defense-in-depth for story-1309's test assertions.

### DisclaimerView privacy section

The existing "Your Privacy" section is updated. A new section "Data & Cloud Sync" is added before the button. Links open via `url_launcher`'s `launchUrl()`. Placeholder URLs point to `https://bioliminal.app/privacy` and `https://bioliminal.app/terms`.

### Import update for story-1301 seam

`providers.dart` currently imports:
```dart
import 'package:bioliminal/domain/mocks/mock_angle_calculator.dart';
import 'package:bioliminal/domain/mocks/mock_chain_mapper.dart';
```
After story-1301 these become:
```dart
import 'package:bioliminal/domain/services/rule_based_angle_calculator.dart';
import 'package:bioliminal/domain/services/rule_based_chain_mapper.dart';
```
And provider constructors change from `MockAngleCalculator()` / `MockChainMapper()` to `RuleBasedAngleCalculator()` / `RuleBasedChainMapper()`.

<!-- CODER_ONLY -->
## Read-only context
- lib/core/services/local_storage_service.dart (unchanged, remains primary persistence)
- lib/core/router.dart (unchanged -- no new routes in this story)
- lib/core/theme.dart (for styling constants)
- lib/main.dart (Firebase.initializeApp stays -- needed even if auth is lazy, for Firestore offline SDK)
- plans/data-persistence.md (original auth/persistence architecture for reference)

## Tasks
1. **Add `url_launcher` to pubspec.yaml** -- Add `url_launcher: ^6.2.0` under `dependencies` after `path_provider`.

2. **Update `lib/core/providers.dart`** -- Remove `firebase_auth` import and direct `AuthService` instantiation from the global graph. Changes:
   - Remove `import 'package:firebase_auth/firebase_auth.dart';` (no longer needed at top level).
   - Keep `import 'package:cloud_firestore/cloud_firestore.dart';` and `import 'package:firebase_storage/firebase_storage.dart';` -- these are still needed for the lazy provider.
   - Update mock imports to story-1301 new paths:
     - `import 'package:bioliminal/domain/mocks/mock_angle_calculator.dart';` -> `import 'package:bioliminal/domain/services/rule_based_angle_calculator.dart';`
     - `import 'package:bioliminal/domain/mocks/mock_chain_mapper.dart';` -> `import 'package:bioliminal/domain/services/rule_based_chain_mapper.dart';`
   - Add `cloudSyncEnabledProvider`:
     ```dart
     final cloudSyncEnabledProvider = StateProvider<bool>((ref) => false);
     ```
   - Replace `authServiceProvider` -- change from eagerly constructing `AuthService(FirebaseAuth.instance)` to a provider that throws if cloud sync is not enabled:
     ```dart
     final authServiceProvider = Provider<AuthService>((ref) {
       final enabled = ref.watch(cloudSyncEnabledProvider);
       if (!enabled) {
         throw StateError('AuthService unavailable — cloud sync not enabled');
       }
       return AuthService(FirebaseAuth.instance);
     });
     ```
     NOTE: Keep the `firebase_auth` import since AuthService constructor still needs it when cloud sync IS enabled. Correction to the remove-import instruction above: keep `import 'package:firebase_auth/firebase_auth.dart';`.
   - Replace `firestoreServiceProvider` similarly:
     ```dart
     final firestoreServiceProvider = Provider<firestore_impl.FirestoreService>((ref) {
       final enabled = ref.watch(cloudSyncEnabledProvider);
       if (!enabled) {
         throw StateError('FirestoreService unavailable — cloud sync not enabled');
       }
       return firestore_impl.FirestoreService(
         FirebaseFirestore.instance,
         FirebaseStorage.instance,
         ref.read(authServiceProvider),
       );
     });
     ```
   - Update `angleCalculatorProvider` and `chainMapperProvider` to use renamed classes:
     ```dart
     final angleCalculatorProvider = Provider<angle_service.AngleCalculator>(
       (ref) => RuleBasedAngleCalculator(),
     );
     final chainMapperProvider = Provider<chain_service.ChainMapper>(
       (ref) => RuleBasedChainMapper(),
     );
     ```
   - `localStorageServiceProvider` stays exactly as-is -- it's the primary persistence layer.

3. **Update `lib/core/services/firestore_service.dart`** -- Add cloud-sync guard to every public method. Changes:
   - Add `final bool _cloudSyncEnabled;` field.
   - Update constructor: `FirestoreService(this._firestore, this._storage, this._auth, {bool cloudSyncEnabled = false}) : _cloudSyncEnabled = cloudSyncEnabled;`
   - Add private guard method:
     ```dart
     void _requireCloudSync() {
       if (!_cloudSyncEnabled) {
         throw StateError('Cloud sync not enabled — user has not opted in');
       }
     }
     ```
   - Add `_requireCloudSync()` as the first line in: `saveAssessment`, `loadAssessment`, `listAssessments`, `deleteAssessment`, `saveReport`, `loadReport`, `uploadPdf`, `syncLocalAssessments`.
   - Update the provider construction in task 2 to pass `cloudSyncEnabled: true` when creating the instance.

4. **Update `lib/core/services/auth_service.dart`** -- Documentation-only change. Add class-level doc comment:
   ```dart
   /// Firebase authentication service — NOT in the default provider graph.
   ///
   /// Only instantiated when user explicitly opts into cloud sync.
   /// All app functionality works offline-first via [LocalStorageService]
   /// without this service.
   ```
   No API changes.

5. **Update `lib/features/onboarding/views/disclaimer_view.dart`** -- Privacy messaging and links. Changes:
   - Add `import 'package:url_launcher/url_launcher.dart';`.
   - Update the "Your Privacy" section body text to:
     `'All data stays on your device by default. Movement analysis '`
     `'happens entirely on-device — no video or personal data is '`
     `'stored on external servers. You control whether to save or '`
     `'share your report.'`
   - Add a new `_section` after "Your Privacy" titled "Data & Cloud Sync" with body:
     `'Bioliminal works fully offline. Cloud backup is an optional '`
     `'feature that requires creating an account and giving explicit '`
     `'consent. You can enable it later in Settings if you choose.'`
   - After the "Data & Cloud Sync" section, add tappable links for Privacy Policy and Terms of Service:
     ```dart
     _linkRow('Privacy Policy', Uri.parse('https://bioliminal.app/privacy'), theme),
     _linkRow('Terms of Service', Uri.parse('https://bioliminal.app/terms'), theme),
     ```
   - Add `_linkRow` helper method:
     ```dart
     Widget _linkRow(String label, Uri url, ThemeData theme) {
       return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: GestureDetector(
           onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
           child: Text(
             label,
             style: theme.textTheme.bodyMedium?.copyWith(
               color: theme.colorScheme.primary,
               decoration: TextDecoration.underline,
             ),
           ),
         ),
       );
     }
     ```
   - Keep scroll-to-bottom gating and "I Understand" button unchanged.
<!-- END_CODER_ONLY -->

## Contract

### New providers (lib/core/providers.dart)
```dart
final cloudSyncEnabledProvider = StateProvider<bool>((ref) => false);

// authServiceProvider — throws StateError when cloudSyncEnabled is false
final authServiceProvider = Provider<AuthService>((ref) { ... });

// firestoreServiceProvider — throws StateError when cloudSyncEnabled is false
final firestoreServiceProvider = Provider<FirestoreService>((ref) { ... });
```

### FirestoreService (updated constructor)
```dart
class FirestoreService {
  FirestoreService(
    FirebaseFirestore firestore,
    FirebaseStorage storage,
    AuthService auth, {
    bool cloudSyncEnabled = false,
  });

  // All existing public methods unchanged in signature.
  // All throw StateError when cloudSyncEnabled is false.
}
```

### AuthService (unchanged API)
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

### DisclaimerView (unchanged public API)
```dart
class DisclaimerView extends StatefulWidget { ... }
// Internal additions:
// Widget _linkRow(String label, Uri url, ThemeData theme)
```

## Acceptance criteria
- Given the app launches fresh, when the provider graph initializes, then `cloudSyncEnabledProvider` is `false` and reading `authServiceProvider` throws `StateError`
- Given cloud sync is disabled, when any FirestoreService public method is called, then it throws `StateError('Cloud sync not enabled')`
- Given the user opens the disclaimer screen, when they read the "Your Privacy" section, then it says "All data stays on your device by default"
- Given the user is on the disclaimer screen, when they see the "Data & Cloud Sync" section, then it explains cloud backup is optional and requires explicit consent
- Given the user taps "Privacy Policy" on the disclaimer screen, then `url_launcher` opens `https://bioliminal.app/privacy` in an external browser
- Given the user taps "Terms of Service" on the disclaimer screen, then `url_launcher` opens `https://bioliminal.app/terms` in an external browser
- Given the user scrolls to the bottom and taps "I Understand", then navigation proceeds to `/screening` as before (no auth call)
- Given `cloudSyncEnabledProvider` is set to `true`, when `authServiceProvider` is read, then it returns a valid `AuthService` instance
- Given `cloudSyncEnabledProvider` is set to `true`, when `firestoreServiceProvider` is read, then it returns a `FirestoreService` with `cloudSyncEnabled: true`
- Given the app is running offline, when the user completes a screening, then data persists via `LocalStorageService` without any Firebase calls

## Verification
- Confirm `authServiceProvider` and `firestoreServiceProvider` are gated behind `cloudSyncEnabledProvider`
- Confirm no code path calls `signInAnonymously()` at app startup
- Confirm `FirestoreService` guards all public methods
- Confirm DisclaimerView privacy text says "on your device by default"
- Confirm privacy policy and terms links are tappable and use `url_launcher`
- Confirm `providers.dart` imports from story-1301 renamed paths
- Confirm `pubspec.yaml` includes `url_launcher`
- No changes outside write scope
<!-- TESTER_ONLY -->
test_files: test/core/providers_test.dart, test/core/services/firestore_service_test.dart

### providers_test.dart
- Test `cloudSyncEnabledProvider` defaults to false
- Test reading `authServiceProvider` when cloud sync disabled throws StateError
- Test reading `firestoreServiceProvider` when cloud sync disabled throws StateError
- Test setting `cloudSyncEnabledProvider` to true allows reading `authServiceProvider` (mock FirebaseAuth needed)
- Test `localStorageServiceProvider` is always available regardless of cloud sync state

### firestore_service_test.dart (additions to existing)
- Test every public method throws StateError when `cloudSyncEnabled: false`
- Test every public method proceeds normally when `cloudSyncEnabled: true` and auth is valid
- These tests support story-1309's assertion that cloud sync doesn't fire without opt-in
<!-- END_TESTER_ONLY -->
