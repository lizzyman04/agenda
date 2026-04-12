# Pitfalls Research — AGENDA

**Domain:** Offline-first Flutter mobile app (task + finance manager)
**Researched:** 2026-04-12
**Overall confidence:** HIGH (most findings verified against official docs and GitHub issues)

---

## 1. Isar Database

### Pitfall: Enum Ordinal Strategy Causes Silent Data Corruption
**Severity:** CRITICAL

**What goes wrong:** Isar's default `@enumerated` strategy stores enums by ordinal position (index). If you reorder, insert, or remove values from any Dart enum after the database has live data, all existing records silently return wrong values. A production team discovered 50+ instances across their codebase; fixing it required migrating every affected user's database.

**Warning signs:**
- You have enums like `TaskPriority`, `RecurrenceType`, `TransactionCategory`, `QuadrantType` stored in Isar collections.
- A new enum value is inserted in the middle of an existing list (e.g., adding `medium` between `low` and `high`).
- Queries filter by enum value and return unexpected results after an app update.

**Prevention:**
- Always annotate enums with `@enumerated(EnumType.name)` — stores the string name, not the ordinal index, so reordering is safe.
- Establish a project-wide convention: every Isar-persisted enum gets `EnumType.name`. Enforce in code review.
- Never rely on `EnumType.ordinal` or `EnumType.ordinal32` unless the enum is guaranteed append-only forever.

**Phase to address:** Phase 1 (schema design). This must be decided before the first collection is written. Retrofitting after data exists requires a migration on every user device.

---

### Pitfall: No Built-in Schema Versioning or Data Migration
**Severity:** CRITICAL

**What goes wrong:** Isar automatically handles structural changes (adding/removing fields, indexes) but provides zero built-in data migration. When you add a computed field (e.g., `totalSpent` derived from transaction records), existing rows remain `null` until explicitly backfilled. There is no migration runner; developers must manually detect schema version and execute custom logic.

**Warning signs:**
- An app update adds a field that must be populated from existing data.
- New mandatory field appears null/zero on records created before the update.
- No `schemaVersion` value tracked anywhere in the codebase.

**Prevention:**
- Store a `schemaVersion` integer in `SharedPreferences` at app startup.
- On open, compare stored version to target version; run conditional migration blocks in sequence.
- Paginate through large collections during migration (avoid loading all records into memory at once).
- Run migrations in a background isolate to avoid UI freezes on large datasets.
- Document each migration step in a `MIGRATIONS.md` or inline comments with version numbers.

**Phase to address:** Phase 1 (core data layer). Migration infrastructure should be in place before any schema is finalized.

---

### Pitfall: Synchronous Isar Calls on the UI Thread
**Severity:** HIGH

**What goes wrong:** Isar provides both sync and async APIs. Sync reads/writes block the calling thread. If called from the main isolate (which drives the UI), any non-trivial query causes jank or ANR on Android.

**Warning signs:**
- Using `isar.collection.getSync()`, `putSync()`, or `where().findAllSync()` in widget build methods, BLoC event handlers, or use cases.
- Frame render times spike when lists are scrolled or filters are changed.

**Prevention:**
- Use only `async` Isar APIs (`findAll()`, `put()`, `delete()`) in application code.
- Restrict synchronous calls exclusively to background isolates where they are safe.
- Treat sync Isar APIs as forbidden in the main isolate — enforce via linting or code review checklist.

**Phase to address:** Phase 1 (repository layer). Establish the pattern in the first repository before other features copy it.

---

### Pitfall: Isar Inspector Fails When Database Runs in Isolate
**Severity:** MEDIUM

**What goes wrong:** The Isar Inspector (browser-based debug tool) cannot connect when Isar is opened inside a background isolate. This silently prevents debugging during development even though the database itself works correctly.

**Warning signs:**
- You moved database operations to an isolate for performance.
- Inspector shows "Cannot connect" at the debug URL.

**Prevention:**
- During development, open Isar on the main isolate for debugging; move to isolate only after schema is stable.
- Use Isar's query builder and `.explain()` for performance profiling as an alternative to the Inspector.
- Document this limitation so future contributors don't waste time troubleshooting the inspector.

**Phase to address:** Phase 1. Set up development workflow decision early.

---

### Pitfall: Missing Index on Frequently Queried Fields
**Severity:** HIGH

**What goes wrong:** Isar stores documents without relational indexes by default. Queries against unindexed fields perform full collection scans. For a task manager with hundreds of tasks or a finance app with thousands of transactions, unindexed queries on `dueDate`, `categoryId`, or `isCompleted` degrade to O(n) reads.

**Warning signs:**
- Filter queries slow down noticeably as the collection grows past ~500 records.
- Reactive watchers on filtered queries trigger excessive rebuilds.

**Prevention:**
- Add `@Index()` to fields used in `.filter()` chains: `dueDate`, `isCompleted`, `categoryId`, `recurrenceType`, `quadrant`.
- Use composite indexes for multi-field queries (e.g., `isCompleted + dueDate` for "pending tasks due today").
- Run `.explain()` during development to verify index hits.

**Phase to address:** Phase 1 (schema definition). Indexes must be declared in the schema, not added as an afterthought.

