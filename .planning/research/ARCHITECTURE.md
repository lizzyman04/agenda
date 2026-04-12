# Architecture Research — AGENDA

**Researched:** 2026-04-12
**Domain:** Offline-first personal productivity + finance mobile app (Flutter)
**Overall confidence:** HIGH (verified against Flutter official docs, pub.dev, and multiple community implementations)

---

## Recommended Folder Structure

**Verdict:** Use a hybrid approach — global Clean Architecture layers at the top level, with feature sub-directories inside `data/`, `domain/`, and `application/` where domain-specific code lives. Cross-cutting concerns (notifications, backup, app lock, i18n) live in `core/` as services, NOT inside feature folders.

**Rationale:** A purely layer-first structure keeps imports and dependency rules trivially enforceable (nothing in `presentation/` imports from `data/`). A purely feature-first structure makes it easy to add features but hard to enforce layer boundaries. For a 2-domain app (tasks + finance) that will stay at roughly that size, layer-first with feature sub-namespacing is the right balance.

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, router, global BlocProviders
│
├── core/                           # Pure Dart — no Flutter framework imports
│   ├── constants/
│   │   ├── app_constants.dart      # durations, limits, magic numbers
│   │   └── storage_keys.dart       # SharedPreferences keys
│   ├── enums/
│   │   ├── task_priority.dart      # urgent/important quadrants, GTD contexts
│   │   ├── recurrence_type.dart
│   │   ├── transaction_type.dart   # income / expense
│   │   └── app_locale.dart         # pt_BR, en
│   ├── errors/
│   │   ├── failure.dart            # sealed class Failure hierarchy
│   │   └── exceptions.dart
│   ├── extensions/
│   │   ├── datetime_extensions.dart
│   │   └── string_extensions.dart
│   └── utils/
│       ├── date_utils.dart
│       └── currency_formatter.dart
│
├── data/                           # Isar schemas, DTOs, repository implementations
│   ├── database/
│   │   ├── isar_service.dart       # singleton Isar instance, open/close, migration
│   │   └── isar_collections.dart   # lists all @Collection types for Isar.open()
│   ├── tasks/
│   │   ├── models/
│   │   │   ├── task_model.dart             # @Collection, Isar schema
│   │   │   ├── project_model.dart
│   │   │   └── task_model.g.dart           # generated
│   │   └── repositories/
│   │       └── task_repository_impl.dart
│   ├── finance/
│   │   ├── models/
│   │   │   ├── transaction_model.dart      # @Collection
│   │   │   ├── budget_model.dart
│   │   │   ├── savings_goal_model.dart
│   │   │   └── debt_model.dart
│   │   └── repositories/
│   │       └── finance_repository_impl.dart
│   └── shared/
│       ├── models/
│       │   └── app_settings_model.dart     # @Collection, PIN hash, locale, lock enabled
│       └── repositories/
│           └── settings_repository_impl.dart
│
├── domain/                         # Pure Dart — zero Flutter/Isar imports
│   ├── tasks/
│   │   ├── entities/
│   │   │   ├── task.dart           # plain Dart class, no Isar annotations
│   │   │   └── project.dart
│   │   ├── repositories/
│   │   │   └── task_repository.dart        # abstract interface
│   │   └── services/
│   │       ├── task_scheduler_service.dart # abstract — schedules task notifications
│   │       └── recurring_task_service.dart # business logic for recurrence expansion
│   ├── finance/
│   │   ├── entities/
│   │   │   ├── transaction.dart
│   │   │   ├── budget.dart
│   │   │   ├── savings_goal.dart
│   │   │   └── debt.dart
│   │   ├── repositories/
│   │   │   └── finance_repository.dart     # abstract interface
│   │   └── services/
│   │       ├── budget_alert_service.dart   # abstract — budget threshold logic
│   │       └── debt_reminder_service.dart  # abstract
│   └── shared/
│       ├── entities/
│       │   └── app_settings.dart
│       ├── repositories/
│       │   └── settings_repository.dart    # abstract
│       └── services/
│           ├── notification_service.dart   # abstract — schedules ANY notification
│           ├── backup_service.dart         # abstract — export/import
│           └── app_lock_service.dart       # abstract — PIN verify/set/clear
│
├── application/                    # BLoC/Cubit — depends on domain only
│   ├── tasks/
│   │   ├── task_cubit.dart
│   │   ├── task_state.dart
│   │   ├── project_cubit.dart
│   │   └── project_state.dart
│   ├── finance/
│   │   ├── transaction_cubit.dart
│   │   ├── transaction_state.dart
│   │   ├── budget_cubit.dart
│   │   ├── budget_state.dart
│   │   └── goals_cubit.dart
│   └── shared/
│       ├── settings_cubit.dart     # locale, app lock toggle
│       ├── settings_state.dart
│       ├── app_lock_cubit.dart     # lock/unlock lifecycle
│       ├── app_lock_state.dart
│       └── backup_cubit.dart       # export/import status
│
├── presentation/                   # Flutter widgets — depends on application/ only
│   ├── tasks/
│   │   ├── screens/
│   │   │   ├── task_list_screen.dart
│   │   │   ├── task_detail_screen.dart
│   │   │   ├── eisenhower_screen.dart
│   │   │   ├── one_three_five_screen.dart
│   │   │   └── gtd_screen.dart
│   │   └── widgets/
│   │       ├── task_card.dart
│   │       └── quadrant_grid.dart
│   ├── finance/
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── transaction_list_screen.dart
│   │   │   ├── budget_screen.dart
│   │   │   ├── savings_goals_screen.dart
│   │   │   └── debts_screen.dart
│   │   └── widgets/
│   │       ├── budget_progress_bar.dart
│   │       └── goal_card.dart
│   └── shared/
│       ├── screens/
│       │   ├── home_screen.dart        # bottom nav shell
│       │   ├── settings_screen.dart
│       │   ├── backup_screen.dart
│       │   └── app_lock_screen.dart    # PIN entry gate
│       └── widgets/
│           ├── loading_indicator.dart
│           └── error_snackbar.dart
│
├── infrastructure/                 # Concrete implementations of domain services
│   ├── notifications/
│   │   ├── notification_service_impl.dart  # wraps flutter_local_notifications
│   │   └── notification_channels.dart      # Android channel IDs and config
│   ├── backup/
│   │   ├── backup_service_impl.dart        # file_picker + path_provider + JSON/CSV
│   │   └── csv_serializer.dart
│   └── security/
│       └── app_lock_service_impl.dart      # PIN hashing, flutter_secure_storage
│
└── config/
    ├── routes/
    │   ├── app_router.dart         # GoRouter or Navigator 2.0 route definitions
    │   └── route_names.dart
    ├── di/
    │   ├── injection.dart          # single getIt.init() entry point
    │   ├── core_module.dart        # registers IsarService, shared infra
    │   ├── tasks_module.dart       # registers task repo, task cubits
    │   └── finance_module.dart     # registers finance repo, finance cubits
    └── l10n/
        ├── app_en.arb
        ├── app_pt.arb
        └── l10n.yaml
