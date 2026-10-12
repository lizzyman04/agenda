# Phase 4: Notifications + Backup - Research

**Researched:** 2026-10-12
**Domain:** Flutter local notifications (flutter_local_notifications 21.0.0 + timezone) on Android/iOS, plus Isar-backed JSON/CSV export and atomic import
**Confidence:** MEDIUM-HIGH (in-repo facts and plugin signatures verified; OEM/boot/iOS delivery behaviour needs on-device confirmation)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Reminder timing**
- **D-01:** Task reminders fire a **fixed 30 minutes before** the due time. No per-task or global lead setting. Date-only tasks (no time) fire at the morning-briefing hour on the due day.
- **D-02:** Debt-due and recurring-payment (bill/subscription) reminders fire **1 day before the due date at 09:00**, once. No repeat for overdue debts.
- **D-03:** Morning briefing defaults to **08:00**, time **user-configurable** in notification prefs. Body: count of tasks due today + top 3 titles. **Skipped on days with nothing due.**
- **D-04:** Recurring-task reminders schedule the **next occurrence only**; reschedule when an occurrence is completed and on app start. Keeps usage under the iOS 64-notification cap.

**Budget and goal alerts**
- **D-05:** Budget alerts are evaluated **on transaction save/edit** (app open), not by a scheduled job. Thresholds 80% and 100% each fire **at most once per category per calendar month**. Fired state must be persisted so it survives restarts.
- **D-06:** Goal off-track = saved amount is more than **10% below linear expected progress** between goal creation and deadline. Evaluated on app open and by a **weekly scheduled check (Mon 09:00)**; max one alert per goal per week. Goals without a deadline are never flagged.

**Quotes and quiet hours**
- **D-07:** Motivational quotes come from a **bundled static list, ~50 per language** (PT-BR + EN, following app locale). Default **OFF**. User picks **daily or weekly** plus a time. Pre-schedule the next ~7 in random non-repeating order.
- **D-08:** Quiet hours default **22:00-07:00**, configurable. A notification landing inside the window is **deferred to the window end** (not dropped), for all types including the morning briefing if its time falls inside.
- **D-09:** Notification preferences live on a **standalone Notification Settings page + cubit** in Phase 4, reachable from a temporary entry point. Phase 5 mounts it as a section of the Settings screen with no rework. Prefs stored in SharedPreferences.

**Backup and import**
- **D-10:** **JSON** is the full, versioned backup/restore format (every collection in one file). **CSV** is exported **one file per entity** (tasks, transactions, budgets, goals, debts, recurring payments) and is also importable (DATA-04). CSV decimals are locale-aware.
- **D-11:** Import is **replace-all, atomic**: automatic safety backup first, then wipe + load in a single Isar transaction. A failed import leaves the database unchanged. A confirmation screen shows record counts and date range before commit.
- **D-12:** Exports are written to a **user-chosen location via file_picker** (no share_plus, to avoid routing data to other apps). The pre-import safety backup goes to the **app-private documents directory** (keep last 3); its path is shown if import fails.

### Claude's Discretion
- Notification ID strategy and channel layout per type.
- Android exact-alarm permission flow/fallback and notification permission prompt timing.
- iOS 64-slot priority ordering when the cap is reached.
- Tap-through navigation targets from each notification.
- JSON schema versioning and CSV column layout.

### Deferred Ideas (OUT OF SCOPE)
- Per-task reminder lead time and snooze (NOTF-V2-01) - v2.
- User-editable quotes - possible future phase.
- Merge-by-id import mode - not in MVP.
- Phase 3 `03-VERIFICATION.md` status `gaps_found` (BL-01) was noted in STATE.md; not part of this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTF-01 | Task reminders when due date/time approaches | Reconciler + pure fire-time rule (due - 30 min; date-only -> briefing hour); uncapped sorted due-item query (Pitfall 2); `zonedSchedule` 21.0.0 signature |
| NOTF-02 | Daily morning briefing with tasks due that day | Per-day one-shot schedule for next ~7 days, content precomputed (cannot be a repeating `DateTimeComponents.time`); skip empty days |
| NOTF-03 | Budget alerts at 80% / 100% | Evaluator on `TransactionRepository.watchChanges()`; fired-set in SharedPreferences keyed `YYYY-MM:categoryId:threshold`; highest-crossed-threshold-only rule |
| NOTF-04 | Recurring-task reminders | Recurring items already materialise their next occurrence as a new Item row (`buildNextOccurrence`); reconcile covers D-04 with no engine change; separate toggle kind |
| NOTF-05 | Debt due-date reminders | 1 day before @09:00 once; skip if fire time already past; `DebtRepository.watchChanges()` exists |
| NOTF-06 | Goal off-track alerts | Fire-time-deterministic evaluation (saved amount only changes in-app), weekly Mon 09:00 one-shot per goal + on-open check, persisted last-alert-week |
| NOTF-07 | Recurring-payment reminders | `nextDueDate` is never advanced by Phase 3; compute effective next due in memory; add `watchChanges()` to repo (missing today) |
| NOTF-08 | Motivational quotes (default OFF; frequency + time) | Bundled const lists, persisted shuffle seed -> deterministic non-repeating slots, 7 one-shots |
| NOTF-09 | Per-type toggles | `NotificationPrefs` in SharedPreferences; planner filters by kind; standalone cubit + page (D-09) |
| NOTF-10 | Quiet hours (default 22:00-07:00) | Pure `deferOutOfQuietHours` applied inside the planner for every kind including immediate budget alerts (schedule instead of `show`) |
| NOTF-11 | Reschedule after reboot | Plugin `ScheduledNotificationBootReceiver` + `RECEIVE_BOOT_COMPLETED` in manifest; app-start reconcile as belt-and-braces; device UAT mandatory |
| DATA-02 | JSON export | Explicit versioned codecs over Isar models, one envelope, uncapped reads (BL-01 class), `FilePicker.saveFile(bytes:)` |
| DATA-03 | CSV export | `csv` 8.0.0 `csv.encode`/`Csv(...)`, six files, locale-aware amount + locale-free `amount_cents`, formula-injection neutralisation |
| DATA-04 | JSON/CSV import w/ safety backup + atomic txn | Validate fully in memory -> confirm -> safety JSON -> one `isar.writeTxn` (clear + putAll); rollback is `abort(); rethrow` [VERIFIED in isar_community source] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Privacy:** no data may leave the device; no analytics, crash reporting, or cloud sync. `firebase_*`, `sentry_flutter`, `connectivity_plus`, `dio`/`http`, `share_plus`-style routing are out (CI greps `pubspec.yaml` for `http:|dio:|firebase_|sentry_flutter|connectivity_plus` [VERIFIED: .github/workflows/ci.yml:53]).
- **Stack is decided:** Flutter + isar_community 3.3.2 + BLoC/Cubit + GetIt/injectable. Pinned: flutter_local_notifications 21.0.0, timezone 0.11.0, flutter_timezone 5.0.2, file_picker 11.0.2, csv 8.0.0. Do not bump (newer majors exist - see State of the Art).
- **Forbidden / avoid:** `provider`, `riverpod`, `hive`, `mockito`, `freezed`, `get`, `to_csv`/`json2csv_dart`, `flutter_native_timezone`, `easy_localization`, `slang`.
- **Offline:** every feature must work with zero connectivity.
- **Language:** code in English; UI text PT-BR with EN toggle (three ARB files must stay in parity - `test/l10n/l10n_test.dart`).
- **Mobile only** (Android + iOS).
- **Phase 6 architecture guard (CI-enforced):** no hand-written `lib/` file over 150 lines; max 10 hand-written `.dart` files per directory; every directory under `lib/presentation/` and `lib/application/` needs a `README.md` [VERIFIED: tool/check_architecture.dart header + `maxLinesPerFile = 150`, `maxFilesPerDirectory = 10`].
- **GSD workflow:** edits go through a GSD command; `FlutterFragmentActivity` must stay (MainActivity.kt comment: "Do not revert to FlutterActivity").
- **Analyzer budget:** `flutter analyze --no-fatal-infos --fatal-warnings` currently reports 65 infos; STATE.md treats 65 as a held budget [VERIFIED: STATE.md]. New code should add zero infos (use `unawaited(...)`, avoid `discarded_futures`/`cascade_invocations` patterns noted in STATE.md).

## Summary

