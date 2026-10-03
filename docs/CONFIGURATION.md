<!-- GSD:GENERATED -->
<!-- generated-by: gsd-doc-writer -->

# Configuration

Reference for all configuration surfaces in AGENDA: SDK requirements, build settings, localization, lint rules, dependency injection, and runtime preferences.

---

## Flutter and Dart SDK Requirements

The minimum runtimes enforced in `pubspec.yaml`:

| Runtime | Constraint |
|---------|-----------|
| Dart SDK | `>=3.7.0 <4.0.0` |
| Flutter SDK | `>=3.38.1` |

CI pins the exact Flutter version used for all automated checks:

- **Flutter** `3.41.4` (stable channel) — set in `.github/workflows/ci.yml`

The `>=3.38.1` floor is required by `flutter_local_notifications 21.0.0` (Phase 4). Earlier Flutter versions will fail `pub get` for that package when it is activated.

---

## Application Identity

Defined in `lib/core/config/app_config.dart` as compile-time constants:

| Constant | Value | Purpose |
|----------|-------|---------|
| `AppConfig.appName` | `'AGENDA'` | Display name shown in Settings |
| `AppConfig.packageName` | `'com.omeu.space.agenda'` | Reverse-DNS bundle/application ID |
| `AppConfig.version` | `'1.0.0'` | Human-readable version string |
| `AppConfig.buildNumber` | `1` | Platform store build number |
| `AppConfig.schemaVersion` | `3` | Current Isar schema version (bump on every schema change) |

The Android application ID (`applicationId`) in `android/app/build.gradle.kts` is set to `com.omeu.space.agenda`, matching `AppConfig.packageName`.

---

## Android Build Configuration

**File:** `android/app/build.gradle.kts`

| Setting | Value |
|---------|-------|
| `namespace` | `com.omeu.space.agenda` |
| `compileSdk` | `flutter.compileSdkVersion` (resolved by Flutter Gradle plugin) |
| `minSdk` | `flutter.minSdkVersion` (resolved by Flutter Gradle plugin) |
| `targetSdk` | `flutter.targetSdkVersion` (resolved by Flutter Gradle plugin) |
| Java source/target compatibility | `JavaVersion.VERSION_17` |
| Kotlin `jvmTarget` | `"17"` |
| Android Gradle Plugin | `8.11.1` (set in `android/settings.gradle.kts`) |
| Kotlin Android plugin | `2.2.20` (set in `android/settings.gradle.kts`) |
| Gradle wrapper | `8.13` (`android/gradle/wrapper/gradle-wrapper.properties`) |

**`android/gradle.properties`:**

```properties
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
```

**Release signing:** The release build type currently re-uses the debug signing config (`signingConfigs.getByName("debug")`). A production keystore must be configured in `android/app/build.gradle.kts` before publishing to the Play Store. <!-- VERIFY: production signing keystore location and configuration -->

---

## Dependencies

### Runtime Dependencies

Declared in `pubspec.yaml` under `dependencies`:

| Package | Version | Purpose |
|---------|---------|---------|
| `bloc` | `9.2.0` | Core BLoC/Cubit state management |
| `equatable` | `2.0.8` | Value equality for BLoC states and events |
| `fl_chart` | `1.2.0` | Finance charts (pie and bar), active since Phase 3 |
| `flutter_bloc` | `9.1.1` | Flutter widgets for BLoC/Cubit |
| `flutter_localizations` | SDK bundle | Material/Cupertino translated widget strings |
| `get_it` | `9.2.1` | Service locator / dependency injection container |
| `go_router` | `17.2.0` | Declared but not wired yet (navigation is `Navigator` plus a tab shell) |
| `injectable` | `2.7.1+4` | Annotation-driven DI registration on top of GetIt |
| `intl` | `0.20.2` | Date/number formatting and localization support |
| `isar_community` | `3.3.2` | On-device NoSQL database (community fork of abandoned `isar`) |
| `isar_community_flutter_libs` | `3.3.2` | Compiled binary companion to `isar_community` |
| `path_provider` | `2.1.5` | Platform-appropriate file system paths |
| `shared_preferences` | `2.5.5` | Lightweight key-value persistence for user preferences |

