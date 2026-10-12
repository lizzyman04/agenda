# Phase 4: Notifications + Backup - Pattern Map

**Mapped:** 2026-10-12
**Files analyzed:** 41 new/modified (grouped where one analog covers a family)
**Analogs found:** 36 / 41 (all analog paths verified git-tracked via `git ls-files lib test`)

Constraints that apply to every file below (from CLAUDE.md / RESEARCH.md): <=150 lines per hand-written `lib/` file, <=10 hand-written `.dart` files per directory, a `README.md` in every new directory under `lib/application/` and `lib/presentation/` (see `lib/application/shared/locale/README.md` for the format: Responsibility / Files table with line counts / Conventions / Upstream dependencies). Package imports use `package:agenda/...` (no relative imports in `lib/`). Domain layer must not import Flutter, Isar, the plugin, or `timezone`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `pubspec.yaml`, `android/app/build.gradle.kts`, `AndroidManifest.xml`, `ios/Runner/AppDelegate.swift` (modify) | config | n/a | no code analog (RESEARCH Pitfalls 4, 10, 11, 13) | none |
| `lib/core/constants/storage_keys.dart` (modify) | config | n/a | itself (existing quiet-hours keys) | exact |
| `lib/core/constants/app_constants.dart` (modify: `iosMaxScheduledNotifications` etc.) | config | n/a | itself | exact |
| `lib/domain/notifications/model/*` (NotificationKind, PlannedNotification, NotificationPrefs, QuietHours) | model | transform | `lib/domain/finance/debt/debt.dart` + `lib/application/shared/locale/locale_state.dart` (Equatable value) | role-match |
| `lib/domain/notifications/rules/*` (task_fire_time, quiet_hours, slot_budget, goal_off_track, budget_threshold, effective_due_date, quote_picker, notification_id) | utility (pure rules) | transform | `lib/application/finance/budget/budget_aggregator.dart` (pure fn, injected inputs) + `lib/infrastructure/tasks/recurrence_engine_impl.dart` `_nextMonthly` clamp | role-match |
| `lib/domain/notifications/*_gateway.dart`, `notification_prefs_repository.dart`, `budget_alert_state_store.dart` (interfaces) | repository interface | request-response | `lib/domain/finance/recurring/recurring_payment_repository.dart` | exact |
| `lib/domain/finance/recurring/recurring_payment_repository.dart` (modify: add `watchChanges`) | repository interface | event-driven | `lib/infrastructure/finance/debt_repository_impl.dart:130` + `DebtRepository.watchChanges` | exact |
| `lib/domain/finance/budget/budget_repository.dart` (modify: add `watchChanges`) | repository interface | event-driven | same as above | exact |
| `lib/data/finance/recurring/recurring_payment_dao.dart`, `budget_dao.dart` (modify: `watchLazy`) | DAO | event-driven | `lib/data/finance/debt/debt_dao.dart:47` | exact |
| `lib/infrastructure/finance/recurring_payment_repository_impl.dart`, `budget_repository_impl.dart` (modify) | repository impl | event-driven | `lib/infrastructure/finance/debt_repository_impl.dart:130` | exact |
| `lib/data/tasks/item_dao.dart` (modify: `findUpcomingDue`, window query) | DAO | CRUD read (uncapped/sorted) | `lib/data/finance/debt/debt_dao.dart:20-29` (uncapped, documented) + `item_dao.dart` filters | role-match |
| `lib/domain/tasks/item_repository.dart` + `lib/infrastructure/tasks/item_repository_impl*.dart` (modify) | repository | CRUD | `lib/infrastructure/tasks/item_repository_impl_queries.dart` | role-match |
| `lib/infrastructure/notifications/gateway/*` (FlutterLocalNotificationsGateway, channels, permission service, tz bootstrap) | service | request-response (platform channel) | `lib/infrastructure/finance/debt_repository_impl.dart` (injectable + try/catch -> Result) | partial |
| `lib/infrastructure/notifications/sync/*` (NotificationSyncCoordinator, SnapshotLoader, ScheduleDiff) | service | event-driven | `lib/application/finance/budget/budget_cubit.dart` (watch subscription + reload + close) | role-match |
| `lib/infrastructure/notifications/prefs/*` (PrefsRepositoryImpl, BudgetAlertStateStoreImpl) | repository impl | CRUD (SharedPreferences) | `lib/application/shared/locale/locale_cubit.dart` | role-match |
| `lib/infrastructure/notifications/quotes/quotes_{en,pt}.dart` | config (const data) | n/a | none | none |
| `lib/application/notifications/notification_settings_cubit.dart` + state | cubit | request-response | `lib/application/shared/locale/locale_cubit.dart` + `debt_state.dart` | exact |
| `lib/application/notifications/budget_alert_evaluator.dart` | service | event-driven | `lib/application/finance/budget/budget_cubit.dart:37-125` | role-match |
| `lib/presentation/notifications/screens/notification_settings_screen.dart` + widgets | screen | request-response | `lib/presentation/finance/screens/debt_list_screen.dart` / `recurring_payment_form_screen.dart` | role-match |
| `lib/presentation/notifications/` tap router + `navigatorKey` in `lib/app.dart` (modify) | router | event-driven | `lib/app.dart` | role-match |
| `lib/main.dart` (modify: bootstrap tz + plugin + coordinator start) | config | n/a | itself | exact |
| `lib/config/di/infrastructure_module.dart` (modify) + `injection.config.dart` (regenerate) | config | n/a | `lib/config/di/finance_module.dart`, `core_module.dart` | exact |
| `lib/domain/backup/*` (BackupSnapshot, ImportPreview, BackupRepository iface, formatVersion) | model/interface | transform | `lib/domain/finance/debt/debt.dart`, `*_repository.dart` | role-match |
| `lib/data/backup/dao/*` (BackupDao uncapped reads, BackupImportDao single txn) | DAO | batch / file-I/O | `lib/data/finance/debt/debt_dao.dart` | role-match |
| `lib/data/backup/json/*` (per-entity codecs + envelope + validator) | utility | transform | `lib/data/finance/debt/debt_mapper.dart` | role-match |
| `lib/data/backup/csv/*` (row mappers, strict amount parser, injection guard) | utility | transform | `lib/core/utils/amount_parser.dart` + `amount_formatter.dart` (but NOT reusable for import, see Pitfall) | partial |
| `lib/infrastructure/backup/*` (BackupRepositoryImpl, safety dir rotation) | repository impl | file-I/O | `lib/infrastructure/finance/debt_repository_impl.dart` | role-match |
| `lib/application/backup/backup_cubit.dart` + state | cubit | request-response | `lib/application/finance/debt/debt_cubit.dart` + `debt_state.dart` | role-match |
| `lib/presentation/backup/screens/*` (export/import page, confirm screen) | screen | request-response | `lib/presentation/finance/screens/debt_list_screen.dart` | role-match |
| `lib/presentation/tasks/screens/task_list_screen.dart` (modify: AppBar action entry point) | screen | n/a | itself lines 84-93 | exact |
| `lib/config/l10n/app_{en,pt,pt_BR}.arb` (modify) | config | n/a | themselves; parity test `test/l10n/l10n_test.dart` | exact |
| `test/widget_test.dart` (modify: stubs gain `watchChanges`) | test | n/a | itself | exact |
| `test/domain/notifications/*_test.dart` | test | transform | `test/domain/tasks/recurrence_engine_test.dart` | role-match |
| `test/application/notifications/*_test.dart` | test | event-driven | `test/application/finance/debt_cubit_test.dart` | exact |
| `test/infrastructure/notifications/fake_notification_gateway.dart`, `manifest_contract_test.dart` | test support | n/a | `test/data/finance/transaction_dao_ordering_test.dart` (source-text assertion style) | partial |
| `test/data/backup/*_test.dart` (600-row, atomicity, round-trip) | test | batch | `test/data/finance/transaction_dao_aggregate_completeness_test.dart` + `test/support/isar_test_harness.dart` | exact |

