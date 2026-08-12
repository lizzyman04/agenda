# presentation/tasks/form/gtd/widgets

The renderers for the GTD guide: one widget per `GtdNodeSpec` subtype,
plus the sheet's chrome.

## Responsibility

Turn a spec into pixels. Nothing here decides *what* to ask — that is the
tree's job in `../` — and nothing here navigates.

## Files

| File | Lines | Role |
|------|------:|------|
| `gtd_option_node.dart` | 80 | Renders a `GtdOptionSpec`: question heading plus a card of tappable options |
| `gtd_text_node.dart` | 62 | Renders a `GtdTextSpec`: question heading, text field, Next button |
| `gtd_review_node.dart` | 143 | Terminal step: a summary of everything the tree decided, with go-back-and-edit or save |
| `gtd_sheet_header.dart` | 83 | Drag handle, back/close control, and the progress bar over the tree's main path |
| `gtd_sheet_scaffold.dart` | 61 | Sheet sizing, the scroll view, and the slide/fade transition between nodes |
| `gtd_atoms.dart` | 88 | `GtdIconBox`, `GtdReviewRow`, `GtdRowDivider` — the smallest shared chrome, grouped because none is meaningful alone |
| `gtd_cancel_dialog.dart` | 30 | Discard-confirmation dialog; returns `true` when the user chooses to discard, and the caller owns the actual abandon |

## Conventions in this slice

- **One widget per spec subtype.** Adding a new kind of question means
  adding a `GtdNodeSpec` subtype in `../gtd_models.dart` and a matching
  widget here — never a conditional inside an existing renderer.
- **Chrome is separate from content.** The scaffold owns sizing and the
  inter-node transition; a node widget renders only its own question, so
  the transition is defined once.
- **Dialogs return, they do not act.** `gtd_cancel_dialog.dart` answers a
  question; the sheet performs the abandon.

## Upstream dependencies

`../gtd_models.dart` (the spec types) · `generated/l10n/`.
