# Dead Code Cleanup
Story: story-1306
Agent: quick-fixer

## Context
Bootstrap scaffold (story-1293) left behind dead code: an unreachable `_SplashView` on `/`, a test that asserts against it, and code-gen deps (`freezed`, `json_serializable`, `build_runner`, `freezed_annotation`, `json_annotation`) that were never wired up. This story removes all of it and adds `app_settings` — a dependency story-1303 (camera lifecycle fixes) is blocked on.

Files:
- lib/core/router.dart
- pubspec.yaml
- test/widget_test.dart

## What changes
| File | Change |
|---|---|
| lib/core/router.dart | Remove `_SplashView` class and the `/` GoRoute entry. Keep all other routes intact. |
| pubspec.yaml | Remove `freezed_annotation` and `json_annotation` from dependencies. Remove `freezed`, `json_serializable`, and `build_runner` from dev_dependencies. Add `app_settings: ^0.2.0` to dependencies. |
| test/widget_test.dart | Rewrite test to assert the app renders `DisclaimerView` content (`'Before We Begin'`) instead of the deleted `SplashView` text. |

<!-- CODER_ONLY -->
## Tasks
1. **router.dart** — Delete the `GoRoute(path: '/', ...)` entry (lines 13-15) and the entire `_SplashView` class (lines 37-46). Leave trailing blank lines clean.
2. **pubspec.yaml** — Remove these 5 lines:
   - `freezed_annotation: ^2.4.0` (line 23)
   - `json_annotation: ^4.9.0` (line 24)
   - `freezed: ^2.5.0` (line 30)
   - `json_serializable: ^6.8.0` (line 31)
   - `build_runner: ^2.4.0` (line 32)
   Add under dependencies (after `path_provider`):
   - `app_settings: ^0.2.0`
3. **widget_test.dart** — Replace the test body:
   - Change test description to `'App renders disclaimer view'`
   - After `pumpWidget`, add `await tester.pumpAndSettle();` (GoRouter needs a frame to resolve initialLocation)
   - Change assertion from `find.text('SplashView')` to `find.text('Before We Begin')`
<!-- END_CODER_ONLY -->

## Acceptance criteria
- No `/` route in router.dart; no `_SplashView` class anywhere in codebase
- `freezed_annotation`, `json_annotation`, `freezed`, `json_serializable`, `build_runner` absent from pubspec.yaml
- `app_settings` present in pubspec.yaml dependencies
- `widget_test.dart` asserts `DisclaimerView` renders (finds `'Before We Begin'`)
- No changes outside the three listed files

## Cross-story seam
- story-1303 (camera lifecycle) imports `app_settings` for `openAppSettings()`. This story unblocks it.

## Verification
- `flutter analyze` — no new errors
- `flutter test test/widget_test.dart` — passes
<!-- TESTER_ONLY -->
needs_testing: false (dead code removal + dep hygiene)
<!-- END_TESTER_ONLY -->