## Pattern Assignments

### `lib/domain/finance/recurring/recurring_payment_repository.dart` and `budget_repository.dart` (add `watchChanges`)

**Analog:** `lib/infrastructure/finance/debt_repository_impl.dart:130-131` and `lib/data/finance/debt/debt_dao.dart:45-48`

```dart
// Repository impl (debt_repository_impl.dart:130)
@override
Stream<void> watchChanges() => _dao.watchLazy();

// DAO (debt_dao.dart:47)
Stream<void> watchLazy() =>
    _isarService.db.collection<DebtModel>().watchLazy();
```

Also remove the "not reactive / No watchChanges" doc sentences from the two interfaces (recurring_payment_repository.dart lines 7-10, budget_repository.dart line 10). Update the stubs in `test/widget_test.dart` (`_StubBudgetRepository`, `_StubRecurringPaymentRepository`) with `Stream<void> watchChanges() => const Stream.empty();`.

---

### `lib/data/tasks/item_dao.dart` additions (uncapped/sorted reminder + briefing reads)

**Analog:** `lib/data/finance/debt/debt_dao.dart:20-29` (uncapped read with BL-01 rationale doc) and the filter chain style at `item_dao.dart:22-28`.

```dart
/// Returns EVERY active (non-deleted) debt — deliberately uncapped.
/// ... Never add .limit() back to this query.
Future<List<DebtModel>> findAll() async =>
    _collection.filter().deletedAtIsNull().findAll();
```

