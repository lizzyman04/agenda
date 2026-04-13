<!-- GSD:project-start source:PROJECT.md -->
## Project

**AGENDA**

AGENDA is a privacy-first Flutter mobile app (Android + iOS) that serves as a personal HQ for task management and personal finances. It combines structured productivity frameworks (Eisenhower Matrix, 1-3-5 Rule, GTD) with full financial tracking (income, expenses, budgets, savings goals) — all stored exclusively on the user's device, with no server or cloud dependency.

**Core Value:** A user should be able to open AGENDA at any moment — morning, midday, or night — and immediately see what needs doing and where their money stands, without ever needing an internet connection.

### Constraints

- **Privacy**: No data may leave the device — no analytics, no crash reporting to external services, no cloud sync in MVP
- **Tech Stack**: Flutter + Isar + BLoC/Cubit + GetIt — these are decided, not up for debate
- **Platform**: Mobile only (Android + iOS) — no web, no desktop in MVP
- **Connectivity**: App must be 100% functional offline — no feature may require internet
- **Language**: All code in English; UI text in PT-BR with EN toggle
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
# Use these instead of isar / isar_flutter_libs
## Recommended Supporting Packages
### Isar Code Generation
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `isar_community_generator` | 3.3.2 | Generates `.g.dart` schema files from `@Collection` annotations | HIGH |
| `build_runner` | 2.13.1 | Runs code generation pipeline (`flutter pub run build_runner build`) | HIGH |
### Dependency Injection (GetIt Enhancement)
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `injectable` | 2.7.1+4 | Annotation-driven DI registration on top of GetIt | HIGH |
| `injectable_generator` | 2.12.1 | Generates `injection.config.dart` from `@injectable` / `@singleton` annotations | HIGH |
### State Equality (BLoC States and Events)
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `equatable` | 2.0.8 | Value equality for BLoC state/event classes without code generation | HIGH |
### Scheduled Notifications (Required Companion Packages)
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `timezone` | 0.11.0 | TZDateTime objects required by `flutter_local_notifications.zonedSchedule()` | HIGH |
| `flutter_timezone` | 5.0.2 | Gets the device's current timezone string (IANA format) at runtime | HIGH |
### Charts / Data Visualization
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `fl_chart` | 1.2.0 | Line, bar, pie, radar charts for finance dashboards | HIGH |
### Security — App Lock (PIN / Biometrics)
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `flutter_screen_lock` | 9.2.2+2 | PIN/passcode lock screen UI, customizable, biometric integration hook | HIGH |
| `local_auth` | 3.0.1 | Platform biometric authentication (Face ID, fingerprint, device PIN) | HIGH |
| `flutter_secure_storage` | 10.0.0 | Stores the PIN hash securely in Keychain (iOS) / Encrypted SharedPrefs (Android) | HIGH |
- `flutter_screen_lock` provides the PIN entry UI and integrates with `local_auth` for biometric bypass. Version 9.2.2+2, published June 2025. Actively maintained.
- `local_auth` (official Flutter plugin) handles the platform biometric call. Version 3.0.1, published ~Feb 2026. Supports Face ID, fingerprint, weak and strong biometrics, with PIN/pattern fallback on Android.
- `flutter_secure_storage` stores the PIN hash. Never store PINs or passwords in `shared_preferences` (plain text on Android). Keychain/Encrypted SharedPrefs is the correct layer. Version 10.0.0, published Dec 2025.
### CSV Export / Import
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `csv` | 8.0.0 | RFC-compliant CSV encode/decode for export and import of tasks and transactions | HIGH |
### Internationalization (EN + PT-BR)
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `intl` | 0.20.2 | Date/number formatting, plural rules, message extraction | HIGH |
| `flutter_localizations` | SDK bundle | Material/Cupertino widget string translations, locale delegates | HIGH |
### Navigation
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `go_router` | 17.2.0 | Declarative routing, deep linking, route guards | HIGH |
### Settings Persistence
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `shared_preferences` | 2.5.5 | Stores non-sensitive user preferences (language toggle, theme, notification prefs) | HIGH |
### Testing
| Package | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| `bloc_test` | 10.0.0 | Cubit/BLoC unit testing with `whenListen`, `expectLater`, `blocTest()` | HIGH |
| `mocktail` | 1.0.5 | Mock creation without code generation (preferred over `mockito` for BLoC testing) | HIGH |
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
## Compatibility Notes
### flutter_local_notifications v21 Requirements
### Isar Community vs Original API
# pubspec.yaml anchor pattern — keeps all isar versions in sync
### flutter_screen_lock + local_auth Integration
### Android: Exact Alarms Permission (API 31+)
### iOS Notification Limit
### Dart 3 Sealed Classes vs Freezed
### build_runner Version Pinning
### intl Version Alignment
## Recommended pubspec.yaml Skeleton
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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
