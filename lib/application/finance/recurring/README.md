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
| `recurring_payment_cubit.dart` | 72 | `RecurringPaymentCubit` — `start`, `createPayment`, `updatePayment`, `softDelete`, each followed by a reload |
| `recurring_payment_state.dart` | 41 | Sealed state family: Initial / Loading / Loaded / Error |

## Conventions in this slice

- **The one non-reactive list cubit.**
  `RecurringPaymentRepository` exposes no `watchChanges()` stream, so this
  cubit loads on demand via `start()` and reloads explicitly after each
  mutation. That is a deliberate, documented exception to the "list cubits
  subscribe" rule in `../README.md` — not an oversight. If a stream is
  added to the repository later, this cubit should adopt it.
- **Factory, not singleton** — a fresh instance per screen.

## Upstream dependencies

`domain/finance/recurring/` (`RecurringPayment`,
`RecurringPaymentRepository`) · `core/failures/` (`Result`, `Failure`).