---

## 2. flutter_local_notifications

### Pitfall: SCHEDULE_EXACT_ALARM Denied by Default on Android 12+
**Severity:** CRITICAL

**What goes wrong:** Starting with Android 14 (API 34), `SCHEDULE_EXACT_ALARM` is denied by default for newly installed apps targeting Android 13+. Calling `zonedSchedule()` without the permission throws an `ExactAlarmPermissionException` at runtime and crashes silently in some builds. Task reminders and debt due-date alerts that rely on exact timing will fail for most users.

**Warning signs:**
- Scheduled notifications work in the emulator but not on physical Android 12+ devices.
- No notification fires at the expected time in a production release.
- Logcat shows `ExactAlarmPermissionException` or similar alarm manager errors.

**Prevention:**
- Declare `USE_EXACT_ALARM` in `AndroidManifest.xml` if targeting a single-purpose alarm-type app (subject to Play Store review). This requires no user prompt but requires policy justification.
- Alternatively, use `SCHEDULE_EXACT_ALARM` and call `requestExactAlarmsPermission()` at runtime, with an explanation screen.
- Provide graceful fallback: if exact alarm permission is denied, fall back to `androidScheduleMode: AndroidScheduleMode.inexact` and inform the user that notifications may arrive a few minutes late.
- Test on a clean Android 14 install, not just emulator, before each release.

**Phase to address:** Phase 2 (notifications feature). Must be addressed before any notification is shipped, not as a post-launch fix.

---

### Pitfall: Scheduled Notifications Lost After Device Reboot
**Severity:** CRITICAL

**What goes wrong:** Android's `AlarmManager` does not survive device reboot. All scheduled notifications (task reminders, recurring payments, morning briefing) are wiped when the device restarts. Without the `ScheduledNotificationBootReceiver` correctly declared, users who reboot their phones receive zero notifications until they open the app.

**Warning signs:**
- Notifications work perfectly until a reboot, then stop firing.
- Users report "notifications stopped working" after phone updates.
- `RECEIVE_BOOT_COMPLETED` permission is absent from `AndroidManifest.xml`.

**Prevention:**
- Declare `RECEIVE_BOOT_COMPLETED` permission in `AndroidManifest.xml`.
- Register both `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` as receivers in the manifest — since plugin v16, these are NOT automatically included.
- Persist all scheduled notification payloads (id, scheduled time, type, payload) to Isar so the boot receiver can reschedule them without requiring user interaction.
- Test by scheduling a notification, rebooting the device, and waiting for the trigger time.

**Phase to address:** Phase 2 (notifications feature). Cannot be deferred; it is a fundamental reliability requirement.

---

### Pitfall: OEM Battery Optimization Kills Background Alarms
**Severity:** HIGH

**What goes wrong:** Samsung, Xiaomi, Huawei, Oppo, and other OEM Android skins aggressively kill background processes and restrict alarm delivery. Notifications scheduled for later that day may never fire even with correct permissions. This is an OS-level restriction outside the plugin's control.

**Warning signs:**
- Notifications work on stock Android (Pixel) but not on Samsung/Xiaomi devices.
- Users on "brand X" consistently report missed reminders.
- `zonedSchedule()` works in foreground but fails after the app is swiped away on real devices.

**Prevention:**
- Prompt the user to disable battery optimization for the app on first launch (direct them to Settings > Battery > Unrestricted for the app).
- Use `requestExactAlarmsPermission()` proactively.
- Document this as a known limitation in app onboarding; don't promise 100% notification delivery across all Android variants.
- Test on at least one Samsung device before each release.

**Phase to address:** Phase 2 (notifications feature). Add the battery optimization prompt to the onboarding flow.

---

### Pitfall: Samsung 500-Alarm Hard Limit
**Severity:** HIGH

**What goes wrong:** Samsung's Android implementation caps `AlarmManager` at 500 simultaneous alarms. AGENDA schedules multiple notification types: task reminders, recurring task reminders, debt due-date alerts, budget alerts, recurring payment reminders, morning briefing, motivational quotes. With many active tasks and recurring schedules, it is possible to approach or exceed 500 alarms on Samsung devices, causing `SecurityException` crashes.

**Warning signs:**
- App crashes on Samsung devices after heavy use.
- Exception logs mention `AlarmManager` or alarm quota.
- Users with many recurring tasks report sudden notification failures.

**Prevention:**
- Implement a notification budget: schedule only the next N occurrences of recurring notifications (e.g., next 30 days) rather than scheduling every future occurrence.
- Deduplicate: cancel old alarms before rescheduling updated ones. The plugin does not auto-detect duplicates by ID.
- Track scheduled alarm count in Isar; warn internally if approaching 400.
- Prefer daily/weekly recurring alarms (which use `RepeatInterval`) over individually scheduled repeats where possible.

**Phase to address:** Phase 2 (notifications feature) and Phase 3 (recurring features). Must architect the scheduling strategy early.

---

### Pitfall: iOS Hard Limit of 64 Pending Notifications
**Severity:** HIGH