Copy: fluent `_collection.filter().deletedAtIsNull().and()....`, no `.limit(500)` on the window query, `sortByDueDate()` then `.limit(slotBudget)` only for "soonest N" query (RESEARCH Pitfall 2). Note `ItemDao` is already ~136 lines: put new queries in a new file (e.g. `lib/data/tasks/item_reminder_queries.dart`, same pattern as `item_query_builder.dart` free function taking `IsarCollection<ItemModel>`) to stay under 150 lines.

---

### `lib/domain/notifications/rules/*` (pure fire-time / quiet-hours / slot / goal / quote rules)

**Analog:** `lib/application/finance/budget/budget_aggregator.dart` (pure top-level function, no I/O) and clamp logic in `lib/infrastructure/tasks/recurrence_engine_impl.dart:81-100`.

Month-end clamp to copy for `effectiveDueDate` (never use `DateTime(y, m+1, d)` overflow):
```dart
final nextMonth = from.month == 12
    ? DateTime(from.year + 1)
    : DateTime(from.year, from.month + 1);
final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
final clampedDay = day.clamp(1, daysInNextMonth);
```
Note: engine drifts the day after a clamp when chaining (Jan 31 -> Feb 28 -> Mar 28). `effectiveDue` must step from the ORIGINAL `nextDueDate` day-of-month each cycle, not from the previous clamped value.

Reference snippets for the rules themselves are in `04-RESEARCH.md` Code Examples (`deferOutOfQuietHours`, `taskFireAt`, `dayBefore9am`, `isOffTrack`, `notificationId`). Use `AppConfig.taskNotificationBase/financeNotificationBase/systemNotificationBase` (`lib/core/config/app_config.dart:32-38`) as the `base` argument.

**Value-object style** (Equatable, const ctor, `props`), from `lib/application/shared/locale/locale_state.dart`:
```dart
final class LocaleState extends Equatable {
  const LocaleState(this.locale);
  final Locale locale;
  @override
  List<Object?> get props => [locale];
}
```

---

### `lib/domain/notifications/*` interfaces (gateway, prefs repo, alert-state store)

