---
phase: "05"
review: 05-REVIEW.md
created: "2026-11-17"
---

# Phase 05 — Review Disposition

| Finding | Severity | Disposition | Note |
|---------|----------|-------------|------|
| CR-01 | critical | open | Forgot-PIN reset screen survives background trips, so the timeout never re-checks the devi |
| WR-01 | warning | open | Forgot-PIN accepts any biometric, including Class-2 "weak" face unlock, even when the user |
| WR-02 | warning | open | App SnackBars, including working "Undo" actions, render on top of the lock screen |
| WR-03 | warning | open | Locking again during the unlock fade leaves the lock screen stuck in `verifying` (keypad a |
| WR-04 | warning | open | Closing PIN setup during `saving` or `verifying` pops `false`, but the enable or disable s |
| WR-05 | warning | open | A non-bool `pin_configured` locks the app but leaves the native shield off |
| IN-01 | info | open | The PIN switch can push two setup screens; a second "create" overwrites the PIN without as |
| IN-02 | info | open | Language switch drops the `setLocale` future |