**What goes wrong:** iOS allows at most 64 pending local notifications system-wide. AGENDA's full notification suite (morning briefing + motivational quotes + task reminders + debt alerts + budget alerts + recurring payment reminders) can easily exceed 64 notifications for a power user with many active items. The OS silently drops notifications beyond 64.

**Warning signs:**
- Users with many tasks report missing reminders on iOS.
- No error is thrown; notifications simply don't appear.

**Prevention:**
- Prioritize notification scheduling: task due-date reminders take priority over motivational quotes.
- Implement a scheduling queue that re-evaluates and re-schedules the highest-priority 64 notifications on every app open.
- Cancel and re-schedule on app foreground to ensure the current 64-slot budget is filled with the most relevant notifications.
- Accept that motivational quotes may be dropped under heavy load; this is acceptable degradation.

**Phase to address:** Phase 2 (notifications feature). Design the scheduling strategy around this constraint from the start.

---

### Pitfall: Missing timezone Package Initialization Breaks Scheduled Notifications
**Severity:** HIGH

**What goes wrong:** `zonedSchedule()` requires the `timezone` package to be initialized with `tz.initializeTimeZones()` before any scheduling call. If initialization is skipped or happens after the first schedule call, all zoned notifications fail silently or throw cryptic errors. The user's local timezone must also be set explicitly.

**Warning signs:**
- Notifications fire at wrong times (timezone offset errors).
- `BadStateException` or silent failures from `zonedSchedule()`.
- Works in development but fails in production after timezone initialization is accidentally removed.

**Prevention:**
- Call `tz.initializeTimeZones()` in `main()` before `runApp()` and before any notification scheduling.
- Set `tz.setLocalLocation()` using the device's current timezone.
- Add an integration test that schedules a notification and verifies the scheduled time matches the expected local time.

**Phase to address:** Phase 2 (notifications setup). First thing wired up before any scheduling logic is written.

---

## 3. BLoC / Cubit in Clean Architecture

### Pitfall: Logic Leaking Into the Presentation Layer
**Severity:** HIGH

**What goes wrong:** Developers place business logic directly in BLoC event handlers rather than delegating to use cases. The BLoC starts calling repositories directly, performing calculations, or applying domain rules. This violates the dependency rule — the application layer knows about data layer details — and makes unit testing impossible without mocking the entire data layer in every BLoC test.

**Warning signs:**
- BLoC constructors receive `IsarCollection` or repository implementations (not interfaces).
- BLoC event handlers contain `if/else` chains implementing domain rules (e.g., "is a task overdue?").
- Tests for BLoC require setting up Isar or mocking file I/O.

**Prevention:**
- BLoCs and Cubits receive only use case interfaces (domain layer abstractions), never repositories or data sources directly.
- All domain rules live in use cases or domain entities. The BLoC only orchestrates: call use case, map result to state, emit.
- Use case interfaces live in `domain/`, implementations in `application/`. BLoCs live in `presentation/` or `application/` — decide and standardize.

**Phase to address:** Phase 1 (architecture setup). Establish the layer contract before writing the first feature BLoC.

---

### Pitfall: Bloc-to-Bloc Direct Communication
**Severity:** HIGH

**What goes wrong:** When one BLoC directly holds a reference to another BLoC and calls methods or listens to its stream, sibling dependencies form in the same layer. This creates tight coupling, makes testing harder, and makes the event flow opaque. Example: `FinanceBLoC` directly calling `NotificationBLoC.scheduleAlert()` when a budget is exceeded.

**Warning signs:**
- A BLoC constructor receives another BLoC as a parameter.
- One BLoC's `on<Event>` handler adds events to a different BLoC.
- BLoC tests require instantiating multiple BLoCs in sequence.

**Prevention:**
- The official `flutter_bloc` recommendation: push cross-BLoC communication to the presentation layer using `BlocListener`. Widget listens to BLoC A state, then dispatches an event to BLoC B.
- For non-UI coordination (e.g., "budget exceeded → schedule notification"), use a domain event bus or a coordinator use case that both BLoCs call independently.
- Prefer reactive use cases that return `Stream` results; multiple BLoCs can listen to the same domain stream without knowing about each other.

**Phase to address:** Phase 1 (architecture). Document the coordination pattern before two features need to talk to each other.

---

### Pitfall: "Cannot Emit After Close" Runtime Crash
**Severity:** HIGH

**What goes wrong:** User navigates away from a screen while an async operation (database write, file export) is in progress. The screen's BLoC is disposed. When the async operation completes and calls `emit()`, it throws `Bad state: Cannot emit new states after calling close`. This is among the most common BLoC runtime errors in production.

**Warning signs:**
- `Bad state: Cannot emit new states after calling close` in crash logs.
- Triggered by rapid navigation during async operations.
- Appears during backup/restore or slow Isar transactions.

**Prevention:**
- Check `isClosed` before every `emit()` in async handlers: `if (!isClosed) emit(state)`.
- Prefer wrapping long async operations in `try/catch/finally` blocks that check `isClosed`.
- For operations that must complete regardless of navigation (e.g., backup write), move them to a use case that runs independently and does not emit BLoC state after completion.

**Phase to address:** All phases with async BLoC operations. Establish the pattern in Phase 1; apply consistently.

