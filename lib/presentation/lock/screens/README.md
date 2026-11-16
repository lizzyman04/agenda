# presentation/lock/screens

The PIN lock screen, the PIN setup screen and the forgot-PIN flow.

## Responsibility

Render the UI-SPEC lock-screen column and forward keypad input to its own
`LockScreenCubit`. Open the D-08 biometric auto-prompt once per lock
episode. Run "Esqueci meu PIN" (D-06) through the device credential. Render
the PIN setup screen for creating, changing, turning off and resetting the
PIN over its own `PinSetupCubit`.

## Files

| File | Lines | Role |
|------|------:|------|
| `lock_screen.dart` | 150 | `LockScreen` — owns `getIt<LockScreenCubit>()` (`start` in `initState`, `close` in `dispose`). After `start` and a post-frame callback it calls `autoPromptBiometric` when `WidgetsBinding.instance.lifecycleState` is `resumed`, otherwise an `AppLifecycleListener` (disposed with the screen) does it on the next `resumed` (RESEARCH Pitfall 10). Builds the `DeviceAuthPrompt` with `lockAuthPrompt(l10n, lockBiometricReason)`. `PopScope(canPop: false)` → `Scaffold(cs.surface)` → `SafeArea` → `Center` → `SingleChildScrollView` (no overflow at 200% text) → column: 48 gap, `lock_outline` 48, `lockEnterPinTitle`, `LockStatusLine(message: state.message)` in the fixed 40 dp slot, `PinDots(count, errorTick)`, `PinKeypad(enabled: phase == ready, leading: biometricOffered ? BiometricKey(onPressed: requestBiometric) : null)` (digits disabled while loading, verifying and during a cooldown; the biometric key never is), 24 gap, `ForgotPinButton(onConfirm: cubit.confirmForgotPin, resetPage: PinSetupScreen(mode: PinSetupMode.reset))` (enabled in every phase), 32 bottom |
| `forgot_pin_button.dart` | 87 | `lockAuthPrompt(l10n, reason)` — the shared OS prompt text (`lockBiometricSheetTitle`, `lockBiometricSheetHint`, `lockUsePin`). `ForgotPinButton(onConfirm, resetPage)` — `TextButton(lockForgotPin)`, never disabled; on tap calls `onConfirm(lockAuthPrompt(l10n, lockForgotReason))` once at a time: `success` pushes `resetPage` on the enclosing (lock layer's) Navigator, `noDeviceCredential` shows `showForgotPinUnavailableDialog`, anything else (or a throw) does nothing. Never unlocks |
| `forgot_pin_dialog.dart` | 25 | `showForgotPinUnavailableDialog(context)` — `AlertDialog(lockForgotUnavailableTitle, scrollable lockForgotUnavailableBody, one TextButton(lockGotIt))`; the app stays locked (user decision 1) |
| `pin_setup_screen.dart` | 150 | `PinSetupScreen(mode)` — owns `getIt<PinSetupCubit>()` (`start(mode)` in `initState`, `close` in `dispose`). The lock-screen column without the lock icon, biometric key or forgot button: 48 gap, step title (`pinCurrentPrompt` / `pinCreatePrompt` / `pinConfirmPrompt`) in an `AnimatedSwitcher` cross-fading 150 ms (zero under `disableAnimations`), `LockStatusLine`, `PinDots`, `PinKeypad(enabled: phase == entering)`, 32 bottom. AppBar title by mode (`pinSetupTitle`, `lockChangePin`, `lockPinToggle`) with a close `IconButton(Icons.close, tooltip: cancelButton)` that pops `false`; system back also pops `false`. Reset mode: no AppBar, back ignored; on `done` it calls `AppLockCubit.unlock()` and shows a floating `pinChangedSnack` over the app. Other modes pop `true` on `done` (the caller shows its SnackBar) |

## Conventions in this slice

- **The screen owns its cubit**, created per lock episode, so digits from a
  previous episode can never survive.
- **Biometrics are an alternative path; the keypad is always available.**
  A cancelled, failed or locked-out prompt shows no message: the OS sheet
  already explained, and the keypad simply stays.
- **Forgot PIN never opens the lock.** Only `DeviceAuthResult.success`
  leads to reset mode, and only saving the new PIN unlocks. Without a
  device screen lock the app stays locked and explains the recovery.
- **Cancelling PIN setup changes nothing.** Close and back pop `false`
  before any write.

## Upstream dependencies

`application/lock/` (`LockScreenCubit`, `LockScreenState`, `AppLockCubit`,
`setup/PinSetupCubit`, `setup/PinSetupState`) ·
`domain/lock/device_auth_gateway.dart` (`DeviceAuthPrompt`) · `../keypad/` ·
`config/di/injection.dart` (`getIt`) · `generated/l10n/`.
