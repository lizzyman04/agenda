# Research Summary — AGENDA

**Project:** AGENDA
**Domain:** Offline-first Flutter mobile app — task management + personal finance
**Researched:** 2026-04-12
**Confidence:** HIGH

---

## Recommended Stack

The pre-decided stack (Flutter + Isar + BLoC/Cubit + GetIt + flutter_local_notifications) is sound. One critical correction is required: the original `isar` package has been abandoned since April 2023 and must be replaced with the community fork `isar_community` 3.3.2. The API is drop-in compatible; only the import path and pubspec entries change. Lock all three isar_community packages to the same version via a YAML anchor.

The stack requires these additions not listed in PROJECT.md: `injectable` + `injectable_generator` (annotation-driven DI on top of GetIt), `equatable` (BLoC state equality), `go_router` (declarative routing with PIN guard), `timezone` + `flutter_timezone` (required for scheduled notifications), `fl_chart` (finance charts), `flutter_screen_lock` + `local_auth` + `flutter_secure_storage` (app lock), `csv` (backup), and `shared_preferences` (settings). The minimum Flutter SDK is **3.38.1** due to flutter_local_notifications v21.

**Core technologies:**
- `isar_community` 3.3.2: local embedded database — community fork of abandoned original; actively maintained as of Mar 2026
- `flutter_bloc` 9.1.1 + `equatable` 2.0.8: state management — equatable is mandatory for correct BLoC state comparison
- `get_it` 9.2.1 + `injectable` 2.7.1: dependency injection — injectable generates boilerplate, essential for Clean Architecture at this scale
- `go_router` 17.2.0: navigation — official Flutter plugin; route guards enable PIN lock enforcement
- `flutter_local_notifications` 21.0.0 + `timezone` + `flutter_timezone`: scheduled notifications — all three are required together; timezone initialization must happen in `main()` before `runApp()`
- `flutter_screen_lock` 9.2.2 + `local_auth` 3.0.1 + `flutter_secure_storage` 10.0.0: app lock — PIN must be stored in secure storage, never Isar or SharedPreferences
- `fl_chart` 1.2.0: finance charts — MIT license, sufficient for bar/line/pie charts needed
- `csv` 8.0.0: backup serialization — pure Dart, handles round-trip export/import
- `intl` 0.20.2 + `flutter_localizations` (SDK): i18n — official ARB tooling is sufficient for EN + PT-BR; no third-party i18n package needed

**Packages to avoid:** original `isar`/`isar_flutter_libs` (abandoned), `firebase_*` (violates privacy constraint), `freezed` (unnecessary overhead for straightforward state classes), `riverpod`/`provider` (wrong state manager), `syncfusion_flutter_charts` (paid license), `easy_localization`/`slang` (overkill for two languages), `dio`/`http` (no network calls).

---

## Table Stakes Features

Features users universally expect that must be in v1. Items marked [GAP] are not explicitly listed in PROJECT.md.

**Task management:**
- Create, edit, delete tasks with due date + time
- Mark complete, recurring tasks, subtasks, project grouping
- Eisenhower Matrix, 1-3-5 Rule, GTD contexts (core differentiators)
- Task reminders and daily morning briefing
- **[GAP] Search across tasks** — users abandon apps without this; no new infrastructure required
- **[GAP] Undo on task delete** (5-second snackbar) — accidental delete destroys trust; soft delete needed

**Finance management:**
- Log income/expenses with categories, budget per category
- Savings goals with progress, debt tracking (owe + owed), recurring payments
- Balance/net worth overview on dashboard
- **[GAP] Spending summary charts** (monthly by category, pie/bar) — most-requested finance visualization; `fl_chart` already in stack
- Budget rollover toggle per category [low priority gap]