**Analog:** `lib/domain/finance/recurring/recurring_payment_repository.dart`

```dart
import 'package:agenda/core/failures/result.dart';
abstract class RecurringPaymentRepository {
  AsyncResult<RecurringPayment> createPayment(RecurringPayment payment);
  ...
}
```
Copy: abstract class, every fallible method returns `AsyncResult<T>` and never throws; doc comment states implementation location. Gateway failures map to `NotificationFailure` (`lib/core/failures/failure.dart:41`); backup to `BackupFailure` (`:46`).

---

### `lib/infrastructure/notifications/**` and `lib/infrastructure/backup/**` (impls)

**Analog:** `lib/infrastructure/finance/debt_repository_impl.dart`

**Imports + registration** (lines 1-17):
```dart
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
...
import 'package:injectable/injectable.dart';

@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._dao, this._mapper);
```

**Error-handling pattern** (lines 38-40, repeat per method):
```dart
} on Object catch (e) {
  return Err(DatabaseFailure('createDebt failed: $e'));
}
```
Substitute `NotificationFailure('schedule failed: $e')` / `BackupFailure('export failed: $e')`. In the gateway, wrap EACH `zonedSchedule` in its own try/catch so one bad item cannot abort the batch (RESEARCH Pitfall 3).

**Services that are not repositories** (coordinator, plugin instance) cannot self-register by interface; register via module getters as in `lib/config/di/core_module.dart:16-26`:
```dart
@module
abstract class CoreModule {
  @singleton
  IsarService get isarService => IsarService.instance;
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
```
Use `@lazySingleton FlutterLocalNotificationsPlugin plugin => FlutterLocalNotificationsPlugin();` style entries in `infrastructure_module.dart` (currently empty `abstract class InfrastructureModule {}`), and DAOs as in `finance_module.dart:23-37` (`@lazySingleton TransactionDao transactionDao(IsarService isarService) => TransactionDao(isarService);`). After edits run `dart run build_runner build --delete-conflicting-outputs`; `injection.config.dart` is committed.

---

### `lib/infrastructure/notifications/sync/notification_sync_coordinator.dart`

**Analog:** `lib/application/finance/budget/budget_cubit.dart:34-42, 127-131`

```dart
StreamSubscription<void>? _watchSubscription;

Future<void> start() async {
  _watchSubscription = _transactionRepository
      .watchChanges()
      .listen((_) async => _reload());
  await _reload();
}

@override
Future<void> close() async {
  await _watchSubscription?.cancel();
  return super.close();
}
```
Copy: subscribe to all repos' `watchChanges()` (items, transactions, debts, goals, recurring payments, budgets), `isClosed`-style disposed guard before and after each await, cancel subscriptions on dispose. ADD (not in analog): debounce 300-500 ms and single-flight (re-run flag) because `watchLazy` emits per write. Must be a long-lived lazySingleton, not a factory cubit. Use `unawaited(...)` for fire-and-forget (analyzer info budget is 65; add zero).

---

### `lib/application/notifications/budget_alert_evaluator.dart`

**Analog:** `lib/application/finance/budget/budget_cubit.dart:71-125` (load month txns, budgets, categories via repo `Result` switch, then pure merge)

```dart
final txResult = await _transactionRepository.getByMonth(month, year);
final List<Transaction> transactions;
switch (txResult) {
  case Err<List<Transaction>>(:final failure):
    emit(BudgetError(failure));
    return;
  case Success<List<Transaction>>(:final value):
    transactions = value;
}
final budgetsResult = await _budgetRepository.getForMonth(month, year);
...
final combined = mergeBudgetData(transactions: transactions, budgets: budgets);
```
Reuse `mergeBudgetData` from `budget_aggregator.dart` for spend vs limit; apply `budget_threshold.dart` highest-crossed rule; fired key `YYYY-MM:categoryId:threshold` persisted via the SharedPreferences store. Evaluator is not a cubit (no emit): on `Err` just return/log, never throw.

