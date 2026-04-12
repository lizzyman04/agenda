# Stack Research — AGENDA

**Researched:** 2026-04-12
**Flutter target:** 3.x (stable channel)
**Overall confidence:** MEDIUM-HIGH (all versions verified from pub.dev; Isar status is the main open risk)

---

## Pre-decided Core Stack (verified versions)

| Package | Latest Stable | Last Published | Status | Notes |
|---------|--------------|----------------|--------|-------|
| `isar` | 3.1.0+1 | Apr 2023 | CAUTION — abandoned by original author | See critical note below |
| `isar_flutter_libs` | 3.1.0+1 | Apr 2023 | CAUTION — same repo, same status | Required binary companion to `isar` |
| `isar_community` | 3.3.2 | ~Mar 2026 | ACTIVE (community fork) | Drop-in replacement; actively patched |
| `isar_community_flutter_libs` | 3.3.2 | ~Mar 2026 | ACTIVE | Binary companion for the community fork |
| `flutter_bloc` | 9.1.1 | ~May 2025 | ACTIVE | Maintained by felangel.dev |
| `bloc` | (same release) | ~May 2025 | ACTIVE | Core Dart package, same publisher |
| `get_it` | 9.2.1 | ~Feb 2026 | ACTIVE | Maintained, widely used |
| `flutter_local_notifications` | 21.0.0 | ~Mar 2026 | ACTIVE | Requires Flutter SDK ≥ 3.38.1; compile SDK 35+ |
| `file_picker` | 11.0.2 | ~Apr 2026 | ACTIVE | Very recently updated |
| `path_provider` | 2.1.5 | Oct 2024 | ACTIVE | Stable, official Flutter team package |

### Critical Note — Isar Maintenance

The original `isar` package (by @simc) has been **abandoned** since April 2023. The Isar 4.0 prerelease (4.0.0-dev.14) stalled two years ago and has no active development path.

**Recommendation:** Use `isar_community` 3.3.2 + `isar_community_flutter_libs` 3.3.2 instead. The API is identical to `isar` 3.x (drop-in swap). The community fork focuses on bug fixes and stability. It published 3.3.2 in March 2026, confirming active maintenance. Quality concerns have been raised in GitHub discussions (CI failures merged, non-conventional commits), so lock the version explicitly and pin test before upgrading.

```yaml
# Use these instead of isar / isar_flutter_libs
isar_community: 3.3.2
isar_community_flutter_libs: 3.3.2

dev_dependencies:
  isar_community_generator: 3.3.2
```