**Notifications:**
- Task due reminders, budget alerts at threshold (default 80%, not just 100%), recurring payment reminders, debt due reminders
- Per-type opt-in/opt-out with independent toggles
- Respect quiet hours (default 10pm-7am)
- **[GAP] Snooze action on task reminders** (15 min / 1 hr / tomorrow) — standard iOS/Android notification expectation
- Motivational quotes default OFF; max 1/day; user-configurable time

**Data/privacy:**
- All data local, JSON + CSV export, import from backup, app lock (PIN)
- **[GAP] Biometric unlock** (fingerprint / Face ID) — PIN alone is friction; finance apps universally pair PIN with biometrics; `local_auth` already in stack
- **[GAP] Onboarding privacy statement** ("your data never leaves this device") — essential trust signal for local-first positioning; one screen, no new infrastructure

**Should defer to v2+:**
- Multi-currency (do not hard-code one symbol in v1 but do not build the feature)
- Budget rollover toggle (low priority gap)
- Natural language task input
- Cloud sync (explicitly out of scope)

---

## Architecture Guidance

Use layered Clean Architecture with feature sub-namespacing: `core/` -> `domain/` -> `data/` -> `infrastructure/` -> `application/` -> `presentation/` -> `config/`. The `infrastructure/` directory is a recommended addition to the pre-decided structure — it houses concrete implementations of notification, backup, and app lock services that have Flutter/platform dependencies and belong neither in `data/` (not a database concern) nor `domain/` (not pure Dart). The `config/` directory handles DI wiring, routing, and l10n.

The strict dependency rule — outer layers depend on inner layers, never the reverse — must be enforced from Phase 1. Domain entities (`Task`, `Transaction`, etc.) are plain Dart classes with no Isar annotations. Isar schemas (`TaskModel`) live only in `data/` and map to/from domain entities at the repository boundary. Cubits receive abstract repository interfaces injected by GetIt, never concrete implementations.

Build order from the architecture research: foundation (core, l10n, IsarService, DI scaffold) -> tasks domain -> finance domain -> shared infrastructure (notifications, backup, app lock). This ensures domain shapes Isar models, not the reverse, and infrastructure is built on stable domain entities.

**Major components:**
1. `core/` — pure Dart: enums, constants, extensions, failure hierarchy; zero Flutter imports
2. `domain/tasks/` + `domain/finance/` — plain Dart entities, abstract repository interfaces, domain services
3. `data/tasks/` + `data/finance/` — Isar schemas, repository implementations, model mappers
4. `infrastructure/notifications/` + `infrastructure/backup/` + `infrastructure/security/` — concrete platform service implementations
5. `application/tasks/` + `application/finance/` + `application/shared/` — BLoC/Cubit layer; each Cubit owns one cohesive state slice
6. `presentation/` — Flutter widgets only; depends on application layer; domain entities may be used for display but not directly queried
7. `config/di/` + `config/routes/` + `config/l10n/` — wiring layer; the only place that sees all other layers

**Cross-domain coordination rule:** `TaskCubit` must never reference `BudgetCubit` or any finance entity. A `HomeDashboardCubit` in `application/shared/` that reads from both repositories is the correct pattern for the home screen.

---

## Critical Risks

These are the pitfalls most likely to cause data loss, security failure, or fundamental feature breakage if not addressed in the phase indicated.

**1. Isar enum ordinal corruption — Phase 1**
Default Isar enum storage uses ordinal index. Reordering any enum after data exists silently corrupts all existing records. Fix: annotate every Isar-persisted enum with `@enumerated(EnumType.name)` before writing the first collection. This is a project-wide convention that must be established before Phase 1 schema design.

**2. No schema migration infrastructure — Phase 1**
Isar has no built-in migration runner. Adding or backfilling computed fields on existing records requires a hand-rolled migration. Fix: store a `schemaVersion` integer in SharedPreferences at first launch; compare on every cold start and run sequential migration blocks. This infrastructure must exist before the first production schema is finalized.