---

### Pitfall: Emitting Identical State Does Not Trigger Rebuild
**Severity:** MEDIUM

**What goes wrong:** `flutter_bloc` uses `==` equality to determine if a new state differs from the current one. If a state class uses default `Object` equality (reference equality) and you emit the same logical state with updated list contents but the same object reference, no rebuild is triggered. Conversely, if `Equatable` is misconfigured (props list incomplete), state changes are swallowed.

**Warning signs:**
- Modifying a list inside a Cubit state and re-emitting it causes no UI update.
- Adding a new task does not cause the task list widget to rebuild.
- `copyWith()` returns the same object reference.

**Prevention:**
- Use `Equatable` (or `sealed` classes with full `==` implementation) for all state classes.
- Always emit a new state object: `emit(state.copyWith(tasks: [...state.tasks, newTask]))`.
- For list updates, spread into a new list rather than mutating in place.
- Add BLoC unit tests that assert on emitted state sequence, not just the final state.

**Phase to address:** Phase 1 (state modeling). Establish `Equatable` convention before first BLoC is written.

---

## 4. Backup / Restore Reliability

### Pitfall: No Schema Version in Export File
**Severity:** CRITICAL

**What goes wrong:** A backup JSON/CSV file written by app version 1.0 is imported by app version 2.0. The schema has changed (new required fields, renamed keys, removed fields). The importer either crashes, silently drops data, or produces corrupted records. The user has overwritten their current data with a broken import.

**Warning signs:**
- Import silently completes but records are missing or have null values.
- `JsonUnsupportedObjectError` or type cast failures in import logs.
- No `"schemaVersion"` or `"appVersion"` key in the exported file.

**Prevention:**
- Always include a top-level `"schemaVersion": N` in every JSON export.
- On import, read schema version first and run a version-specific parser/transformer before inserting into Isar.
- Maintain a registry of schema transformers: `v1_to_v2_transformer.dart`, `v2_to_v3_transformer.dart`, etc.
- For CSV: include a header row with `schema_version` as a metadata comment or first row convention.

**Phase to address:** Phase 2 (backup feature). Establish the versioned format before the first backup file is ever exported to a user's device. Retro-adding versioning after users have backup files is painful.

---

### Pitfall: Partial Import Leaves Database in Inconsistent State
**Severity:** CRITICAL

**What goes wrong:** Importing a large JSON backup fails midway (malformed JSON at record 847, disk full, app backgrounded by OS). The import has already written 846 records into Isar. The database now contains partial data mixed with original data. There is no way to roll back.

**Warning signs:**
- Import progress bar stops mid-operation and the app shows an error.
- After a failed import, some records exist twice or in a hybrid state.
- No transactional import logic in the codebase.

**Prevention:**
- Wrap the entire import operation in a single Isar write transaction: if anything fails, the whole transaction rolls back atomically.
- Validate the entire JSON/CSV file before writing a single record: check structure, required fields, type compatibility.
- Offer the user a choice before import: "This will replace all current data. Continue?" with a clear warning — do not silently merge.
- Consider writing to a temporary Isar instance first, then swapping if successful.

**Phase to address:** Phase 2 (backup feature). Atomic import is a correctness requirement, not an enhancement.

---

### Pitfall: CSV Type Coercion Corrupts Numeric and Boolean Fields
**Severity:** HIGH

**What goes wrong:** The `csv` Dart package automatically converts strings that look like numbers into `int` or `double` during parsing. A field like `"id": "0012345"` becomes `int 12345`, stripping leading zeros. Boolean fields stored as `"true"/"false"` may be misread. Amount fields with comma decimal separators (Brazilian locale: `"1.234,56"`) are parsed incorrectly when the parser expects period decimal format.

**Warning signs:**
- IDs change after CSV round-trip.
- Amount values are wrong after import on PT-BR locale devices.
- Boolean fields (`isCompleted`, `isRecurring`) become integers (0/1) after import.

**Prevention:**
- Quote all string fields explicitly in CSV export; configure the CSV converter to treat all fields as strings by default.
- Parse amounts as strings during CSV import, then explicitly convert with locale-aware parsing (`NumberFormat` with explicit locale, not device locale).
- Write round-trip tests: export a known dataset to CSV, import it back, assert byte-for-byte field equality.

**Phase to address:** Phase 2 (backup feature). Add round-trip tests immediately when the feature is written.

---

### Pitfall: Import Overwrites Data Without User Confirmation
**Severity:** HIGH

**What goes wrong:** Restore flow imports and merges data without a clear warning that existing records will be affected. User accidentally imports an old backup and loses recent entries. The "Import" button behavior (replace all vs. merge) is not clearly communicated.

**Warning signs:**
- No confirmation dialog before import begins.
- Import silently merges on ID conflict without informing the user.
- Post-import data inconsistencies are only discovered days later.

**Prevention:**
- Show a pre-import summary: file name, schema version, record counts per type, and date range.
- Always ask for explicit confirmation with clear language: "This will DELETE all current data and replace it with the backup. This action cannot be undone."
- Export a backup automatically before any import begins (a safety copy).