---

### `lib/application/notifications/notification_settings_cubit.dart` (+ `_state.dart`)

**Analog:** `lib/application/shared/locale/locale_cubit.dart`

**Core pattern** (lines 15-49): `@injectable`, `SharedPreferences` constructor-injected, initial state resolved synchronously from prefs, **persist before emit**:
```dart
@injectable
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs)
      : super(LocaleState(_resolveInitialLocale(_prefs)));
  final SharedPreferences _prefs;

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    await _prefs.setString(StorageKeys.locale, locale.languageCode);
    emit(LocaleState(locale));
  }
}
```
Keys go in `lib/core/constants/storage_keys.dart` (existing `quietHoursEnabled/Start/End` use "hour 0-23" docs; D-03/D-08 need minutes-of-day so change/add keys and update their doc comments rather than adding duplicates). Because D-09 says Phase 5 mounts this page in Settings, register as `@injectable` factory and provide at the page, not above `MaterialApp`.

**State style** (sealed Equatable hierarchy) from `lib/application/finance/debt/debt_state.dart:1-45`: `sealed class X extends Equatable`, `final class XLoaded`, `final class XError(this.failure)`.

**Cubit test** analog `test/application/finance/debt_cubit_test.dart`: `blocTest`, `Mock... extends Mock implements Repo`, `when(() => repo.watchChanges()).thenAnswer((_) => const Stream.empty())`, imports `package:test/test.dart`.

---

### `lib/application/backup/backup_cubit.dart` (+ state)

**Analog:** `lib/application/finance/debt/debt_cubit.dart` / `debt_state.dart` (sealed Initial/Loading/Loaded/Error). Add states: `BackupIdle`, `BackupWorking`, `ImportPreviewReady(preview)`, `BackupDone(counts)`, `BackupError(failure, safetyBackupPath?)`. Cubit calls only the `BackupRepository` interface; confirm step is a separate method so the UI shows the preview before commit (D-11).

---

### `lib/data/backup/dao/*` (BackupDao, BackupImportDao)

**Analog:** `lib/data/finance/debt/debt_dao.dart` (collection getter via `_isarService.db.collection<T>()`, uncapped finder with BL-01 doc).

```dart
IsarCollection<DebtModel> get _collection =>
    _isarService.db.collection<DebtModel>();
```
Copy the collection-getter and "deliberately uncapped" doc comment. Export reads: `collection.where().findAll()` / `.filter().anyId()`-style with NO `deletedAtIsNull()` and NO limit (JSON includes soft-deleted, D-15).

**Atomic import:** DAO `save()` methods each open their own `writeTxn` (`debt_dao.dart:33-34`), so the importer must use `isarService.db.collection<T>()` directly inside ONE `isar.writeTxn(() async { clear(); putAll(); })` (RESEARCH "Atomic import" example). Never call DAO `save` inside it (nested txn throws). Collections and schemas to cover are the seven in `lib/main.dart:26-34` (Item, Transaction, TransactionCategory, Budget, SavingsGoal, Debt, RecurringPayment).

---

### `lib/data/backup/json/*` (codecs)

**Analog:** `lib/data/finance/debt/debt_mapper.dart`

```dart
Debt toDomain(data.DebtModel model) { return Debt(id: model.id, ...); }

data.DebtModel toModel(Debt debt) {
  final model = data.DebtModel();
  if (debt.id != 0) { model.id = debt.id; }
  model
    ..title = debt.title
    ...
  return model;
}
```
Copy: one small class per entity with explicit field-by-field mapping (swap Domain<->Model for Model<->`Map<String,Object?>`), enum converters as private switch-expression methods (`debt_mapper.dart:50+`), keep explicit `id` (import preserves ids so FKs like `categoryId`, `parentId`, `linkedGoalId` stay valid). One codec file per entity keeps each <=150 lines and the directory split `json/` (<=10 files: 7 codecs + envelope + validator = 9). Ensure `SavingsGoalModel.contributions` is built with `List.of(...)` (growable).