### Dev Dependencies

Declared in `pubspec.yaml` under `dev_dependencies`:

| Package | Version | Purpose |
|---------|---------|---------|
| `bloc_test` | `10.0.0` | Unit testing helpers for Cubit/BLoC |
| `build_runner` | `^2.13.1` | Code generation pipeline runner |
| `flutter_lints` | `6.0.0` | Flutter-recommended lint rules baseline |
| `flutter_test` | SDK bundle | Flutter widget and unit testing framework |
| `injectable_generator` | `2.12.1` | Generates `injection.config.dart` from `@injectable` annotations |
| `isar_community_generator` | `3.3.2` | Generates `.g.dart` schema files from `@Collection` annotations |
| `mocktail` | `1.0.5` | Mock creation without code generation (preferred over `mockito`) |
| `very_good_analysis` | `10.2.0` | Strict lint rule set (VGV) extended by `analysis_options.yaml` |

### Phase-Gated Dependencies (currently commented out)

These packages are declared in `pubspec.yaml` but commented out until the corresponding phase begins (`pubspec.yaml` is the source of truth):

| Package | Version | Phase |
|---------|---------|-------|
| `csv` | `8.0.0` | Phase 4 — Backup/export |
| `file_picker` | `11.0.2` | Phase 4 — Backup/import |
| `flutter_local_notifications` | `21.0.0` | Phase 4 — Notifications |
| `flutter_timezone` | `5.0.2` | Phase 4 — Timezone-aware scheduling |
| `timezone` | `0.11.0` | Phase 4 — Timezone-aware scheduling |
| `flutter_screen_lock` | `9.2.2+2` | Phase 5 — App lock PIN UI |
| `flutter_secure_storage` | `10.0.0` | Phase 5 — Secure PIN hash storage |
| `local_auth` | `3.0.1` | Phase 5 — Biometric authentication |

To activate a phase's packages, uncomment the relevant lines in `pubspec.yaml` and run `flutter pub get`.

---

## Code Generation

Two code generators run via `build_runner`:

1. **`isar_community_generator`** — produces `.g.dart` schema files from `@Collection`-annotated model classes.
2. **`injectable_generator`** — produces `lib/config/di/injection.config.dart` from `@injectable`, `@singleton`, and `@module` annotations.

Run generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated code is **committed to the repository**: `lib/generated/l10n`, every `.g.dart` file, and `lib/config/di/injection.config.dart`. `analysis_options.yaml` excludes these paths from analysis only:

- `lib/generated/**`
- `lib/config/di/injection.config.dart`
- `**/*.g.dart`

Regenerate after changing ARB files, Isar models or injectable annotations. CI also runs code generation before `flutter analyze` and `flutter test` to ensure the generated files are up to date.

---

## Lint and Static Analysis

**File:** `analysis_options.yaml`

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - lib/generated/**
    - lib/config/di/injection.config.dart
    - "**/*.g.dart"
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore

linter:
  rules:
    public_member_api_docs: false
```

- The base rule set is `very_good_analysis` (strict VGV rules), extended here with project-specific overrides.
- `missing_required_param` and `missing_return` are promoted to errors (build-breaking).
- `public_member_api_docs` is disabled — internal API documentation is encouraged but not enforced.
- TODOs in source code are silenced at the analysis level.

CI enforces analysis with `flutter analyze --no-fatal-infos --fatal-warnings`.

---

## Localization

**Primary configuration file:** `l10n.yaml` (project root)

```yaml
arb-dir: lib/config/l10n
template-arb-file: app_pt_BR.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/generated/l10n
preferred-supported-locales:
  - pt_BR
  - en
