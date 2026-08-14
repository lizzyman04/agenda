# presentation/tasks/widgets/detail

The **task detail screen's** body, broken into the cards and chips it is
assembled from.

## Responsibility

Render one `Item` read-only. Nothing here mutates a task; the edit and
delete actions are callbacks the screen supplies.

## Files

| File | Lines | Role |
|------|------:|------|
| `task_detail_sections.dart` | 24 | `TaskDetailBody` — the scrollable body: hero card, then the conditional info cards |
| `task_detail_hero_card.dart` | 92 | Status/priority/size chip row, title, and optional description |
| `task_detail_info_cards.dart` | 27 | `TaskDetailInfoCards` — the conditional Dates/Flags/GTD cards plus the finance chip; each child decides for itself whether it has anything to show |
| `task_detail_dates_card.dart` | 77 | Due date/time and recurrence; renders nothing when the task carries no dates |
| `task_detail_flags_gtd.dart` | 115 | `TaskDetailFlagsCard` (urgent / important / next-action) and `TaskDetailGtdCard` (context tag and waiting-for) |
| `task_detail_finance_chip.dart` | 89 | Chip linking to the goal or debt this task funds; resolves the linked entity's title via `loadFinanceLinks` so it names the goal/debt instead of showing a raw id, and renders nothing when unlinked |
| `task_detail_chips.dart` | 126 | `StatusChip`, `PriorityChip`, `SizeChip`, `FlagChip` — the small pills used by the hero and flags cards |
| `task_detail_section_card.dart` | 95 | `SectionCard` (titled card shell) and `DetailRow` (one icon/label/value line) |
| `task_detail_action_bar.dart` | 55 | Bottom delete/edit button row |

## Conventions in this slice

- **A card with nothing to show returns `SizedBox.shrink()`**, so the
  caller places it unconditionally in a `Column` instead of writing an
  `if` per card. This is why `TaskDetailInfoCards` is nine lines of layout
  and not a chain of null checks.
- **Small widgets that are never meaningful alone share a file** —
  the four chips, and the flags/GTD pair. Splitting them would produce
  30-line files and blow the ten-file directory cap for no gain.
- **Purely presentational.** No cubit, no `Navigator` calls — the action
  bar takes `onEdit`/`onDelete` callbacks. The one deliberate exception is
  `task_detail_finance_chip.dart`, which resolves `GoalRepository` and
  `DebtRepository` through `getIt` in `initState`: the chip's whole job is
  naming an entity that lives in another aggregate, and an `Item` carries
  only that entity's id. It reuses `loadFinanceLinks` from
  `presentation/tasks/form/task_form_logic.dart` rather than adding a second
  lookup. Same shape as `presentation/finance/widgets/README.md` documenting
  `transaction/transaction_form_submit.dart` as its exception.

## Upstream dependencies

`domain/tasks/` (`Item`, `Priority`, `SizeCategory`) · `domain/finance/`
(goal/debt titles for the finance chip) · `generated/l10n/`.
