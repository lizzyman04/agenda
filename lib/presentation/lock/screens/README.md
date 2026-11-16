# presentation/lock/screens

The PIN lock screen.

## Responsibility

Render the UI-SPEC lock-screen column and forward keypad input to its own
`LockScreenCubit`. Open the D-08 biometric auto-prompt once per lock
episode.

## Files

| File | Lines | Role |
|------|------:|------|
| `lock_screen.dart` | 145 | `LockScreen` — owns `getIt<LockScreenCubit>()` (`start` in `initState`, `close` in `dispose`). After `start` and a post-frame callback it calls `autoPromptBiometric` when `WidgetsBinding.instance.lifecycleState` is `resumed`, otherwise an `AppLifecycleListener` (disposed with the screen) does it on the next `resumed` (RESEARCH Pitfall 10). Builds the `DeviceAuthPrompt` from l10n (`lockBiometricReason`, `lockBiometricSheetTitle`, `lockBiometricSheetHint`, `lockUsePin`). `PopScope(canPop: false)` → `Scaffold(cs.surface)` → `SafeArea` → `Center` → `SingleChildScrollView` (no overflow at 200% text) → column: 48 gap, `lock_outline` 48, `lockEnterPinTitle`, `LockStatusLine(message: state.message)` in the fixed 40 dp slot, `PinDots(count, errorTick)`, `PinKeypad(enabled: phase == ready, leading: biometricOffered ? BiometricKey(onPressed: requestBiometric) : null)` (digits disabled while loading, verifying and during a cooldown; the biometric key never is), 32 bottom |

## Conventions in this slice

- **The screen owns its cubit**, created per lock episode, so digits from a
  previous episode can never survive.
- **Biometrics are an alternative path; the keypad is always available.**
  A cancelled, failed or locked-out prompt shows no message: the OS sheet
  already explained, and the keypad simply stays.
- The forgot-PIN button arrives with its flow (plan 05-12).

## Upstream dependencies

`application/lock/` (`LockScreenCubit`, `LockScreenState`) ·
`domain/lock/device_auth_gateway.dart` (`DeviceAuthPrompt`) · `../keypad/` ·
`config/di/injection.dart` (`getIt`) · `generated/l10n/`.