**3. Notifications lost after device reboot — Phase 2**
Android's AlarmManager does not survive reboot. All scheduled notifications (task reminders, morning briefing, debt alerts) are wiped. Fix: declare `RECEIVE_BOOT_COMPLETED` in AndroidManifest, register `ScheduledNotificationBootReceiver`, and persist all scheduled notification payloads to Isar for rescheduling on boot. Without this, the app's primary value driver (reliable notifications) silently stops working after any reboot.

**4. Backup import atomicity — Phase 2**
A failed mid-import leaves the database in a partially-replaced state with no rollback. Fix: validate the entire JSON file before writing any records, wrap the full import in a single `isar.writeTxn()`, export an automatic safety backup before every import, and require explicit user confirmation with record counts and date range shown.

**5. App lock state lost on cold start — Phase 3**
If lock state lives only in memory, an OS process kill exposes the user's financial data on next open. Fix: persist a `lastBackgroundedAt` timestamp in SharedPreferences (not Isar; it must be readable before Isar opens); on every cold start, show the PIN screen if a PIN is configured, regardless of elapsed time.

**Additional risks to monitor:**
- Android exact alarm permission (`SCHEDULE_EXACT_ALARM`) denied by default on Android 14+ — must be requested at runtime with graceful fallback to inexact
- Samsung 500-alarm hard cap — schedule only next N occurrences of recurring notifications; implement a notification budget
- iOS 64 pending notification limit — reschedule highest-priority 64 on every app foreground; motivational quotes are acceptable-drop candidates
- `local_auth` requires `FlutterFragmentActivity` on Android — change `MainActivity.kt` before any auth code is written
- iOS App Switcher bypasses lock — respond to `AppLifecycleState.inactive` with a privacy overlay, not just `paused`

---

## Feature Gaps (vs PROJECT.md)

Features research identified as standard user expectations not explicitly listed in PROJECT.md:

| Gap | Category | Priority | Rationale |
|-----|----------|----------|-----------|
| Search across tasks | Task Management | High | Universal expectation; users abandon apps without it; no new infrastructure |
| Biometric unlock (Face ID / fingerprint) | Data/Privacy | High | PIN alone is friction; finance apps universally pair PIN + biometrics; `local_auth` already in stack |
| Spending summary charts (monthly by category) | Finance | High | Most-requested finance visualization; `fl_chart` already in stack |
| Undo on task delete (5s snackbar) | Task Management | Medium | Accidental delete destroys trust; soft delete pattern is well-understood |
| Snooze action on task reminders | Notifications | Medium | Standard iOS/Android notification interaction |
| Empty state designs with action prompts | UX | Medium | Empty charts/lists without guidance cause abandonment |
| Onboarding privacy statement | UX/Trust | Medium | "Your data never leaves this device" — essential for local-first trust-building |
| Budget rollover toggle per category | Finance | Low | YNAB gap; differentiator; not blocking v1 |

---

## Key Pre-Phase Decisions

These decisions must be made before Phase 1 work begins:

**1. Confirm `isar_community` over original `isar`**
The original `isar` package is abandoned. Decision: use `isar_community` 3.3.2. Impacts pubspec.yaml, all import paths (`package:isar_community/isar_community.dart`), and all code references. Must be decided before writing a single data model.

**2. Add `infrastructure/` as a sixth layer**
The pre-decided Clean Architecture lists 6 layers: `core/`, `data/`, `domain/`, `application/`, `presentation/`, `config/`. Notification, backup, and app lock service implementations have Flutter/platform dependencies that fit neither `data/` nor `domain/`. Decision: add `infrastructure/` between `data/` and `application/` in the layer stack. If the owner prefers not to add a layer, these implementations can go in `data/shared/services/` — but the layer boundary must still be defined.

**3. Confirm `@enumerated(EnumType.name)` as project-wide convention**
Must be decided before writing any Isar schema. Affects: `TaskPriority`, `RecurrenceType`, `TransactionCategory`, `QuadrantType`, `GTDContext`, `DebtDirection`, and all future enums stored in collections.

