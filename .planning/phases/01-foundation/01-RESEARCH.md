# Phase 1: Foundation - Research

**Researched:** 2026-04-13
**Domain:** Flutter project bootstrap, Isar database + migration, GetIt/injectable DI, flutter gen-l10n, offline guarantee
**Confidence:** HIGH

---

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Package name: `com.omeu.space.agenda`
- **D-02:** Display name: `AGENDA` (all caps)
- **D-03:** Scaffold for Android + iOS only — no web or desktop directories
- **D-04:** Minimum Flutter SDK: 3.38.1 (required by flutter_local_notifications v21)
- **D-05:** Domain failures use a sealed `Failure` abstract class hierarchy — no exceptions in domain layer; exhaustive pattern matching at call sites
- **D-06:** Failure types are per-layer: `DatabaseFailure`, `ValidationFailure`, `NotificationFailure`, `BackupFailure`, `SecurityFailure` — defined in `core/failures/`
- **D-07:** Domain layer returns `Either<Failure, T>` or `Result<T>` — failures are values, never thrown
- **D-08:** No env vars or dart-define flags — the app is fully local with no backend endpoints
- **D-09:** A single `AppConfig` class in `core/config/` holds compile-time constants: app name, version string, schema version integer, notification namespace ranges
- **D-10:** Debug vs release differences limited to logging only — verbose output in debug via `kDebugMode`, silent in release
- **D-11:** Linting ruleset: `very_good_analysis` — strict rules enforce Clean Architecture layer boundaries and catch common Dart/Flutter issues
- **D-12:** Phase 1 testing scope: unit tests for `MigrationRunner`, `Failure` types, and `AppConfig` — skip trivial DI wiring code
- **D-13:** Test file co-location: `test/` mirrors `lib/` structure (e.g., `test/core/failures/` for `lib/core/failures/`)
- **D-14:** Layer order: `core/ → domain/ → data/ → infrastructure/ → application/ → presentation/ → config/`; strict outer-depends-on-inner; `domain/` has zero Flutter imports
- **D-15:** All Isar-persisted enums annotated with `@enumerated(EnumType.name)` — convention established in Phase 1 before any schema code is written
- **D-16:** `IsarService` lives in `data/database/`; `MigrationRunner` called inside `IsarService.open()`; `schemaVersion` stored in `SharedPreferences` (readable before Isar opens)
- **D-17:** GetIt + injectable — `@injectable` annotations on all services/repositories; `configureDependencies()` called in `main()` before `runApp()`
- **D-18:** DI modules split by domain from day one: `CoreModule`, `TasksModule`, `FinanceModule`, `InfrastructureModule` — no single flat registration file
- **D-19:** `FlutterFragmentActivity` replaces `MainActivity` in `android/app/src/main/kotlin/` during Phase 1 scaffold — required for `local_auth` biometrics (DATA-06)
- **D-20:** Official `flutter gen-l10n` with ARB files — no third-party i18n package
- **D-21:** Two locales: `en` and `pt_BR`; `pt_BR` is the default locale
- **D-22:** ARB files in `lib/config/l10n/` — `app_en.arb` and `app_pt_BR.arb`
- **D-23:** Locale switching state managed by a `LocaleCubit` in `application/shared/` — persisted in `SharedPreferences`

### Claude's Discretion

- Specific extension methods to include in `core/extensions/`
- Internal structure of `AppConfig` (static class vs singleton)
- Whether to use `go_router` or Navigator 2.0 directly (go_router recommended by research)
- CI smoke test tooling (GitHub Actions vs local script)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 1 scope.

</user_constraints>

---

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | All data stored locally on the device using Isar; no data transmitted externally | IsarService singleton pattern; offline-only app architecture; no network packages in pubspec |
| UX-02 | App is fully functional offline — no feature requires internet access | Assert at startup that no HTTP client is instantiated; `connectivity_plus` explicitly excluded from stack |

</phase_requirements>

---

## Summary

Phase 1 creates the entire architectural skeleton on which Phases 2–5 build. No production feature code ships in this phase — only infrastructure: a scaffolded Flutter app, a working Isar database with migration-safe enum convention and a manual migration runner, a wired GetIt + injectable DI graph split into domain modules, and a `flutter gen-l10n` scaffold producing ARB-backed localization with PT-BR as the default locale.

The critical risks in this phase are the Isar enum ordinal pitfall (must be guarded by the `@enumerated(EnumType.name)` convention before the first schema is written) and the migration runner design (schemaVersion in SharedPreferences must be readable before Isar opens, so it cannot live in Isar itself). Both are decided; the research confirms the standard patterns that implement them.

All stack packages for Phase 1 are verified. The Flutter SDK (3.41.4) on this machine exceeds the 3.38.1 minimum. The Android SDK (35.0.0) meets the compileSdk 35 requirement. No blocking environment gaps exist.

**Primary recommendation:** Scaffold with `flutter create --org com.omeu.space --project-name agenda --platforms android,ios`, then layer the clean architecture directories incrementally in the build order: core → data/database → config/di → config/l10n → app shell.