```

**Note on the `infrastructure/` layer:** The pre-decided structure uses `data/` and `domain/`. The concrete implementations of notification, backup, and app lock services do NOT belong in `data/` (they are not database concerns) and do NOT belong in `domain/` (they have Flutter/platform dependencies). A thin `infrastructure/` directory solves this cleanly. If the owner prefers to keep strictly 6 layers, these implementations can live in `data/shared/services/` — but `infrastructure/` is cleaner and widely used in Flutter Clean Architecture literature.

---

## Component Boundaries

**Confidence: HIGH** — Verified against Flutter official architecture docs and Robert C. Martin's Dependency Rule.

### The Dependency Rule

Dependencies point inward only. Outer layers know about inner layers; inner layers know nothing about outer layers.

```
presentation/ → application/ → domain/ ← data/
                                  ↑
                            infrastructure/
```

Concretely:

| Layer | May import from | Must NOT import from |
|-------|----------------|---------------------|
| `core/` | nothing (pure Dart stdlib) | everything else in lib/ |
| `domain/` | `core/` only | `data/`, `application/`, `presentation/`, `infrastructure/`, Flutter SDK |
| `data/` | `domain/`, `core/`, Isar | `application/`, `presentation/` |
| `infrastructure/` | `domain/`, `core/`, Flutter SDK, platform packages | `data/` (no Isar), `application/`, `presentation/` |
| `application/` | `domain/`, `core/` | `data/`, `infrastructure/`, `presentation/` |
| `presentation/` | `application/`, `core/`, Flutter SDK | `domain/` (except entity classes for display), `data/`, `infrastructure/` |
| `config/` | everything (wiring layer) | — |

### Feature Boundary Rule

Tasks and finance must not import from each other at any layer. They communicate only through:
1. Shared domain services (e.g., `NotificationService` is called by both `TaskSchedulerService` and `BudgetAlertService`)
2. Shared application state via `SettingsCubit`

A `TaskCubit` must never hold a reference to `BudgetCubit` or any finance entity. If a screen needs to show both task and finance summaries (e.g., a home dashboard), the `HomeCubit` lives in `application/shared/` and reads from both repositories.

### What Repositories Know About

- A repository interface in `domain/` is a pure abstract class with no implementation details.
- A repository implementation in `data/` knows about Isar models and the `IsarService` singleton.
- Repositories do NOT know about each other. They do NOT call other repositories.
- If a use case needs data from two repositories, that composition happens in a Cubit or a domain service, never inside a repository.

### Isar Model vs Domain Entity

Isar schemas (`@Collection`) live exclusively in `data/`. Domain entities are plain Dart classes in `domain/`. The repository implementation is the only place that converts between them:

```dart
// data/tasks/repositories/task_repository_impl.dart
class TaskRepositoryImpl implements TaskRepository {
  final IsarService _isar;

