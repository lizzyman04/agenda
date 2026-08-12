# presentation/tasks

Presentation slice for the **productivity half** of the app: the task
list, task detail, projects, the Eisenhower matrix, the 1-3-5 day planner,
the GTD context filter, and the create/edit form.

## Responsibility

Rendering and interaction for tasks only. Task rules live in
`domain/tasks/`; orchestration lives in `application/tasks/`.

## Layout

```
tasks/
├── screens/   route-level widgets; each owns (or reads) a cubit
├── widgets/   presentation-only pieces shared across those screens
│   └── detail/  the task detail screen's cards and chips
└── form/      the create/edit form and its GTD clarification guide —
                a self-contained sub-slice with its own README
```

Every subdirectory has its own README with a file/role table.

## Conventions in this slice

- **Screens own cubits; widgets never do.** Widgets take `Item`s and
  callbacks.
- **Cards render nothing when they have nothing to show**, so callers can
  place them unconditionally in a `Column` instead of branching.
- **The form is a sub-slice, not a screen.** It has its own layout rules
  (see `form/README.md`) because the GTD guide is large enough to warrant
  them.

## Upstream dependencies

`application/tasks/` (`TaskListCubit`, `ProjectCubit`, `DayPlannerCubit`
and their states) · `domain/tasks/` (`Item`, `Priority`, `SizeCategory`,
`ItemType`, `EisenhowerQuadrant`, `ItemRepository` for the GTD context
query) · `domain/finance/` (goal/debt linking) · `generated/l10n/` ·
`config/di/injection.dart`.
