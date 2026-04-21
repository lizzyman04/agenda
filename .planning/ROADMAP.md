# Roadmap: AGENDA

## Overview

AGENDA is built in five dependency-ordered phases. Phase 1 lays the architectural foundation — database, DI, l10n — that every other phase builds on. Phase 2 completes the task domain, establishing the patterns (entity shapes, Cubit conventions, Isar query style) that finance inherits. Phase 3 delivers the finance domain on those proven patterns. Phase 4 wires all notifications and backup together with the now-stable domain, because budget alerts and debt reminders are finance's primary value-add. Phase 5 adds app lock, settings, and the final polish that makes the app release-ready.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Architecture scaffold, Isar + migration runner, DI wiring, l10n setup, offline guarantee
- [x] **Phase 2: Task Core** - Complete task domain — projects, subtasks, CRUD, recurring, Eisenhower, 1-3-5, GTD, search, filter
- [ ] **Phase 3: Finance Core** - Complete finance domain — transactions, budgets, goals, debts, recurring payments, dashboard, charts
- [ ] **Phase 4: Notifications + Backup** - All notification types with boot-safe rescheduling; JSON + CSV export/import
- [ ] **Phase 5: App Lock + Settings + Polish** - PIN + biometric lock, settings screen, onboarding, empty states

## Phase Details

### Phase 1: Foundation ✅ Complete
**Goal**: A runnable Flutter app with correct architecture, Isar open and migration-safe, DI wired, l10n scaffolded for EN + PT-BR, and the offline guarantee provably in place
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, UX-02
**Completed**: 2026-04-19
**Success Criteria** (what must be TRUE):
  1. App launches on Android and iOS without errors; no network calls are made at any point during startup or normal use
  2. Isar database opens successfully with schema version stored in SharedPreferences; a migration runner executes on cold start and no-ops when schema is current
  3. All Isar-persisted enums are annotated with `@enumerated(EnumType.name)` — reordering any enum does not corrupt existing records
  4. GetIt + injectable DI graph resolves without errors; swapping a repository implementation requires changing only the registration, not call sites
  5. `flutter gen-l10n` produces ARB files with parity keys for both `en` and `pt_BR`; the app renders PT-BR strings by default
**Plans**: 5/5 complete
**UI hint**: no

Plans:
- [x] 01-01-PLAN.md — Project bootstrap: pubspec (all versions locked), layer directories, very_good_analysis linting, FlutterFragmentActivity, AppConfig, core constants
- [x] 01-02-PLAN.md — Isar + migration runner: IsarService singleton, MigrationRunner (schemaVersion in SharedPreferences), MigrationRunner unit tests
- [x] 01-03-PLAN.md — DI scaffold: GetIt + injectable, four domain modules (CoreModule/TasksModule/FinanceModule/InfrastructureModule), main.dart wiring, DI smoke test
- [x] 01-04-PLAN.md — l10n scaffold: ARB files (EN + PT-BR), flutter gen-l10n, LocaleCubit with PT-BR default, app.dart locale wiring, ARB parity test
- [x] 01-05-PLAN.md — Failure hierarchy + offline guarantee: sealed Failure types, Result typedefs, Failure/AppConfig tests, CI workflow (analyze + test + offline check)

---

### Phase 2: Task Core ✅ Complete
**Goal**: Users can manage their entire task workload — create projects and subtasks, classify tasks with Eisenhower/1-3-5/GTD, set recurring due dates, search, and filter — with all data persisted locally
**Depends on**: Phase 1
**Requirements**: TASK-01, TASK-02, TASK-03, TASK-04, TASK-05, TASK-06, TASK-07, TASK-08, TASK-09, TASK-10, TASK-11, TASK-12
**Completed**: 2026-04-21
**Success Criteria** (what must be TRUE):
  1. User can create a project with title and description, add subtasks to it, and see subtask completion roll up to the project
  2. User can create a standalone task with title, due date, and time; edit it; and delete it with a 5-second undo snackbar that restores the task if tapped
  3. User can classify any task into an Eisenhower quadrant and plan their day using the 1-3-5 Rule (exactly 1 big + 3 medium + 5 small slots); constraints are enforced in the UI
  4. User can tag tasks with GTD attributes (next action, context, waiting for) and create recurring tasks that auto-regenerate on the configured interval
  5. User can search tasks by keyword and filter the task list by project, Eisenhower quadrant, GTD context, or due date range; results update immediately
**Plans**: 5/5 complete
**UI hint**: yes

Plans:
- [x] 02-01-PLAN.md — Task domain layer: Item entity, EisenhowerQuadrant getter, enums, ItemRepository interface, RecurrenceEngine interface
- [x] 02-02-PLAN.md — Task data layer: ItemModel @Collection, ItemMapper, ItemDao, ItemRepositoryImpl, RecurrenceEngineImpl, migration v1→v2
- [x] 02-03-PLAN.md — Task application layer: TaskListCubit, ProjectCubit, DayPlannerCubit + all states (Equatable)
- [x] 02-04-PLAN.md — Task presentation (core): task list screen, project screen, task form, Eisenhower board, 1-3-5 day planner + checkpoint
- [x] 02-05-PLAN.md — GTD + search + filter + recurring UI + DI wiring: complete tasks_module.dart, ARB keys, injection.config.dart regenerated

---