  @override
  Future<List<Task>> getTasksDueToday() async {
    final models = await _isar.instance.taskModels
        .filter()
        .dueDateLessThan(DateTime.now().endOfDay())
        .findAll();
    return models.map((m) => m.toDomain()).toList();
  }
}
```

The domain `Task` entity has no `.g.dart` generated file and no `@IsarId` annotations.

---

## Cross-cutting Concerns

**Confidence: HIGH** — Pattern verified against multiple Flutter Clean Architecture implementations and Flutter official docs.

### Principle

Cross-cutting concerns are services that multiple features need but that no feature domain owns. They are defined as abstract interfaces in `domain/shared/services/` and implemented in `infrastructure/`. GetIt wires the concrete implementation to the interface at startup. Feature domain services (e.g., `TaskSchedulerService`) depend on the abstract `NotificationService`, not on `flutter_local_notifications` directly.

### Notifications

**Where it lives:** `domain/shared/services/notification_service.dart` (abstract) + `infrastructure/notifications/notification_service_impl.dart` (concrete).

**Pattern:**

```dart
// domain/shared/services/notification_service.dart
abstract class NotificationService {
  Future<void> scheduleTaskReminder(Task task);
  Future<void> scheduleBudgetAlert(Budget budget, double spent);
  Future<void> scheduleDebtReminder(Debt debt);
  Future<void> scheduleDailyBriefing(TimeOfDay time);
  Future<void> cancelNotification(int id);
  Future<void> cancelAllForTask(int taskId);
}

