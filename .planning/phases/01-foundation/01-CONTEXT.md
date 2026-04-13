# Phase 1: Foundation - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Set up a runnable Flutter app with correct clean architecture, Isar open and migration-safe, DI wired, l10n scaffolded for EN + PT-BR, and the offline guarantee provably in place. No feature code, no domain entities, no UI screens beyond a bare app shell.

Requirements: DATA-01 (local-only storage), UX-02 (100% offline)

</domain>

<decisions>
## Implementation Decisions

### App Identity
- **D-01:** Package name: `com.omeu.space.agenda`
- **D-02:** Display name: `AGENDA` (all caps)
- **D-03:** Scaffold for Android + iOS only — no web or desktop directories
- **D-04:** Minimum Flutter SDK: 3.38.1 (required by flutter_local_notifications v21)

### Failure Modeling
- **D-05:** Domain failures use a sealed `Failure` abstract class hierarchy — no exceptions in domain layer; exhaustive pattern matching at call sites
- **D-06:** Failure types are per-layer: `DatabaseFailure`, `ValidationFailure`, `NotificationFailure`, `BackupFailure`, `SecurityFailure` — defined in `core/failures/`
- **D-07:** Domain layer returns `Either<Failure, T>` or `Result<T>` — failures are values, never thrown

### Environment Configuration
- **D-08:** No env vars or dart-define flags — the app is fully local with no backend endpoints
- **D-09:** A single `AppConfig` class in `core/config/` holds compile-time constants: app name, version string, schema version integer, notification namespace ranges
- **D-10:** Debug vs release differences limited to logging only — verbose output in debug via `kDebugMode`, silent in release

### Code Quality
- **D-11:** Linting ruleset: `very_good_analysis` — strict rules enforce Clean Architecture layer boundaries and catch common Dart/Flutter issues
- **D-12:** Phase 1 testing scope: unit tests for `MigrationRunner`, `Failure` types, and `AppConfig` — skip trivial DI wiring code
- **D-13:** Test file co-location: `test/` mirrors `lib/` structure (e.g., `test/core/failures/` for `lib/core/failures/`)

### Architecture Conventions (carry forward to all phases)
- **D-14:** Layer order: `core/ → domain/ → data/ → infrastructure/ → application/ → presentation/ → config/`; strict outer-depends-on-inner; `domain/` has zero Flutter imports
- **D-15:** All Isar-persisted enums annotated with `@enumerated(EnumType.name)` — convention established in Phase 1 before any schema code is written
- **D-16:** `IsarService` lives in `data/database/`; `MigrationRunner` called inside `IsarService.open()`; `schemaVersion` stored in `SharedPreferences` (readable before Isar opens)
- **D-17:** GetIt + injectable — `@injectable` annotations on all services/repositories; `configureDependencies()` called in `main()` before `runApp()`
- **D-18:** DI modules split by domain from day one: `CoreModule`, `TasksModule`, `FinanceModule`, `InfrastructureModule` — no single flat registration file
- **D-19:** `FlutterFragmentActivity` replaces `MainActivity` in `android/app/src/main/kotlin/` during Phase 1 scaffold — required for `local_auth` biometrics (DATA-06)

### Localization
- **D-20:** Official `flutter gen-l10n` with ARB files — no third-party i18n package
- **D-21:** Two locales: `en` and `pt_BR`; `pt_BR` is the default locale
- **D-22:** ARB files in `lib/config/l10n/` — `app_en.arb` and `app_pt_BR.arb`
- **D-23:** Locale switching state managed by a `LocaleCubit` in `application/shared/` — persisted in `SharedPreferences`

### Claude's Discretion
- Specific extension methods to include in `core/extensions/`
- Internal structure of `AppConfig` (static class vs singleton)
- Whether to use `go_router` or Navigator 2.0 directly (go_router recommended by research)
- CI smoke test tooling (GitHub Actions vs local script)

</decisions>

<specifics>
## Specific Ideas

- `isar_community` 3.3.2 — NOT the original `isar` package (abandoned April 2023); import path is `package:isar_community/isar_community.dart`
- Notification ID strategy: `taskId * 10 + notificationType` — defined as constants in `core/constants/notification_ids.dart` in Phase 1 even though notifications ship in Phase 4
- `FlutterFragmentActivity` must be set in Phase 1 before any auth code — required for `local_auth`

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — vision, constraints, key decisions (isar_community, infrastructure layer, enum convention, migration runner design)
- `.planning/REQUIREMENTS.md` — v1 requirements; Phase 1 covers DATA-01, UX-02
- `.planning/STATE.md` — pre-phase decisions log
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and plan titles

### Research
- `.planning/research/STACK.md` — verified package versions, isar_community drop-in migration, flutter_local_notifications v21 Flutter SDK floor, injectable code-gen setup
- `.planning/research/ARCHITECTURE.md` — layer structure, build order, DI module splitting, cross-cutting concerns pattern
- `.planning/research/PITFALLS.md` — Isar enum ordinal risk (D-15), migration runner design (D-16), notification IDs (D-09), FlutterFragmentActivity requirement (D-19)
- `.planning/research/SUMMARY.md` — critical risks and pre-phase decisions summary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — Flutter project not yet scaffolded; `legacy/` contains archived web version (not relevant)

### Established Patterns
- None yet — Phase 1 establishes all patterns

### Integration Points
- Phase 1 output is the foundation every other phase builds on; all layer conventions set here propagate to Phases 2–5

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 1 scope.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-04-13*
