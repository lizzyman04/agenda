# Roadmap: AGENDA

## Overview

AGENDA is built in six dependency-ordered phases. Phase 1 lays the architectural foundation — database, DI, l10n — that every other phase builds on. Phase 2 completes the task domain, establishing the patterns (entity shapes, Cubit conventions, Isar query style) that finance inherits. Phase 3 delivers the finance domain on those proven patterns. Phase 4 wires all notifications and backup together with the now-stable domain, because budget alerts and debt reminders are finance's primary value-add. Phase 5 adds app lock, settings, and the final polish that makes the app release-ready. Phase 6 is the architecture-compliance rework.

## Phases

**Phase Numbering:** integer phases only. Phase 6 was executed out of order — the
architecture rework was carried out immediately after Phase 3, before Phases 4 and 5 —
but it is numbered as a normal phase rather than a decimal insertion.

- [x] **Phase 1: Foundation** - Architecture scaffold, Isar + migration runner, DI wiring, l10n setup, offline guarantee
- [x] **Phase 2: Task Core** - Complete task domain — projects, subtasks, CRUD, recurring, Eisenhower, 1-3-5, GTD, search, filter
- [ ] **Phase 3: Finance Core** - Complete finance domain — transactions, budgets, goals, debts, recurring payments, dashboard, charts
- [ ] **Phase 4: Notifications + Backup** - All notification types with boot-safe rescheduling; JSON + CSV export/import
- [ ] **Phase 5: App Lock + Settings + Polish** - PIN + biometric lock, settings screen, onboarding, empty states
- [x] **Phase 6: Architecture Compliance** - 150-line file limit, nested feature modules, per-nest README docs

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
**Plans**: 14 plans (5 build + 3 UAT gap closure + 4 code-review gap closure + 2 verification gap closure)
**UI hint**: yes

Plans:
- [x] 03-01-PLAN.md — Finance domain: Transaction, Budget, SavingsGoal, Debt, RecurringPayment entities + enums + repository interfaces; Currencies constants; FinanceColors; formatAmount utility
- [x] 03-02-PLAN.md — Finance data layer: 6 Isar @Collection models, 6 DAOs, finance_mappers.dart, 5 repository impls; AppConfig.schemaVersion → 3; MigrationRunner case 3 (seed 13 categories); FinanceModule populated; main.dart schema list updated
- [x] 03-03-PLAN.md — Finance application layer: TransactionCubit, BudgetCubit, GoalCubit + GoalListCubit, DebtCubit, RecurringPaymentCubit, HomeDashboardCubit (single-pass balance + net worth + chart aggregation) *(post-fix 2026-06-01: build_runner re-run to regenerate injection.config.dart with cubit factories)*
- [x] 03-04-PLAN.md — Finance presentation: 10 screens (transaction list/form, budget overview, goal list/detail/form, debt list/form, recurring list/form), 4 widgets (TransactionCard, BudgetProgressBar, GoalProgressCard, FinanceEmptyState), Finance tab in NavigationBar, task↔finance link display + task form picker *(checkpoint approved 2026-06-01; provider-scope crash fixed in 260601-u6q; budget-save BottomSheet crash deferred as known non-blocking bug — see STATE.md)*
- [x] 03-05-PLAN.md — Dashboard + charts: DashboardSummaryCard (displaySmall balance), SpendingPieChart + SpendingBarChart (fl_chart 1.2.0), month navigation, empty states for dashboard and no-expenses-in-month *(code complete + merged 2026-06-01; human-verify checkpoint pending; HomeDashboardCubit.start() made idempotent)*
- [x] 03-06-PLAN.md — Gap closure (UAT test 2): expose the category list on TransactionLoaded, resolve categoryId → localized name on the transaction list, and stop the note rendering twice on the card *(wave 1, merged 2026-08-14)*
- [x] 03-07-PLAN.md — Gap closure (UAT test 3): hide the current undo SnackBar before showing the next one, so a second swipe-delete inside the undo window replaces it instead of queueing behind it *(wave 2, 2026-08-14; mutation-checked regression test; on-device re-test still pending)*
- [x] 03-08-PLAN.md — Gap closure (UAT test 9): resolve the linked goal/debt title in the task detail finance chip instead of rendering the raw entity id *(wave 1, merged 2026-08-14)*
- [x] 03-09-PLAN.md — Gap closure (code review CR-04, Critical): split the uncapped aggregate read from a newest-first capped list read, so the dashboard balance stops going silently wrong past 500 transactions *(wave 3, 2026-08-14; both mutations run — the balance one reproduced Expected 1049999 / Actual 50000)*
- [x] 03-10-PLAN.md — Gap closure (code review CR-01, Critical): add DebtCubit.restoreDebt and an undo SnackBar to the debt swipe, which currently destroys a debt with no recovery path at any layer *(wave 3, 2026-08-14; mutation run — emptying the undo action fails both tests on `No matching calls ... [VERIFIED] MockDebtCubit.softDelete(4)`)*
- [x] 03-11-PLAN.md — Gap closure (code review CR-02, Critical): stop the active-only list query hiding deactivated recurring payments permanently, and make paused rows visibly paused and resumable *(wave 3, 2026-08-15; both mutations run — restoring the isActive filter fails the query-shape test on `Expected: false / Actual: <true>`)*
- [x] 03-12-PLAN.md — Gap closure (code review CR-03 Critical + WR-07): capture the cubit before popping the route so task-detail Undo actually works, and point the budget limit sheet at the shared amount parser *(wave 3)*
- [ ] 03-13-PLAN.md — Gap closure (verification BL-01, wave 1): build IsarTestHarness, a reusable real-isar_community test helper (Isar.initializeIsarCore(download: true) against an isolated temp dir), plus a self-test proving open/write/read/teardown
- [ ] 03-14-PLAN.md — Gap closure (verification BL-01, wave 2, depends on 03-13): uncap TransactionDao.findByMonth and findByLinkedGoal (feeding BudgetCubit spend and GoalCubit tagged progress), correct the class doc's false single-exception claim, add real-Isar behavioral regression tests

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