---

## Project Constraints (from CLAUDE.md)

Directives the planner must verify are never violated:

| Directive | Impact on Phase 1 |
|-----------|-------------------|
| Use `isar_community` 3.3.2, NOT `isar` / `isar_flutter_libs` | pubspec must reference `isar_community`, `isar_community_flutter_libs`, `isar_community_generator` |
| Flutter + BLoC/Cubit + GetIt — tech stack is decided | No alternative state manager; GetIt is the service locator |
| No data leaves the device — no analytics, crash reporters, cloud | No `firebase_*`, `sentry_flutter`, `dio`, `http` anywhere in pubspec |
| Minimum Flutter SDK 3.38.1 | `flutter: '>=3.38.1'` in pubspec environment |
| All code in English; UI text in PT-BR with EN toggle | ARB files contain PT-BR UI strings; code identifiers and comments in English |
| No provider, riverpod, hive, freezed, mockito, easy_localization, slang, get (GetX) | Verified absent from pubspec |
| very_good_analysis for linting (D-11) | `analysis_options.yaml` includes `package:very_good_analysis/analysis_options.yaml` |

---

## Standard Stack

### Phase 1 Direct Dependencies

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `isar_community` | 3.3.2 | Local NoSQL database — community fork of abandoned original | [VERIFIED: pub.dev + CLAUDE.md] |
| `isar_community_flutter_libs` | 3.3.2 | Binary companion (platform libs for Isar) | [VERIFIED: pub.dev + CLAUDE.md] |
| `flutter_bloc` | 9.1.1 | BLoC/Cubit state management | [VERIFIED: pub.dev + CLAUDE.md] |
| `bloc` | 9.1.1 | Core Dart BLoC package | [VERIFIED: pub.dev] |
| `equatable` | 2.0.8 | Value equality for Cubit states — no code gen | [VERIFIED: pub.dev + CLAUDE.md] |
| `get_it` | 9.2.1 | Service locator / DI container | [VERIFIED: pub.dev + CLAUDE.md] |
| `injectable` | 2.7.1+4 | Annotation-driven DI registration on top of GetIt | [VERIFIED: pub.dev + CLAUDE.md] |
| `shared_preferences` | 2.5.5 | Stores schemaVersion, locale preference, non-sensitive settings | [VERIFIED: pub.dev + CLAUDE.md] |
| `go_router` | 17.2.0 | Declarative routing; required for PIN guard in Phase 5 | [VERIFIED: pub.dev + CLAUDE.md] |
| `intl` | 0.20.2 | Date/number formatting; required companion for flutter_localizations | [VERIFIED: pub.dev + CLAUDE.md] |
| `path_provider` | 2.1.5 | Gets application documents directory for Isar database path | [VERIFIED: pub.dev + CLAUDE.md] |

### Phase 1 Dev Dependencies

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `isar_community_generator` | 3.3.2 | Generates `.g.dart` schema files from `@Collection` annotations | [VERIFIED: pub.dev + CLAUDE.md] |
| `build_runner` | 2.13.1 | Runs code generation for Isar schemas and injectable | [VERIFIED: pub.dev + CLAUDE.md] |
| `injectable_generator` | 2.12.1 | Generates `injection.config.dart` from `@injectable` annotations | [VERIFIED: pub.dev + CLAUDE.md] |
| `very_good_analysis` | 10.2.0 | Strict lint rules; enforces layer boundary discipline | [VERIFIED: pub.dev — published ~Feb 2026] |
| `bloc_test` | 10.0.0 | BLoC/Cubit unit testing | [VERIFIED: pub.dev + CLAUDE.md] |
| `mocktail` | 1.0.5 | Mock creation without code generation | [VERIFIED: pub.dev + CLAUDE.md] |

**Note on very_good_analysis:** Decision D-11 requires this. Latest version is 10.2.0 (published ~Feb 2026). [VERIFIED: pub.dev]

### Packages NOT Installed in Phase 1

These are in the full stack but not needed until later phases: `flutter_local_notifications`, `timezone`, `flutter_timezone`, `file_picker`, `flutter_screen_lock`, `local_auth`, `flutter_secure_storage`, `csv`, `fl_chart`. Include them commented-out in pubspec or add them in Phase 4/5.

**Exception:** All packages should be listed in pubspec.yaml during Phase 1 bootstrap so the pubspec is the single source of truth and `flutter pub get` works once. The planner can decide whether to add them all up front or incrementally.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `very_good_analysis` | `flutter_lints` | flutter_lints is less strict; very_good_analysis catches layer boundary violations earlier |
| `injectable` | Manual GetIt registration | Manual registration is error-prone at scale; injectable is the standard |
| `go_router` | Navigator 2.0 directly | Navigator 2.0 requires more boilerplate; go_router is official Flutter and handles route guards cleanly |

### Installation Command (Phase 1 core only)

