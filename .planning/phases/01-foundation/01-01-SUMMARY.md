---
phase: 01-foundation
plan: 01
subsystem: scaffold
tags: [flutter, pubspec, linting, architecture, android, kotlin]
requirements: [DATA-01, UX-02]

dependency_graph:
  requires: []
  provides:
    - Flutter project scaffold (Android + iOS only)
    - pubspec.yaml with all Phase 1 dependencies locked
    - very_good_analysis strict linting active
    - Seven-layer directory structure under lib/
    - AppConfig, AppConstants, StorageKeys compile-time constants
    - DateTimeExtensions and StringExtensions utility extensions
    - FlutterFragmentActivity prerequisite for local_auth (Phase 5)
  affects:
    - All subsequent plans in Phase 1 (build on this scaffold)
    - Phase 5 (biometric auth — FlutterFragmentActivity already in place)

tech_stack:
  added:
    - flutter_bloc: 9.1.1
    - bloc: 9.2.0 (plan specified 9.1.1 — does not exist on pub.dev; 9.2.0 used)
    - equatable: 2.0.8
    - get_it: 9.2.1
    - injectable: 2.7.1+4
    - isar_community: 3.3.2
    - isar_community_flutter_libs: 3.3.2
    - go_router: 17.2.0
    - shared_preferences: 2.5.5
    - path_provider: 2.1.5
    - intl: 0.20.2
    - very_good_analysis: 10.2.0 (dev)
    - isar_community_generator: 3.3.2 (dev)
    - build_runner: ^2.13.1 (dev)
    - injectable_generator: 2.12.1 (dev)
    - bloc_test: 10.0.0 (dev)
    - mocktail: 1.0.5 (dev)
  patterns:
    - abstract final class for compile-time constant namespaces (AppConfig, AppConstants, StorageKeys)
    - Extension methods on DateTime and String for cross-layer utilities
    - Package imports (always_use_package_imports rule active)
    - Alphabetical dependency ordering in pubspec.yaml (sort_pub_dependencies rule active)

key_files:
  created:
    - pubspec.yaml (all Phase 1 deps locked; isar_community not abandoned isar)
    - analysis_options.yaml (very_good_analysis strict; generated files excluded)
    - lib/main.dart (minimal async main; DI placeholder comment for Plan 03)
    - lib/app.dart (bare MaterialApp shell; l10n/routing wired in later plans)
    - lib/core/config/app_config.dart (schemaVersion=1, appName, notification namespaces)
    - lib/core/constants/app_constants.dart (magic numbers: undo duration, 1-3-5 rule, budgets)
    - lib/core/constants/storage_keys.dart (SharedPreferences key strings)
    - lib/core/extensions/datetime_extensions.dart (startOfDay, endOfDay, isToday, isPast, isFuture)
    - lib/core/extensions/string_extensions.dart (isBlank, capitalised, isNullOrBlank)
    - lib/domain/.gitkeep
    - lib/data/.gitkeep
    - lib/infrastructure/.gitkeep
    - lib/application/.gitkeep
    - lib/presentation/.gitkeep
    - lib/config/.gitkeep
    - android/ (full Android scaffold)
    - ios/ (full iOS scaffold)
    - test/widget_test.dart (updated to use AgendaApp)
    - .gitignore (Flutter standard ignores)
  modified:
    - android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt (FlutterFragmentActivity swap)

decisions:
  - "bloc: 9.2.0 used instead of plan-specified 9.1.1 — version 9.1.1 does not exist on pub.dev; 9.2.0 is the actual release matching the flutter_bloc 9.1.1 companion"
  - "Dependency order in pubspec.yaml: flutter/flutter_localizations sdk entries interleaved alphabetically with regular deps to satisfy sort_pub_dependencies lint rule"
  - "Forward references ([MigrationRunner], [LocaleCubit]) removed from doc comments — classes not yet defined; plain text used to avoid comment_references lint and document_ignores overhead"

metrics:
  duration_minutes: 13
  completed_date: "2026-04-13"
  tasks_completed: 2
  tasks_total: 2
  files_created: 80
  files_modified: 2
---

# Phase 01 Plan 01: Flutter Project Scaffold Summary

**One-liner:** Flutter Android+iOS scaffold with isar_community 3.3.2, very_good_analysis strict linting, seven-layer clean architecture dirs, and FlutterFragmentActivity prerequisite for Phase 5 biometrics.

## What Was Built

A compilable Flutter shell (no feature logic) that:

1. Targets Android and iOS only — no web, linux, windows, or macOS directories
2. Pins all Phase 1 dependencies to exact versions in pubspec.yaml
3. Enforces very_good_analysis strict lint rules via analysis_options.yaml
4. Establishes the seven-layer clean architecture directory structure under `lib/`
5. Provides compile-time constant namespaces (AppConfig, AppConstants, StorageKeys)
6. Provides DateTime and String extension utilities used across all layers
7. Uses FlutterFragmentActivity (not FlutterActivity) — prerequisite for local_auth biometrics

## Packages Added

