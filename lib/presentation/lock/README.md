# presentation/lock

Presentation slice for the **app lock** (DATA-05): the layer that covers the
app, the PIN lock screen and the shared keypad.

## Responsibility

Cover every route, dialog and sheet with the lock screen while
`AppLockState.locked` is true, take a 4-digit PIN and hand it to
`LockScreenCubit`. Whether the app is locked, and whether a PIN is right,
is decided in `application/lock/`; nothing here reads storage.

## Layout

```
lock/
├── widgets/   LockGate (MaterialApp.builder layer: app below, lock above)
├── screens/   LockScreen (title, status line slot, dots, keypad, forgot PIN),
│              PinSetupScreen (create / change / verify / reset)
└── keypad/    PinKeypad, DigitKey, KeypadIconKey, PinDots (shared with PIN setup)
```

## Layer order (do not change)

`MaterialApp.builder` → `LockGate` → `Stack`:

1. **App** — the app Navigator, `Offstage` + `TickerMode(enabled: false)`
   while locked: not painted, not hit-testable, absent from semantics, and
   its navigation state is kept.
2. **Lock** — its own `Navigator` (inside `HeroControllerScope.none`) so
   tooltips and dialogs have an Overlay and draw above app content.

Later layers (the privacy overlay, plan 05-08) go above the lock.

## Conventions in this slice

- **Frame 1 decides.** `AppLockCubit` is seeded synchronously, so a cold
  start with a PIN never paints app content before the lock screen.
- **Locking is instant, unlocking fades** (150 ms, zero under
  `MediaQuery.disableAnimations`). The app is onstage in the unlock frame.
- **System back while locked** goes to the app Navigator (RESEARCH
  Pitfall 12, accepted): it may pop a hidden route, but the lock stays.
- **Digits never leave the cubit.** Widgets receive only the digit count.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`application/lock/` (`AppLockCubit`, `LockScreenCubit`) ·
`config/di/injection.dart` (`getIt`) · `generated/l10n/`.