Phase 4 is two largely independent subsystems that meet only at import (post-import reschedule). **Notifications** are best built as a *reconciler*: a pure, fully unit-testable planner turns a snapshot of (items, debts, goals, recurring payments, budgets, prefs, `now`, timezone) into a desired list of `PlannedNotification`s (id, fire time, title, body, payload); a thin gateway diffs that against `pendingNotificationRequests()` and issues `cancel`/`zonedSchedule`. Every write path in the app already exposes `watchChanges()` (Isar `watchLazy`) for items, transactions, debts and goals, so a single long-lived coordinator subscribed to those streams (debounced, single-flight) is more robust than scattering imperative schedule calls through cubits - cubits are per-screen factories and would miss writes from import, undo, and other screens.

The hard constraints that shape the design: (1) a local notification cannot run code when it fires, so everything dynamic (briefing counts, goal off-track state) must be **precomputed at schedule time** - which is exact here because all data mutates only inside the app; (2) iOS keeps only 64 pending requests, so the planner owns a priority/slot budget; (3) Android 13+ needs a runtime notification permission and 14+ denies exact alarms by default, so the scheduler must pick `exactAllowWhileIdle` vs `inexactAllowWhileIdle` from `canScheduleExactNotifications()` and re-reconcile on resume; (4) this repo already burned itself on `.limit(500)`-without-sort (BL-01) - the backup exporter and the reminder queries must use dedicated uncapped/sorted reads, never the capped display-list repository methods.

**Backup** is a pure data-layer job: explicit versioned codecs per Isar model into one JSON envelope, six CSV files via `csv` 8.0.0, and an import pipeline of *parse + validate everything in memory -> confirm -> safety JSON to app-private dir -> one `isar.writeTxn` that `clear()`s and `putAll()`s every collection*. The isar_community source confirms `clear()` joins the ambient write transaction and any exception in the callback triggers `txn.abort(); rethrow`, so atomicity is real and testable with the existing real-Isar harness.

**Primary recommendation:** Build a pure-Dart `ReminderPlanner` + `ScheduleDiff` (domain layer) behind a single `NotificationSyncCoordinator` driven by repository `watchChanges()` streams, with a thin `flutter_local_notifications` gateway; build backup as explicit codecs + a single-transaction importer using uncapped DAO reads; do all `pubspec.yaml`, Gradle, manifest and AppDelegate edits in plan 04-01 so later plans never touch them.

## Architectural Responsibility Map

AGENDA is an on-device app; "tiers" are the project's layers plus the OS.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fire-time rules (30 min lead, 1 day @09:00, quiet-hours deferral, slot budget, quote selection) | Domain (pure Dart) | - | Zero Flutter/Isar; unit-testable with injected `now` |
| Snapshot loading for planner (uncapped due-item query, debts, goals, payments) | Data (DAO) + Domain repo interfaces | Infrastructure (repo impl) | Needs new sorted/uncapped DAO queries; repos stay the only DB door |
| Scheduling, diffing, permission checks, channel creation | Infrastructure (`flutter_local_notifications` gateway) | Platform (OS AlarmManager / UNUserNotificationCenter) | Plugin and `timezone` must never leak into domain |
| Reacting to data changes (reconcile trigger) | Application (long-lived coordinator) | Infrastructure | Subscribes to repo `watchChanges()`; not a per-screen cubit |
| Budget-alert evaluation + fired-state | Application (evaluator) + Infrastructure (SharedPreferences store) | Domain (threshold rule) | Evaluate on transaction change; state must survive restarts |
| Notification prefs (toggles, quiet hours, times) | Infrastructure (SharedPreferences repo) | Application (settings cubit) | D-09: SharedPreferences, standalone page + cubit |
| Tap-through navigation | Presentation (navigator key + router) | Application | Needs `Navigator`; payload grammar defined in domain |
| JSON/CSV encode/decode, validation, FK checks | Data (`lib/data/backup`) | Domain (snapshot value objects) | Isar-model-aware; pure functions over in-memory snapshot |
| Atomic wipe+load | Data (single `isar.writeTxn`) | - | Must not go through per-DAO `writeTxn` (nesting throws) |
| File I/O (save dialog, pick, safety backup dir) | Infrastructure (`file_picker`, `path_provider`) | - | Platform channels |
| Backup/settings screens | Presentation | Application (cubits) | Temporary entry point; Phase 5 re-mounts |
| Reboot persistence | Platform (plugin boot receiver) | Application (app-start reconcile) | Plugin persists + replays schedules; app reconcile corrects drift |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_local_notifications | 21.0.0 (pinned; latest on pub is 22.3.1) | Local scheduled + immediate notifications | The de-facto plugin; decided in CLAUDE.md. Requires Flutter >=3.38.1, Dart >=3.10, Android API 24+, compileSdk 36, AGP 8.11.1, Java 17, desugar_jdk_libs 2.1.4 [CITED: pub.dev changelog 21.0.0; README] |
| timezone | 0.11.0 (latest 0.11.1) | `TZDateTime` required by `zonedSchedule` | dart-lang labs verified publisher; transitive dep of the plugin |
| flutter_timezone | 5.0.2 | Device IANA timezone id | 5.x returns `TimezoneInfo` with `.identifier` [CITED: pub.dev TimezoneInfo class page] |
| file_picker | 11.0.2 | `saveFile(bytes:)` export, `pickFiles` import | Decided (D-12); 11.x uses **static** `FilePicker.saveFile/pickFiles` [CITED: changelog 11.0.0]; 11.0.2 fixes an Android path traversal (CWE-22) [CITED: changelog] |
| csv | 8.0.0 | RFC-4180 CSV encode/decode | Decided; 8.0.0 renamed `CsvCodec` -> `Csv`, top-level `csv` instance with `csv.encode`/`csv.decode` [CITED: pub.dev csv 8.0.0 README + changelog] |
| path_provider | 2.1.5 (already installed) | App-private documents dir for safety backups | Already in pubspec |
| shared_preferences | 2.5.5 (already installed) | Notification prefs + fired-state | D-05/D-09; existing pattern (LocaleCubit) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| intl | 0.20.2 (installed) | Amount/time formatting in notification bodies | `formatAmount(...)` already exists in `lib/core/utils/amount_formatter.dart` |
| bloc_test / mocktail | 10.0.0 / 1.0.5 (installed) | Cubit + gateway tests | Settings cubit, backup cubit |
| injectable / get_it | installed | DI registration | New services as `@LazySingleton(as: ...)`; regenerate `injection.config.dart` (committed) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reconciler (diff vs pending) | Imperative schedule/cancel calls in each cubit | Misses import/undo/other-screen writes; cubits are per-screen factories - reject |
| Explicit JSON codecs | Isar `collection.exportJson()/importJson()` | Less code but file format is welded to Isar field names; a renamed field silently breaks old backups. Explicit codecs + `formatVersion` recommended |
| `saveFile` x6 for CSV | `getDirectoryPath()` + `dart:io` writes | Android 11+ scoped storage: picked directory path can be unwritable/`/` [CITED: file_picker docs per search result]; use `saveFile(bytes:)` per file |
| Workmanager/background isolate for "weekly check" | Precompute at schedule time | Extra package outside decided stack; precompute is exact here (see Pattern 4) |

**Installation (plan 04-01, single pubspec edit):**
```yaml
# uncomment in pubspec.yaml (exact pins already present as comments)
  csv: 8.0.0
  file_picker: 11.0.2
  flutter_local_notifications: 21.0.0
  flutter_timezone: 5.0.2
  timezone: 0.11.0
```
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

**Version verification (this session):** pub.dev package pages fetched via WebFetch: flutter_local_notifications 21.0.0 page shows "Latest 22.3.1"; timezone page shows latest 0.11.1 (0.11.0 pinned); flutter_timezone page shows latest 5.1.1 (5.0.2 pinned, changelog dated 2026-03-15); csv 8.0.0 is latest; file_picker latest 13.1.0 (11.0.2 pinned). `curl` to pub.dev from the sandbox timed out, so registry JSON was not available. Pinned versions are decisions - no change recommended.

## Package Legitimacy Audit

The `gsd-tools package-legitimacy check` seam only accepts `npm|pypi|crates` (usage error for `pub`), so it could not be run for pub.dev packages. Audit performed manually from pub.dev pages fetched this session.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| flutter_local_notifications | pub.dev | multi-year | not shown | github.com/MaikuB/flutter_local_notifications | OK (verified publisher dexterx.dev) | Approved (pinned 21.0.0) |
| timezone | pub.dev | multi-year | 4.05M total | github.com/dart-lang/labs/tree/main/pkgs/timezone | OK (verified publisher labs.dart.dev) | Approved (pinned 0.11.0) |
| flutter_timezone | pub.dev | multi-year | 1.18M total | github.com/tjarvstrand/flutter_timezone | OK (verified publisher wolverinebeach.net) | Approved (pinned 5.0.2) |
| file_picker | pub.dev | multi-year | 4.42M | github.com/vicajilau/flutter_file_picker (repo URL now under a different owner than the long-time upstream `miguelpruivo`) | OK, note maintainer/repo move (verified publisher victorcarreras.dev) | Approved at pinned 11.0.2; review changelog before any bump |
| csv | pub.dev | multi-year | 824k | github.com/close2/csv | SUS-lite: **unverified uploader** (pure Dart, no native code) | Approved - decided stack; keep usage narrow, pin exact version; planner may add a `checkpoint:human-verify` before first `pub get` if the team wants |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** `csv` (unverified publisher only; no postinstall concept on pub; it is in the user-decided stack)