| Package | Version | Purpose |
|---------|---------|---------|
| `isar_community` | 3.3.2 | Local embedded database (community fork; original abandoned Apr 2023) |
| `isar_community_flutter_libs` | 3.3.2 | Binary companion for isar_community |
| `flutter_bloc` | 9.1.1 | BLoC/Cubit state management |
| `bloc` | 9.2.0 | Core bloc Dart package |
| `equatable` | 2.0.8 | Value equality for BLoC state/event classes |
| `get_it` | 9.2.1 | Service locator / dependency injection |
| `injectable` | 2.7.1+4 | Annotation-driven DI on top of GetIt |
| `go_router` | 17.2.0 | Declarative routing |
| `shared_preferences` | 2.5.5 | Non-sensitive settings persistence |
| `path_provider` | 2.1.5 | File system path access |
| `intl` | 0.20.2 | Internationalization (EN + PT-BR) |
| `flutter_localizations` | SDK | Material/Cupertino locale delegates |
| `very_good_analysis` | 10.2.0 | Strict lint ruleset (dev) |
| `isar_community_generator` | 3.3.2 | Isar schema code generation (dev) |
| `build_runner` | ^2.13.1 | Code generation pipeline (dev) |
| `injectable_generator` | 2.12.1 | DI config code generation (dev) |
| `bloc_test` | 10.0.0 | BLoC/Cubit unit test utilities (dev) |
| `mocktail` | 1.0.5 | Mock creation without code generation (dev) |

## Directory Structure Created

```
lib/
  core/
    config/         app_config.dart
    constants/      app_constants.dart, storage_keys.dart
    extensions/     datetime_extensions.dart, string_extensions.dart
  domain/           .gitkeep
  data/             .gitkeep
  infrastructure/   .gitkeep
  application/      .gitkeep
  presentation/     .gitkeep
  config/           .gitkeep
  main.dart
  app.dart
```

## FlutterFragmentActivity Swap

`android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt` now extends
`FlutterFragmentActivity` instead of `FlutterActivity`. This satisfies the `local_auth`
biometric prerequisite (DATA-06, CONTEXT.md D-19) before any auth code is written.

## flutter analyze Result

`flutter analyze --no-fatal-infos` exits **0** with **no issues found**.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] bloc 9.1.1 does not exist on pub.dev**
- **Found during:** Task 1 — `flutter pub get` failed with version solving error
- **Issue:** Plan specified `bloc: 9.1.1` but pub.dev only has `bloc: 9.2.0` as the release matching `flutter_bloc: 9.1.1`
- **Fix:** Updated pubspec.yaml to use `bloc: 9.2.0`
- **Files modified:** pubspec.yaml
- **Commit:** 35cff35

**2. [Rule 1 - Bug] pubspec.yaml dependency ordering violated sort_pub_dependencies lint**
- **Found during:** Task 1 — `flutter analyze` reported sort violations
- **Issue:** sdk dependencies (`flutter`, `flutter_localizations`) must be interleaved alphabetically with regular deps; comments between packages break sort detection
- **Fix:** Reordered all dependencies alphabetically with sdk entries in-line
- **Files modified:** pubspec.yaml
- **Commit:** 35cff35

**3. [Rule 1 - Bug] test/widget_test.dart referenced deleted MyApp class**
- **Found during:** Task 1 — `flutter analyze` reported `MyApp isn't a class` error
- **Issue:** Default scaffold test referenced `MyApp` from the original main.dart which was replaced
- **Fix:** Rewrote widget_test.dart to test `AgendaApp` with simple text assertion
- **Files modified:** test/widget_test.dart
- **Commit:** 35cff35

**4. [Rule 1 - Bug] main.dart relative import violated always_use_package_imports lint**
- **Found during:** Task 1 — `flutter analyze` reported `always_use_package_imports`
- **Issue:** `import 'app.dart'` must be `import 'package:agenda/app.dart'`
- **Fix:** Updated import in main.dart
- **Files modified:** lib/main.dart
- **Commit:** 35cff35

**5. [Rule 1 - Bug] directives_ordering violations in main.dart and test file**
- **Found during:** Task 1 — `flutter analyze` reported `directives_ordering`
- **Issue:** Package imports must be sorted alphabetically within each group (no blank lines separating them)
- **Fix:** Reordered imports alphabetically in main.dart and widget_test.dart
- **Files modified:** lib/main.dart, test/widget_test.dart
- **Commit:** 35cff35

**6. [Rule 1 - Bug] comment_references lint for forward-referenced class names**
- **Found during:** Task 1 — `flutter analyze` reported `comment_references` for `[MigrationRunner]`, `[LocaleCubit]`
- **Issue:** Doc comments used `[ClassName]` bracket syntax for classes not yet defined (created in later plans); very_good_analysis flags these as unresolved references
- **Fix:** Replaced bracket references with plain text in doc comments to avoid both `comment_references` and the `document_ignores` overhead of suppress directives
- **Files modified:** lib/core/config/app_config.dart, lib/core/constants/storage_keys.dart
- **Commit:** 35cff35

## Known Stubs

None — this plan creates structural scaffolding only; no data-driven UI components.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes beyond the planned scope.

## Self-Check: PASSED

- `lib/core/config/app_config.dart` exists: FOUND
- `lib/core/constants/app_constants.dart` exists: FOUND
- `lib/core/constants/storage_keys.dart` exists: FOUND
- `lib/core/extensions/datetime_extensions.dart` exists: FOUND
- `lib/core/extensions/string_extensions.dart` exists: FOUND
- `lib/domain/.gitkeep` exists: FOUND
- `lib/infrastructure/.gitkeep` exists: FOUND
- `lib/application/.gitkeep` exists: FOUND
- `lib/presentation/.gitkeep` exists: FOUND
- `lib/config/.gitkeep` exists: FOUND
- `android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt` contains FlutterFragmentActivity: FOUND
- Commit 35cff35 exists: FOUND
- Commit 2590eee exists: FOUND
- `flutter analyze --no-fatal-infos` exits 0: PASSED
