# Bootstrap — Flutter Project Scaffold
Story: story-1293
Agent: architect

## Context
Initialize the AuraLink Flutter project from scratch: project structure, all dependencies, shared domain models, routing, theme, Firebase config, and Riverpod DI. This is the foundation every downstream feature imports from. No existing code — pure greenfield.

Files:
- lib/core/router.dart
- lib/core/theme.dart
- lib/core/providers.dart
- lib/domain/models.dart
- pubspec.yaml
- firebase.json
- analysis_options.yaml

## What changes
| File | Change |
|---|---|
| pubspec.yaml | Full dependency manifest — flutter_riverpod, go_router, camera, google_mlkit_pose_detection, firebase_core, firebase_auth, cloud_firestore, firebase_storage, pdf, share_plus, path_provider, freezed_annotation, json_annotation + dev deps (freezed, json_serializable, build_runner) with pinned versions |
| analysis_options.yaml | Dart recommended lints + project-specific rules (require_trailing_commas, prefer_const_constructors, avoid_print) |
| firebase.json | Firebase Hosting configuration pointing to build/web, Firestore and Storage deploy targets |
| lib/domain/models.dart | All shared domain model classes: Landmark, JointAngle, Compensation, Assessment, Movement, Report, Finding, Citation + enums MovementType, CompensationType, ChainType, ConfidenceLevel, CitationType |
| lib/core/router.dart | GoRouter config with routes: / (splash), /camera, /screening, /report/:id |
| lib/core/theme.dart | AuraLink ThemeData — brand colors, confidence colors (green >0.9, yellow 0.7-0.9, red <0.7), typography scale |
| lib/core/providers.dart | Global Riverpod providers for PoseEstimationService, AngleCalculator, ChainMapper, FirestoreService, AuthService, LocalStorageService — all initially throw UnimplementedError, overridden per-story |

<!-- CODER_ONLY -->
## Read-only context
- presearch/auralink-product.md (technical briefing)

## Tasks
1. Run `flutter create --org com.auralink --platforms ios,android,web auralink` in the project root. Move generated contents to project root if nested.
2. Replace the generated `pubspec.yaml` with the full dependency manifest:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_riverpod: ^2.5.0
     go_router: ^14.0.0
     camera: ^0.11.0
     google_mlkit_pose_detection: ^0.11.0
     firebase_core: ^3.0.0
     firebase_auth: ^5.0.0
     cloud_firestore: ^5.0.0
     firebase_storage: ^12.0.0
     pdf: ^3.10.0
     share_plus: ^9.0.0
     path_provider: ^2.1.0
     freezed_annotation: ^2.4.0
     json_annotation: ^4.9.0
   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^5.0.0
     freezed: ^2.5.0
     json_serializable: ^6.8.0
     build_runner: ^2.4.0
   ```
3. Create `analysis_options.yaml` extending `flutter_lints` with project rules: `require_trailing_commas`, `prefer_const_constructors`, `avoid_print`.
4. Create `firebase.json` with hosting config (`public: build/web`, rewrites to `index.html`), plus empty Firestore and Storage deploy targets.
5. Create `lib/domain/models.dart` with all shared types:
   - **Enums**: `MovementType` (overheadSquat, singleLegBalance, overheadReach, forwardFold), `CompensationType` (kneeValgus, hipDrop, ankleRestriction, trunkLean), `ChainType` (sbl, bfl, ffl), `ConfidenceLevel` (high, medium, low), `CitationType` (research, clinical, guideline)
   - **Classes** (immutable, with `const` constructors and named parameters):
     - `Landmark` — `double x, y, z, visibility`
     - `JointAngle` — `String joint, double angleDegrees, ConfidenceLevel confidence`
     - `Compensation` — `CompensationType type, String joint, ChainType? chain, ConfidenceLevel confidence, double value, double threshold, Citation citation`
     - `Movement` — `MovementType type, List<List<Landmark>> landmarks, List<JointAngle> keyframeAngles, Duration duration`
     - `Citation` — `String finding, String source, String url, CitationType type, String appUsage`
     - `Finding` — `String bodyPathDescription, List<Compensation> compensations, String? upstreamDriver, String recommendation, List<Citation> citations`
     - `Report` — `List<Finding> findings, List<String> practitionerPoints, String? pdfUrl`
     - `Assessment` — `String id, DateTime createdAt, List<Movement> movements, List<Compensation> compensations, Report? report`
6. Create `lib/core/router.dart`:
   - `GoRouter` with 4 routes: `/` (SplashView placeholder), `/camera` (CameraView placeholder), `/screening` (ScreeningView placeholder), `/report/:id` (ReportView placeholder)
   - Placeholder screens are simple `Scaffold` + `Center(child: Text('ScreenName'))` — downstream stories replace them
   - Export the router as a `final goRouter` top-level variable
7. Create `lib/core/theme.dart`:
   - `AuraLinkTheme` class with static `ThemeData get lightTheme`
   - Brand primary: deep teal `Color(0xFF00695C)`, secondary: warm coral `Color(0xFFFF6B6B)`
   - Confidence semantic colors as static `Color` constants: `confidenceHigh` = green `Color(0xFF4CAF50)`, `confidenceMedium` = amber `Color(0xFFFFC107)`, `confidenceLow` = red `Color(0xFFF44336)`
   - Confidence thresholds as static constants: `highThreshold = 0.9`, `mediumThreshold = 0.7`
   - Static helper `Color confidenceColor(double visibility)` that returns the correct color for a visibility score
   - Typography: `GoogleFonts` or default Material with body/title/headline sizing
8. Create `lib/core/providers.dart`:
   - Import `flutter_riverpod`
   - Placeholder providers that throw `UnimplementedError('Provided by story-XXXX')` for: `poseEstimationServiceProvider`, `angleCalculatorProvider`, `chainMapperProvider`, `firestoreServiceProvider`, `authServiceProvider`, `localStorageServiceProvider`
   - Each provider typed to return the corresponding abstract interface (defined as `abstract class` stubs at top of file or imported from domain)
9. Update `lib/main.dart` to wrap the app in `ProviderScope`, use `MaterialApp.router` with `AuraLinkTheme.lightTheme` and the `goRouter` config.
<!-- END_CODER_ONLY -->

## Contract
Exported types consumed by downstream stories:

```dart
// lib/domain/models.dart
enum MovementType { overheadSquat, singleLegBalance, overheadReach, forwardFold }
enum CompensationType { kneeValgus, hipDrop, ankleRestriction, trunkLean }
enum ChainType { sbl, bfl, ffl }
enum ConfidenceLevel { high, medium, low }
enum CitationType { research, clinical, guideline }

