# Phase 02: Task Core — Context

**Gathered:** 2026-04-13
**Status:** Ready for planning
**Source:** /gsd-discuss-phase session

<domain>
## Phase Boundary

Phase 2 delivers the complete task management domain: create/edit/delete projects, subtasks, and standalone tasks; classify with Eisenhower/1-3-5/GTD; set due dates; create recurring tasks; and search/filter the task list — all persisted via Isar.

Tasks and finances are architecturally connected in AGENDA. A task may carry a money value (e.g., "Desenvolvimento Website K-Desperta" — 8000 MZN). Phase 2 stores the money shell (`moneyInfo`) but adds no finance logic. Phase 3 fills the linkages (goals, debts, transactions).

Notifications are explicitly out of scope for Phase 2. Due dates are stored; reminders are wired in Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Entity Shape — Unified Item Collection

**LOCKED:** One Isar collection (`ItemModel`) discriminated by `ItemType` enum:
- `ItemType.project` — top-level container with title and optional description
- `ItemType.task` — standalone or child task
- `ItemType.subtask` — child of a project (parent_id set)

Parent/child relationships use `parent_id` (nullable `Id`). Subtask completion rollup to project is computed at the application layer, not stored as a denormalized field.

Rationale: a unified collection makes cross-linking with finance in Phase 3 trivial — one foreign key on any Item regardless of type.

### moneyInfo — Amount + Currency Only

**LOCKED:** `moneyInfo` stores `{ amount: double, currencyCode: String }` only in Phase 2. No foreign keys to goals, debts, or transactions yet. Phase 3 adds those links when the Finance domain exists.

Currency code is stored as a plain string (ISO 4217, e.g., "MZN", "USD"). No currency conversion logic in Phase 2.

### Notifications — Defer to Phase 4

**LOCKED:** Phase 2 stores `dueDate` and `dueTime` on Items but schedules no notifications. `flutter_local_notifications` is NOT added to pubspec in Phase 2. Phase 4 reads the persisted due dates and wires all notification types.

### timeInfo — Task Features

**LOCKED:** `timeInfo` is expanded in Phase 2 to hold:
- `dueDate` (nullable DateTime)
- `dueTime` (nullable TimeOfDay — stored as minutes-since-midnight int)
- `recurrenceRule` (nullable — see Recurrence section)

### Eisenhower Matrix

**LOCKED:** Two boolean fields on Item: `isUrgent` and `isImportant`. Quadrant is derived at the application layer from the combination — not stored as an enum.

Quadrants:
- Q1 (Do): urgent + important
- Q2 (Schedule): not urgent + important
- Q3 (Delegate): urgent + not important
- Q4 (Eliminate): not urgent + not important

### 1-3-5 Rule

**LOCKED:** Items carry a `sizeCategory` enum: `big`, `medium`, `small`, `none`. The 1-3-5 day planner enforces the daily slot constraint (1 big, 3 medium, 5 small) at the application layer via `DayPlannerCubit`. Constraint violation is a UI warning, not a hard block.

### GTD Attributes

**LOCKED:** Stored as nullable fields on Item:
- `isNextAction` (bool, default false)
- `gtdContext` (nullable String — freeform tag, e.g., "@home", "@phone")
- `waitingFor` (nullable String — name or system being waited on)

GTD is additive — items without GTD tags are unaffected.

### Recurring Tasks

**LOCKED:** `recurrenceRule` stored as a plain string using iCal RRULE format subset (e.g., `FREQ=DAILY`, `FREQ=WEEKLY;BYDAY=MO`, `FREQ=MONTHLY;BYMONTHDAY=1`). A `RecurrenceEngine` domain service parses the rule and generates the next due date. On task completion, the engine creates the next occurrence as a new Item (no mutation of the completed item).

### Soft Delete (TASK-05)

**LOCKED:** Deletion uses a `deletedAt` (nullable DateTime) field. Items with `deletedAt != null` are excluded from all queries. The undo snackbar calls a `restoreItem()` that nulls out `deletedAt` within the 5-second window. Permanent purge is a background job (or on next open).