**Confidence:** HIGH (verified from pub.dev + GitHub issue #1689 confirming abandonment + community fork pub.dev page confirming Mar 2026 publish).

---

## Recommended Supporting Packages

### Isar Code Generation

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `isar_community_generator` | 3.3.2 | Generates `.g.dart` schema files from `@Collection` annotations | HIGH |
| `build_runner` | 2.13.1 | Runs code generation pipeline (`flutter pub run build_runner build`) | HIGH |

These are mandatory for Isar — the database schema code is generated, not hand-written.

---

### Dependency Injection (GetIt Enhancement)

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `injectable` | 2.7.1+4 | Annotation-driven DI registration on top of GetIt | HIGH |
| `injectable_generator` | 2.12.1 | Generates `injection.config.dart` from `@injectable` / `@singleton` annotations | HIGH |

**Rationale:** GetIt alone requires manual `sl.registerFactory(...)` calls everywhere. `injectable` generates this boilerplate from annotations (`@injectable`, `@singleton`, `@lazySingleton`), which is the standard pattern in Flutter Clean Architecture projects in 2025. Both packages are maintained by the same verified publisher (codeness.ly) as GetIt's ecosystem.

---

### State Equality (BLoC States and Events)

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `equatable` | 2.0.8 | Value equality for BLoC state/event classes without code generation | HIGH |

**Rationale:** Required for BLoC states to compare correctly (prevents rebuilds when state has not actually changed). No code generation overhead. The alternative — `freezed` — adds `build_runner` generation for `copyWith`, pattern matching, and immutability, which is powerful but heavier. For AGENDA's straightforward state classes, `equatable` is the right choice. If sealed class patterns (Dart 3+) are used for states, `equatable` still handles equality correctly alongside them.

**Note:** A 3.0.0-dev.1 prerelease exists. Stick with 2.0.8 stable.

---

### Scheduled Notifications (Required Companion Packages)

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `timezone` | 0.11.0 | TZDateTime objects required by `flutter_local_notifications.zonedSchedule()` | HIGH |
| `flutter_timezone` | 5.0.2 | Gets the device's current timezone string (IANA format) at runtime | HIGH |

**Rationale:** `flutter_local_notifications` v21 depends on `timezone` for any scheduled notifications. `flutter_timezone` provides the device's actual timezone, which the `timezone` package cannot discover on its own. Without these two, all scheduled reminders (morning briefings, debt due dates, budget alerts) will fire at wrong times.

---

### Charts / Data Visualization

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `fl_chart` | 1.2.0 | Line, bar, pie, radar charts for finance dashboards | HIGH |

**Rationale:** `fl_chart` is MIT-licensed, 6,200+ GitHub stars, actively maintained (published ~Mar 2026), and zero licensing cost. Syncfusion Flutter Charts has more chart types (30+) but requires a commercial license for revenue above $1M or teams > 5 people; it's overkill for AGENDA's needs. AGENDA needs: a bar/line chart for income vs. expenses over time, a pie/donut chart for spending by category, and a progress bar for savings goals. `fl_chart` handles all three with clean Flutter APIs.

---

### Security — App Lock (PIN / Biometrics)

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `flutter_screen_lock` | 9.2.2+2 | PIN/passcode lock screen UI, customizable, biometric integration hook | HIGH |
| `local_auth` | 3.0.1 | Platform biometric authentication (Face ID, fingerprint, device PIN) | HIGH |
| `flutter_secure_storage` | 10.0.0 | Stores the PIN hash securely in Keychain (iOS) / Encrypted SharedPrefs (Android) | HIGH |

**Rationale:**
- `flutter_screen_lock` provides the PIN entry UI and integrates with `local_auth` for biometric bypass. Version 9.2.2+2, published June 2025. Actively maintained.
- `local_auth` (official Flutter plugin) handles the platform biometric call. Version 3.0.1, published ~Feb 2026. Supports Face ID, fingerprint, weak and strong biometrics, with PIN/pattern fallback on Android.
- `flutter_secure_storage` stores the PIN hash. Never store PINs or passwords in `shared_preferences` (plain text on Android). Keychain/Encrypted SharedPrefs is the correct layer. Version 10.0.0, published Dec 2025.

---

### CSV Export / Import

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `csv` | 8.0.0 | RFC-compliant CSV encode/decode for export and import of tasks and transactions | HIGH |

**Rationale:** Pure Dart, MIT license, stream-friendly, handles quoted fields, Excel-compatible delimiters. Published ~Mar 2026. This is the standard CSV library in the Flutter ecosystem. `to_csv` and `json2csv_dart` are wrappers built on top of it — use the base library directly for full control over the AGENDA-specific export schema.

---

### Internationalization (EN + PT-BR)

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `intl` | 0.20.2 | Date/number formatting, plural rules, message extraction | HIGH |
| `flutter_localizations` | SDK bundle | Material/Cupertino widget string translations, locale delegates | HIGH |

**Rationale:** The Flutter-official approach uses ARB files + `l10n.yaml` + `flutter gen-l10n` (built into the Flutter CLI). This generates a type-safe `AppLocalizations` class. `intl` handles formatting (currencies, dates in PT-BR locale). `flutter_localizations` is bundled with the Flutter SDK and provides translated strings for built-in widgets. No third-party i18n package is needed for two languages — the official tooling covers this completely.

**No `slang` or `easy_localization` needed.** Those packages add value for teams managing 10+ languages via external translation services. For EN + PT-BR with static ARB files, they are unnecessary dependencies.

---

### Navigation

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `go_router` | 17.2.0 | Declarative routing, deep linking, route guards | HIGH |

**Rationale:** `go_router` is published by flutter.dev (official), widely adopted in 2025 BLoC + Clean Architecture projects, and handles the main navigation concern for AGENDA: protecting routes behind the PIN lock screen (route guards). Published 9 days ago as of research date, confirmed actively maintained. `auto_route` is a viable alternative but requires more code generation boilerplate — not justified for a single-user mobile app with a modest route count.

---

### Settings Persistence

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `shared_preferences` | 2.5.5 | Stores non-sensitive user preferences (language toggle, theme, notification prefs) | HIGH |

**Rationale:** Isar is the correct choice for domain data (tasks, transactions). For lightweight, non-relational settings (which locale is active, whether notifications are enabled), `shared_preferences` is appropriate and adds no meaningful complexity. It is NOT appropriate for the PIN hash (use `flutter_secure_storage` for that). Published ~Mar 2026, active.

---

### Testing

| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `bloc_test` | 10.0.0 | Cubit/BLoC unit testing with `whenListen`, `expectLater`, `blocTest()` | HIGH |
| `mocktail` | 1.0.5 | Mock creation without code generation (preferred over `mockito` for BLoC testing) | HIGH |

**Rationale:** `bloc_test` is published by felangel.dev (same publisher as flutter_bloc), designed specifically for BLoC/Cubit. `mocktail` avoids the `@GenerateMocks` annotation + build_runner overhead of `mockito`. Both are the standard testing pair in the BLoC ecosystem in 2025. `bloc_test` 10.0.0 ships with `mocktail` as an internal dependency, but declaring both explicitly in dev_dependencies is the documented practice.

---

## What NOT to Use

| Package | Reason to Avoid |
|---------|----------------|
| `isar` (original) | Abandoned since April 2023. No updates, no Isar 4. Use `isar_community` instead. |
| `isar_flutter_libs` (original) | Same abandonment as above. Use `isar_community_flutter_libs`. |
| `provider` | Superseded by Riverpod (and irrelevant here — BLoC is the decided state manager). Adding `provider` on top of BLoC creates confusion. |
| `riverpod` / `flutter_riverpod` | Wrong state manager for this project. Tech stack is decided: BLoC/Cubit only. |
| `hive` / `hive_flutter` | Redundant second database. Isar (community) covers all persistence needs. |
| `mockito` | Requires code generation (`@GenerateMocks` + build_runner). `mocktail` is simpler and is what the BLoC team uses. |
| `freezed` | Code-gen heavy. Justified for deeply nested union types, but for AGENDA's straightforward state classes, `equatable` is sufficient and adds zero build complexity. |
| `syncfusion_flutter_charts` | Requires paid commercial license for teams/revenue above thresholds. `fl_chart` (MIT) is fully sufficient for AGENDA's chart needs. |
| `easy_localization` | Third-party wrapper around `intl` that adds a runtime JSON loading layer. The official ARB + `flutter gen-l10n` pipeline is simpler for two languages. |
| `slang` | Designed for large-scale localization workflows. Unnecessary overhead for EN + PT-BR. |
| `firebase_*` (any) | Violates the privacy-first, no-data-leaves-device constraint. No analytics, no Crashlytics, no remote config. |
| `sentry_flutter` | Crash reporting goes to an external server. Violates the privacy constraint. |
| `connectivity_plus` | AGENDA requires zero internet. There is no conditional online/offline logic to gate. |
| `dio` / `http` | No network calls in MVP. Any network dependency signals a scope creep risk. |
| `flutter_native_timezone` | Superseded by `flutter_timezone` (same plugin, renamed). Do not use the old name. |
| `to_csv` / `json2csv_dart` | Wrappers over `csv`. Use the base `csv` package directly for schema control. |
| `get` (GetX) | Conflicts with the decided BLoC + GetIt architecture. GetX is an all-in-one opinionated framework, not composable with BLoC. |

---

## Compatibility Notes

### flutter_local_notifications v21 Requirements
Version 21.0.0 requires **Flutter SDK ≥ 3.38.1** and **compile SDK 35+** on Android. This is a hard lower bound for the Flutter version the project must target. Verify `compileSdkVersion = 35` is set in `android/app/build.gradle`.

### Isar Community vs Original API
`isar_community` is API-compatible with `isar` 3.x. The import path changes from `package:isar/isar.dart` to `package:isar_community/isar_community.dart`. The `@Collection`, `@Id`, `IsarCollection<T>`, and query builder APIs are identical. The pubspec anchor pattern is recommended:

```yaml
# pubspec.yaml anchor pattern — keeps all isar versions in sync
isar_version: &isar_version 3.3.2

dependencies:
  isar_community: *isar_version
  isar_community_flutter_libs: *isar_version

dev_dependencies:
  isar_community_generator: *isar_version
  build_runner: ^2.13.1
```

### flutter_screen_lock + local_auth Integration
`flutter_screen_lock` integrates with `local_auth` by accepting a `didOpened` callback that triggers biometric auth immediately on lock screen display. Both packages must be declared as separate dependencies — `flutter_screen_lock` does not bundle `local_auth`.

### Android: Exact Alarms Permission (API 31+)
`flutter_local_notifications` v21 on Android 12+ requires the `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` permission for precise scheduled notifications (morning briefings, debt reminders). Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```
`USE_EXACT_ALARM` (API 33+) does not require user grant at runtime but is restricted to specific app categories. `SCHEDULE_EXACT_ALARM` requires the user to grant it via system settings on Android 12+. Use `AndroidScheduleMode.exactAllowWhileIdle` in `zonedSchedule()` calls.

### iOS Notification Limit
iOS caps pending scheduled notifications at **64 per app**. AGENDA's notification types (daily briefing, task reminders, budget alerts, debt reminders, recurring payment reminders, motivational quotes) can accumulate quickly. Implement a notification budget manager that prioritizes high-value notifications and reschedules on app foreground.

### Dart 3 Sealed Classes vs Freezed
All BLoC states and events can use Dart 3 `sealed class` syntax (available since Flutter 3.10 / Dart 3.0) combined with `equatable` for comparison. This eliminates the need for `freezed` entirely:

```dart
sealed class TaskState extends Equatable { ... }
final class TaskLoaded extends TaskState { ... }
final class TaskError extends TaskState { ... }
```

Pattern matching via `switch` on sealed classes is available natively. This is the modern (2025) approach.

### build_runner Version Pinning
Do not use `build_runner: any` — pin to `^2.13.1`. The `any` constraint has caused version solve conflicts in multiple community reports when other code-gen packages (injectable_generator, isar_community_generator) resolve to incompatible build_runner versions.

### intl Version Alignment
The `intl` package version must match what `flutter_localizations` (bundled with the Flutter SDK) expects. When upgrading Flutter SDK, run `flutter pub upgrade intl` immediately — version mismatches between the SDK-bundled `flutter_localizations` and a pinned `intl` cause compilation errors.

---

## Recommended pubspec.yaml Skeleton

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.38.1'   # Required by flutter_local_notifications v21

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Database
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

  # Notifications
  flutter_local_notifications: ^21.0.0
  timezone: ^0.11.0
  flutter_timezone: ^5.0.2

  # File I/O
  file_picker: ^11.0.2
  path_provider: ^2.1.5

  # Security
  flutter_screen_lock: ^9.2.2
  local_auth: ^3.0.1
  flutter_secure_storage: ^10.0.0

  # CSV
  csv: ^8.0.0

  # Settings
  shared_preferences: ^2.5.5

  # Charts
  fl_chart: ^1.2.0

  # i18n
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Database code generation
  isar_community_generator: 3.3.2
  build_runner: ^2.13.1

  # Dependency injection code generation
  injectable_generator: ^2.12.1

  # Testing
  bloc_test: ^10.0.0
  mocktail: ^1.0.5
```

---

## Sources

- [isar package — pub.dev](https://pub.dev/packages/isar)
- [isar_community — pub.dev](https://pub.dev/packages/isar_community)
- [GitHub Issue #1689: "Isar is dead, long live Isar"](https://github.com/isar/isar/issues/1689)
- [isar_community_flutter_libs — pub.dev](https://pub.dev/packages/isar_community_flutter_libs)
- [isar_community_generator — pub.dev](https://pub.dev/packages/isar_community_generator)
- [flutter_bloc — pub.dev](https://pub.dev/packages/flutter_bloc)
- [bloc_test — pub.dev](https://pub.dev/packages/bloc_test)
- [mocktail — pub.dev](https://pub.dev/packages/mocktail)
- [get_it — pub.dev](https://pub.dev/packages/get_it)
- [injectable — pub.dev](https://pub.dev/packages/injectable)
- [injectable_generator — pub.dev](https://pub.dev/packages/injectable_generator)
- [flutter_local_notifications — pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [timezone — pub.dev](https://pub.dev/packages/timezone)
- [flutter_timezone — pub.dev](https://pub.dev/packages/flutter_timezone)
- [file_picker — pub.dev](https://pub.dev/packages/file_picker)
- [path_provider — pub.dev](https://pub.dev/packages/path_provider)
- [fl_chart — pub.dev](https://pub.dev/packages/fl_chart)
- [flutter_screen_lock — pub.dev](https://pub.dev/packages/flutter_screen_lock)
- [local_auth — pub.dev](https://pub.dev/packages/local_auth)
- [flutter_secure_storage — pub.dev](https://pub.dev/packages/flutter_secure_storage)
- [csv — pub.dev](https://pub.dev/packages/csv)
- [equatable — pub.dev](https://pub.dev/packages/equatable)
- [shared_preferences — pub.dev](https://pub.dev/packages/shared_preferences)
- [go_router — pub.dev](https://pub.dev/packages/go_router)
- [intl — pub.dev](https://pub.dev/packages/intl)
- [build_runner — pub.dev](https://pub.dev/packages/build_runner)
- [Flutter Localization official docs](https://docs.flutter.dev/ui/internationalization)
- [Stop Using These Flutter Packages in 2026 — Medium](https://medium.com/@gurlekyunusemre2/stop-using-these-flutter-packages-in-2026-579b2e4c9d12)