*All five names were present in the project's own pre-decided pubspec comments (user-authored), not discovered via search, so no `[ASSUMED]` package-name provenance applies.*

Also note: `timezone` 0.11.0 lists `http` and `path` as dependencies [CITED: pub.dev timezone 0.11.0 page]. `http` becomes a *transitive* dependency; the CI offline guard greps only direct `pubspec.yaml` entries, so it will not trip, and `timezone/data/latest.dart` ships its data in-package [CITED: README] - no network call is made. Do not import `package:timezone/standalone.dart` or `browser.dart`.

## Architecture Patterns

### System Architecture Diagram

```
 Isar writes (tasks, transactions, debts, goals, recurring payments, budgets, import)
            |  watchLazy() streams
            v
  +-------------------------------+      app start / resume / locale change / prefs change
  | NotificationSyncCoordinator   |<-----------------------------------------------+
  | (lazySingleton, debounce      |                                                 |
  |  300-500ms, single-flight)    |                                                 |
  +---------------+---------------+                                                 |
                  | reconcile()                                                      |
                  v                                                                  |
  +-------------------------------+   +---------------------------+                |
  | SnapshotLoader (repos; uses   |-->| ReminderPlanner (PURE)    |                |
  | uncapped/sorted queries)      |   |  - per-kind fire time     |                |
  +-------------------------------+   |  - quiet-hours deferral   |                |
        prefs (SharedPreferences) --->|  - toggles                |                |
        now, tz offset, locale ------>|  - slot budget/priority   |                |
                                      +-------------+-------------+                |
                                                    | List<PlannedNotification>     |
                                                    v                               |
                                      +---------------------------+                |
                                      | ScheduleDiff (PURE)       |                |
                                      | desired vs pending        |                |
                                      +-------------+-------------+                |
                                                    | cancel[], schedule[]          |
                                                    v                               |
                                      +---------------------------+   OS          |
                                      | LocalNotificationGateway  |-------------> AlarmManager / UNUserNotificationCenter
                                      | (flutter_local_notif.)    |                |          |
                                      +---------------------------+                |          | fires
                                                                                   |          v
  TransactionRepository.watchChanges --> BudgetAlertEvaluator --> (threshold crossed, not yet fired)
                                          | persist fired-key (SharedPreferences)  |   show()/schedule at quiet end
                                          v                                        |
                                      gateway.showOrDefer(...)                      |
                                                                                    |
  Notification tap --> onDidReceiveNotificationResponse(payload) --> NotificationTapRouter --> navigatorKey.push(...)
  Cold start tap  --> getNotificationAppLaunchDetails() ------------------------------^

  Device reboot --> plugin ScheduledNotificationBootReceiver replays persisted schedules (no app code)
                    next app launch --> reconcile() corrects drift

  BACKUP
  Export:  BackupDao (uncapped reads, ALL rows) --> codecs --> JSON envelope / 6 CSV --> FilePicker.saveFile(bytes)
  Import:  FilePicker.pickFiles(withData) --> parse+validate in memory --> ImportPreview(counts, date range)
           --> user confirms --> SafetyBackup (JSON -> app docs/backups, keep 3)
           --> isar.writeTxn{ clear() x7; putAll() x7 }  (throw => abort => DB unchanged)
           --> reset fired-state / seed silently --> coordinator.reconcile()
```

### Recommended Project Structure

(Each directory <= 10 hand-written files and each file <= 150 lines; `application/` and `presentation/` dirs each need a README.)

```
lib/
├── core/constants/               # extend StorageKeys, AppConstants (keys listed below)
├── domain/notifications/
│   ├── model/                    # NotificationKind, PlannedNotification, NotificationPrefs, QuietHours
│   ├── rules/                    # fire-time rules, quiet_hours.dart, slot_budget.dart, goal_off_track.dart,
│   │                             #   budget_threshold.dart, effective_due_date.dart, quote_picker.dart
│   └── (interfaces)              # LocalNotificationGateway, NotificationPrefsRepository, BudgetAlertStateStore
├── domain/backup/                # BackupSnapshot, ImportPreview, BackupRepository interface, formatVersion const
├── data/backup/
│   ├── dao/                      # BackupDao (uncapped findAll for all 7 collections), BackupImportDao (single txn)
│   ├── json/                     # one codec per entity + envelope + validator
│   └── csv/                      # per-entity row mappers, amount parser, injection guard, delimiter sniff
├── infrastructure/notifications/
│   ├── gateway/                  # FlutterLocalNotificationsGateway, channels, permission service, tz bootstrap
│   ├── sync/                     # NotificationSyncCoordinator, SnapshotLoader, ScheduleDiff
│   ├── prefs/                    # NotificationPrefsRepositoryImpl, BudgetAlertStateStoreImpl
│   └── quotes/                   # quotes_en.dart, quotes_pt.dart (const lists)
├── infrastructure/backup/        # BackupRepositoryImpl (file_picker, path_provider, safety dir rotation)
├── application/notifications/    # NotificationSettingsCubit(+state), BudgetAlertEvaluator (+README)
├── application/backup/           # BackupCubit(+state): export, import preview, confirm (+README)
├── presentation/notifications/   # screens/ (settings page), widgets/ (+README)
├── presentation/backup/          # screens/ (export/import page, confirm screen) (+README)
└── config/di/                    # InfrastructureModule populated; regenerate injection.config.dart
```

### Pattern 1: Pure planner, thin gateway

**What:** `ReminderPlanner.plan(PlannerInput) -> List<PlannedNotification>` is a pure function of `now`, the data snapshot, and prefs. No plugin, no `tz`, no Isar. The gateway converts `DateTime` -> `tz.TZDateTime.from(dt, tz.local)` only at the last moment.
**When to use:** all scheduled kinds. This is what makes NOTF-01..10 testable in < 1 s per test with no emulator.
**Example:** see Code Examples (`PlannedNotification`, `deferOutOfQuietHours`, id derivation).

### Pattern 2: Diff against pending, with signature in the payload

**What:** `pendingNotificationRequests()` returns only `id`, `title`, `body`, `payload` [CITED: platform_flutter_local_notifications.dart] - not the fire time or schedule mode. Embed `fireEpochSec` and mode (`e`/`i`) in the payload so a diff can detect "same id, different time/mode" and re-schedule (this also makes "exact permission granted later" and "timezone changed" self-heal on the next reconcile).
**Payload grammar (recommended):** `v1|<kind>|<entityId>|<fireEpochSec>|<mode>` - the tap router reads fields 1-2; everything else is for the diff. Parse defensively (Security).

### Pattern 3: Precompute dynamic content at schedule time

**What:** A fired local notification cannot execute code. Content that depends on data (briefing "3 tasks due: ...", goal off-track state) is computed for the *fire date* when scheduling. This is exact because data mutates only while the app runs, and every mutation triggers a reconcile.
**Consequences:** briefing is N one-shots (next ~7 days, only days with due tasks), not `matchDateTimeComponents: DateTimeComponents.time`; the "weekly goal check" is a per-goal one-shot for next Monday 09:00 computed `asOf` that instant; both stop being refreshed if the user never opens the app (accepted).

### Pattern 4: Evaluate-on-write for budget alerts

**What:** `BudgetAlertEvaluator` subscribes to `TransactionRepository.watchChanges()` (exists) and also gets poked by budget-limit changes (BudgetRepository has no `watchChanges()` today - add one or call evaluate from `BudgetCubit.setLimit`). It loads this month's expense totals via `getByMonth` (uncapped after BL-01 fix) and `getForMonth`, computes the highest crossed threshold per category, and fires only if its key is not in the fired-set.
**Rules to encode:** highest crossed threshold only (70% -> 110% in one transaction fires the 100% alert once and marks 80% fired too); current calendar month only (a back-dated transaction in last month does not alert); limit `0`/absent budgets are ignored; evaluation inside quiet hours schedules the notification at window end instead of `show()`.
**Import interaction:** after import, *seed* the fired-set silently with every threshold already exceeded so a restore does not spam.