### Search and Filter

**LOCKED:** All search/filter logic runs in-process against Isar query results. No FTS index — keyword search uses Isar's `filter().titleContains()` with case-insensitive match. Multi-criteria filter composes Isar query clauses. Results update immediately on filter change via Cubit stream.

### Application Layer — Cubit Conventions

**LOCKED:**
- `TaskListCubit` — owns the filtered/searched task list observable by the task list screen
- `ProjectCubit` — owns project CRUD and subtask rollup computation
- `DayPlannerCubit` — owns the 1-3-5 daily slot state and constraint enforcement
- One repository interface per bounded concern: `ItemRepository` (single interface for all Item types, discriminated by type)
- Cubits receive the repository via GetIt injection; `TasksModule` in DI graph is populated in this phase

### Isar Schema Conventions (from Phase 1 Patterns)

**LOCKED (from Phase 1):**
- All enums annotated with `@enumerated(EnumType.name)` — safe to reorder
- All repository methods return `Result<T>` / `AsyncResult<T>` (never throw)
- Package imports only (`package:agenda/...`)
- No synchronous Isar calls (no `findSync`, `putSync`, etc.)

### Phase 3 Extensibility Contract

The `ItemModel` Isar schema MUST include the following nullable fields even though Phase 3 does not exist yet:
- `linkedGoalId` (nullable Id) — reserved for Phase 3 goal linkage
- `linkedDebtId` (nullable Id) — reserved for Phase 3 debt linkage

These fields are `null` in Phase 2 and never read. They exist so Phase 3 adds no breaking schema migration — only a `MigrationRunner` version bump to populate indexes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Foundation Patterns (Phase 1 — reuse, do not reinvent)
- `lib/data/database/isar_service.dart` — IsarService singleton; open() idempotency pattern
- `lib/data/database/migration_runner.dart` — MigrationRunner; version-gated migration blocks
- `lib/core/failures/failure.dart` — sealed Failure hierarchy; all repository errors wrap in DatabaseFailure or ValidationFailure
- `lib/core/failures/result.dart` — Result<T> / AsyncResult<T> typedefs; all repository methods return these
- `lib/core/constants/app_constants.dart` — 1-3-5 slot counts defined here; do not hardcode in UI
- `lib/config/di/tasks_module.dart` — empty placeholder; Phase 2 populates this

### Architecture Reference
- `.planning/ROADMAP.md` — Phase 2 plan list and success criteria
- `.planning/REQUIREMENTS.md` — TASK-01 through TASK-12 (all must be addressed)
- `.planning/STATE.md` — project-wide decisions and history

</canonical_refs>

<specifics>
## Specific Ideas

- Example task with money value: "Desenvolvimento Website K-Desperta" — amount: 8000, currencyCode: "MZN". This is the primary use case driving `moneyInfo` in Phase 2.
- GTD context tags are freeform strings. No predefined list. User types "@home", "@phone", etc.
- iCal RRULE subset is sufficient — no need for a full RFC 5545 parser. Support: DAILY, WEEKLY (with BYDAY), MONTHLY (with BYMONTHDAY), YEARLY. No UNTIL or COUNT in Phase 2.
- Subtask completion rollup: a project's "completion percentage" = (completed subtasks / total subtasks). Stored nowhere — computed on read.
- 1-3-5 constraint is a soft warning in the UI, not a hard block. Users can exceed limits.

</specifics>

<deferred>
## Deferred to Phase 3 or Later

- Populating `linkedGoalId` / `linkedDebtId` — fields exist but are always null in Phase 2
- Task completion triggering financial transactions — Phase 3
- Multi-currency UI and conversion — v2
- Natural language task input — v2
- Notification scheduling for task due dates — Phase 4
- Boot-safe notification rescheduling — Phase 4

</deferred>

---

*Phase: 02-task-core*
*Context gathered: 2026-04-13 via /gsd-discuss-phase session*