---

### `lib/data/backup/csv/*` (CSV row mappers)

**Analog (formatting only):** `lib/core/utils/amount_formatter.dart` `formatAmount(cents, symbol, locale)`.
**Do NOT reuse** `lib/core/utils/amount_parser.dart` `parseAmountCentsOrNull` for import (rejects `1.250,50`, turns `-5` into `+500`). Write a strict parser; `amount_cents` integer column is authoritative on import. Use `csv` 8.0.0 `Csv(...)`/`csv.encode`/`csv.decode`, not 6.x converters.

---

### `lib/presentation/notifications/screens/*` and `lib/presentation/backup/screens/*`

**Analog:** `lib/presentation/finance/screens/debt_list_screen.dart` and `lib/presentation/finance/widgets/budget/README.md` conventions. Rules to copy:
- Sheet/dialog widgets own and dispose their own `TextEditingController` (regression `ae397ae`).
- A sheet pops a value; the caller persists via the cubit.
- Strings via `AppLocalizations.of(context)` (`lib/app.dart:104`), never hard-coded; add keys to all three ARB files.
- Cubits that must outlive a pushed route are provided above `MaterialApp` (`lib/app.dart:27-49`); page-local cubits use `BlocProvider(create: (_) => getIt<...>())` at the screen.
- Each new directory gets a README.md; presentation dir layout `screens/` + `widgets/`.

---

### `lib/presentation/tasks/screens/task_list_screen.dart` (temporary entry point, D-15)

**Analog:** itself, lines 84-93

```dart
appBar: AppBar(
  title: Text(l10n.tasksScreenTitle),
  actions: [
    IconButton(
      icon: const Icon(Icons.filter_list),
      tooltip: l10n.gtdFilterTitle,
      onPressed: _navigateToGtdFilter,
    ),
  ],
```
Add a second `IconButton(icon: Icons.notifications_outlined, tooltip: l10n.<new>, onPressed: ...)` that pushes the settings page (a backup entry may live as a link inside that page). Check file length first; extract the navigation helper if the file nears 150 lines (guard applies to hand-written files).

---

### `lib/app.dart` (navigatorKey + tap routing) and `lib/main.dart` (bootstrap)

**Analog:** themselves. `app.dart:52` `MaterialApp(` is where `navigatorKey:` is added; `_AppShellState._selectedIndex` (line 92) is private, so expose tab selection through a small `ValueNotifier<int>`/cubit for the briefing tap target. `TaskDetailScreen(item: item)` is used at `task_list_screen.dart:61` as the task tap-through target.

`main.dart` order (lines 23-36): `ensureInitialized` -> `configureDependencies` -> `IsarService.instance.open([...])` -> `runApp`. Insert tz init + plugin `initialize` + `coordinator.start()` AFTER Isar open and BEFORE `runApp`; never initialise the plugin inside `AgendaApp.build` (`test/widget_test.dart` pumps the real shell).

---

### Tests

**Pure rules:** `test/domain/tasks/recurrence_engine_test.dart` style (`flutter_test`, plain `group/test`, inject `now`, assert on date components not instants).

**Real-Isar backup tests:** analog `test/data/finance/transaction_dao_aggregate_completeness_test.dart` + `test/support/isar_test_harness.dart:124-165`:
```dart
class MockIsarService extends Mock implements IsarService {}
import '../../support/isar_test_harness.dart';
// harness.open([schemas]) -> Isar; harness.close() in tearDown
// only IsarService is mocked; collections/filters are real
```
Seed 600 rows per collection (>500 cap regression); run with `flutter test -j 1`.