**Phase to address:** Phase 2 (backup feature). UX contract before implementation.

---

## 5. App Lock / PIN

### Pitfall: iOS Inactive-State-Only Backgrounding Bypasses Lock
**Severity:** HIGH

**What goes wrong:** Flutter lifecycle on iOS behaves differently from Android when the user enters the App Switcher. On iOS, the app only transitions to `inactive` (not `paused`) when viewing the App Switcher. If lock logic only activates on `paused`, the app remains unlocked while visible in the App Switcher — exposing content in the thumbnail preview.

**Warning signs:**
- Lock screen does not appear when user double-presses home button to view App Switcher on iOS.
- App content visible in iOS App Switcher screenshot.
- Lock logic uses only `AppLifecycleState.paused` as the trigger.

**Prevention:**
- Respond to `AppLifecycleState.inactive` by immediately overlaying a privacy screen (blank or logo screen).
- Trigger the actual lock/PIN prompt on `AppLifecycleState.paused` (or on `resumed` if using a timer-based lock).
- Use `WidgetsBindingObserver` and handle both `inactive` and `paused` states in the lock state machine.
- On `resumed`, check elapsed time since backgrounding; show PIN if it exceeds the user's configured timeout.

**Phase to address:** Phase 3 (app lock feature). This edge case must be tested on a real iOS device, not a simulator.

---

### Pitfall: Lock State Lost on Process Kill and Cold Start
**Severity:** HIGH

**What goes wrong:** The app is killed by the OS while locked (low memory). On the next cold start, the app skips the PIN screen because the in-memory lock state was never persisted — the lock state machine starts as "unlocked." The user's data is exposed without authentication.

**Warning signs:**
- Lock screen does not appear after force-stopping the app.
- App opens directly to the home screen after being killed by the OS.
- Lock state is held only in a BLoC/Cubit with no persistence.

**Prevention:**
- Persist a `lastBackgroundedAt` timestamp in `SharedPreferences` (not Isar, which may take time to open).
- On every cold start (`main()`), read `lastBackgroundedAt` and compare to current time against the configured lock timeout before initializing the main app widget.
- Default behavior on cold start: always show PIN if a PIN is configured, regardless of time elapsed.

**Phase to address:** Phase 3 (app lock feature).

---

### Pitfall: Biometric Auth Cancelled by OS on Incoming Call
**Severity:** MEDIUM

**What goes wrong:** `local_auth`'s biometric prompt is dismissed by the system when the user receives a phone call. If the app does not retry after the call ends, the user is stuck on the lock screen with no way to proceed without relaunching the app.

**Warning signs:**
- Users report getting locked out after receiving a call while authenticating.
- Biometric prompt returns `LAErrorUserCancel` or `BiometricException.userCanceled` after a call.

**Prevention:**
- Set `persistAcrossBackgrounding: true` in the `local_auth` options so the prompt retries when the app is foregrounded after the interruption.
- Always provide a PIN/password fallback that can be used if biometric fails for any reason.
- Catch `PlatformException` from `local_auth` and re-present the auth screen rather than leaving the user on a dead state.

**Phase to address:** Phase 3 (app lock feature).

---

### Pitfall: `local_auth` Requires `FlutterFragmentActivity` on Android
**Severity:** HIGH

**What goes wrong:** `local_auth` requires `MainActivity` to extend `FlutterFragmentActivity` instead of the default `FlutterActivity`. If this is not changed, biometric authentication dialogs fail to display on Android with a silent crash or blank dialog.

**Warning signs:**
- Biometric prompt appears briefly then immediately dismisses on Android.
- `PlatformException: Activity is null` in logcat.
- Works on iOS but not Android.

**Prevention:**
- Change `MainActivity.kt` to `extends FlutterFragmentActivity` before implementing any auth logic.
- Document this as a setup requirement in the architecture notes.

**Phase to address:** Phase 3 (app lock feature). Change `MainActivity` before writing any `local_auth` code.

---

## 6. Notification Scheduling at Scale

### Pitfall: Orphaned Notifications After Task Deletion or Reschedule
**Severity:** HIGH

**What goes wrong:** User deletes a task or changes its due date. The original notification is not cancelled. At the original time, a reminder fires for a task that no longer exists or has a different time. The notification's tap action leads to a 404/null state in the app.

**Warning signs:**
- Tapping a notification crashes the app or opens a blank task detail screen.
- Notifications fire for deleted tasks.
- No `cancelNotification(id)` call in the task deletion use case.

**Prevention:**
- Each task's notification ID must be deterministic and derived from the task ID (e.g., `taskId * 10 + notificationType`). This enables targeted cancellation without needing a separate notification registry.
- Call `cancelNotification(derivedId)` in every task deletion use case.
- On task due-date update: cancel existing notification, schedule new one.
- Persist notification ID mappings to Isar for audit and cleanup.

**Phase to address:** Phase 2 (notifications). Establish the ID derivation strategy before any notification is scheduled.

---

### Pitfall: Duplicate Notifications on App Reinstall or Update
**Severity:** MEDIUM