### Pattern 5: Single-transaction import

**What:** Everything that can fail on bad data fails *before* the write transaction (parse, type checks, FK checks, duplicate unique keys). Inside the transaction only DB errors remain; any throw aborts and rolls back.
See Code Examples (`importAll`).

### Anti-Patterns to Avoid
- **Calling `schedule` from cubits:** per-screen factory cubits are not alive for import/undo/other-screen writes. Use the coordinator.
- **Using repository display-list methods for export/reminders:** `ItemDao.filterItems/findByType/...` apply `.limit(500)` (see Pitfall 2). Add dedicated DAO methods.
- **Nested `writeTxn`:** DAO `save()` methods each open their own `writeTxn` (e.g. `TransactionDao.save`); calling them inside the import transaction throws. The importer must use the collections directly.
- **`cancelAll()` then re-schedule on every change:** causes a window with nothing pending and doubles work; diff instead (plus it destroys already-fired-but-pending state on some OEMs).
- **Initialising the plugin or requesting permission inside `AgendaApp.build`:** `test/widget_test.dart` pumps the real app shell with stub repositories; platform channels throw in VM tests. Bootstrap from `main()` only.
- **Reusing `parseAmountCentsOrNull` for CSV import:** it rejects `1.250,50` and silently turns `-5` into `+500` cents (STATE.md blocker). Write a dedicated strict parser.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scheduling after reboot | Custom BOOT_COMPLETED receiver + Isar payload store (ROADMAP 04-02 sketch) | Plugin `ScheduledNotificationBootReceiver` (declared in manifest) | The plugin persists schedules and replays them on boot / package replace / QUICKBOOT [CITED: README receiver section]. Isar payload persistence is unnecessary |
| Time-zone math | Manual UTC-offset arithmetic | `timezone` `TZDateTime` + `flutter_timezone` id | DST/offset correctness |
| CSV quoting/escaping | `join(',')` | `csv` 8.0.0 `csv.encode` / `Csv(...)` | Quotes, embedded newlines, `;`+`,` decimals |
| Notification permission flows | Raw platform channels | `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()` / `requestExactAlarmsPermission()` / `canScheduleExactNotifications()`; iOS `requestPermissions(...)` | Already in plugin [CITED: platform_flutter_local_notifications.dart] |
| Atomic restore | Manual "copy old data, try, restore on failure" | One `isar.writeTxn` | Isar aborts on throw [VERIFIED: isar_common.dart `_beginTxn`] |
| Save/open dialogs | `dart:io` into a picked directory | `FilePicker.saveFile(bytes:)` / `pickFiles(withData: true)` | Android 11+ scoped storage |
| Localised strings in services | Hard-coded PT/EN maps | `lookupAppLocalizations(Locale)` from generated l10n | Exists without a `BuildContext` [VERIFIED: lib/generated/l10n/app_localizations.dart:1494] |
| Amount formatting | String concat | existing `formatAmount(cents, symbol, locale)` | Locale-correct thousands/decimals |

**Key insight:** the only genuinely custom logic in this phase is *rules* (fire times, quiet hours, slot priority, threshold crossing, validation). Everything else has a library or an Isar guarantee. Keep the rules pure so they are cheap to verify.

## Common Pitfalls

### Pitfall 1: `tz.local` defaults to UTC
**What goes wrong:** all notifications fire at the wrong wall-clock hour (e.g. 08:00 UTC instead of 08:00 local).
**Why:** `timezone` default local location is UTC until `setLocalLocation` is called [CITED: timezone README].
**How to avoid:** at every cold start `initializeTimeZones()` (from `package:timezone/data/latest.dart`, **not** `latest_10y`, whose data covers only ~5 years around the package date and would drop DST rules later [CITED: README variants]) then `tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier))`. Re-read on every start/resume (user travels). Wrap in try/catch; fall back to `tz.getLocation('UTC')` + a `NotificationFailure`.
**Warning signs:** briefing arrives hours off on device; fine in unit tests.

### Pitfall 2: `.limit(500)` without sort in reminder and export queries (BL-01 class)
**What goes wrong:** with >500 items the oldest 500 (id order) are read and newer ones are silently dropped - reminders never scheduled, backups silently truncated.
**Why:** Isar returns id order; `ItemDao.findByType/findSubtasks/searchByTitle/filterItems` all `.limit(500)` [VERIFIED: lib/data/tasks/item_dao.dart], `RecurringPaymentDao.findAll` caps at 500 after a sort, `TransactionDao.findAll` caps at 500 after `sortByDateDesc`. Only `TransactionDao.findAllForAggregates` is uncapped [VERIFIED: lib/data/finance/transaction/transaction_dao.dart].
**How to avoid:** add dedicated methods: `ItemDao.findUpcomingDue(from)` = `deletedAtIsNull & isCompletedEqualTo(false) & dueDateGreaterThan(...)` **sorted by dueDate asc then limited to the platform slot budget** (sort-then-cap = "soonest N", which is correct for reminders); a separate time-window query (`dueDate` between today and +8 days, *uncapped*) for briefing counts; `BackupDao.findAll*()` with **no** limit and **no** `deletedAtIsNull` filter for JSON. Add a real-Isar regression test seeding 600 rows (pattern from `test/support/isar_test_harness.dart`).
**Warning signs:** export record count != Isar count.

### Pitfall 3: Past dates throw
**What goes wrong:** `zonedSchedule` throws `ArgumentError: Must be a date in the future` when `matchDateTimeComponents` is null and the date is before now [CITED: plugin 21.0.0 `helpers.dart` `validateDateIsInTheFuture`], crashing the whole reconcile.
**How to avoid:** planner drops anything with `fireAt <= now` (D-02 "once" is then satisfied by determinism); gateway wraps each schedule in try/catch so one bad item cannot abort the batch.

### Pitfall 4: Android 14 exact alarms denied by default
**What goes wrong:** `exactAllowWhileIdle` without the permission logs an error and the notification is not scheduled [CITED: README]; on API 31+ `setExact*` throws `SecurityException` without the permission [CITED: developer.android.com schedule-exact-alarms].
**How to avoid:** `final exact = await android.canScheduleExactNotifications() ?? false;` -> `exactAllowWhileIdle` else `inexactAllowWhileIdle`; offer an in-app explanation + `requestExactAlarmsPermission()`; re-reconcile on `AppLifecycleState.resumed` (permission may have changed; revocation kills the app and cancels future exact alarms [CITED: developer.android.com alarms/schedule]). Mode is part of the diff signature so a later grant upgrades pending items.
**Declaration choice:** declare `SCHEDULE_EXACT_ALARM` (user-granted), not `USE_EXACT_ALARM` - the latter is for alarm-clock/calendar apps under a Play policy [CITED: developer.android.com; Play policy specifics `[ASSUMED]`, see A1].

### Pitfall 5: iOS 64 pending cap
**What goes wrong:** more than 64 pending requests -> some are discarded by iOS.
**Why/ambiguity:** the plugin README says that on iOS > 9 the system keeps "the 64 notifications that were set most recently" [CITED: README]; Apple's older UILocalNotification documentation said soonest-firing - behaviour is not safe to rely on.
**How to avoid:** the planner never emits more than the platform budget (iOS 60 of `AppConstants.iosMaxScheduledNotifications = 64`, leaving 4 spare; Android 200 [ASSUMED], well under the ~500 Samsung alarm limit the README warns about). Priority: user-created reminders (task, recurring task, debt, recurring payment, goal weekly) soonest-first; reserve fixed shares for briefing (<=7) and quotes (<=7). Immediate budget alerts (`show`) are not pending and do not count. Surface "N reminders waiting" in the settings page if truncated.

### Pitfall 6: Quiet-hours placement in the roadmap
**What goes wrong:** ROADMAP puts quiet hours and the iOS slot manager in 04-04, *after* the task scheduler (04-02) that must already apply both to be correct.
**How to avoid:** implement `QuietHours` and `SlotBudget` as pure rules in 04-01/04-02; 04-04 then only adds prefs UI/cubit. See Plan Sizing.

### Pitfall 7: Date-only reminders + briefing double up (D-01 x D-03)
**What goes wrong:** D-01 fires every date-only task at the briefing hour, and the briefing itself fires then too - N+1 notifications in the same minute.
**How to avoid (stays inside the locks):** keep per-task notifications as locked, but on Android set a shared `groupKey` (and a summary) for same-time date-only reminders and on iOS a `threadIdentifier`; also each costs an iOS slot, so the slot budget matters most here. Flag to user in discuss/UAT if it feels noisy (not a research decision to change).