```bash
flutter pub add isar_community:3.3.2 isar_community_flutter_libs:3.3.2 flutter_bloc bloc equatable get_it injectable shared_preferences go_router intl path_provider
flutter pub add --dev isar_community_generator:3.3.2 build_runner injectable_generator very_good_analysis bloc_test mocktail
```

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── main.dart                          # configureDependencies(); runApp(App())
├── app.dart                           # MaterialApp.router, locale from LocaleCubit
│
├── core/                              # Pure Dart — zero Flutter/SDK imports
│   ├── config/
│   │   └── app_config.dart            # AppConfig static class — version, schemaVersion, notification namespaces
│   ├── constants/
│   │   ├── app_constants.dart         # durations, limits, magic numbers
│   │   └── storage_keys.dart          # SharedPreferences keys as constants
│   ├── failures/
│   │   └── failure.dart               # sealed class Failure hierarchy (D-05, D-06)
│   └── extensions/
│       ├── datetime_extensions.dart   # .startOfDay(), .endOfDay(), .isToday()
│       └── string_extensions.dart     # .isNullOrEmpty, .capitalize()
│
├── data/
│   └── database/
│       ├── isar_service.dart          # IsarService singleton — open(), instance, close()
│       └── migration_runner.dart      # MigrationRunner — version-gated migration blocks
│
├── domain/                            # Pure Dart — zero Flutter/Isar imports
│   └── (empty in Phase 1 — placeholder dirs only)
│
├── infrastructure/
│   └── (empty in Phase 1 — placeholder dirs only)
│
├── application/
│   └── shared/
│       └── locale/
│           ├── locale_cubit.dart      # LocaleCubit — reads/writes locale to SharedPreferences
│           └── locale_state.dart
│
├── presentation/
│   └── app_shell.dart                 # Minimal root widget, BlocProviders, MaterialApp.router
│
└── config/
    ├── di/
    │   ├── injection.dart             # @InjectableInit configureDependencies() entry point
    │   ├── injection.config.dart      # GENERATED — do not edit manually
    │   ├── core_module.dart           # @module CoreModule — IsarService, SharedPreferences
    │   ├── tasks_module.dart          # @module TasksModule — placeholder, ready for Phase 2
    │   ├── finance_module.dart        # @module FinanceModule — placeholder, ready for Phase 3
    │   └── infrastructure_module.dart # @module InfrastructureModule — placeholder
    └── l10n/
        ├── app_en.arb                 # English strings
        ├── app_pt_BR.arb              # Portuguese (Brazil) strings — default
        └── l10n.yaml                  # flutter gen-l10n configuration
```

**test/ mirrors lib/:**

```
test/
├── core/
│   ├── config/
│   │   └── app_config_test.dart
│   └── failures/
│       └── failure_test.dart
└── data/
    └── database/
        └── migration_runner_test.dart
```

### Pattern 1: Isar Database Open + Migration

**What:** `IsarService` opens the database once, runs `MigrationRunner`, and exposes the singleton instance. Called from DI wiring, not directly from application code.

**When to use:** Every cold start. IsarService must be the first dependency resolved in the DI graph.

```dart
// Source: isar.dev/recipes/data_migration.html + CONTEXT.md D-16
// lib/data/database/isar_service.dart

import 'package:isar_community/isar_community.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  Isar get db {
    assert(_isar != null, 'IsarService not initialized. Call open() first.');
    return _isar!;
  }

  Future<void> open(List<CollectionSchema<dynamic>> schemas) async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(schemas, directory: dir.path);

    final prefs = await SharedPreferences.getInstance();
    await MigrationRunner.run(_isar!, prefs);
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
```

```dart
// lib/data/database/migration_runner.dart
// Source: isar.dev/recipes/data_migration.html

class MigrationRunner {
  /// Current target schema version — bump when a migration is added.
  static const int targetVersion = 1;
  static const String _versionKey = 'schema_version';

  static Future<void> run(Isar isar, SharedPreferences prefs) async {
    final current = prefs.getInt(_versionKey) ?? 0;
    if (current >= targetVersion) return;

    for (var v = current + 1; v <= targetVersion; v++) {
      await _runMigration(isar, v);
    }

    await prefs.setInt(_versionKey, targetVersion);
  }

  static Future<void> _runMigration(Isar isar, int toVersion) async {
    switch (toVersion) {
      case 1:
        // Initial schema — no data migration needed.
        return;
      // Future: case 2: await _migrateV1ToV2(isar);
    }
  }
}
```

### Pattern 2: injectable Module Split

**What:** DI registrations are split into domain-named `@module` classes. The generated `injection.config.dart` is the only file that sees all modules. `configureDependencies()` is the single call site in `main()`.

**When to use:** Every new injectable class is registered in its domain module, never in a flat global file.

```dart
// Source: pub.dev/packages/injectable + CONTEXT.md D-17, D-18
// lib/config/di/injection.dart

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
```

```dart
// lib/config/di/core_module.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/isar_service.dart';