**Manifest contract test:** read `android/app/src/main/AndroidManifest.xml` as text and assert `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, both plugin receivers `android:exported="false"`, and `allowBackup="false"` (same source-text assertion approach used in `transaction_dao_ordering_test.dart`'s "DAO query shape" group).

**Fake gateway:** new `test/infrastructure/notifications/fake_notification_gateway.dart` implementing the gateway interface with an in-memory pending list.

## Shared Patterns

### Result-returning fallible services
**Source:** `lib/core/failures/failure.dart:20-53`, `lib/infrastructure/finance/debt_repository_impl.dart:21-41`
**Apply to:** gateway, prefs repo, backup repo, snapshot loader
Return `AsyncResult<T>`; catch `on Object catch (e)`; map to `NotificationFailure` / `BackupFailure` / `ValidationFailure`; `Success(...)` / `Err(...)`. Switch on results exhaustively with `case Err<T>(:final failure)` / `case Success<T>(:final value)` as in `budget_cubit.dart:83-89`.

### Watch-stream reactions
**Source:** `lib/application/finance/budget/budget_cubit.dart:34-42,127-131`
**Apply to:** `NotificationSyncCoordinator`, `BudgetAlertEvaluator`

### SharedPreferences-backed settings
**Source:** `lib/application/shared/locale/locale_cubit.dart`, `lib/core/constants/storage_keys.dart`
**Apply to:** `NotificationPrefsRepositoryImpl`, `BudgetAlertStateStoreImpl`, settings cubit
Keys centralised in `StorageKeys` with a doc comment each; persist then emit. Locale for notification text read from `StorageKeys.locale` (`'en'` or `'pt'`).

### Soft delete + uncapped reads
**Source:** `lib/data/finance/debt/debt_dao.dart:20-43`
**Apply to:** all new DAO read methods (reminders must filter `deletedAtIsNull()`; backup reads must not)

### DI
**Source:** `lib/config/di/finance_module.dart`, `core_module.dart`; repo impls use `@LazySingleton(as: Interface)`, cubits `@injectable`
**Apply to:** every new service; regenerate `injection.config.dart` (covered by `test/config/di/di_test.dart`).

### Test doubles
**Source:** `test/application/finance/debt_cubit_test.dart:10-12,30-36` (mocktail `Mock`, `blocTest`, stub `watchChanges` with `Stream.empty()`).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/infrastructure/notifications/gateway/*` (plugin calls, tz bootstrap, permissions) | service | platform channel | No platform-channel service exists yet; use RESEARCH.md "Plugin bootstrap / Schedule one / Permission calls" examples and the Result/try-catch shell from `debt_repository_impl.dart` |
| `lib/infrastructure/notifications/quotes/quotes_{en,pt}.dart` | const data | n/a | No bundled content lists exist; plain `const List<String>`, split per language, <=150 lines (so ~50 short quotes per file, or two files per language) |
| `ScheduleDiff` (desired vs pending) | utility | transform | No diff logic exists; pure function per RESEARCH Pattern 2 (payload `v1|kind|entityId|fireEpochSec|mode`) |
| Platform config (Gradle desugaring, manifest receivers/permissions, `allowBackup`, iOS `UNUserNotificationCenter` delegate) | config | n/a | Follow RESEARCH Pitfalls 4, 11, 13; keep `FlutterFragmentActivity` in `MainActivity.kt` |
| File picker I/O (`FilePicker.saveFile(bytes:)`, `pickFiles(withData: true)`) and safety-backup rotation via `path_provider` | service | file-I/O | No file I/O exists yet; use RESEARCH "Export via file_picker 11.0.2" (static methods, no `.platform`) |

## Metadata

**Analog search scope:** `lib/` (all layers), `test/`, `lib/config/di`, `android/app/src/main` (via RESEARCH)
**Files scanned:** ~230 tracked `lib/` and `test/` files listed; 14 read in full or in part
**Pattern extraction date:** 2026-10-12