### Pitfall 8: Recurring payments' `nextDueDate` is never advanced
**What goes wrong:** Phase 3 only stores it; the model doc says "Phase 4 advances this" [VERIFIED: recurring_payment_model.dart doc]. An old payment has `nextDueDate` in the past, so the reminder is perpetually "past" and never fires.
**How to avoid:** compute `effectiveDueDate = firstOnOrAfter(nextDueDate, cycle, now)` in memory (clamp month-ends like `RecurrenceEngineImpl._nextMonthly`; `DateTime(y, m+1, d)` overflows Jan 31 -> Mar 3). Do **not** mutate the DB inside reconcile (would trigger the watcher again and silently implies "paid"). Persisting the advance is an Open Question.
**Also:** `RecurringPaymentRepository` has no `watchChanges()` [VERIFIED: interface] - add it (DAO `watchLazy`), and update the two hand-written stubs in `test/widget_test.dart` (`_StubBudgetRepository`, `_StubRecurringPaymentRepository` implement the interfaces and will stop compiling).

### Pitfall 9: Notification text language and staleness
**What goes wrong:** body/title are baked at schedule time. Changing language (Phase 5) or editing a title leaves stale text.
**How to avoid:** read `StorageKeys.locale` (`'en'` or `'pt'`) at reconcile time, resolve with `lookupAppLocalizations`, and have the coordinator also listen to `LocaleCubit.stream`; the diff compares title/body so text drift reschedules. Android channel *names* are fixed at creation except name/description updates [A13] - re-call `createNotificationChannel` on locale change.

### Pitfall 10: Permission prompt at the wrong time
**What goes wrong:** `DarwinInitializationSettings` defaults `requestAlertPermission/Sound/Badge = true` [CITED: initialization_settings.dart], so `initialize()` prompts on first launch before the user has any reminders.
**How to avoid:** pass `false` for all three; request explicitly in context (first time the user enables a type in settings or saves a task/debt/bill that would schedule). Android 13+ uses `requestNotificationsPermission()`. Persist an "asked" flag; on denial show a non-blocking banner (no `permission_handler` in the stack, so no deep-link - text instruction only).

### Pitfall 11: Safety backup and Android Auto Backup
**What goes wrong:** `AndroidManifest.xml` sets no `android:allowBackup`; the default is `true` and Auto Backup includes `getFilesDir()` content to the user's Google Drive [VERIFIED: manifest read in full; CITED: developer.android.com/identity/data/autobackup]. The Isar DB and the new safety-backup files live there. That contradicts "no data may leave the device".
**How to avoid:** set `android:allowBackup="false"` (and `dataExtractionRules`/`fullBackupContent` excluding all domains) - but this changes reinstall behaviour (data not auto-restored), so it is an Open Question for the user. Either way, document it.

### Pitfall 12: ID collisions and int32
**What goes wrong:** `entityId * 10 + type` collides across entity families (task 5/type 1 vs debt 5/type 1) and plugin IDs must fit 32-bit [CITED: platform-interface `validateId` doc "32-bit"].
**How to avoid:** `id = base * 10_000_000 + entityId * 10 + type` using the existing `AppConfig.taskNotificationBase = 10`, `financeNotificationBase = 20`, `systemNotificationBase = 30` (03-CONTEXT.md says "do not remove" `financeNotificationBase`). Max 30*10M + 999,999*10 + 9 = 309,999,999 < 2,147,483,647. Property-test uniqueness across the grid.

### Pitfall 13: iOS UIScene AppDelegate
The iOS runner already uses the UIScene lifecycle (`FlutterImplicitEngineDelegate`, `SceneDelegate: FlutterSceneDelegate`) [VERIFIED: ios/Runner/AppDelegate.swift, SceneDelegate.swift]. The README requires `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` in `didFinishLaunchingWithOptions` [CITED: README]; the plugin-registrant-callback variant applies only to background action handlers, which this phase does not use. iOS cannot be built or verified on this Linux machine (no `xcodebuild`) - iOS delivery is a human UAT item.

### Pitfall 14: Docs drift between package majors
`FilePicker.saveFile` in the latest docs returns a `Uri`-flavoured result and is documented for 12.x/13.x; 11.0.2 is `static Future<String?> saveFile({dialogTitle, fileName, initialDirectory, type, allowedExtensions, bytes, lockParentWindow})` [CITED: pub.dev file_picker 11.0.x API page]. Same for csv 6.x tutorials (`ListToCsvConverter`) - removed in 7.0.0. Do not copy examples from blog posts or `latest` docs.

### Pitfall 15: CSV delimiter auto-detection
`csv` 7+ auto-detects `,` `;` `\t` `|` and honours `sep=;` [CITED: README]. A one-column file or a text field full of commas can mis-detect. Sniff the delimiter yourself from the header row (we write canonical English headers), construct `Csv(fieldDelimiter: sniffed)`, and verify the parsed header equals the expected column list before accepting; otherwise reject with a clear error.

## Code Examples

Signatures marked [CITED] were read from the 21.0.0 / 11.0.x / 8.0.0 sources or API pages this session. Wrapper types and rules are recommendations.

### Plugin bootstrap (runs from `main()` only)
```dart
// Source: flutter_local_notifications 21.0.0 README + platform_flutter_local_notifications.dart [CITED]
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> bootstrap(FlutterLocalNotificationsPlugin plugin) async {
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone(); // TimezoneInfo, 5.x
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } on Object {
    tz.setLocalLocation(tz.getLocation('UTC')); // + report NotificationFailure
  }
  await plugin.initialize(
    settings: const InitializationSettings( // shape [ASSUMED], compile-check in Wave 0
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (r) => /* router.handle(r.payload) */ null,
  );
}
```

### Schedule one notification (21.0.0 named-parameter API)
```dart
// Source: plugin zonedSchedule signature [CITED]; AndroidScheduleMode values [CITED]:
//   alarmClock, exact, exactAllowWhileIdle, inexact, inexactAllowWhileIdle
Future<void> schedule(PlannedNotification p, {required bool canExact}) async {
  await plugin.zonedSchedule(
    id: p.id,
    title: p.title,
    body: p.body,
    scheduledDate: tz.TZDateTime.from(p.fireAt, tz.local),
    notificationDetails: detailsFor(p.kind),          // NotificationDetails(android:, iOS:)
    androidScheduleMode: canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    payload: p.payload,
  );
}
// cancel is named too: await plugin.cancel(id: id);
// Android details: AndroidNotificationDetails('agenda_tasks', 'Tasks',  // 2 positional
//     channelDescription: '...', importance: Importance.high, priority: Priority.high,
//     visibility: NotificationVisibility.private);                        // lock-screen privacy [A17]
```

### Permission calls
```dart
final android = plugin.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>();
final granted = await android?.requestNotificationsPermission();   // Android 13+
final canExact = await android?.canScheduleExactNotifications();   // bool?
await android?.requestExactAlarmsPermission();                     // opens system page
final ios = plugin.resolvePlatformSpecificImplementation<
    IOSFlutterLocalNotificationsPlugin>();
await ios?.requestPermissions(alert: true, sound: true);           // badge optional
```

### Deterministic notification IDs
```dart
// Reuses AppConfig.{task,finance,system}NotificationBase = 10 / 20 / 30 [VERIFIED].
// id = base * 10_000_000 + entityId * 10 + type  (type 0..9)
int notificationId({required int base, required int entityId, required int type}) {
  assert(entityId >= 0 && entityId < 1_000_000 && type >= 0 && type < 10);
  return base * 10000000 + entityId * 10 + type;
}
// task: base 10, type 0 = due reminder, 1 = recurring-task reminder
// finance: base 20, type 0 = debt, 1 = recurring payment, 2 = goal weekly, 3 = budget80, 4 = budget100
// system: base 30, entityId = epochDay (briefing, type 0) / slot epochDay|epochWeek (quote, type 1)
```

### Quiet-hours deferral (pure; start inclusive, end exclusive; handles overnight wrap)
```dart
DateTime deferOutOfQuietHours(
  DateTime t, {required int startMin, required int endMin}) {
  if (startMin == endMin) return t;                 // zero-length = no window
  final m = t.hour * 60 + t.minute;
  final wraps = startMin > endMin;
  final inside = wraps ? (m >= startMin || m < endMin)
                       : (m >= startMin && m < endMin);
  if (!inside) return t;
  // Evening part of an overnight window ends on the NEXT calendar day.
  final addDay = wraps && m >= startMin;
  return DateTime(t.year, t.month, t.day + (addDay ? 1 : 0),
      endMin ~/ 60, endMin % 60);                   // component constructor: DST-safe
}
```