nullable-getter: false
```

A second identical file exists at `lib/config/l10n/l10n.yaml` with `synthetic-package: false` added.

### Supported Locales

| Locale tag | Language | Status |
|------------|----------|--------|
| `pt_BR` | Portuguese (Brazil) | Default |
| `en` | English | Translations in place; the in-app language switch arrives with Settings in Phase 5 |

**ARB source files:**

| File | Locale |
|------|--------|
| `lib/config/l10n/app_pt_BR.arb` | PT-BR (template) |
| `lib/config/l10n/app_en.arb` | English |
| `lib/config/l10n/app_pt.arb` | Portuguese (generic) |

### Generated Output

`flutter gen-l10n` writes to `lib/generated/l10n/`. The output is committed, and excluded from analysis only. Re-run `flutter gen-l10n` after editing any ARB file; CI also runs it as a build step.

### Locale Selection at Runtime

`LocaleCubit` (`lib/application/shared/locale/locale_cubit.dart`) reads the stored locale from `SharedPreferences` on startup. When no preference is stored, PT-BR is used as the default. The locale choice is persisted as an IETF language tag string (`'pt'` or `'en'`) under the `StorageKeys.locale` key. `LocaleCubit.setLocale` has no caller yet; the in-app language switch belongs to the Settings screen in Phase 5.

```dart
// Supported locales (must match l10n.yaml preferred-supported-locales)
static const List<Locale> supportedLocales = [
  Locale('pt', 'BR'),
  Locale('en'),
];

