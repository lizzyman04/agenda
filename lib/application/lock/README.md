# application/lock

App-lock state, the lock-screen keypad logic and **PIN verification**
(DATA-05, D-05, D-07).

## Responsibility

Answer each PIN attempt from persisted state: check the D-07 attempt ladder,
compare the PIN against the stored PBKDF2 record and record the outcome in
secure storage. Hashing lives in `infrastructure/lock/pbkdf2_pin_hasher.dart`,
storage in `infrastructure/lock/secure_pin_store.dart`, and the ladder itself
in `domain/lock/lock_attempts.dart`. Also own whether the app is locked
(`AppLockCubit`, seeded synchronously for frame 1) and the keypad entry
state of the lock screen (`LockScreenCubit`). Nothing here renders UI; the
lock layer lives in `presentation/lock/`.

## Files

| File | Lines | Role |
|------|------:|------|
| `app_lock_state.dart` | 32 | `AppLockState(pinEnabled, locked, obscured)` with `copyWith` |
| `app_lock_cubit.dart` | 113 | `AppLockCubit(prefs, ExcursionGuard, {@ignoreParam clock})` (`@lazySingleton`, one app-wide instance) — seeds `pinEnabled`/`locked` synchronously in the constructor from `StorageKeys.pinConfigured` (a non-bool value locks: fail closed); `unlock()`; `pinEnabledChanged(enabled:)` always leaves it unlocked; lifecycle: `onInactive()` sets `obscured` when a PIN is on, `onHidden()` records the first hidden time of a trip and whether `ExcursionGuard.isActive` then (D-03), `onResumed()` reads `StorageKeys.lockTimeoutSeconds` (default 60), asks `shouldLockOnResume` and emits ONE state (`obscured: false`, `locked` if due) |
| `lock_screen_state.dart` | 98 | `LockEntryPhase` (`loading`, `ready`, `verifying`, `coolingDown`); the status-line model `LockMessage` (`WrongPinMessage(remaining)`, `CooldownMessage(remaining)`, `CheckFailedMessage`); `LockScreenState(phase, digitCount, message, errorTick)` — the digit COUNT only, never the digits; `errorTick` increments on every rejected entry (the dots shake on change) |
| `lock_screen_cubit.dart` | 147 | `LockScreenCubit` (`@injectable`, one per lock screen) — keeps the digits in a private field; `start()` loads attempts: a running cooldown enters `coolingDown` at once, an `Err` or throw shows `CheckFailedMessage` in `ready`; `addDigit` clears any message and auto-submits the 4th digit once to `PinVerifier.verify(digits, clock())`; only `PinVerified` calls `AppLockCubit.unlock()`. `PinRejected(n)` → `WrongPinMessage(n)`, `PinCheckFailed` or an exception → `CheckFailedMessage`, `PinCoolingDown` → `coolingDown` with a `Timer.periodic(1 s)` countdown that ends in `ready`; each bumps `errorTick`. Input acts only in `ready`; `close()` cancels the ticker |
| `pin_verifier.dart` | 102 | `PinVerifyOutcome` (`PinVerified`, `PinRejected(remaining)`, `PinCoolingDown(attempts)`, `PinCheckFailed`) and `PinVerifier` — `verify(pin, now)` checks format, cooldown, record and hash, and persists the new attempt state before answering; `loadAttempts`; `resetAttempts` |

## Conventions in this slice

- **Persist attempts before revealing a result.** A wrong PIN's new attempt
  state is awaited into secure storage before `PinRejected` or
  `PinCoolingDown` is returned, so killing the app mid-verify cannot erase a
  counted failure. During a cooldown nothing is hashed or counted.
- **Fail closed.** A malformed PIN, a missing or malformed record, or any
  storage `Err` yields `PinCheckFailed`, never `PinVerified`. Recovery is the
  forgot-PIN flow, not an open lock.
- **Lock only after `hidden`.** `inactive` alone (notification shade,
  biometric sheet) never locks; background time uses the injected wall
  clock and a clock moved back locks.
- **A cooldown is read, never remembered.** The countdown is recomputed
  from the persisted `LockAttempts.cooldownRemaining(clock())` on every
  tick, and `start()` resumes a running cooldown before accepting input, so
  killing the app cannot reset or shorten the wait (T-05-26).
- **Never log PIN material.** No PIN, record, salt or hash appears in a log,
  exception or failure message; failures carry the exception type only.

## Upstream dependencies

`domain/lock/` (`LockAttempts`, `PinHasher`, `isValidPin`, `PinStore`) ·
`core/failures/` (`Result`) · `domain/lock/lock_policy.dart` (`shouldLockOnResume`) · `domain/lock/excursion_guard.dart`.