### Fire-time rules (inputs are local wall-clock `DateTime`s)
```dart
DateTime? taskFireAt(Item i, {required int briefingMin, required DateTime now}) {
  final d = i.dueDate; if (d == null) return null;
  final day = DateTime(d.year, d.month, d.day);
  final due = i.dueTimeMinutes == null
      ? DateTime(day.year, day.month, day.day, briefingMin ~/ 60, briefingMin % 60)
      : DateTime(day.year, day.month, day.day, i.dueTimeMinutes! ~/ 60,
            i.dueTimeMinutes! % 60).subtract(const Duration(minutes: 30));
  return due.isAfter(now) ? due : null;
}
DateTime? dayBefore9am(DateTime due, DateTime now) {          // debts + bills (D-02)
  final f = DateTime(due.year, due.month, due.day - 1, 9);
  return f.isAfter(now) ? f : null;                           // already past -> no reminder
}
```

### Goal off-track (asOf = the instant the alert would fire)
```dart
bool isOffTrack({required int savedCents, required int targetCents,
    required DateTime createdAt, required DateTime? deadline,
    required DateTime asOf}) {
  if (deadline == null || targetCents <= 0) return false;
  final span = deadline.difference(createdAt).inSeconds;
  if (span <= 0) return false;
  final elapsed = asOf.difference(createdAt).inSeconds.clamp(0, span);
  final expected = elapsed / span;                            // 0..1
  return savedCents / targetCents < expected - 0.10;          // 10 percentage points [A14]
}
```

### Effective next due date for a recurring payment (no DB write)
```dart
DateTime effectiveDue(DateTime next, RecurringCycle c, DateTime now) {
  var d = next;
  while (d.isBefore(DateTime(now.year, now.month, now.day))) {
    d = stepCycle(d, c); // monthly/quarterly/yearly: clamp day to month length
  }
  return d;
}
```

### Atomic import (the only place that may touch all collections in one txn)
```dart
// Source: isar_community 3.3.2: clear() resets auto-increment and joins the ambient
// write txn (isar_collection_impl.dart:406-411); _beginTxn does `await txn.abort(); rethrow;`
Future<void> importAll(Isar isar, BackupSnapshot s) async {
  // 1) s was fully parsed + validated BEFORE this call (types, FKs, unique keys).
  await isar.writeTxn(() async {
    await isar.collection<ItemModel>().clear();
    await isar.collection<TransactionModel>().clear();
    await isar.collection<TransactionCategoryModel>().clear();
    await isar.collection<BudgetModel>().clear();
    await isar.collection<SavingsGoalModel>().clear();
    await isar.collection<DebtModel>().clear();
    await isar.collection<RecurringPaymentModel>().clear();
    await isar.collection<TransactionCategoryModel>().putAll(s.categories); // explicit ids kept
    await isar.collection<ItemModel>().putAll(s.items);
    // ... remaining collections; any throw aborts everything
  });
}
```
Gotcha: `SavingsGoalModel.contributions` must be a **growable** list when building models (Phase 3 UAT bug) - `List.of(...)`, never `const []`/`List.unmodifiable` [VERIFIED: savings_goal_model.dart doc].

### CSV encode/decode (csv 8.0.0)
```dart
import 'package:csv/csv.dart';
// Source: pub.dev/packages/csv/versions/8.0.0 README [CITED]
final codecPt = Csv(fieldDelimiter: ';', lineDelimiter: '\r\n'); // PT-BR Excel list separator [A8]
final text = codecPt.encode(rows);                  // List<List<dynamic>> -> String
final rowsBack = Csv(fieldDelimiter: sniffed).decode(text);
final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(text)]; // UTF-8 BOM so Excel reads accents [A8]
```
Column design (recommended): canonical English header names; dates as ISO-8601; money as both `amount` (locale decimal, display) and `amount_cents` (integer, authoritative on import); text columns neutralised against formula injection (prefix `'` when the cell starts with `= + - @ \t \r`, strip on import).

### Export via file_picker 11.0.2
```dart
// Source: pub.dev file_picker 11.0.x API [CITED] - static methods since 11.0.0
final path = await FilePicker.saveFile(
  dialogTitle: l10n.exportSaveTitle,
  fileName: 'agenda-backup-2026-10-12.json',
  bytes: Uint8List.fromList(utf8.encode(jsonText)),   // always pass bytes [A5]
);
// null => user cancelled
final picked = await FilePicker.pickFiles(type: FileType.any, withData: true); // [A6]
```

### Tap routing (payload -> screen)
| Kind | Target (existing widget) | Note |
|------|--------------------------|------|
| task / recurring task | `TaskDetailScreen(item:)` | load `Item` by id first; if missing/deleted -> task tab |
| briefing | select task tab / day planner | `_AppShellState._selectedIndex` is private; expose via a small `ValueNotifier`/cubit |
| budget | `BudgetOverviewScreen` | finance cubits are provided above `MaterialApp` |
| debt | `DebtListScreen` | |
| recurring payment | `RecurringPaymentScreen` | |
| goal | `GoalDetailScreen(goalId:)` | |
| quote | app open only | |
`AgendaApp` has no `navigatorKey` today [VERIFIED: lib/app.dart]; add one (hoisted above `MaterialApp`) and call `getNotificationAppLaunchDetails()` once the first frame is up for cold-start taps.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Positional `zonedSchedule(id, title, body, date, details, ...)` | Named params; `androidScheduleMode` required | plugin 20.0.0 [CITED: changelog] | Old blog snippets will not compile |
| `uiLocalNotificationDateInterpretation` param | Removed | plugin 19.0.0 [CITED] | Do not pass it |
| `FilePicker.platform.saveFile` | `FilePicker.saveFile` (static) | file_picker 11.0.0 [CITED] | Drop `.platform` |
| `CsvToListConverter` / `ListToCsvConverter` | `csv.decode` / `csv.encode`, `Csv(...)` | csv 7.0.0/8.0.0 [CITED] | 6.x tutorials obsolete |
| `flutter_timezone` returns `String` | `TimezoneInfo.identifier` | flutter_timezone 5.0.0 [CITED] | Use `.identifier` |
| `SCHEDULE_EXACT_ALARM` effectively pre-granted | Denied by default on Android 14 for new installs targeting API 33+ | Android 14 [CITED] | Must check + fall back |

**Newer majors exist (decisions pin the old ones):** flutter_local_notifications 22.3.1 (23.0.0-dev), file_picker 13.1.0, flutter_timezone 5.1.1, timezone 0.11.1. Record, do not act.

**Deprecated/outdated:**
- `flutter_native_timezone`: replaced by `flutter_timezone` (already in the "never use" list).
- Isar original package: abandoned; project uses `isar_community`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Google Play's `USE_EXACT_ALARM` policy admits only alarm-clock/calendar-type apps, so a to-do app should declare `SCHEDULE_EXACT_ALARM` | Pitfall 4 | If a to-do app qualified, UX could skip the permission prompt; low risk either way |
| A2 | iOS drops excess pending requests in an unspecified order (README says "most recent" kept) | Pitfall 5 | If actually soonest-kept, our budget still protects; only matters if we exceed it |
| A3 | Plugin boot receiver replays one-shot `zonedSchedule` entries from its persisted store and handles ones that elapsed while powered off sensibly | Don't Hand-Roll, NOTF-11 | Missed or burst-fired notifications after reboot; **needs device UAT on the Infinix X6831** |
| A4 | `putAll` with explicit ids advances Isar's auto-increment counter (and `clear()` resets it) | Code Examples (import) | New rows after restore could collide or overwrite; must be proven by a real-Isar test in Wave 0 |
| A5 | file_picker 11.0.2 `saveFile` on Android/iOS needs `bytes` and uses the system save UI | Code Examples | Export writes nothing; verify on device in Wave 0 |
| A6 | `FileType.custom` + `allowedExtensions: ['json','csv']` is unreliable across Android MIME types; `FileType.any` + content sniff is safer | Code Examples | Picker greys out valid files on some OEMs |
| A7 | `NumberFormat`/`formatAmount` works in a non-widget service without calling `initializeDateFormatting`; `DateFormat('HH:mm')` is locale-independent | Pitfall 9 | Format exception at schedule time |
| A8 | Excel PT-BR expects `;` list separator and a UTF-8 BOM for accents | CSV example | CSV opens as one column / mojibake in Excel (data still correct) |
| A9 | `package:timezone/data/latest.dart` ships tz data in-package (no network) | Package Legitimacy Audit | Would violate offline constraint (README suggests it does not) |
| A10 | Android budget cap of 200 pending is conservative enough for OEM alarm limits | Pitfall 5 | OEM drops alarms above its own cap |
| A11 | Debt reminders apply to both `toPay` and `toReceive` (unpaid, not deleted) | NOTF-05 | User may only want payables |
| A12 | Recurring-task reminders use the same 30-minute lead as D-01 | NOTF-04 | D-04 is silent on lead |
| A13 | Android channel importance/sound are immutable after creation; only name/description can be updated | Pitfall 9 | Wrong channel config cannot be fixed without reinstall/new channel id |
| A14 | "10% below linear expected progress" means 10 percentage points of target (not 10% relative) | Code Examples | Alerts fire earlier/later than the user intended |
| A15 | `InitializationSettings(android:, iOS:)` and `FlutterLocalNotificationsPlugin.show({id,title,body,notificationDetails,payload})` shapes (only the platform-level `show` was read) | Code Examples | Compile error, trivial to fix in Wave 0 |
| A16 | Isar returns stored `DateTime`s in local time | Backup codecs | Date-semantic fields shift by timezone on restore if wrong |
| A17 | `NotificationVisibility.private` hides content on a secure lock screen | Security | Finance/task text readable on lock screen |
| A18 | `showDatePicker` yields local midnight so `Item.dueDate` is a date-only value | fire-time rules | Reminder off by the time component |
| A19 | Tasks and subtasks (not projects) get reminders/briefing counts | NOTF-01/02 | Projects with due dates silently ignored |

