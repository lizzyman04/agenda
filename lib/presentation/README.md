# presentation

The **presentation layer** — every screen, widget, sheet, and dialog the
user actually touches.

## Responsibility

Rendering and user interaction. This layer reads state from cubits in
`application/` and calls their methods; it holds no business rules and
talks to no repository except through a cubit or an explicitly documented
form-logic helper.

## Layout

```
presentation/
├── tasks/    the productivity half: list, detail, planner, matrix, form
└── finance/  the money half: dashboard, transactions, budgets, debts,
              recurring payments, savings goals
```

Both slices are documented by their own READMEs, one per directory.

## Conventions across the layer

- **Screens own state; widgets do not.** A widget takes plain data plus
  callbacks, so it renders in isolation and in a widget test.
- **Sheets and dialogs own their controllers.** A sheet body is a
  `StatefulWidget` that creates its `TextEditingController`s in the State
  and disposes them in `State.dispose()`. Creating one in the caller's
  method scope and disposing it after `await showModalBottomSheet` disposes
  it mid-dismiss-animation and crashes — this shipped twice (see
  `finance/goals/README.md` for the full post-mortem).
- **Sheets pop a value, they do not mutate.** The caller awaits the popped
  result and then calls the cubit, never the other way round.
- **Form logic is extracted to plain function files.** Load and save logic
  for a form lives beside its slice as a `*_form_logic.dart` file so it can
  be unit-tested without pumping a frame.
- **One file, one screen-sized responsibility.** Every hand-written file
  here is at or under the 150-line architecture cap
  (`dart run tool/check_architecture.dart`).
- **UI strings come from `generated/l10n/`**, never inline literals, except
  for the handful of dev-default constants documented in place.

## Upstream dependencies

`application/` (cubits and states) · `domain/` (entities and enums) ·
`core/` (formatters, parsers, colour constants) · `generated/l10n/`
(localisations) · `config/di/injection.dart` (`getIt`, for screens that
construct their own cubit).