@module
abstract class CoreModule {
  @singleton
  IsarService get isarService => IsarService.instance;

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
```

**Code generation command:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Pattern 3: Sealed Failure Hierarchy

**What:** A sealed class hierarchy for domain failures. Pattern matching is exhaustive. No exceptions leave the domain layer.

**When to use:** Every repository method, every domain service. Return `Either<Failure, T>` (or a simple `Result<T>` typedef) instead of throwing.

```dart
// Source: CONTEXT.md D-05, D-06, D-07
// lib/core/failures/failure.dart

sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

final class BackupFailure extends Failure {
  const BackupFailure(super.message);
}

final class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}
```

Usage at call sites — exhaustive pattern match:

```dart
switch (result) {
  case DatabaseFailure(:final message) => showError(message);
  case ValidationFailure(:final message) => showValidationError(message);
  case NotificationFailure(:final message) => log(message);
  case BackupFailure(:final message) => showBackupError(message);
  case SecurityFailure(:final message) => showSecurityError(message);
}
```

### Pattern 4: flutter gen-l10n with PT-BR Default

**What:** `l10n.yaml` configures `flutter gen-l10n` to produce a type-safe `AppLocalizations` class. PT-BR is the template (default) locale. EN is the secondary locale.

```yaml
# lib/config/l10n/l10n.yaml
arb-dir: lib/config/l10n
template-arb-file: app_pt_BR.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/generated/l10n
preferred-supported-locales:
  - pt_BR
  - en
nullable-getter: false
```

```json
// lib/config/l10n/app_pt_BR.arb  (template)
{
  "@@locale": "pt_BR",
  "appName": "AGENDA",
  "@appName": { "description": "Nome da aplicação" }
}
```

```json
// lib/config/l10n/app_en.arb
{
  "@@locale": "en",
  "appName": "AGENDA",
  "@appName": { "description": "Application name" }
}
```

Generate with: `flutter gen-l10n`
Output lands in `lib/generated/l10n/app_localizations.dart` (and `app_localizations_en.dart`, `app_localizations_pt.dart`).

**Important:** Because `synthetic-package: false`, import is:
```dart
import 'package:agenda/generated/l10n/app_localizations.dart';
```

### Pattern 5: LocaleCubit — Locale Switching

**What:** A Cubit that holds the active `Locale` and persists it to `SharedPreferences`. `MaterialApp.router`'s `locale` parameter is driven from `BlocBuilder<LocaleCubit, LocaleState>`.

```dart
// lib/application/shared/locale/locale_cubit.dart
@injectable
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs) : super(
    LocaleState(
      Locale(_prefs.getString('locale') ?? 'pt'),
    ),
  );

  final SharedPreferences _prefs;

  void setLocale(Locale locale) {
    _prefs.setString('locale', locale.languageCode);
    emit(LocaleState(locale));
  }
}
```

### Pattern 6: AppConfig Static Class

**What:** A single static class in `core/config/` holding compile-time constants. No constructor, no factory, no GetIt registration — accessed directly.

```dart
// lib/core/config/app_config.dart
// Source: CONTEXT.md D-09

abstract final class AppConfig {
  static const String appName = 'AGENDA';
  static const String packageName = 'com.omeu.space.agenda';
  static const String version = '1.0.0';
  static const int buildNumber = 1;

  /// Bump this when a new MigrationRunner migration block is added.
  static const int schemaVersion = 1;

