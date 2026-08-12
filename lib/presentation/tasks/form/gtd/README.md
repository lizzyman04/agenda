# presentation/tasks/form/gtd

The **GTD clarification guide** — a self-contained sub-slice of the task
form that walks the user through "is this actionable, can it be delegated,
how important is it" and returns the answers as task field values.

## Responsibility

Model the decision tree as data and produce a `GtdResult`. This directory
owns no widgets: `screens/` renders the sheet and `widgets/` renders the
node specs this directory emits.

## Layout

```
gtd/
├── (this directory)  the tree: models, answers, context, three spec halves
├── screens/          the guide sheet — history, controllers, result
└── widgets/          node renderers and sheet chrome
```

## Files

| File | Lines | Role |
|------|------:|------|
| `gtd_models.dart` | 120 | `GtdNode` enum, `GtdResult`, the `GtdNodeSpec` union (`GtdOptionSpec`/`GtdTextSpec`/`GtdReviewSpec`), the `GtdOpt` record, and the main-path list that drives the progress bar |
| `gtd_answers.dart` | 69 | `GtdAnswers` — deliberately mutable; the tree writes to it as the user answers |
| `gtd_tree_actions.dart` | 41 | `GtdTreeContext` — the callbacks the tree may invoke (`push`, `endWithSnackbar`, `abandon`), with no knowledge of widgets or navigation |
| `gtd_tree_clarify.dart` | 142 | The *clarify* half, q1–q4b: is it actionable, is it delegable, is it a two-minute job |
| `gtd_tree_prioritize.dart` | 98 | The *prioritise* half, q5 through review: importance and impact |
| `gtd_tree_scheduling.dart` | 92 | The two questions whose options are computed rather than fixed — the deadline choice (relative to today) and the impact scale |

## Conventions in this slice

- **The tree contains no widgets.** `clarifySpec` and `prioritizeSpec` are
  pure functions from `(GtdNode, GtdTreeContext)` to a `GtdNodeSpec` —
  data describing what to ask. The sheet turns specs into widgets. That is
  what makes the flow unit-testable: `test/presentation/tasks/
  gtd_decision_tree_test.dart` walks every node and asserts on state
  transitions without pumping a single frame.
- **The tree never navigates.** It calls into `GtdTreeContext`; only the
  sheet touches `Navigator`.
- **Every node must resolve in exactly one half.** The "every node
  resolves" test fails if a node has no spec, or if both halves claim it.

## Adding a question

1. Add the node to `GtdNode` in `gtd_models.dart`.
2. Add its case to whichever half owns it — clarify or prioritise.
3. If it belongs on the happy path, add it to `gtdMainPath` so the
   progress bar counts it.
4. No rendering change is needed unless the question needs a new *kind* of
   input, in which case add a `GtdNodeSpec` subtype and a matching widget
   in `widgets/`.

## Upstream dependencies

`domain/tasks/` (`Priority`, `SizeCategory` — the values a `GtdResult`
carries) · `generated/l10n/`. No cubit, no repository.