**What goes wrong:** On Android, `ScheduledNotificationBootReceiver` fires on app update (BOOT_COMPLETED can be triggered by update events on some OEMs). If the app reschedules all notifications on boot without first cancelling existing ones, duplicates accumulate in the `AlarmManager` queue. The user receives double (or triple) notifications for the same event.

**Warning signs:**
- Users report duplicate notifications after app updates.
- AlarmManager alarm count grows unexpectedly over time.

**Prevention:**
- Before rescheduling on boot/update, call `cancelAllNotifications()` first, then re-schedule from Isar data.
- Implement idempotent scheduling: check if a notification with the given ID is already scheduled before adding a new one.

**Phase to address:** Phase 2 (notifications). Test the update scenario explicitly before releasing.

---

### Pitfall: Notification Tap Payload Lost When App is Terminated
**Severity:** MEDIUM

**What goes wrong:** User taps a notification while the app is fully closed. Flutter's cold start from a notification tap must read the launch payload and navigate to the correct screen (e.g., the specific task or debt). If `getNotificationAppLaunchDetails()` is not called at startup, the payload is lost and the user lands on the home screen with no context.

**Warning signs:**
- Tapping a notification opens the app at the home screen, not the relevant item.
- Notification tap payload is only handled in the `onDidReceiveNotificationResponse` callback, which is never called on cold launch.

**Prevention:**
- At app startup, call `flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails()` and check `didNotificationLaunchApp`.
- If `true`, parse the payload and navigate to the relevant screen after the app initializes.
- Use a consistent payload format (JSON string with `type` + `entityId`) to determine navigation target.

**Phase to address:** Phase 2 (notifications). Handle both foreground and cold-launch tap routing together.

---

## 7. Internationalization (i18n / l10n)

### Pitfall: Hardcoded Strings in Business Logic and Data Layer
**Severity:** HIGH

**What goes wrong:** Error messages, category names, and status labels are hardcoded as English strings in use cases, repositories, or domain entities. These strings are returned to the UI and displayed directly, bypassing the localization system. Portuguese users see English error messages.

**Warning signs:**
- `throw Exception("Task not found")` in domain layer code that bubbles to the UI.
- Category names like `"Food"` stored in Isar and displayed without translation.
- Use case returning `"Success"` strings to BLoC state.

**Prevention:**
- Domain layer returns typed error objects (sealed classes or enums), never string messages.
- UI layer maps error types to localized strings via `AppLocalizations`.
- Category names stored in Isar as enum values (translated on display) or as localization keys.
- Establish a rule: no `String` literals in `domain/` or `data/` that will reach the UI.

**Phase to address:** Phase 1 (architecture). The error type pattern must be established before any use case is written.

---

### Pitfall: Missing `supportedLocales` Entry Prevents Locale Switching
**Severity:** HIGH

**What goes wrong:** The app's `MaterialApp.supportedLocales` does not include `Locale('pt', 'BR')` or uses `Locale('pt')` without the country code. Flutter only rebuilds the widget tree in response to locale changes for locales in `supportedLocales`. The PT-BR toggle appears to work but strings fall back to EN silently.

**Warning signs:**
- Language toggle has no visible effect on strings.
- `AppLocalizations.of(context)` returns English strings regardless of selected locale.
- `flutter gen-l10n` generates files but locale switching doesn't trigger rebuild.

**Prevention:**
- Declare `supportedLocales: [Locale('en'), Locale('pt', 'BR')]` explicitly in `MaterialApp`.
- Set `localizationsDelegates` to include `AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`.
- Test locale switching in integration tests: toggle language, assert a known string changes.

**Phase to address:** Phase 1 (app scaffold). Set up l10n correctly during the initial Flutter project setup before any UI strings are written.

---

### Pitfall: Missing or Inconsistent ARB Keys Between Locales
**Severity:** MEDIUM

**What goes wrong:** `app_pt.arb` is missing a key that exists in `app_en.arb`. At runtime, Flutter falls back to the template locale (EN) silently, so PT-BR users see English strings for that feature. This is not caught at compile time without additional tooling.

**Warning signs:**
- A specific string always appears in English even when PT-BR is selected.
- No CI check comparing ARB key sets between locale files.
- ARB files diverge as new features are added and the developer forgets to add the PT-BR translation.

**Prevention:**
- Add a lint/test step that compares ARB key sets: fail if any key exists in EN but not PT-BR.
- When adding a new string, add both locale entries in the same commit.
- Use `flutter_localizations` tooling (`flutter gen-l10n`) with `--required-resource-attributes` to catch missing translations at generation time.

**Phase to address:** Phase 1 (l10n setup). Add ARB key parity check to the development workflow immediately.

---

### Pitfall: Number and Date Formatting Uses Device Locale Instead of Selected Locale
**Severity:** MEDIUM

**What goes wrong:** The app allows the user to switch to EN, but amount formatting (`NumberFormat.currency`) and date display (`DateFormat`) pick up the device's system locale (PT-BR) rather than the app's selected locale. A user who switched to EN sees dates like `12/04/2026` (day/month/year) instead of `04/12/2026` (month/day/year), and currency as `R$ 1.234,56` instead of `$ 1,234.56`.