class Landmark { final double x, y, z, visibility; }
class JointAngle { final String joint; final double angleDegrees; final ConfidenceLevel confidence; }
class Compensation { final CompensationType type; final String joint; final ChainType? chain; final ConfidenceLevel confidence; final double value; final double threshold; final Citation citation; }
class Movement { final MovementType type; final List<List<Landmark>> landmarks; final List<JointAngle> keyframeAngles; final Duration duration; }
class Citation { final String finding; final String source; final String url; final CitationType type; final String appUsage; }
class Finding { final String bodyPathDescription; final List<Compensation> compensations; final String? upstreamDriver; final String recommendation; final List<Citation> citations; }
class Report { final List<Finding> findings; final List<String> practitionerPoints; final String? pdfUrl; }
class Assessment { final String id; final DateTime createdAt; final List<Movement> movements; final List<Compensation> compensations; final Report? report; }

// lib/core/theme.dart
class AuraLinkTheme {
  static ThemeData get lightTheme;
  static const Color confidenceHigh;   // green — visibility > 0.9
  static const Color confidenceMedium; // amber — visibility 0.7–0.9
  static const Color confidenceLow;    // red   — visibility < 0.7
  static const double highThreshold;   // 0.9
  static const double mediumThreshold; // 0.7
  static Color confidenceColor(double visibility);
}

// lib/core/router.dart
final GoRouter goRouter; // routes: /, /camera, /screening, /report/:id

// lib/core/providers.dart
final Provider<PoseEstimationService> poseEstimationServiceProvider;
final Provider<AngleCalculator> angleCalculatorProvider;
final Provider<ChainMapper> chainMapperProvider;
final Provider<FirestoreService> firestoreServiceProvider;
final Provider<AuthService> authServiceProvider;
final Provider<LocalStorageService> localStorageServiceProvider;
```

## Acceptance criteria
- `flutter create` project compiles for iOS, Android, and Web targets without errors
- `pubspec.yaml` contains all 13 runtime dependencies and 4 dev dependencies at specified versions
- `analysis_options.yaml` enforces require_trailing_commas, prefer_const_constructors, avoid_print
- `firebase.json` has hosting, Firestore, and Storage deploy configuration
- All 8 domain model classes and 5 enums are defined with const constructors and correct field types
- GoRouter has 4 routes (/, /camera, /screening, /report/:id) and app navigates to each without crash
- Theme includes brand colors, 3 confidence colors, thresholds (0.9/0.7), and `confidenceColor()` helper
- 6 Riverpod providers declared and typed — each throws UnimplementedError until downstream stories override
- `main.dart` uses ProviderScope + MaterialApp.router with theme and router wired in
- `flutter analyze` reports no errors (warnings acceptable for unused imports in placeholder files)

## Verification
- Confirm each task implemented correctly
- No changes outside write scope
<!-- TESTER_ONLY -->
needs_testing: false (scaffold/boilerplate)
<!-- END_TESTER_ONLY -->
