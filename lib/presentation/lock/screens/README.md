# presentation/lock/screens

The PIN lock screen.

## Responsibility

Render the UI-SPEC lock-screen column and forward keypad input to its own
`LockScreenCubit`.

## Files

| File | Lines | Role |
|------|------:|------|
| `lock_screen.dart` | 97 | `LockScreen` — owns `getIt<LockScreenCubit>()` (`start` in `initState`, `close` in `dispose`). `PopScope(canPop: false)` → `Scaffold(cs.surface)` → `SafeArea` → `Center` → `SingleChildScrollView` (no overflow at 200% text) → column: 48 gap, `lock_outline` 48, `lockEnterPinTitle`, `LockStatusLine(message: state.message)` in the fixed 40 dp slot, `PinDots(count, errorTick)`, `PinKeypad(enabled: phase == ready)` (disabled while loading, verifying and during a cooldown), 32 bottom |

## Conventions in this slice

- **The screen owns its cubit**, created per lock episode, so digits from a
  previous episode can never survive.
- The forgot-PIN button and biometric key arrive with their flows
  (plans 05-12 and 05-11).

## Upstream dependencies

`application/lock/` (`LockScreenCubit`, `LockScreenState`) · `../keypad/` ·
`config/di/injection.dart` (`getIt`) · `generated/l10n/`.