**Warning signs:**
- Date and number formats do not change when language toggle is switched.
- `DateFormat.yMd()` called without explicit locale argument.
- `NumberFormat.currency()` using `Intl.defaultLocale` which tracks device locale.

**Prevention:**
- Always pass the app's currently selected locale explicitly to `DateFormat` and `NumberFormat`: `DateFormat.yMd(selectedLocale.toString())`.
- Store selected locale in a global `AppLocale` service accessible across the app.
- Never rely on `Intl.defaultLocale`; always be explicit.

**Phase to address:** Phase 1 (l10n setup) and reinforced in every feature that formats dates/amounts.

---

## 8. Performance: Large Collections, Rendering, Memory Leaks

### Pitfall: Isar QueryBuilder Native Memory Leak
**Severity:** HIGH

**What goes wrong:** There is a documented GitHub issue in Isar where `QueryBuilder` exhibits native memory leaks — `isar_qb_build` allocations with zero deallocations in certain usage patterns. In AGENDA, reactive queries that rebuild query objects on every state change (e.g., a filtered task list that re-queries on every keystroke in a search field) can accumulate native memory until the process is killed by the OS.

**Warning signs:**
- Memory profile shows steadily growing native heap over time.
- App is killed by Android's low-memory killer after extended use.
- Query objects are created inside `StreamBuilder` or `BlocBuilder` build methods.

**Prevention:**
- Create `QueryBuilder` instances once and store them; avoid rebuilding query objects inside widget build methods.
- Cache frequently used queries as class-level fields in repositories.
- Monitor memory with Flutter DevTools during development; look for native allocations that don't return to baseline.
- Consider batching reactive query refreshes (debounce) rather than re-querying on every character typed in a filter.

**Phase to address:** Phase 1 (repository layer). Establish query caching pattern in the first repository.

---

### Pitfall: Isar Watcher StreamSubscription Never Cancelled
**Severity:** HIGH

**What goes wrong:** Isar's `watchLazy()` and `watch()` return `Stream`s. If a widget or BLoC subscribes to these streams and never calls `cancel()` on the `StreamSubscription`, the subscription continues to fire even after the widget is disposed. In AGENDA, where reactive Isar streams drive task lists, finance summaries, and notification triggers, uncancelled subscriptions cause memory accumulation, spurious state emissions, and potential crashes as they try to interact with disposed widgets.

**Warning signs:**
- Memory grows during navigation (new screens accumulate subscriptions).
- State emissions occur for screens that are no longer in the navigator stack.
- `setState() called after dispose()` errors in logs.

**Prevention:**
- Store every `StreamSubscription` as a class field. In `State.dispose()` or `Cubit.close()`, call `subscription.cancel()`.
- In BLoCs, cancel Isar subscriptions in the overridden `close()` method.
- Prefer `StreamBuilder` (handles subscription lifecycle automatically) over manual subscriptions in widgets.
- Use Flutter DevTools Memory tab to verify subscriptions are cancelled on screen pop.

**Phase to address:** All phases. Establish the dispose pattern in Phase 1 and enforce in every feature.

---

### Pitfall: Rendering Large Lists Without Virtualization
**Severity:** HIGH

**What goes wrong:** Using `Column` + `children: tasks.map(...)` or `ListView` (non-builder) to render all tasks, transactions, or notification history at once causes enormous widget tree builds. With 500+ tasks or 1000+ transactions, the initial render takes hundreds of milliseconds and causes jank during navigation.

**Warning signs:**
- Frame times spike on screens with many items.
- Slow animations entering a screen with a long list.
- `ListView` constructed with a full list instead of `ListView.builder`.

**Prevention:**
- Always use `ListView.builder`, `SliverList.builder`, or `CustomScrollView` with slivers — never construct a full list widget upfront.
- Apply pagination or load-more at 50-100 items per page for transaction history and task archives.
- Use Isar's `.offset()` and `.limit()` for paginated queries instead of loading all records into memory.

**Phase to address:** All phases that include list screens. Enforce in Phase 1 as a rendering convention.

---

### Pitfall: BLoC Not Disposed Causes Memory Leak in GetIt Registration
**Severity:** MEDIUM

**What goes wrong:** BLoCs registered with GetIt as singletons persist for the app lifetime. For feature-scoped BLoCs (e.g., `TaskDetailCubit`, `AddTransactionCubit`), singleton registration means the BLoC and its held data live forever in memory even after the screen is gone. With GetIt, `registerFactory` (new instance per resolution) is correct for screen-scoped BLoCs; `registerSingleton` is correct only for app-wide state.

**Warning signs:**
- Memory does not decrease after navigating away from heavy screens.
- `GetIt` registered BLoC holds a list of thousands of records after the screen that loaded them is no longer visible.
- All BLoCs registered as `registerSingleton` regardless of scope.

**Prevention:**
- Use `registerFactory<TaskDetailCubit>()` for screen-scoped BLoCs (new instance per navigation).
- Use `registerSingleton<AppSettingsCubit>()` only for truly global state.
- Provide BLoCs via `BlocProvider` with `create:` in the widget tree for screen-scoped cases; this ensures automatic `close()` on widget disposal.
- Audit GetIt registrations at the end of each phase.

