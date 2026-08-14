# application/finance/recurring

Owns the **recurring payments** list — subscriptions, rent, and anything
else on a fixed cycle.

## Responsibility

Load, create, update and soft-delete recurring payments. The cycle itself
and the next-due-date maths are domain concepts
(`domain/finance/recurring/`).

## Files

| File | Lines | Role |
|------|------:|------|
| `recurring_payment_cubit.dart` | 76 | `RecurringPaymentCubit` — `start`, `createPayment`, `updatePayment`, `softDelete`, each followed by a reload |
| `recurring_payment_state.dart` | 41 | Sealed state family: Initial / Loading / Loaded / Error |

## Conventions in this slice

- **The one non-reactive list cubit.**
  `RecurringPaymentRepository` exposes no `watchChanges()` stream, so this
  cubit loads on demand via `start()` and reloads explicitly after each
  mutation. That is a deliberate, documented exception to the "list cubits
  subscribe" rule in `../README.md` — not an oversight. If a stream is
  added to the repository later, this cubit should adopt it.
- **Factory, not singleton** — a fresh instance per screen.
- **Paused payments stay in the list.** `isActive` is a pause flag, not a
  delete flag, and the list screen owns the only control that can un-pause
  a payment. So `getPayments()` returns paused rows too — filtering them
  out here is what made pausing an irreversible hide (CR-02). The
  repository method was named `getActivePayments` until that fix; anything
  that genuinely needs unpaused rows only must filter at its own call site
  and say so.

## Upstream dependencies

`domain/finance/recurring/` (`RecurringPayment`,
`RecurringPaymentRepository`) · `core/failures/` (`Result`, `Failure`).
