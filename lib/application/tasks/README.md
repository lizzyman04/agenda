# application/tasks

Task-side cubits — everything the productivity half of the app needs in
order to turn `ItemRepository` calls into renderable state.

## Responsibility

Orchestration for tasks, projects, and the 1-3-5 day planner. No task
business rules: recurrence maths lives in `domain/tasks/recurrence_engine.dart`
and the Eisenhower quadrant is computed on `Item` itself.

## Layout

```
tasks/
├── task_list/    the filtered/searched task list, its filter, and the
│                 recurrence roll-forward on completion
├── project/      one project and its subtask rollup
└── day_planner/  the in-memory 1-3-5 planning session
```

Each leaf directory has its own README with the file/role table.

## Upstream dependencies

`domain/tasks/` (`Item`, `ItemRepository`, `RecurrenceEngine`,
`ItemType`, `EisenhowerQuadrant`) · `core/` (`Result`, `Failure`,
`AppConstants`).