// infrastructure/notifications/notification_service_impl.dart
// -- imports flutter_local_notifications, timezone
// -- maps domain objects to platform notification calls
// -- assigns stable integer IDs (e.g., task IDs get namespace 1000–1999, budgets 2000–2999)
```

Feature Cubits (e.g., `TaskCubit`) call domain services like `TaskSchedulerService` which call `NotificationService`. Cubits do NOT call `NotificationService` directly — the scheduling logic belongs in domain.

**Background scheduling:** `flutter_local_notifications` supports `zonedSchedule()` for persistent scheduled notifications that fire even when the app is closed. Use the `timezone` package. Schedule IDs must be stable and deterministic (derive from entity IDs, not timestamps) so re-scheduling on app restart does not create duplicates.

**Android channel configuration:** Define channels in `notification_channels.dart` and initialize at app start (before `runApp()`). Categories: tasks, finance, system.

### Backup / Restore

**Where it lives:** `domain/shared/services/backup_service.dart` (abstract) + `infrastructure/backup/backup_service_impl.dart` (concrete).

**Pattern:**

```dart
abstract class BackupService {
  Future<String> exportToJson();          // returns file path
  Future<String> exportToCsv();
  Future<void> importFromJson(String filePath);
  Future<void> importFromCsv(String filePath);
}
```

The concrete implementation:
1. Uses `path_provider` to get a temp directory for the export file.
2. Reads all data via repositories (injected into the service), serializes to JSON/CSV.
3. Uses `file_picker` (save dialog) or `Share` to let the user store/send the file.
4. On import, reads the file via `file_picker`, deserializes, and writes through repositories.

The `BackupCubit` in `application/shared/` calls `BackupService` and exposes loading/success/error states to the UI.

**Critical:** Import must be transactional. Isar supports write transactions natively. Wrap the entire import in a single `isar.writeTxn()` call. If any collection fails to parse, roll back the entire transaction rather than leaving partial data.

### i18n (Internationalization)

**Where it lives:** `config/l10n/` — Flutter's built-in `flutter_localizations` + ARB files.

**Pattern:** Use `flutter gen-l10n` to generate typed `AppLocalizations`. Access via `AppLocalizations.of(context)!` in widgets. Do NOT pass `BuildContext` into Cubits or domain — if a Cubit needs a localized string (e.g., for a notification body), pass the string in from the widget or keep notification body templates in the `NotificationService` impl where context is available.

**Language switching at runtime:** `SettingsCubit` holds the `Locale` state. `MaterialApp.locale` is set from `BlocBuilder<SettingsCubit, SettingsState>`. The chosen locale is persisted in Isar via `AppSettingsModel`.

**No locale logic in domain.** Domain entities are locale-agnostic. Formatting (dates, currencies) happens in `presentation/` via extension methods defined in `core/utils/`.

### App Lock

**Where it lives:** `domain/shared/services/app_lock_service.dart` (abstract) + `infrastructure/security/app_lock_service_impl.dart` (concrete).

**Pattern:**

```dart
abstract class AppLockService {
  bool get isLockEnabled;
  Future<void> setPin(String pin);          // hashes and stores
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
}
```

The concrete implementation uses `flutter_secure_storage` to store the PIN hash (bcrypt or SHA-256 + salt stored alongside). Never store the PIN in plain text or in Isar (Isar files are not encrypted by default).

**App lifecycle integration:** `AppLockCubit` listens to `AppLifecycleState` via a `WidgetsBindingObserver`. When the app is paused and lock is enabled, it transitions to `AppLockState.locked`. When resumed, it transitions to `AppLockState.requiresUnlock`. The `app.dart` shell wraps the router with a `BlocBuilder<AppLockCubit>` that renders `AppLockScreen` over the entire app when locked.

**Route guard:** GoRouter's `redirect` callback checks `AppLockCubit` state. If locked, redirect to `/lock` regardless of requested route.

---

## Build Order

**Confidence: HIGH** — Bottom-up from most stable to most volatile. Inner layers have no outward dependencies, so they can be built and tested in isolation.

### Phase sequence (recommended)

**Stage 1 — Foundation (no features, fully testable)**
1. `core/` — enums, constants, failure hierarchy, extensions. Zero dependencies. Write these first; everything else imports from here.
2. `config/l10n/` — ARB files and `flutter gen-l10n`. UI strings need to be available when building the first screen.
3. `data/database/` — `IsarService` singleton (open, close, instance accessor). Required by all repository implementations.
4. `config/di/` — Stub `injection.dart` that compiles, even with nothing registered yet. Add registrations incrementally.

**Stage 2 — First domain (Tasks)**
5. `domain/tasks/entities/` — `Task`, `Project` plain Dart classes.
6. `domain/tasks/repositories/` — abstract `TaskRepository` interface.
7. `data/tasks/models/` — `TaskModel` with Isar `@Collection` annotations. Write `toDomain()` / `fromDomain()` mappers.
8. `data/tasks/repositories/` — `TaskRepositoryImpl` implementing the domain interface.
9. `application/tasks/` — `TaskCubit` + `TaskState`. Write unit tests against mock repository.
10. `presentation/tasks/screens/` + `widgets/` — task list, task form. BlocProvider via GetIt.

**Stage 3 — Second domain (Finance)**
11. Repeat steps 5–10 for `domain/finance/`, `data/finance/`, `application/finance/`, `presentation/finance/`.

**Stage 4 — Shared infrastructure**
12. `domain/shared/services/notification_service.dart` (interface).
13. `infrastructure/notifications/notification_service_impl.dart`. Wire into GetIt.
14. Domain services that use notifications: `TaskSchedulerService`, `BudgetAlertService`, etc.
15. Wire notification calls into existing Cubits.

**Stage 5 — App lock**
16. `domain/shared/services/app_lock_service.dart` (interface).
17. `infrastructure/security/app_lock_service_impl.dart`.
18. `application/shared/app_lock_cubit.dart` + lifecycle observer.
19. `presentation/shared/screens/app_lock_screen.dart`.

**Stage 6 — Backup/restore**
20. `domain/shared/services/backup_service.dart` (interface).
21. `infrastructure/backup/backup_service_impl.dart`.
22. `application/shared/backup_cubit.dart`.
23. `presentation/shared/screens/backup_screen.dart`.

**Why this order matters:**
- Domain is built before data so Isar models are shaped to fit domain entities, not the reverse. This prevents Isar schema leaking into domain.
- Tasks domain is built before finance because tasks have more complexity (recurrence, GTD, Eisenhower) and will reveal structural patterns that finance can reuse.
- Infrastructure (notifications, lock, backup) is built last because it depends on domain entities being stable. Changing `Task` after wiring notifications forces changes in two places.
- GetIt registration is incremental — add each class to its module file as it is implemented. Never add a batch of registrations at the end.

---

## Common Mistakes

**Confidence: HIGH** — Sourced from Flutter official docs, community post-mortems, and architectural analysis of open-source Flutter Clean Architecture projects.

### Mistake 1: Isar annotations bleeding into domain entities

**What goes wrong:** Developers put `@IsarId`, `@Index`, or `@Enumerated` directly on domain entity classes to save the mapping step.

**Consequence:** Domain is now coupled to Isar. Swapping the database requires rewriting entities. Unit tests for domain logic must pull in the Isar package. The domain layer loses its "pure Dart" property.

**Prevention:** Always maintain two separate classes — `TaskModel` (in `data/`) and `Task` (in `domain/`). The 15 extra lines of mapping code pay for themselves immediately in test speed and isolation.

---

### Mistake 2: Cubits calling repository implementations directly

**What goes wrong:** `TaskCubit` is injected with `TaskRepositoryImpl` (the concrete class) instead of `TaskRepository` (the abstract interface).

**Consequence:** Cubits cannot be tested without an Isar database. Swapping the data source requires changes in the DI layer AND the Cubit constructor.

**Prevention:** Always register and inject the abstract interface. `getIt.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(...))`. Cubits declare `final TaskRepository _repository`.

---

### Mistake 3: One god-BLoC per domain

**What goes wrong:** A single `TaskBloC` handles task CRUD, project management, Eisenhower view, 1-3-5 planning, and GTD state. It grows to thousands of lines.

**Consequence:** Any change risks breaking unrelated functionality. Testing requires setting up the entire task domain. State classes become enormous unions.

**Prevention:** One Cubit per cohesive slice of state. `TaskCubit` handles individual task CRUD. `ProjectCubit` handles projects. `EisenhowerCubit` handles quadrant view filtering. They can share a `TaskRepository` — GetIt makes this trivial.

---

### Mistake 4: Cross-domain Cubit dependencies

**What goes wrong:** `TaskCubit` takes a constructor parameter of `BudgetCubit` to "link" task completion with a budget update, or `FinanceDashboardCubit` reads from `TaskCubit` to show today's tasks.

**Consequence:** Tasks and finance are tightly coupled. Changing one feature breaks the other. The domain boundary is meaningless.

**Prevention:** Cross-domain coordination belongs in `application/shared/` or in domain services. A `HomeDashboardCubit` can hold references to both `TaskRepository` and `FinanceRepository` — that is legitimate because it is explicitly a cross-domain concern. Cubits in feature sub-folders must not import from each other's feature folder.

---

### Mistake 5: Putting notification scheduling logic in Cubits

**What goes wrong:** `TaskCubit.createTask()` directly calls `FlutterLocalNotificationsPlugin.zonedSchedule(...)`.

**Consequence:** Notification scheduling is untestable without platform setup. Logic is duplicated when the same notification type needs to be rescheduled from multiple places. The Cubit imports a platform package, violating the application-layer boundary.

**Prevention:** Scheduling logic belongs in a domain service (`TaskSchedulerService`) that depends on the abstract `NotificationService`. The Cubit calls `_taskScheduler.scheduleReminder(task)`. Tests inject a `MockNotificationService`.

---

### Mistake 6: Registering GetIt dependencies after they are first accessed

**What goes wrong:** GetIt setup is deferred or split across lazy initializers, and some class tries to call `getIt<TaskRepository>()` before `injection.dart` has run.

**Consequence:** `StateError: Object/factory with type TaskRepository is not registered inside GetIt` crash at runtime, often in unexpected screens.

**Prevention:** Call the full `configureDependencies()` in `main()` before `runApp()`. All modules must be registered synchronously (or awaited) before the widget tree builds. Verify with `getIt.isRegistered<T>()` in debug asserts.

---

### Mistake 7: Using `BuildContext` for locale inside domain or application layers

**What goes wrong:** A Cubit or domain service calls `AppLocalizations.of(context)` to generate notification body text, requiring `BuildContext` to be threaded down into non-UI code.

**Consequence:** Application and domain layers become dependent on the widget tree. Unit tests require a widget environment. The architecture boundary is broken.

**Prevention:** Notification body text is the responsibility of `NotificationServiceImpl` (infrastructure layer), not domain. Domain passes structured data (entity + notification type enum); the infrastructure layer formats the human-readable string using a locale loaded at service initialization, not passed per-call.

---

### Mistake 8: Treating `core/` as a dumping ground

**What goes wrong:** `core/` accumulates business logic (e.g., "is this task overdue?"), UI helpers (e.g., theme colors), and platform utilities all mixed together.

**Consequence:** `core/` grows unbounded, imports grow circular, and the module loses its meaning.

**Prevention:** `core/` contains only: pure utility functions (no state), constants, enums, and extension methods on Dart built-in types. Business logic belongs in domain services. UI helpers belong in `presentation/shared/`. Platform wrappers belong in `infrastructure/`.

---

## Sources

- Flutter official architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter common architecture concepts: https://docs.flutter.dev/app-architecture/concepts
- Offline-first with Isar (Hoomanely): https://tech.hoomanely.com/offline-first-with-isar-building-faster-more-reliable-flutter-apps/
- Multi-module DI with injectable: https://medium.com/@kaleed4allah/dependency-injection-in-multimodule-flutter-projects-using-injectable-and-getit-339bcdbd2cef
- Notification service Clean Architecture: https://medium.com/@sayedmoataz9/building-a-robust-notification-status-service-in-flutter-a-deep-dive-into-clean-architecture-and-396e003d4db8
- Feature-first vs layer-first analysis: https://yshean.com/flutter-architecture-patterns-clean-architecture-vs-feature-first
- Clean Architecture Flutter 2025: https://coding-studio.com/clean-architecture-in-flutter-a-complete-guide-with-code-examples-2025-edition/
- GetIt + BLoC combination: https://stackademic.com/blog/combining-getit-and-bloc-for-clean-flutter-apps
- Flutter BLoC Clean Architecture mistakes: https://medium.com/@alaxhenry0121/flutter-clean-architecture-99-of-developers-get-this-wrong-complete-bloc-guide-2025-e3c7d74b273f
