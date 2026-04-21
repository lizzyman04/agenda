<!-- GSD:GENERATED -->
<!-- generated-by: gsd-doc-writer -->

# Architecture

AGENDA is a privacy-first Flutter mobile application structured as a strict layered architecture. All data is stored exclusively on-device via Isar Community. No network layer exists — there are no HTTP clients, no analytics SDKs, and no external service integrations in the current codebase. The architecture enforces one-way dependency flow: presentation depends on application, application depends on domain, data and infrastructure implement domain interfaces, and nothing in domain knows about Flutter or Isar.

---

## Layer Overview

```
┌─────────────────────────────────────────────┐
│              presentation/                  │
│   Screens, Widgets (Flutter/Material UI)    │
└───────────────────┬─────────────────────────┘
                    │ reads state, calls cubit methods
┌───────────────────▼─────────────────────────┐
│              application/                   │
│        BLoC/Cubit state management          │
└───────────────────┬─────────────────────────┘
                    │ calls repository interfaces, domain services
┌───────────────────▼─────────────────────────┐
│               domain/                       │
│   Entities, Repository interfaces,          │
│   Domain services (pure Dart)               │
└───────────────┬───┴─────────────────────────┘
                │ implemented by
┌───────────────▼─────────────┐   ┌───────────────────────────────┐
│       infrastructure/       │   │           data/               │
│  Repository implementations │   │  Isar models, DAOs, DB service│
│  (wrap data layer with      │◄──│  ItemMapper, MigrationRunner  │
│   Result<T> error handling) │   │                               │
└─────────────────────────────┘   └───────────────────────────────┘
                    ▲
┌───────────────────┴─────────────────────────┐
│                core/                        │
│   Result<T>/Failure hierarchy, constants,   │
│   extensions, AppConfig                     │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                config/                      │
│   GetIt DI graph (injectable), router,      │
│   l10n delegates                            │
└─────────────────────────────────────────────┘
```

### Directory roles

| Directory | Role |
|-----------|------|
| `lib/core/` | Cross-cutting utilities: `Result<T>` / `Failure` sealed classes, `AppConfig`, `AppConstants`, datetime/string extensions, storage key constants. No Flutter imports in non-extension files. |
| `lib/domain/` | Pure Dart entities and abstract interfaces. `Item` entity, `ItemRepository` interface, `RecurrenceEngine` interface, enums (`ItemType`, `Priority`, `EisenhowerQuadrant`, `SizeCategory`). Zero Flutter, zero Isar. |
| `lib/data/` | Isar persistence. `ItemModel` (`@Collection`), embedded value objects (`MoneyInfo`, `TimeInfo`), `ItemDao` (all raw queries), `ItemMapper` (bidirectional domain↔model conversion), `IsarService` singleton wrapper, `MigrationRunner`. |
| `lib/infrastructure/` | Implements domain interfaces. `ItemRepositoryImpl` wraps `ItemDao` + `ItemMapper` in try/catch blocks and always returns `Result<T>` — never throws. `RecurrenceEngineImpl` parses iCal RRULE strings and computes next occurrence dates. |
| `lib/application/` | BLoC/Cubit state machines. `TaskListCubit`, `DayPlannerCubit`, `ProjectCubit`, `LocaleCubit`. All cubits receive dependencies via constructor injection from GetIt. |
| `lib/presentation/` | Flutter screens and widgets. Reads cubit state via `BlocBuilder`/`BlocConsumer`. Dispatches user actions to cubit methods. Never calls repositories directly. |
| `lib/config/` | Wiring: GetIt DI modules (`CoreModule`, `TasksModule`), generated `injection.config.dart`, l10n setup, router. |
| `lib/generated/` | Code-generated ARB output (`AppLocalizations`, `AppLocalizationsEn`, `AppLocalizationsPt`). Do not edit manually. |

---

## Data Flow

A typical user action — creating a task — moves through the following path:

1. **User taps FAB** on `TaskListScreen` → `_navigateToCreate()` pushes `TaskFormScreen`.
2. **User submits form** → `TaskListCubit.createItem(item)` is called with a domain `Item` (id = 0).
3. **`TaskListCubit`** calls `ItemRepository.createItem(item)` (the abstract interface).
4. **`ItemRepositoryImpl`** (concrete) validates `parentId` if set, stamps `createdAt`/`updatedAt` via `DateTime.now()`, calls `ItemMapper.toModel(item)` to produce an `ItemModel`, then calls `ItemDao.save(model)`.
5. **`ItemDao`** executes an Isar write transaction (`writeTxn → collection.put(model)`). Isar assigns the auto-increment id.
6. **`IsarService.db.collection<ItemModel>().watchLazy()`** fires a change event.
7. **`TaskListCubit._watchSubscription`** listener receives the event and calls `_reload()`.
8. **`_reload()`** calls `ItemRepository.filterItems(...)` with the current `TaskListFilter`, receives `Success<List<Item>>`, and emits `TaskListLoaded(items: ...)`.
9. **`TaskListScreen`** rebuilds via `BlocBuilder` — the new item appears in the list.