### Phase 6: Architecture Compliance ✅ Complete

**Goal**: Every hand-written source file is under 150 lines, every directory is nested by responsibility with no more than ~10 related files, and every feature nest carries a README documenting its responsibility and rules
**Depends on**: Phase 3
**Executed**: 2026-08-11 → 2026-08-12 — house rules adopted mid-project; applied to the goals slice in quick task 260811-97x, rest of the codebase still non-compliant. Carried out immediately after Phase 3, ahead of Phases 4 and 5, hence the out-of-order number.
**Verified**: 2026-08-12 — all 5 success criteria confirmed by independent re-measurement (06-VERIFICATION.md). Guard enforces in CI.
**UAT**: 2026-08-12 — PASSED on a physical Infinix X6831 (Android 13, arm64). The pre-phase build (installed 2026-08-11, 1 MB Isar db) was upgraded in place and cold-started: all pre-existing tasks, transactions, goals and debts survived, balance unchanged at MT 3.800,00, no Isar or Dart errors in logcat. All six regenerated `*_model.g.dart` files are byte-identical to their pre-move versions, so the schema never moved. Transaction and task forms were exercised end-to-end (create → categorise → save → delete → undo); the extracted pickers, scaffolds, app bars and finance-link card all behave. Three UI defects were found and all three were confirmed **pre-existing** by diffing against the pre-refactor sources — see 06-VERIFICATION.md.
**Requirements**: (none — internal quality)
**Success Criteria** (what must be TRUE):
  1. No hand-written file under lib/ exceeds 150 lines (generated *.g.dart and injection.config.dart exempt)
  2. No directory under lib/ holds more than 10 related source files
  3. Every feature directory under lib/presentation/ and lib/application/ contains a README.md stating its responsibility, its contents, and any slice-specific rules
  4. The full test suite passes unchanged — this is a pure refactor with no behaviour change
  5. `flutter analyze` reports no new errors or warnings
**Plans**: 18 plans (planned 2026-08-11 — expanded from the original 5-plan estimate; see plan-level rationale below)
**UI hint**: no

**Scope baseline** (re-measured 2026-08-11 after the goals slice and GTD sub-slice landed):
21 files over 150 lines · 2 directories over 10 files · 2 of 30 feature nests carry a README.

**Planner deviation from the 5-plan estimate**: 18 plans across 5 waves. Each of the 21
over-limit files needs concrete, per-file extraction seams (not a mechanical batch action) to
stay within a single plan's context budget, and two of the planner's own decomposition choices
(shared finance-form primitives, per-entity `presentation/finance/widgets/<entity>/` subfolders)
were required to avoid the split work itself creating *new* directory-size violations. See
plan `6-08`'s objective for why the four finance form screens share a Wave 1 prerequisite
plan, and plan `6-16`'s objective for why the two folder-nesting plans run last.

Plans:
- [x] 6-01: Architecture guard scaffold — tool/check_architecture.dart + exemption allowlist (currencies.dart), informational mode; guard unit-tested against fixtures
- [x] 6-02: task_form_screen.dart remainder — field groups, finance-link picker, save path (completes the partial 6-01 work from commits 6c06312/04c4f84)
- [x] 6-03: task_detail_screen.dart split (563 lines) — hero card, section atoms, action bar
- [x] 6-04: item.dart split-or-exempt (SPLIT: sentinel + copyWith extension) + task_list_cubit.dart pure-function extraction
- [x] 6-05: item_dao.dart query-builder extraction + item_repository_impl.dart part/part-of split
- [x] 6-06: task_list_screen.dart + day_planner_screen.dart + project_screen.dart splits
- [x] 6-07: home_dashboard_cubit.dart + budget_cubit.dart aggregation-math extraction
- [x] 6-08: Shared finance-form utilities (FormCard/FieldRow/FieldDivider, CategoryPickerSheet, amount_parser) — prerequisite for 6-12..15
- [x] 6-09: debt_list_screen.dart + recurring_payment_screen.dart + budget_overview_screen.dart splits
- [x] 6-10: finance_dashboard_screen.dart split
- [x] 6-11: finance_mappers.dart split-or-exempt (SPLIT into 6 per-entity mapper files) — prerequisite for 6-17
- [x] 6-12: transaction_form_screen.dart split (587 lines, largest presentation/finance file) — depends on 6-08
- [x] 6-13: recurring_payment_form_screen.dart split — depends on 6-08
- [x] 6-14: debt_form_screen.dart split — depends on 6-08
- [x] 6-15: goal_form_screen.dart split — depends on 6-08
- [x] 6-16: domain/finance folder nesting (16 → 6 subfolders) — depends on every finance-touching plan above
- [x] 6-17: data/finance folder nesting (18 → 6 subfolders, using 6-11's mapper files) — depends on 6-16
- [x] 6-18: README per nest (all directories under presentation/+application/, literal reading) + guard enforcement wired into CI — final plan

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 3.1 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 5/5 | ✅ Complete | 2026-04-19 |
| 2. Task Core | 5/5 | ✅ Complete | 2026-04-21 |
| 3. Finance Core | 5/5 | In verification | - |
| 4. Notifications + Backup | 0/5 | Not started | - |
| 5. App Lock + Settings + Polish | 0/4 | Not started | - |
| 6. Architecture Compliance | 18/18 | ✅ Complete | 2026-08-12 |
