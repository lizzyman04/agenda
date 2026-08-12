# presentation/tasks/form/gtd/screens

The GTD guide's single route-level widget.

## Responsibility

Own everything the decision tree deliberately does not: the navigation
history stack, the text controllers, the accumulated `GtdAnswers`, and the
`Navigator.pop` that returns the `GtdResult`.

## Files

| File | Lines | Role |
|------|------:|------|
| `gtd_guide_sheet.dart` | 139 | `GtdGuideSheet` — walks the user through clarification; resolves each `GtdNode` to a spec, renders it via the node widgets, and pops a `GtdResult` |

## Conventions in this slice

- **Controllers live on the sheet, not on nodes.** The sheet outlives
  individual nodes, so text typed at q1 survives navigating back and forth.
- **The guide returns a value, it does not mutate.** The sheet builds a
  `GtdResult` and returns it via `Navigator.pop`; the task form applies it
  to its own controllers. Nothing inside the guide touches a cubit.
- **This is the only file in the guide that knows `Navigator` exists.**
  The tree signals intent through `GtdTreeContext`.

## Upstream dependencies

`../` (`GtdNode`, `GtdNodeSpec`, `GtdAnswers`, `GtdTreeContext`, the two
spec halves) · `../widgets/` (node renderers and sheet chrome) ·
`generated/l10n/`.