## Open Questions

1. **What does CSV "replace-all" replace?**
   - Known: D-10 says CSV is per-entity and importable; D-11 says import is replace-all atomic.
   - Unclear: importing only `transactions.csv` must not wipe tasks, goals, etc.
   - Recommendation: CSV import = replace-all **of the entity collections for which a file was supplied**, with `allowMultiple: true` so a user can import all six together; same safety backup + single transaction; categories are not exported as CSV, so resolve `category_id` first then name match, else create a custom category inside the transaction. Confirm with user.

2. **Should Phase 4 persist the advance of `RecurringPayment.nextDueDate`?**
   - Known: doc comments say Phase 4 advances it; nothing in Phase 3 does.
   - Unclear: advancing silently implies "paid" and writes during reconcile.
   - Recommendation: compute in memory for scheduling (this research); if product wants the list UI to show the next real due date, add an explicit "mark paid / advance" action in a later plan.

3. **Auto Backup (`android:allowBackup`)**
   - Known: default `true`, includes the Isar DB and safety backups [Pitfall 11].
   - Unclear: whether the user wants free cloud restore (contradicts "no data may leave the device") or reinstall data loss.
   - Recommendation: set `allowBackup="false"` + exclusion rules and say so in the README/privacy text; user sign-off needed because behaviour changes.

4. **Goal off-track tolerance wording (D-06)** - percentage points (A14) or relative? Recommend percentage points; confirm.

5. **Soft-deleted rows in exports** - Recommend JSON = exact snapshot of **all** rows including `deletedAt != null` (keeps FKs intact, byte-faithful restore); CSV = user-facing active rows only. Confirm; alternative is excluding both and nulling dangling FKs.

6. **Briefing + date-only duplicates (Pitfall 7)** - accepted noise or revisit D-01/D-03 after device UAT?

7. **Temporary entry point location** - D-09 says "temporary entry point"; the task list AppBar action is the least invasive (task list is tab 0). Needs a UI decision (UI-SPEC may cover).

8. **Which "date range" the import confirmation shows** - recommend min..max of record `createdAt` across the file plus `exportedAt`; transactions' `date` range is an alternative.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | everything | yes | 3.41.4 stable, Dart 3.11.1 | - |
| JDK 17 | Android build (AGP 8.11.1, plugin requires Java 17) | yes | OpenJDK 17.0.2 | - |
| Android Gradle (AGP 8.11.1, Kotlin 2.2.20) | notification plugin 21 | yes (declared) | `settings.gradle.kts` | - |
| Flutter SDK defaults | compileSdk/minSdk/targetSdk | yes | compileSdk 36, minSdk 24, targetSdk 36 [VERIFIED: FlutterExtension.kt:23,26,34] | - |
| adb | on-device UAT | yes | platform-tools present; **no device attached this session** | reattach Infinix X6831 (Android 13) used for Phase 06 UAT |
| Isar Core binary | real-Isar import/export tests | yes | `libisar.so` at repo root (gitignored; CI pre-warms) | `flutter test -j 1 test/support/_warm_isar_core_test.dart` |
| Xcode / iOS device | iOS delivery, 64-cap, AppDelegate change | **no** (`xcodebuild` absent, Linux) | - | iOS items become human UAT / CI-less; AppDelegate edit is reviewed by inspection only |
| Network | `pub get`, Isar core download | assumed for dev; app itself is offline | - | - |

**Missing dependencies with no fallback:** an iOS build/test environment - iOS notification behaviour cannot be verified by the agent; list as `human_needed` UAT.
**Missing dependencies with fallback:** attached Android device (reattach for UAT).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (project standard); real Isar via `test/support/isar_test_harness.dart` |
| Config file | none (`analysis_options.yaml` for lints); `l10n.yaml` for ARB |
| Quick run command | `flutter test --no-pub test/domain/notifications test/data/backup` (pure + codec tests, target < 30 s) |
| Full suite command | `flutter test --no-pub` (306 passing baseline) then `flutter analyze --no-fatal-infos --fatal-warnings` and `dart run tool/check_architecture.dart` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTF-01 | due-30min; date-only -> briefing hour; past -> dropped | unit | `flutter test test/domain/notifications/task_fire_time_test.dart` | Wave 0 |
| NOTF-02 | briefing count + top 3, skip empty days, quiet-hours shift | unit | `flutter test test/domain/notifications/briefing_plan_test.dart` | Wave 0 |
| NOTF-03 | highest threshold only, once per month, fired state persists | unit (fake store) | `flutter test test/application/notifications/budget_alert_evaluator_test.dart` | Wave 0 |
| NOTF-04 | recurring item uses recurring kind + own toggle; completion swaps occurrence | unit | `flutter test test/domain/notifications/recurring_task_plan_test.dart` | Wave 0 |
| NOTF-05 | day-before 09:00, once, skip when past/paid/deleted | unit | `flutter test test/domain/notifications/debt_reminder_test.dart` | Wave 0 |
| NOTF-06 | off-track math, no-deadline never, once/week, Monday 09:00 | unit | `flutter test test/domain/notifications/goal_off_track_test.dart` | Wave 0 |
| NOTF-07 | stale nextDueDate -> effective date incl. Jan-31 clamp, paused excluded | unit | `flutter test test/domain/notifications/effective_due_date_test.dart` | Wave 0 |
| NOTF-08 | default OFF; deterministic non-repeating 7 slots; locale list | unit | `flutter test test/domain/notifications/quote_picker_test.dart` | Wave 0 |
| NOTF-09 | disabled kind never planned; cubit persists toggles | unit + bloc_test | `flutter test test/application/notifications/notification_settings_cubit_test.dart` | Wave 0 |
| NOTF-10 | boundaries (22:00 in, 07:00 out), overnight wrap, defer-not-drop | unit | `flutter test test/domain/notifications/quiet_hours_test.dart` | Wave 0 |
| NOTF-11 | manifest has boot receiver + permission; app-start reconcile re-adds missing | static + unit (fake gateway) | `flutter test test/infrastructure/notifications/manifest_contract_test.dart` ; reboot is **manual UAT** | Wave 0 |
| (cross) | ID uniqueness/int32 across grid; slot budget truncation order; diff add/cancel/replace | unit | `flutter test test/domain/notifications/{notification_id,slot_budget,schedule_diff}_test.dart` | Wave 0 |
| DATA-02 | JSON round-trip equals source for all 7 collections incl. soft-deleted, >500 rows, growable contributions | real-Isar integration | `flutter test -j 1 test/data/backup/json_roundtrip_test.dart` | Wave 0 |
| DATA-03 | CSV PT/EN decimals, `amount_cents` authority, injection neutralised, header sniff | unit | `flutter test test/data/backup/csv_codec_test.dart` | Wave 0 |
| DATA-04 | invalid file leaves DB unchanged; mid-txn failure rolls back (e.g. duplicate unique budget key); safety backup written + rotation keeps 3; counts/date range | real-Isar integration + unit | `flutter test -j 1 test/data/backup/import_atomicity_test.dart` | Wave 0 |
| (cross) | ARB parity for new notification/backup strings | existing | `flutter test test/l10n/l10n_test.dart` | exists |
| (cross) | architecture guard (150 lines, 10 files, README) | existing | `dart run tool/check_architecture.dart` | exists |

