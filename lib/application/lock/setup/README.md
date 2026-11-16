# application/lock/setup

Creating, changing, disabling and resetting the app-lock PIN (DATA-05,
D-06, D-07).

## Responsibility

Own the PIN lifecycle writes and the keypad logic of the PIN setup screen.
Verifying a PIN on the lock screen stays in `../pin_verifier.dart`; this nest
reuses that verifier for the "current PIN" step so both screens share one
persisted attempt counter. Nothing here renders UI; the screen lives in
`presentation/lock/screens/pin_setup_screen.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `pin_lifecycle.dart` | 91 | `PinLifecycle(PinStore, PinHasher, prefs, SecureWindowGateway, AppLockCubit)` (`@lazySingleton`) — `enable(pin)`: new record + `LockAttempts.none`, `setSecure(true)`, then `pin_configured = true` LAST; a failed flag write clears the store and calls `setSecure(false)`; success calls `AppLockCubit.pinEnabledChanged(enabled: true)`. `change(pin)` / `reset(pin)`: record + `LockAttempts.none` (reset does not unlock). `disable()`: `pin_configured = false` FIRST (a failure changes nothing), `setSecure(false)`, `store.clear()` (an `Err` is tolerated), removes `biometric_unlock_enabled`, `pinEnabledChanged(enabled: false)`. Never throws |
| `pin_setup_state.dart` | 128 | `PinSetupMode` (`create`, `change`, `verify`, `reset`), `PinSetupStep` (`current`, `create`, `confirm`), `PinSetupPhase` (`entering`, `verifying`, `coolingDown`, `saving`, `done`); `PinSetupState(mode, step, phase, digitCount, message, errorTick)` with `PinSetupState.initial(mode)` (current step for change and verify), `copyWith`, `ask(step, message:, bump:)`, `cooling(left, tick)` and `busy(phase)` — the digit COUNT only |
| `pin_setup_cubit.dart` | 148 | `PinSetupCubit(PinLifecycle, PinVerifier, {clock})` (`@injectable`, one per setup screen) — `start(mode)`; `addDigit` / `removeDigit` / `clearDigits` act only while `entering`. Create step: the 4th digit keeps the entry privately and asks for `confirm`. Confirm: a match saves through `enable` / `change` / `reset` by mode (`done` on true, `CheckFailedMessage` and back to create on false); a mismatch shows `MismatchMessage`, bumps `errorTick` and returns to create. Current step (change, verify): `PinVerifier.verify(pin, clock())`, the SAME persisted counter as the lock screen (D-07) — `PinVerified` → create step (change) or `disable()` then `done` (verify); `PinRejected` → `WrongPinMessage`; `PinCheckFailed` or a throw → `CheckFailedMessage`; `PinCoolingDown` → `coolingDown` driven by a `CooldownTicker`, input ignored until it ends. `close()` cancels the ticker |

## Conventions in this slice

- **Write order makes a half-enabled lock impossible.** Enabling writes the
  secure record first and the `pin_configured` flag last, rolling back when
  the flag write fails; disabling writes the flag first. A crash between
  steps leaves either "off" or a fully working lock.
- **Nothing changes before the final step.** Closing the setup screen at any
  step before the save writes nothing.
- **A new PIN never inherits a cooldown.** Every new record is written with
  `LockAttempts.none`.
- **Never log PIN material**, and never put digits in state.

## Upstream dependencies

`../app_lock_cubit.dart` · `../pin_verifier.dart` · `../lock_screen_state.dart`
(`LockMessage`) · `domain/lock/` (`PinStore`, `PinHasher`,
`SecureWindowGateway`, `LockAttempts`) · `core/utils/guarded.dart` ·
`core/constants/storage_keys.dart`.
