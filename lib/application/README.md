# application

The **application layer** — cubits, their states, and the pure helper
functions those cubits delegate to.

## Responsibility

Orchestration only: load from repositories, combine and shape the result,
emit a state. Business rules live in `domain/`; rendering lives in
`presentation/`. Nothing here imports Flutter widgets.

## Layout

```
application/
├── tasks/    task-side cubits (list, project, day planner)
├── finance/  finance-side cubits (transaction, budget, goal, debt,
│             recurring, dashboard)
└── shared/   cubits that belong to no single feature (locale)
```

Each leaf directory has its own README describing its files.

## Conventions across the layer

- **One directory per cubit family**, named after the thing it owns.
- **States are `sealed class ... extends Equatable`** with an
  Initial/Loading/Loaded/Error shape, in a `*_state.dart` beside the cubit.
- **Cubits never throw.** Repositories return `Result<T>`; the cubit maps
  `Err` to an `*Error` state carrying the `Failure`.
- **Pure aggregation is extracted.** Multi-source arithmetic lives in a
  plain function file (`budget_aggregator.dart`,
  `dashboard_aggregator.dart`, `task_list_reload.dart`) so it is testable
  without constructing a cubit.
- **Cubits are factories, not singletons**, unless a comment says otherwise;
  ones that subscribe to a repository stream cancel it in `close()`.

## Upstream dependencies

`domain/` (entities and repository interfaces) · `core/` (`Result`,
`Failure`, `AppConstants`, `StorageKeys`). No dependency on `data/`,
`infrastructure/`, or `presentation/`.