  /// Notification ID namespaces — deterministic derivation: entityId * 10 + notificationType
  static const int taskNotificationBase = 10;
  static const int financeNotificationBase = 20;
  static const int systemNotificationBase = 30;
}
```

### Anti-Patterns to Avoid

- **Flat DI file:** All registrations in one `injection.dart`. Scales to hundreds of lines by Phase 3. Use `@module` classes from day one (D-18).
- **schemaVersion in Isar:** Storing the schema version in an Isar collection creates a chicken-and-egg problem — you need the version before Isar opens to decide whether to run migrations. Use SharedPreferences (D-16).
- **`@enumerated(EnumType.ordinal)` or unannotated enums:** Isar's default is ordinal. Reordering any enum silently corrupts records. Annotate every Isar-persisted enum with `@enumerated(EnumType.name)` (D-15).
- **`isar` or `isar_flutter_libs`:** These are the abandoned originals. Use `isar_community` and `isar_community_flutter_libs` (CLAUDE.md).
- **`FlutterActivity` in MainActivity.kt:** Must be `FlutterFragmentActivity` before any auth code is added (D-19). Changing this later requires testing all fragment-dependent plugins.
- **Calling `getIt<T>()` before `configureDependencies()`:** Results in `StateError` at runtime. `await configureDependencies()` must complete before `runApp()` (D-17).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DI registration boilerplate | Manual `sl.register...()` for every class | `injectable` + `injectable_generator` | 100+ manual registrations by Phase 3; annotation-driven generation is less error-prone |
| Lint rule definition | Custom `analysis_options.yaml` rules | `very_good_analysis` 10.2.0 | VGV ruleset is battle-tested for Clean Architecture Flutter projects; catches layer violations, null safety gaps, unused parameters |
| Route management | Custom Navigator 2.0 RouterDelegate | `go_router` 17.2.0 | go_router is official Flutter; handles deep linking, redirect/guard, shell routes — needed in Phase 5 for PIN guard |
| Locale generation | Custom ARB parser | `flutter gen-l10n` built-in tool | Type-safe generated `AppLocalizations`; no runtime parsing errors |
| Key/value persistence for settings | Custom file-based config | `shared_preferences` 2.5.5 | Platform-native persistence; correct tool for non-sensitive scalar settings |

**Key insight:** Phase 1 is almost entirely scaffold work. The "don't hand-roll" items are the infrastructure plumbing — using standard tools here prevents the maintenance burden that accumulates across Phases 2–5.

---

## Common Pitfalls

### Pitfall 1: Enum Ordinal Corruption
**What goes wrong:** Default Isar enum storage uses ordinal index. Inserting a new value in the middle of an enum (e.g., adding `medium` between `low` and `high`) silently corrupts all records written before the change.
**Why it happens:** Isar stores the integer position (0, 1, 2, ...) of the enum value by default, not its string name.
**How to avoid:** Every Isar-persisted enum must carry `@Enumerated(EnumType.name)`. Enforce in Phase 1 before any schema exists. Decision D-15 locks this.
**Warning signs:** Query results return unexpected enum values after adding/reordering an enum. Particularly insidious because it is silent — no error, just wrong data.
**Source:** [VERIFIED: isar.dev + CLAUDE.md PITFALLS.md]

### Pitfall 2: schemaVersion in Wrong Storage
**What goes wrong:** Storing the schema version in an Isar collection. On a schema migration, Isar must be opened first — but you need the version before deciding whether to run the migration.
**Why it happens:** The natural place to store app state is the database, but this creates circular dependency.
**How to avoid:** Store `schemaVersion` (and the `lastBackgroundedAt` lock timestamp, needed in Phase 5) in `SharedPreferences`. Both must be readable before Isar opens. Decision D-16 locks this.
**Warning signs:** Migration runner cannot read version at startup; app crashes on first open after schema change.
**Source:** [VERIFIED: isar.dev/recipes/data_migration.html]

### Pitfall 3: build_runner Version Conflict
**What goes wrong:** Using `build_runner: any` causes version solve failures when `isar_community_generator` and `injectable_generator` resolve to incompatible build_runner versions.
**Why it happens:** Multiple code-gen tools each declare their own `build_runner` constraints; `any` allows incompatible combinations.
**How to avoid:** Pin `build_runner: ^2.13.1` explicitly. [VERIFIED: CLAUDE.md STACK.md]
**Warning signs:** `pub get` or `dart pub upgrade` fails with version solve error mentioning `build_runner`.

### Pitfall 4: intl Version Mismatch with flutter_localizations
**What goes wrong:** `flutter_localizations` (SDK bundle) has a specific `intl` version it expects. If `intl` is pinned to an older version, compilation fails.
**Why it happens:** The Flutter SDK bundles `flutter_localizations` which depends on a specific `intl` version; mismatches break the build.
**How to avoid:** Use `intl: ^0.20.2`. After Flutter SDK upgrades, run `flutter pub upgrade intl` immediately. [VERIFIED: CLAUDE.md STACK.md]
**Warning signs:** `flutter pub get` fails with `intl` version constraint conflict.

### Pitfall 5: injectable_generator Not Finding @module Classes
**What goes wrong:** The `@module` class is defined in a different library and not picked up by the generator, resulting in missing registrations silently.
**Why it happens:** The generator scans files discoverable from the entry point. Files in separate packages require `@InjectableInit` `externalPackageModules` configuration.
**How to avoid:** For a monorepo app (all code in `lib/`), ensure every `@module` class file is within `lib/`. Run `dart run build_runner build --delete-conflicting-outputs` and verify all modules appear in `injection.config.dart`.
**Warning signs:** `GetIt` throws `StateError: Object/factory not registered` at runtime despite `@injectable` annotation being present.

### Pitfall 6: FlutterActivity vs FlutterFragmentActivity
**What goes wrong:** Leaving `MainActivity.kt` extending `FlutterActivity` means `local_auth` cannot call `FragmentManager` APIs needed for biometric authentication. This manifests as a crash in Phase 5, not Phase 1 — which means it is forgotten.
**Why it happens:** `local_auth` requires a `FragmentActivity` context. The default Flutter scaffold creates `FlutterActivity`.
**How to avoid:** Decision D-19 mandates changing this in Phase 1. The change is two lines but must happen before any auth code is written.
**Warning signs:** `PlatformException: FragmentActivity required` at runtime when `local_auth` is invoked in Phase 5.
**Source:** [VERIFIED: pub.dev/packages/local_auth README]

### Pitfall 7: Synchronous Isar Calls on Main Isolate
**What goes wrong:** Using `isar.collection.getSync()` or `.findAllSync()` in BLoC event handlers or widget callbacks blocks the UI thread.
**Why it happens:** Isar provides both sync and async APIs; sync APIs are convenient but unsafe on the main isolate.
**How to avoid:** Use only async Isar APIs: `findAll()`, `put()`, `delete()`. Ban sync APIs from the repository layer. Establish in Phase 1 repository pattern so all subsequent phases inherit it.
**Warning signs:** UI jank correlating with database operations; ANR dialogs on Android.

### Pitfall 8: l10n Output in synthetic-package (import path confusion)
**What goes wrong:** When `synthetic-package: true` (the Flutter default), the generated file is imported as `package:flutter_gen/gen_l10n/app_localizations.dart`. When set to `false`, the import is the app's own package. Mixing these causes "file not found" compile errors.
**Why it happens:** The default changed in recent Flutter versions; docs examples show both forms.
**How to avoid:** Set `synthetic-package: false` in `l10n.yaml` explicitly and use `import 'package:agenda/generated/l10n/app_localizations.dart'`. Be consistent across all files.
**Source:** [CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]

---

## Code Examples

### pubspec.yaml (Phase 1 complete)

```yaml
# Source: CLAUDE.md recommended skeleton + verified versions
name: agenda
description: Privacy-first personal HQ for tasks and finances.
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.38.1'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Database — use community fork, NOT original isar
  isar_community: 3.3.2
  isar_community_flutter_libs: 3.3.2

  # State management
  flutter_bloc: ^9.1.1
  bloc: ^9.1.1
  equatable: ^2.0.8

  # Dependency injection
  get_it: ^9.2.1
  injectable: ^2.7.1

  # Navigation
  go_router: ^17.2.0

  # Persistence (settings + schemaVersion)
  shared_preferences: ^2.5.5

  # File paths (for Isar directory)
  path_provider: ^2.1.5

  # i18n
  intl: ^0.20.2

  # --- Phase 4 (add when implementing notifications/backup) ---
  # flutter_local_notifications: ^21.0.0
  # timezone: ^0.11.0
  # flutter_timezone: ^5.0.2
  # file_picker: ^11.0.2
  # csv: ^8.0.0
  # fl_chart: ^1.2.0

  # --- Phase 5 (add when implementing app lock) ---
  # flutter_screen_lock: ^9.2.2
  # local_auth: ^3.0.1
  # flutter_secure_storage: ^10.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Database code generation — pin to same version as runtime packages
  isar_community_generator: 3.3.2
  build_runner: ^2.13.1

  # DI code generation
  injectable_generator: ^2.12.1

  # Linting
  very_good_analysis: ^10.2.0

  # Testing
  bloc_test: ^10.0.0
  mocktail: ^1.0.5