// Default locale (D-21)
static const Locale defaultLocale = Locale('pt', 'BR');
```

---

## Dependency Injection

**Entry point:** `lib/config/di/injection.dart`

`configureDependencies()` must be `await`ed in `main()` before `runApp()`. It initialises the GetIt graph, including pre-resolving the `SharedPreferences` async singleton.

DI is split into module files under `lib/config/di/`:

| Module file | Registrations |
|-------------|--------------|
| `core_module.dart` | `IsarService` (singleton), `SharedPreferences` (async pre-resolved singleton) |
| `tasks_module.dart` | `ItemDao` and `ItemMapper` (lazy singletons) |
| `finance_module.dart` | The six finance DAOs and six mappers (lazy singletons) |
| `infrastructure_module.dart` | Empty placeholder until the platform services of Phases 4-5 |

Repository implementations and cubits are not listed in the modules: they register themselves through `@LazySingleton(as: ...)` and `@injectable` class annotations. The generated registration glue lives in `lib/config/di/injection.config.dart` (do not edit manually).

---

## Database Configuration

**Service:** `lib/data/database/isar_service.dart`

Isar opens the database in the platform's application documents directory (`getApplicationDocumentsDirectory()`). The database is a process-wide singleton (`IsarService.instance`).

### Schema Versioning and Migrations

Schema version is the single source of truth in `AppConfig.schemaVersion` (currently `3`). The version is also persisted to `SharedPreferences` under `StorageKeys.schemaVersion` so `MigrationRunner` can read it before Isar opens.

**Migration runner:** `lib/data/database/migration_runner.dart`

| Schema version | Change |
|----------------|--------|
| 1 | Initial schema — no data migration needed |
| 2 | Add `ItemModel` collection (tasks, projects, subtasks) |
| 3 | Finance collections added; 13 default transaction categories seeded (9 expense, 4 income) |

To add a migration: bump `AppConfig.schemaVersion` and add a new `case` block in `MigrationRunner._runMigration`.

---

## SharedPreferences Keys

All `SharedPreferences` key strings are centralised in `lib/core/constants/storage_keys.dart` to prevent typo-related bugs:

| Key constant | String value | Type | Description |
|-------------|-------------|------|-------------|
| `StorageKeys.schemaVersion` | `'schema_version'` | `int` | Current Isar schema version; read by `MigrationRunner` before Isar opens |
| `StorageKeys.locale` | `'locale'` | `String` | Active locale IETF tag (`'pt'` or `'en'`); written by `LocaleCubit` |
| `StorageKeys.privacyStatementShown` | `'privacy_statement_shown'` | `bool` | Whether the first-launch privacy statement has been dismissed (UX-03) |
| `StorageKeys.pinConfigured` | `'pin_configured'` | `bool` | Whether an app lock PIN is set (DATA-05, Phase 5) |
| `StorageKeys.lockTimeoutSeconds` | `'lock_timeout_seconds'` | `int` | App lock auto-lock delay in seconds; `0` = lock immediately on background |
| `StorageKeys.quietHoursEnabled` | `'quiet_hours_enabled'` | `bool` | Whether notification quiet hours are active (NOTF-10, Phase 4) |
| `StorageKeys.quietHoursStart` | `'quiet_hours_start'` | `int` | Quiet hours start hour 0–23 |
| `StorageKeys.quietHoursEnd` | `'quiet_hours_end'` | `int` | Quiet hours end hour 0–23 |

Only `schemaVersion` (read and written by `MigrationRunner`) and `locale` (read and written by `LocaleCubit`) are used today. The remaining keys are reserved for Phases 4 and 5.

---

## Application Constants

Project-wide magic numbers are defined in `lib/core/constants/app_constants.dart`:

| Constant | Value | Description |
|----------|-------|-------------|
| `AppConstants.undoSnackbarDuration` | `Duration(seconds: 5)` | Undo window for soft-deleted tasks (TASK-05) |
| `AppConstants.iosMaxScheduledNotifications` | `64` | iOS platform limit for scheduled notifications (Phase 4) |
| `AppConstants.budgetAlertThresholdLow` | `0.80` | 80% budget used — triggers first budget alert (NOTF-03) |
| `AppConstants.budgetAlertThresholdHigh` | `1.00` | 100% budget used — triggers second budget alert (NOTF-03) |
| `AppConstants.quietHoursStartHour` | `22` | Default quiet hours start (22:00) |
| `AppConstants.quietHoursEndHour` | `7` | Default quiet hours end (07:00) |
| `AppConstants.rule135BigTasks` | `1` | 1-3-5 Rule: large task slots per day (TASK-08) |
| `AppConstants.rule135MediumTasks` | `3` | 1-3-5 Rule: medium task slots per day |
| `AppConstants.rule135SmallTasks` | `5` | 1-3-5 Rule: small task slots per day |

The budget alert thresholds and quiet-hours constants are not referenced anywhere outside `app_constants.dart` yet; they are reserved for Phase 4. Budgets currently show a live progress bar only.

---

## Notification ID Namespaces

Notification IDs follow a deterministic derivation scheme defined in `AppConfig`:

```
notificationId = entityId * notificationBase + notificationType
```

| Constant | Value | Namespace |
|----------|-------|-----------|
| `AppConfig.taskNotificationBase` | `10` | Task reminders |
| `AppConfig.financeNotificationBase` | `20` | Finance/budget alerts |
| `AppConfig.systemNotificationBase` | `30` | System notifications (daily briefing, motivational) |

---

## CI Configuration

**File:** `.github/workflows/ci.yml`

Triggers on push and pull request to `main`. Steps in order:

1. Checkout repository
2. Set up Flutter `3.41.4` (stable, cached)
3. `flutter pub get`
4. `dart run build_runner build --delete-conflicting-outputs`
5. `flutter gen-l10n`
6. `flutter analyze --no-fatal-infos --fatal-warnings`
7. Architecture guard — `dart run tool/check_architecture.dart` (see [DEVELOPMENT.md](DEVELOPMENT.md))
8. Isar Core warm-up — `flutter test --no-pub -j 1 test/support/_warm_isar_core_test.dart`. This must stay a `flutter test` invocation, not `dart run`, because of how the Isar Core binary download path is resolved. It pre-fetches the binary once, before the full suite fans out.
9. `flutter test --no-pub --coverage` (the full suite, with coverage)
10. Offline guarantee check (last) — fails the build if any forbidden network package (`http`, `dio`, `firebase_*`, `sentry_flutter`, `connectivity_plus`) appears in `pubspec.yaml`

`dart format` is not enforced in CI, because the tree is not uniformly format-clean.

---

## Privacy Constraint Enforcement

AGENDA has a hard constraint: no data may leave the device. The CI pipeline enforces this mechanically by scanning `pubspec.yaml` for any of the following forbidden package prefixes:

- `http:`
- `dio:`
- `firebase_`
- `sentry_flutter`
- `connectivity_plus`

Adding any of these packages will cause the CI `Verify offline guarantee` step to fail with a non-zero exit code.