This reactive pattern (write → watch stream fires → cubit reloads → UI rebuilds) means cubits never manually reconcile local state after a write; the Isar watch stream is the single source of truth for rebuild triggers.

---

## State Management

All state management uses `flutter_bloc` Cubits (not full Blocs — no event classes).

### Cubits

| Cubit | Lifecycle | Dependencies |
|-------|-----------|--------------|
| `TaskListCubit` | Factory — one per task list screen | `ItemRepository`, `RecurrenceEngine` |
| `DayPlannerCubit` | Factory — ephemeral per session, in-memory only | none |
| `ProjectCubit` | Factory — one per project screen | `ItemRepository` |
| `LocaleCubit` | Factory — provided at app root | `SharedPreferences` |

### State shapes

`TaskListCubit` uses a sealed class hierarchy with four concrete states:

- `TaskListInitial` — pre-load
- `TaskListLoading` — query in flight
- `TaskListLoaded(items, filter, searchQuery)` — data ready
- `TaskListWithPendingUndo(deletedItemId, items, filter, searchQuery)` — soft-delete committed; 5-second undo window active
- `TaskListError(failure)` — repository returned `Err`

All state classes extend `Equatable` for value-based equality. The sealed class constraint (Dart `sealed`) makes all `switch` expressions over state exhaustive at compile time — missing a case is a compile error.

### Reactive reload pattern