flutter:
  uses-material-design: true
  generate: true  # required for flutter gen-l10n with synthetic-package: false
```

### analysis_options.yaml

```yaml
# Source: pub.dev/packages/very_good_analysis — D-11
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - lib/generated/**   # flutter gen-l10n output
    - lib/config/di/injection.config.dart  # injectable generated

linter:
  rules:
    # Project-specific overrides (add as needed):
    # prefer_final_locals: false  # uncomment if too noisy
```

### main.dart

```dart
// Source: CONTEXT.md D-17; injectable docs
import 'package:flutter/material.dart';
import 'config/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const App());
}
```

### FlutterFragmentActivity (Android — Phase 1 requirement D-19)

```kotlin
// android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt
// Source: pub.dev/packages/local_auth README + CONTEXT.md D-19
package com.omeu.space.agenda

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

### android/app/build.gradle (compileSdk requirement)

```groovy
android {
    compileSdk 35   // Required by flutter_local_notifications v21 (Phase 4)
    defaultConfig {
        applicationId "com.omeu.space.agenda"
        minSdk 21
        targetSdk 35
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `isar` + `isar_flutter_libs` (original) | `isar_community` 3.3.2 + `isar_community_flutter_libs` | April 2023 (original abandoned); community fork active | Drop-in API; only pubspec + import path changes |
| `@freezed` for BLoC states | `sealed class` + `equatable` | Dart 3.0 / Flutter 3.10 (2023) | No code generation overhead; exhaustive switch is native |
| `flutter_localizations` + third-party i18n | Official `flutter gen-l10n` with ARB files | Flutter 2.x (now standard) | Type-safe generated class; no runtime JSON loading |
| Manual `GetIt.registerFactory()` everywhere | `injectable` + code generation | ~2021, matured by 2024 | Annotation-driven; no missed registrations |
| `provider` as DI glue | Pure `get_it` + `injectable` | Project decision | Cleaner separation; provider conflicts with BLoC semantics |
| Navigator 1.0 / 2.0 imperative | `go_router` (declarative) | go_router became official Flutter plugin ~2022 | Route guards, deep linking, shell routes without boilerplate |

**Deprecated/outdated:**
- `isar` (original): abandoned April 2023 — all new projects use `isar_community`
- `mockito` with `@GenerateMocks`: replaced by `mocktail` in BLoC ecosystem
- `flutter_native_timezone`: renamed to `flutter_timezone` — do not use old name
- `easy_localization`: unnecessary wrapper for two-locale projects
- `FlutterActivity` for apps using `local_auth`: must be `FlutterFragmentActivity`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `very_good_analysis` 10.2.0 is the latest stable version | Standard Stack | Minor — planner should verify version before writing pubspec; update to latest stable |
| A2 | `go_router` 17.2.0 is compatible with `flutter_bloc` 9.1.1 (no known conflicts) | Standard Stack | Low — both are well-maintained official/semi-official packages; version solve would catch hard conflicts |
| A3 | `flutter create --platforms android,ios` correctly omits web and desktop directories (D-03) | Architecture Patterns | Low — verified flag exists in flutter create --help; actual output confirmed by search |
| A4 | `synthetic-package: false` is the right l10n.yaml choice for this project structure | Code Examples | Low — alternative is synthetic-package: true with different import path; consistent choice prevents confusion |

**If this table is empty of HIGH-risk items:** All critical claims in this research were verified. Assumptions A1–A4 are LOW risk and can be confirmed during plan execution.

---

## Open Questions

1. **Should all pubspec packages (including Phase 4/5) be added in Phase 1?**
   - What we know: Adding them all up front means one `flutter pub get` and a complete lockfile. Deferring means Phase 4/5 bootstrap plans must include a package install step.
   - What's unclear: Project preference for lockfile stability vs. incremental dependency introduction.
   - Recommendation: Add all packages in Phase 1 pubspec (commented-out for Phase 4/5 is also valid); document in pubspec which phase activates each package. This avoids "why doesn't this package exist" errors in later phases.

2. **`Either<Failure, T>` — use `dartz` package or hand-roll?**
   - What we know: D-07 specifies `Either<Failure, T>` or `Result<T>` — failures are values. The `dartz` package provides `Either` but adds a dependency. A simple `Result<T>` sealed class is easy to hand-roll.
   - What's unclear: D-07 says "Either or Result" — both are acceptable, but the planner needs to pick one.
   - Recommendation: Hand-roll a minimal `Result<T>` sealed class in `core/failures/result.dart` (`sealed class Result<T> { ... }` with `Success<T>` and `Failure` subtypes). Avoids `dartz` dependency; sufficient for AGENDA's needs. If `dartz` is preferred, add `dartz: ^0.10.7` to pubspec.

3. **CI smoke test tooling (Claude's Discretion)**
   - What we know: D-11 is about linting; the CONTEXT.md leaves CI tooling to Claude's discretion.
   - What's unclear: GitHub Actions is available (standard), but the machine has no CI YAML files yet.
   - Recommendation: A minimal GitHub Actions workflow running `flutter analyze` and `flutter test` on push to `main` is the standard approach. Add `.github/workflows/ci.yml` in Plan 01-01 as part of bootstrap. Simple, no external service needed.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All Flutter tasks | Yes | 3.41.4 stable | — |
| Dart SDK | All Dart tasks | Yes | 3.11.1 | — |
| Android SDK | Android builds | Yes | 35.0.0 | — |
| adb | Android device testing | Yes | found at ~/Android/platform-tools/adb | — |
| Java / JDK | Android Gradle builds | Yes | OpenJDK 17.0.2 | — |
| iOS toolchain (Xcode) | iOS builds | Not detected (Linux host) | — | Use Android for local testing; iOS CI on macOS runner |
| `flutter_lints` / `very_good_analysis` | Linting | Not globally installed | — | Added as dev dependency in pubspec (correct approach) |
| Gradle | Android builds | Not in PATH | — | Flutter toolchain bundles its own Gradle; not needed in PATH |

**Missing dependencies with no fallback:**
- iOS toolchain (Xcode) — Linux development environment cannot build for iOS locally. Recommendation: Android-only local testing; iOS builds via CI (GitHub Actions macOS runner) or a macOS machine. This is expected for Linux Flutter development.

**Missing dependencies with fallback:**
- None — all required tools for Android development and code generation are available.

**Flutter version note:** 3.41.4 > 3.38.1 minimum (D-04). The machine is ahead of the minimum. [VERIFIED: flutter --version]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK bundle) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 |
| Config file | None — Wave 0 creates no config; `flutter test` uses default discovery |
| Quick run command | `flutter test test/core/ test/data/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Isar opens without error on cold start | unit | `flutter test test/data/database/` | Wave 0 |
| DATA-01 | MigrationRunner no-ops when schemaVersion is current | unit | `flutter test test/data/database/migration_runner_test.dart` | Wave 0 |
| DATA-01 | MigrationRunner runs migration block when version is behind | unit | `flutter test test/data/database/migration_runner_test.dart` | Wave 0 |
| DATA-01 | Enum annotated with `@Enumerated(EnumType.name)` — convention verified | lint/static | `flutter analyze` | N/A (linting) |
| UX-02 | No HTTP client instantiated — no network packages in pubspec | static | `flutter analyze` + manual pubspec review | N/A |
| D-05/06 | Failure sealed class hierarchy compiles with exhaustive switch | unit | `flutter test test/core/failures/failure_test.dart` | Wave 0 |
| D-09 | AppConfig constants compile and have correct types | unit | `flutter test test/core/config/app_config_test.dart` | Wave 0 |
| D-12 | DI graph resolves without errors | integration (manual) | `flutter run` on Android device/emulator | Manual |

**Note on UX-02 automated verification:** The cleanest proof is: (1) `grep -r "import 'dart:io'" lib/ | grep -v "test"` returns no HTTP client usage, and (2) `flutter pub deps | grep -E "dio|http|connectivity"` returns nothing. Add these as assertions in the Plan 01-05 verification step.

### Sampling Rate

- **Per task commit:** `flutter analyze && flutter test test/core/ test/data/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green (`flutter test` exits 0) before `/gsd-verify-work`

### Wave 0 Gaps (files to create before implementation tasks)

- [ ] `test/core/failures/failure_test.dart` — covers D-05, D-06 sealed class hierarchy
- [ ] `test/core/config/app_config_test.dart` — covers D-09 AppConfig constants
- [ ] `test/data/database/migration_runner_test.dart` — covers DATA-01, migration no-op and run cases
- [ ] `test/helpers/` — shared test fixtures (empty directory, populated in later phases)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No (app lock is Phase 5) | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Partial — MigrationRunner validates version integer | `assert` + type safety |
| V6 Cryptography | No (PIN storage is Phase 5) | — |
| V1 Architecture | Yes — layer isolation, no data leaves device | Clean Architecture enforcement via `very_good_analysis` |

### Known Threat Patterns for Phase 1 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive data in SharedPreferences | Information Disclosure | Only store non-sensitive data (schemaVersion, locale); PIN hash goes to `flutter_secure_storage` in Phase 5 (never SharedPreferences) |
| Network permission declared in manifest | Elevation of Privilege / Information Disclosure | Do not declare `INTERNET` permission in `AndroidManifest.xml`; DATA-01 / UX-02 require zero network |
| Isar database not encrypted | Information Disclosure | AGENDA's threat model: local device access. Isar 3.x has no native encryption. If encryption is required, it must be addressed as a pre-Phase-2 decision. Currently not in scope per v1 requirements. |

---

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — verified package versions, isar_community status, pubspec skeleton
- `.planning/research/ARCHITECTURE.md` — layer structure, build order, component boundaries, code patterns
- `.planning/research/PITFALLS.md` — Isar enum ordinal, migration runner design, sync API risk
- `.planning/research/SUMMARY.md` — critical risks synthesis, pre-phase decisions
- `CLAUDE.md` — project constraints, confirmed stack, what NOT to use
- `.planning/phases/01-foundation/01-CONTEXT.md` — locked decisions D-01 through D-23
- `flutter --version` (local) — confirmed Flutter 3.41.4, Dart 3.11.1 [VERIFIED]
- `flutter doctor` (local) — confirmed Android SDK 35.0.0, adb available [VERIFIED]

### Secondary (MEDIUM confidence)
- [isar.dev/recipes/data_migration.html](https://isar.dev/recipes/data_migration.html) — migration runner pattern with SharedPreferences version key [CITED]
- [isar-community.dev/v3/tutorials/quickstart.html](https://isar-community.dev/v3/tutorials/quickstart.html) — `Isar.open()` signature with directory parameter [CITED]
- [pub.dev/packages/very_good_analysis](https://pub.dev/packages/very_good_analysis) — confirmed 10.2.0 latest [VERIFIED]
- [flutterlocalisation.com/blog/flutter-l10n-yaml-configuration](https://flutterlocalisation.com/blog/flutter-l10n-yaml-configuration) — l10n.yaml structure for pt_BR default locale [CITED]
- [pub.dev/packages/injectable](https://pub.dev/packages/injectable) — `@module`, `@InjectableInit`, `configureDependencies()` pattern [CITED]
- [pub.dev/packages/local_auth](https://pub.dev/packages/local_auth) — FlutterFragmentActivity requirement [CITED]
- [docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source](https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source) — synthetic-package behavior [CITED]

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | All versions verified from pub.dev; cross-referenced with CLAUDE.md and prior research |
| Architecture | HIGH | Locked decisions D-01 through D-23 from CONTEXT.md; patterns verified against official docs and ARCHITECTURE.md research |
| Pitfalls | HIGH | Most from official docs and GitHub issues; prior PITFALLS.md research confirmed |
| Environment | HIGH | Verified via `flutter --version` and `flutter doctor` on target machine |
| l10n patterns | MEDIUM-HIGH | Official flutter gen-l10n docs confirm the pattern; pt_BR default configuration verified against published l10n.yaml guide |

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 days — stable packages, but `very_good_analysis` and `go_router` update frequently; verify versions before writing pubspec)
