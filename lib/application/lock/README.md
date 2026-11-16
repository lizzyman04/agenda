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
| `app_lock_cubit.dart` | 45 | `AppLockCubit` (`@lazySingleton`, one app-wide instance) — seeds `pinEnabled`/`locked` synchronously in the constructor from `StorageKeys.pinConfigured` (a non-bool value locks: fail closed); `unlock()`; `pinEnabledChanged(enabled:)` always leaves it unlocked |
| `lock_screen_state.dart` | 40 | `LockEntryPhase` (`loading`, `ready`, `verifying`) and `LockScreenState(phase, digitCount)` — the digit COUNT only, never the digits |
| `lock_screen_cubit.dart` | 93 | `LockScreenCubit` (`@injectable`, one per lock screen) — keeps the digits in a private field; `start()` loads attempts then accepts input; `addDigit` auto-submits the 4th digit once to `PinVerifier.verify(digits, clock())`; only `PinVerified` calls `AppLockCubit.unlock()`, any other outcome or exception clears to `ready`; `removeDigit` / `clearDigits` act only in `ready` |
| `pin_verifier.dart` | 102 | `PinVerifyOutcome` (`PinVerified`, `PinRejected(remaining)`, `PinCoolingDown(attempts)`, `PinCheckFailed`) and `PinVerifier` — `verify(pin, now)` checks format, cooldown, record and hash, and persists the new attempt state before answering; `loadAttempts`; `resetAttempts` |

## Conventions in this slice

- **Persist attempts before revealing a result.** A wrong PIN's new attempt
  state is awaited into secure storage before `PinRejected` or
  `PinCoolingDown` is returned, so killing the app mid-verify cannot erase a
  counted failure. During a cooldown nothing is hashed or counted.
- **Fail closed.** A malformed PIN, a missing or malformed record, or any
  storage `Err` yields `PinCheckFailed`, never `PinVerified`. Recovery is the
  forgot-PIN flow, not an open lock.
- **Never log PIN material.** No PIN, record, salt or hash appears in a log,
  exception or failure message; failures carry the exception type only.

## Upstream dependencies

`domain/lock/` (`LockAttempts`, `PinHasher`, `isValidPin`, `PinStore`) ·
`core/failures/` (`Result`).