`TaskListCubit.start()` subscribes to `ItemRepository.watchChanges()`, which proxies `ItemDao.watchLazy()` (Isar's `collection.watchLazy()` stream). Any write to the `ItemModel` collection — regardless of which cubit caused it — fires the stream and triggers `_reload()`. This keeps the task list synchronized across screens without manual cache invalidation.

---

## Error Handling

All fallible operations use the `Result<T>` / `AsyncResult<T>` types defined in `lib/core/failures/result.dart`. Methods never throw — they return `Err(failure)`.

```dart
sealed class Result<T> { ... }
final class Success<T> extends Result<T> { final T value; }
final class Err<T>     extends Result<T> { final Failure failure; }
typedef AsyncResult<T> = Future<Result<T>>;
```

The `Failure` sealed class hierarchy:

| Subtype | When used |
|---------|-----------|
| `DatabaseFailure` | Isar read/write or transaction errors |
| `ValidationFailure` | Business rule violations (e.g. `parentId` must point to a project) |
| `NotificationFailure` | Reserved for Phase 4 notification scheduling |
| `BackupFailure` | Reserved for Phase 4 CSV export/import |
| `SecurityFailure` | Reserved for Phase 5 PIN/biometric auth |

Pattern matching at call sites is exhaustive — adding a new `Failure` subtype forces all `switch` expressions to handle it or the compiler rejects the build.

---

## Dependency Injection

AGENDA uses GetIt 9.2.1 as the service locator with injectable 2.7.1 for annotation-driven code generation. The DI graph is built in `configureDependencies()` (called in `main()` before `runApp`).

### Registration summary

| Registration | Type | Class |
|---|---|---|
| `SharedPreferences` | Async singleton (pre-resolved) | `CoreModule` |
| `IsarService` | Singleton | `CoreModule` |
| `ItemMapper` | Lazy singleton | `TasksModule` |
| `ItemDao` | Lazy singleton | `TasksModule` |
| `RecurrenceEngine` | Lazy singleton | `RecurrenceEngineImpl` (annotation) |
| `ItemRepository` | Lazy singleton | `ItemRepositoryImpl` (annotation) |
| `LocaleCubit` | Factory | Injectable annotation |
| `TaskListCubit` | Factory | Injectable annotation |
| `ProjectCubit` | Factory | Injectable annotation |
| `DayPlannerCubit` | Factory | Injectable annotation |

`SharedPreferences` is pre-resolved (`preResolve: true`) so it is available synchronously at all call sites after `configureDependencies()` completes. All Cubits are factories (not singletons) — a fresh instance is provided each time a screen creates one via `getIt<CubitType>()`.

The generated wiring lives in `lib/config/di/injection.config.dart` and must not be edited by hand. Regenerate with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Database Schema

AGENDA uses isar_community 3.3.2 (community-maintained fork of the abandoned `isar` package). The database file is stored in the application documents directory via `path_provider`.

### Phase 2 schema: `ItemModel` collection

One unified collection stores projects, tasks, and subtasks. The `type` field (`ItemType` enum: `project`, `task`, `subtask`) discriminates between them. Parent/child relationships use an integer `parentId` field (non-null only for subtasks).

**Indexes:**

| Index | Fields | Purpose |
|-------|--------|---------|
| Composite | `(type, deletedAt)` | Fast active-items-by-type queries |
| Single | `parentId` | Subtask lookups by project |
| Single | `deletedAt` | Soft-delete filter |
| Single | `dueDate` | Due-date range queries |

**Embedded value objects:**

- `TimeInfo` — `dueTimeMinutes` (int, minutes since midnight) and `recurrenceRule` (iCal RRULE string). `dueDate` is promoted to a top-level field (not embedded) so Isar can index it.
- `MoneyInfo` — `amount` (double) and `currencyCode` (ISO 4217 string). Populated only if either field is non-null.

**Key design decisions:**

- `EisenhowerQuadrant` is never stored — it is computed from `(isUrgent, isImportant)` as a getter on the domain `Item` entity.
- All list queries apply `.deletedAtIsNull()` and `.limit(500)`. Soft-deleted records remain in the collection with a non-null `deletedAt` timestamp.
- Enums are persisted as strings (`@Enumerated(EnumType.name)`) for forward-compatibility.
- Phase 3 finance fields (`linkedGoalId`, `linkedDebtId`) are reserved as null-capable `int?` columns — always null in Phase 2.

### Migration system

`MigrationRunner` runs on every cold start inside `IsarService.open()`. The current schema version is stored in `SharedPreferences` under `StorageKeys.schemaVersion`. Migrations execute once in ascending order; each successful migration writes the new version before proceeding to the next. The target version is the `AppConfig.schemaVersion` constant (currently `2`).

---

## Navigation

Navigation uses Flutter's imperative `Navigator.of(context).push(MaterialPageRoute(...))` — `go_router` is declared as a dependency but is not yet wired into the app shell. The current tab structure is managed by `_AppShell` (a `StatefulWidget` with `IndexedStack`).

**Tab screens (persistent — kept alive via `IndexedStack`):**

| Index | Screen | Cubit |
|-------|--------|-------|
| 0 | `TaskListScreen` | `TaskListCubit` |
| 1 | `EisenhowerScreen` | `TaskListCubit` (shared via `BlocProvider.value`) |
| 2 | `DayPlannerScreen` | `DayPlannerCubit` |
| 3 | `GtdFilterScreen` | `TaskListCubit` (shared via `BlocProvider.value`) |

**Modal routes (pushed over tabs):**

- `TaskFormScreen` — create/edit a task or project (receives `TaskListCubit` via `BlocProvider.value`)
- `TaskDetailScreen` — read-only task detail with Edit and Delete actions (receives `TaskListCubit` via `BlocProvider.value`)
- `ProjectScreen` — project detail with subtask rollup (creates its own `ProjectCubit` factory instance)

---

## Localization

AGENDA supports PT-BR (default) and English. Locale selection is persisted to `SharedPreferences` and managed by `LocaleCubit`. The Flutter ARB pipeline (`flutter gen-l10n`) generates `AppLocalizations` from ARB files. The `l10n.yaml` configuration drives generation; output lands in `lib/generated/l10n/`.

Supported locales are `[Locale('pt', 'BR'), Locale('en')]`. `LocaleCubit` defaults to PT-BR when no preference is stored.

---

## Key Abstractions

| Abstraction | File | Description |
|-------------|------|-------------|
| `Item` | `lib/domain/tasks/item.dart` | Core domain entity for projects, tasks, and subtasks. Pure Dart, immutable, with `copyWith` using a `clearField` sentinel for nullable fields. |
| `ItemRepository` | `lib/domain/tasks/item_repository.dart` | Abstract interface for all item persistence operations. Returns `AsyncResult<T>` — never throws. |
| `RecurrenceEngine` | `lib/domain/tasks/recurrence_engine.dart` | Abstract domain service for iCal RRULE parsing and next-occurrence computation. |
| `Result<T>` / `AsyncResult<T>` | `lib/core/failures/result.dart` | Sealed `Success<T>` / `Err<T>` discriminated union. The standard return type for all fallible operations. |
| `Failure` | `lib/core/failures/failure.dart` | Sealed failure hierarchy. Exhaustive `switch` at call sites is compiler-enforced. |
| `ItemModel` | `lib/data/tasks/item_model.dart` | Isar `@Collection` — the only class that touches Isar APIs. |
| `ItemMapper` | `lib/data/tasks/item_mapper.dart` | Pure bidirectional converter between `ItemModel` and `Item`. The only place where data-layer and domain-layer enums are mapped. |
| `ItemDao` | `lib/data/tasks/item_dao.dart` | All raw Isar queries in one place. Async only — no `*Sync` methods. |
| `IsarService` | `lib/data/database/isar_service.dart` | Process-wide singleton wrapping the `Isar` instance. `open()` is idempotent. |
| `TaskListCubit` | `lib/application/tasks/task_list/task_list_cubit.dart` | Primary task management state machine. Subscribes to `ItemRepository.watchChanges()` for reactive reloads. |
| `AppConfig` | `lib/core/config/app_config.dart` | Compile-time constants: app name, package id, version, schema version, notification ID namespaces. |