**4. Confirm schema migration infrastructure design**
Decide the migration runner pattern before writing any production schema: where `schemaVersion` is stored (SharedPreferences), how migration blocks are structured, and who runs them (`IsarService.open()` -> `MigrationRunner`). This decision gates Phase 1 data layer.

**5. Define notification ID derivation strategy**
Deterministic notification IDs (e.g., `taskId * 10 + notificationType`) must be established before any notification is scheduled. This enables cancellation on task delete/update without a separate registry and prevents duplicates on boot reschedule. Must be decided before Phase 2 notification work.

**6. Confirm biometric + PIN scope for app lock**
PROJECT.md lists "optional password to lock access to the app." Research confirms biometric unlock is a user expectation alongside PIN, and `local_auth` is already in the stack. Decision needed: is biometric included in v1 or deferred? If included, `MainActivity.kt` must be changed to `FlutterFragmentActivity` before any auth code is written.

**7. Confirm search as in-scope for v1**
Search across tasks is a universal expectation not listed in PROJECT.md. Isar supports full-text and indexed field queries without additional infrastructure. Confirming scope before Phase 1 avoids retrofitting an index strategy after the schema is finalized.

---

## Implications for Roadmap

Based on combined research, the build order follows the architecture dependency chain: foundation first, tasks before finance (more complex domain reveals patterns), infrastructure last (notifications, lock, backup depend on stable entities).

### Phase 1: Foundation + Task Core
**Rationale:** `core/`, l10n scaffold, IsarService + migration runner, DI wiring, and the complete tasks domain (entities -> models -> repository -> Cubits -> UI) must come first. Tasks have the most domain complexity (recurrence, GTD, Eisenhower) and establish patterns finance will reuse. The enum annotation convention, migration infrastructure, and layer boundaries must be established here before any other domain copies the pattern.
**Delivers:** A working task manager (CRUD, projects, subtasks, due dates, recurring, Eisenhower, 1-3-5, GTD, search) with correct architecture in place.
**Must address:** Isar enum ordinal pitfall, schema migration infrastructure, l10n setup with ARB parity check, BLoC state equality convention, async emit-after-close pattern.

### Phase 2: Finance Core + Notifications + Backup
**Rationale:** Finance domain is structurally similar to tasks and can reuse established patterns. Notifications and backup ship together with finance because budget alerts, debt reminders, and recurring payment reminders are the finance module's primary value-add — shipping finance without its notification triggers is a half-feature. Backup is also grouped here since the finance data is the most sensitive and users will want export capability as soon as financial records exist.
**Delivers:** Complete finance module (transactions, budgets, goals, debts, recurring payments), all notification types wired and tested on both iOS and Android, JSON + CSV export/import with transactional safety.
**Must address:** Notifications-after-reboot (boot receiver), exact alarm permission flow, iOS 64-notification budget manager, timezone initialization, backup import atomicity, CSV locale-aware decimal parsing, notification ID derivation strategy, export schema versioning.

### Phase 3: App Lock + Settings + Polish
**Rationale:** App lock depends on stable domain entities and an open Isar database. It is a security feature that cannot have half-implementations, so it ships as a complete phase: PIN setup, biometric integration, lifecycle observer, cold-start lock enforcement, GoRouter guard. Settings and final UI polish (empty states, onboarding privacy screen, snooze on notifications) round out this phase before release readiness.
**Delivers:** Full app lock (PIN + biometrics), settings screen (language toggle, notification prefs, lock config), onboarding privacy statement, empty state designs, spending summary charts, undo on delete.
**Must address:** Cold-start lock persistence, iOS inactive-state privacy overlay, `FlutterFragmentActivity` Android requirement, biometric call interruption handling, budget rollover toggle (if confirmed in scope).