**Phase to address:** Phase 1 (DI setup). Registration strategy must be decided before features are built.

---

### Pitfall: Image and Heavy Widget Rebuilds in Finance Dashboard
**Severity:** MEDIUM

**What goes wrong:** Finance dashboards with charts (e.g., budget pie charts, expense trend lines) re-render their entire widget tree on every BLoC state change, even when only an unrelated part of the state changed (e.g., a new transaction added triggers a full dashboard rebuild including chart recalculation). Heavy chart widgets are expensive to rebuild.

**Warning signs:**
- Frame drops when adding a transaction while the dashboard is open.
- Charts flicker on every state emission.
- `BlocBuilder` wraps an entire screen including chart widgets.

**Prevention:**
- Use narrow `BlocBuilder` scopes: only wrap the widget that actually changes, not entire screens.
- Use `buildWhen:` in `BlocBuilder` to filter rebuild triggers: `buildWhen: (prev, curr) => prev.totalExpenses != curr.totalExpenses`.
- Cache chart data computations in the BLoC state so the chart widget only rebuilds when its specific data changes.
- Use `const` widgets for static UI sections to short-circuit the widget comparison.

**Phase to address:** Phase 2 onwards (finance screens). Apply `buildWhen` from the first chart widget.

---

## Phase-Specific Warning Summary

| Phase Topic | Most Likely Pitfall | Mitigation |
|---|---|---|
| Phase 1 — Schema design | Enum ordinal corruption | Use `EnumType.name` on every Isar enum |
| Phase 1 — Architecture | Logic in BLoC instead of use cases | Strict layer contract; BLoC only calls use case interfaces |
| Phase 1 — DI setup | Wrong GetIt scope (singleton vs factory) | Decide scope per BLoC before registering |
| Phase 1 — l10n setup | `supportedLocales` misconfiguration | Configure `MaterialApp` with both locales before first string |
| Phase 2 — Notifications | Exact alarm permission on Android 12+ | Handle `SCHEDULE_EXACT_ALARM` with fallback to inexact |
| Phase 2 — Notifications | Notifications lost on reboot | Boot receiver + notification persistence in Isar |
| Phase 2 — Backup | No schema version in export | Embed `schemaVersion` in every export before first user backup |
| Phase 2 — Backup | Partial import corruption | Wrap import in Isar transaction; validate before writing |
| Phase 3 — App lock | iOS inactive state bypasses lock | Handle `inactive` + `paused` lifecycle states |
| Phase 3 — App lock | `local_auth` needs `FlutterFragmentActivity` | Change `MainActivity.kt` before writing any auth code |
| Phase 3 onwards — Scale | Samsung 500-alarm limit | Notification budget: schedule rolling 30-day window only |
| Phase 3 onwards — Scale | iOS 64-notification limit | Priority queue; re-schedule on every app foreground |
| All phases | Isar watcher subscription leak | Cancel subscriptions in `dispose()` / `close()` — always |

---

## Sources

- Isar schema & migration docs: https://isar.dev/recipes/data_migration.html
- Isar schema docs: https://isar.dev/schema.html
- Enum ordinal corruption analysis (Saropa Contacts): https://saropa-contacts.medium.com/isar-enumerated-annotations-data-corruption-trap-671190414fcf
- Isar QueryBuilder memory leak issue: https://github.com/isar/isar/issues/1641
- Isar isolate inspector issue: https://github.com/isar/isar/issues/1134
- flutter_local_notifications pub.dev: https://pub.dev/packages/flutter_local_notifications
- Exact alarm Android 12+ ExactAlarmPermissionException: https://github.com/MaikuB/flutter_local_notifications/issues/1995
- SCHEDULE_EXACT_ALARM Android 14 denied by default: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- Notifications lost after reboot issue: https://github.com/MaikuB/flutter_local_notifications/issues/2412
- flutter_bloc official docs: https://bloclibrary.dev/
- Bloc-to-Bloc communication issue: https://github.com/felangel/bloc/issues/3816
- Bloc "cannot emit after close": https://github.com/felangel/bloc/issues/4112
- Flutter BLoC best practices (DCM, 2026): https://dcm.dev/blog/2026/03/11/flutter-bloc-best-practices-youre-probably-missing/
- Isar StreamSubscription memory leak: https://saropa-contacts.medium.com/critical-stream-subscription-management-in-flutter-with-isar-prevent-memory-leaks-and-performance-30f4847a5baa
- Flutter i18n official docs: https://docs.flutter.dev/ui/internationalization
- Intl package common mistakes (LeanCode): https://leancode.co/glossary/intl-package-in-flutter
- Flutter localization guide (Phrase, 2025): https://phrase.com/blog/posts/flutter-localization/
- local_auth pub.dev: https://pub.dev/packages/local_auth
- Flutter app lock lifecycle (Medium): https://harsha973.medium.com/flutter-app-lifecycle-for-showing-pin-lock-c7a8a758d222
- Migrating from Isar to Drift (context on Isar limitations): https://medium.com/@davidzequeira42/migrating-from-isar-to-drift-in-flutter-building-a-modular-database-architecture-that-scales-aaf29ef271eb