### Phase 3: Finance Core
**Goal**: Users can log income and expenses, track budgets per category, manage savings goals, monitor debts, and view their financial picture on a dashboard with spending charts — all stored locally
**Depends on**: Phase 2
**Requirements**: FIN-01, FIN-02, FIN-03, FIN-04, FIN-05, FIN-06, FIN-07, FIN-08, FIN-09, FIN-10, UX-04
**Success Criteria** (what must be TRUE):
  1. User can log an income or expense transaction with amount, category, date, and note; edit it; and delete it; the balance on the dashboard updates immediately
  2. User can set a monthly budget limit per expense category; a progress indicator shows current spend vs. limit in real time as transactions are added
  3. User can create a savings goal with a target amount and optional deadline, contribute to it, and see the percentage progress update with each contribution
  4. User can log a debt (to pay or to receive) with amount and due date, and log a recurring payment (subscription or bill) with amount and billing cycle
  5. All screens — transaction list, budget overview, goals list, debt list — display meaningful empty states with a clear action prompt when no data exists yet; the dashboard shows current balance and net worth; the spending chart renders a monthly category breakdown as pie and bar
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 03-01: Finance domain — entities (Transaction, Budget, SavingsGoal, Debt, RecurringPayment), repository interfaces
- [ ] 03-02: Finance data layer — Isar schemas (reusing enum convention), model mappers, repository implementations
- [ ] 03-03: Finance application layer — TransactionCubit, BudgetCubit, GoalCubit, DebtCubit, HomeDashboardCubit (shared)
- [ ] 03-04: Finance presentation — transaction log, budget tracker, savings goals, debt tracker, recurring payments
- [ ] 03-05: Dashboard + charts — net worth overview, fl_chart spending pie + bar, empty states across all finance screens

---

### Phase 4: Notifications + Backup
**Goal**: All notification types are scheduled, delivered reliably after device reboot, and controlled by the user; data can be exported as JSON or CSV and restored from backup with transactional safety
**Depends on**: Phase 3
**Requirements**: NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05, NOTF-06, NOTF-07, NOTF-08, NOTF-09, NOTF-10, NOTF-11, DATA-02, DATA-03, DATA-04
**Success Criteria** (what must be TRUE):
  1. Task due reminders, the daily morning briefing, recurring task reminders, budget threshold alerts (80% and 100%), debt due reminders, goal off-track alerts, and recurring payment reminders each fire at the expected time on both Android and iOS
  2. Rebooting the device does not cancel pending notifications — all scheduled notifications are automatically rescheduled on next boot via the boot receiver
  3. Motivational quote notifications default to OFF; when enabled, the user can set frequency and time; quiet hours (default 10pm–7am, configurable) are respected by all notification types
  4. User can export all data as a JSON file and as a CSV file; exported files contain every task, transaction, budget, goal, debt, and recurring payment record
  5. User can import a backup file; the app shows a confirmation screen with record counts and date range, creates an automatic safety backup first, and completes the import atomically — a failed import leaves the database unchanged
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 04-01: Notification infrastructure — flutter_local_notifications init, timezone setup, notification ID strategy, Android manifest permissions
- [ ] 04-02: Task notifications — due reminders, morning briefing, recurring task reminders, boot receiver + Isar payload persistence
- [ ] 04-03: Finance notifications — budget alerts, debt reminders, goal alerts, recurring payment reminders, motivational quotes
- [ ] 04-04: Notification settings — per-type toggles (NOTF-09), quiet hours config (NOTF-10), iOS 64-notification budget manager
- [ ] 04-05: Backup — JSON export, CSV export (locale-aware decimals), import with pre-import safety backup and atomic transaction

---

### Phase 5: App Lock + Settings + Polish
**Goal**: Users can optionally protect the app with a PIN and biometrics; a settings screen unifies language, notification, and lock preferences; and the first-launch experience communicates the app's privacy commitment
**Depends on**: Phase 4
**Requirements**: DATA-05, DATA-06, UX-01, UX-03
**Success Criteria** (what must be TRUE):
  1. User can set an optional PIN; on every cold start with a PIN configured, the app shows the lock screen before any content is visible — even after an OS process kill
  2. When PIN is enabled, user can unlock with biometrics (Face ID or fingerprint) without entering the PIN manually; the privacy overlay appears in the iOS App Switcher
  3. A settings screen lets the user toggle app language (EN / PT-BR), enable or disable individual notification types, configure quiet hours, and manage the app lock PIN
  4. On first launch, the app displays a one-screen privacy statement ("Your data never leaves this device") before showing the main UI; the statement is not shown on subsequent launches
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 05-01: App lock infrastructure — FlutterFragmentActivity migration, flutter_secure_storage PIN, flutter_screen_lock integration, GoRouter PIN guard
- [ ] 05-02: Biometric unlock + lifecycle observer — local_auth integration, AppLifecycleState.inactive privacy overlay, cold-start lock persistence
- [ ] 05-03: Settings screen — SettingsCubit (SharedPreferences), language toggle (UX-01), notification prefs, lock config
- [ ] 05-04: Onboarding + final polish — first-launch privacy statement, remaining empty states, end-to-end smoke test, release build validation

---

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 5/5 | ✅ Complete | 2026-04-19 |
| 2. Task Core | 5/5 | ✅ Complete | 2026-04-21 |
| 3. Finance Core | 0/5 | Not started | - |
| 4. Notifications + Backup | 0/5 | Not started | - |
| 5. App Lock + Settings + Polish | 0/4 | Not started | - |