### Phase Ordering Rationale
- Tasks before finance: recurrence engine and GTD state complexity in tasks will surface architectural decisions (entity shape, query patterns, notification ID strategy) that finance inherits; reversing the order risks rework.
- Infrastructure last: notification, backup, and lock services depend on stable domain entities. Building them before domain is finalized forces double changes.
- Backup and notifications in the same phase as finance: users who enter financial data immediately want both export safety and alert-driven reminders; splitting these creates a release where finance exists without its core value-adds.
- App lock last: it is a cross-cutting concern that overlays the entire app; adding it last avoids the lock screen interfering with feature development in earlier phases.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 — Notifications:** Platform-specific alarm manager behavior on OEM Android (Samsung/Xiaomi/Huawei) varies significantly; notification testing matrix should be researched before scheduling architecture is finalized.
- **Phase 2 — Backup CSV:** Locale-aware amount parsing (PT-BR comma decimal vs EN period decimal) in round-trip CSV has edge cases worth a dedicated spike before implementation.
- **Phase 3 — App Lock:** iOS lifecycle states (`inactive` vs `paused`) for lock triggering benefit from a focused research spike; behavior on iOS simulator vs real device differs.

Phases with standard well-documented patterns (research-phase optional):
- **Phase 1 — Tasks CRUD + BLoC:** Thoroughly documented in flutter_bloc official docs and multiple community resources; standard patterns apply.
- **Phase 1 — l10n setup:** Official `flutter gen-l10n` tooling is well-documented; no research needed beyond following the official guide.
- **Phase 3 — Settings screen:** SharedPreferences + SettingsCubit is a commodity pattern; no research needed.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified from pub.dev; isar_community risk is documented and mitigated; compatibility notes verified against official docs |
| Features | HIGH (table stakes) / MEDIUM (differentiators) | Table stakes verified across multiple 2025 review sources; differentiator claims supported by community research |
| Architecture | HIGH | Verified against Flutter official architecture docs and Clean Architecture principles; build order well-established |
| Pitfalls | HIGH | Most findings sourced from official docs, GitHub issues, and documented production incidents |

**Overall confidence: HIGH**

### Gaps to address during planning

- **Currency handling in data models:** Do not hard-code a single currency symbol in Isar schemas. The decision on whether to store currency code alongside amounts should be made before schema design, even if multi-currency UI is deferred to v2.
- **isar_community longevity:** The community fork has CI quality concerns noted in GitHub discussions. Pin version explicitly; review changelog before any upgrade; document ObjectBox or `sqflite` as contingency if fork becomes unmaintained.
- **OEM battery optimization communication:** Samsung/Xiaomi/Huawei will cause missed notifications regardless of correct implementation. A battery optimization prompt during onboarding is the mitigation — this is a UX decision, not a code decision.
- **CSV decimal/locale handling:** Brazilian locale comma decimal separator (`1.234,56`) requires explicit locale-aware parsing in backup import. Flag for the backup feature spec.

---

## Sources

### Primary (HIGH confidence)
- pub.dev package pages — all version and maintenance status claims verified directly
- GitHub isar/isar#1689 — original Isar abandonment confirmed
- Flutter official architecture guide (docs.flutter.dev/app-architecture) — layer structure and dependency rule
- flutter_local_notifications official docs — Android manifest requirements, exact alarm permissions, iOS 64-notification limit
- flutter_bloc official docs (bloclibrary.dev) — BLoC/Cubit patterns, state equality, Bloc-to-Bloc communication guidance

### Secondary (MEDIUM confidence)
- Capterra, NerdWallet, Appbot 2025/2026 sources — feature expectations and anti-features
- Smashing Magazine 2025 notification UX guidelines — notification best practices
- Cognitofi 2026 privacy app rankings — local-first market positioning
- Multiple Flutter Clean Architecture community posts — common mistakes and build order recommendations

### Tertiary (MEDIUM-LOW confidence)
- GTD forum thread — Eisenhower Matrix + GTD combined app demand signal
- App Store review aggregations (Wallet BudgetBakers, YNAB) — competitive gap analysis

---

*Research completed: 2026-04-12*
*Ready for roadmap: yes*
