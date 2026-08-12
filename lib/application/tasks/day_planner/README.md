# application/tasks/day_planner

Owns the **1-3-5 Rule planning session** — one big task, three medium,
five small (TASK-08).

## Responsibility

Hold the current slot assignments in memory for the duration of a planning
session and flag over-capacity slots. Slot capacities come from
`AppConstants`; they are never hardcoded here.

## Files

| File | Lines | Role |
|------|------:|------|
| `day_planner_cubit.dart` | 75 | `DayPlannerCubit` — assign/remove items per slot; emits `slotLimitWarning` when a slot is over capacity but never blocks the assignment |
| `day_planner_state.dart` | 42 | `DayPlannerState` — the three slot lists plus the `slotLimitWarning` flag |

## Conventions in this slice

- **In-memory only.** Slot assignments are deliberately *not* persisted to
  Isar — a plan is a session, not a stored entity.
- **Ephemeral factory**, never a singleton: closing the planner discards
  the session.
- **The slot limit is a soft constraint** (CONTEXT.md decision). Going over
  raises `slotLimitWarning` for the UI to render a banner; the assignment
  still succeeds.

## Upstream dependencies

`domain/tasks/item.dart` · `core/constants/app_constants.dart` (slot
capacities).