### Sampling Rate
- **Per task commit:** the quick command for the area touched (< 30 s) + `dart run tool/check_architecture.dart`.
- **Per wave merge:** `flutter test --no-pub` + `flutter analyze --no-fatal-infos --fatal-warnings` (no new infos beyond 65).
- **Phase gate:** full suite green, then device UAT checklist below, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/domain/notifications/*_test.dart` - all pure-rule tests above (inject `now`; assert on date *components*, not instants, so CI-UTC and dev timezones agree)
- [ ] `test/infrastructure/notifications/fake_notification_gateway.dart` - in-memory pending list implementing the gateway interface
- [ ] `test/data/backup/` - uses existing `IsarTestHarness`; seed helpers for 600-row collections
- [ ] `test/infrastructure/notifications/manifest_contract_test.dart` - reads `android/app/src/main/AndroidManifest.xml` and asserts `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, both receivers
- [ ] Update `test/widget_test.dart` stubs when `watchChanges()` is added to `BudgetRepository` and `RecurringPaymentRepository`
- [ ] Spike (compile-only): confirm `InitializationSettings`/`show` shapes (A15), `TimezoneInfo.identifier`, and Isar auto-increment after explicit-id `putAll` (A4)

### Device UAT checklist (not automatable; Android Infinix X6831 + iOS if available)
Reboot with pending reminders then confirm they fire; notification during quiet hours lands at window end; deny POST_NOTIFICATIONS then grant; deny exact alarm then grant and confirm mode upgrade on resume; change timezone then reopen; kill app (swipe) and confirm reminders still fire; backup export to Downloads and re-import on same device; failed import keeps data; iOS: >64 pending items.

## Security Domain

`security_enforcement` is not set in `.planning/config.json` (absent = enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (PIN is Phase 5) | - |
| V3 Session Management | no | - |
| V4 Access Control | no (single-user, on-device) | - |
| V5 Input Validation | **yes** - untrusted JSON/CSV files | Schema/type/length validation, `formatVersion` gate, FK + unique-key checks before the write txn, size cap |
| V6 Cryptography | partly - backups are plaintext | No custom crypto; document that exports are unencrypted and live where the user saves them |
| V8 Data Protection | **yes** | `NotificationVisibility.private` + no absolute amounts in lock-screen text; `allowBackup` decision (Pitfall 11) |
| V12 Files and Resources | **yes** | Never use picked file *names* to build paths; fixed app-private dir for safety backups; file-size cap before decode |
| V14 Configuration | **yes** | manifest receivers `exported="false"`; backup rules |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious/corrupt backup (wrong types, huge strings, dangling FKs, duplicate unique keys) | Tampering / DoS | Parse + validate in memory first; reject, never partially apply; length caps; single transaction |
| Oversized import file | DoS | Max size (e.g. 25-50 MB) before `jsonDecode`; `withData` only for bounded files |
| CSV/formula injection in exported CSV (task title `=HYPERLINK(...)`) | Tampering / Info disclosure | Prefix `'` on text cells beginning `= + - @ \t \r`; reverse on import |
| Sensitive text on lock screen (debts, budgets, task titles) | Information disclosure | `visibility: private`; finance bodies without amounts; generic public version where supported |
| Notification payload spoofing (payload parsed on tap) | Spoofing | Strict grammar parse; unknown kind -> open app; load entity by id and re-check existence |
| Data exfiltration via Android Auto Backup | Information disclosure | `android:allowBackup="false"` + extraction rules (user decision) |
| Safety backups accumulating private data | Information disclosure | App-private dir only, keep last 3, delete on rotation; no share intents (D-12) |
| Path traversal in picker (CWE-22) | Tampering | Keep file_picker >= 11.0.2 (fix in 11.0.2) |

## Plan Sizing Guidance (for the planner)

The five roadmap plans are sound but two boundary corrections are needed:

1. **04-01 (infra + all dependency/platform edits):** enable *all five* pubspec deps (incl. `csv`, `file_picker`) here so 04-05 cannot conflict; Gradle (`coreLibraryDesugaringEnabled`, `desugar_jdk_libs:2.1.4`, AGP already 8.11.1), manifest (permissions, two receivers, `allowBackup` decision), iOS AppDelegate delegate line; tz bootstrap; gateway interface + impl + channels + permission service; ID scheme; `NotificationPrefs` model + SharedPreferences repo + `StorageKeys` additions; pure `QuietHours` + `SlotBudget`; fake gateway for tests. Include the Wave 0 compile spike and a one-notification device smoke test.
2. **04-02 (task side + coordinator):** `ReminderPlanner` task/recurring/briefing rules, uncapped sorted DAO/repo additions, `ScheduleDiff`, `NotificationSyncCoordinator` (debounce, single-flight, resume/locale hooks), tap router + `navigatorKey`. **No Isar payload persistence** - the plugin owns boot replay.
3. **04-03 (finance):** debt, recurring payment (+`watchChanges()` + stub updates), goal weekly + on-open, budget evaluator + fired-state store, quotes lists/picker. ARB strings for every kind.
4. **04-04 (settings):** cubit + standalone page + temporary entry point + permission UX + exact-alarm banner + "N reminders waiting". Pure quiet-hours/slot logic already exists by now.
5. **04-05 (backup):** codecs, DAO, importer, safety backup, CSV, cubit + pages, post-import hooks (fired-state reseed + reconcile). Can run in parallel with 04-02..04-04 once 04-01 has landed (no shared files except `injection.config.dart` - regenerate on merge; ARB files likewise).

Per-directory budgets: the planner must pre-split files (a 7-entity codec set, the quote lists at ~50 strings each, and the planner rules each need their own files) to stay within 150 lines and 10 files per directory.

## Sources

### Primary (HIGH confidence)
- In-repo files read this session: `lib/main.dart`, `lib/app.dart`, `lib/config/di/*`, `lib/core/{config,constants,failures,utils}/*`, `lib/data/database/{isar_service,migration_runner}.dart`, all `lib/data/finance/*/*_model.dart`, `lib/data/tasks/{item_model,item_dao,item_mapper}.dart`, `lib/domain/{tasks,finance}/**`, `lib/infrastructure/{tasks,finance}/*` (selected), `lib/application/finance/{transaction,budget,recurring}`, `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`, `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `ios/Runner/{AppDelegate,SceneDelegate}.swift`, `pubspec.yaml`, `.github/workflows/ci.yml`, `tool/check_architecture.dart`, `test/support/isar_test_harness.dart`, `test/widget_test.dart`
- `isar_community-3.3.2` source in `~/.pub-cache`: `lib/src/isar.dart`, `isar_collection.dart`, `common/isar_common.dart`, `native/isar_collection_impl.dart`
- Flutter SDK `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt` (compile/min/target SDK)
- flutter_local_notifications 21.0.0 source at tag (`flutter_local_notifications.dart`, `platform_flutter_local_notifications.dart`, `helpers.dart`, `schedule_mode.dart`, `initialization_settings.dart`, `notification_details.dart`) via raw.githubusercontent.com
- https://pub.dev/packages/flutter_local_notifications/versions/21.0.0 and `/changelog`
- https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- https://developer.android.com/develop/background-work/services/alarms/schedule
- https://developer.android.com/identity/data/autobackup

### Secondary (MEDIUM confidence)
- https://pub.dev/packages/file_picker (+ `/changelog`, `/versions/11.0.2`, API pages for `saveFile`, `pickFiles`)
- https://pub.dev/packages/csv (+ `/changelog`, `/versions/8.0.0`)
- https://pub.dev/packages/timezone/versions/0.11.0
- https://pub.dev/packages/flutter_timezone (+ `/changelog`, `timezone_info/TimezoneInfo-class.html`)
- flutter_local_notifications README at tag `flutter_local_notifications-v21.0.0`

### Tertiary (LOW confidence)
- Web search results on Play Console exact-alarm policy scope and scoped-storage behaviour of `getDirectoryPath` (no authoritative Google policy page retrieved) - drives A1/A5/A6.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all pins are user decisions; signatures read from source/API pages.
- Architecture: HIGH - grounded in the actual repositories, watch streams, DAOs and guard rules.
- Pitfalls: MEDIUM - Isar/plugin mechanics verified; OEM, boot-replay and iOS-cap behaviour not testable here.
- Backup mechanics: HIGH for atomicity (source-verified), MEDIUM for file_picker mobile behaviour (A5/A6).

**Research date:** 2026-10-12
**Valid until:** 2026-11-11 (30 days; plugin/package pins are fixed, but Play policy and OS behaviour can shift)
