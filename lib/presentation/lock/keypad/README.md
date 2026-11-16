# presentation/lock/keypad

The shared PIN keypad, used by the lock screen and the PIN setup screen.

## Responsibility

Draw the 3x4 keypad and the four PIN dots per UI-SPEC "PinKeypad", and
report taps. The keypad holds no digits: callers pass the count.

## Files

| File | Lines | Role |
|------|------:|------|
| `pin_keypad.dart` | 74 | `PinKeypad(digitCount, onDigit, onBackspace, onClear, enabled, leading)` — rows 1-2-3 / 4-5-6 / 7-8-9 / `leading`-0-backspace, column gap 24, row gap 16; empty 72 dp slot when `leading` is null. Backspace is disabled at 0 digits; long-press calls `onClear`. `enabled: false` disables every digit key and backspace (M3 disabled colors) but never the `leading` key |
| `keypad_key.dart` | 119 | `keypadKeySize` (72); `DigitKey` — `surfaceContainerHighest` circle, `headlineMedium` digit, selection haptic, `Semantics(button, label: '<digit>')`, M3 disabled colors (38% label, 12% fill); `KeypadIconKey` — transparent 72 dp icon key with a tooltip that names its semantics node, dimmed when `onTap` is null |
| `pin_dots.dart` | 131 | `PinDots(count, errorTick)` — four 16 dp dots, gap 16: filled `cs.primary`, empty 2 dp `cs.outline` ring; one semantics node labelled `lockDigitsEntered(count)`. A changed `errorTick` plays 300 ms of all-`cs.error` dots shaking ±8 dp over 3 cycles (`easeInOut`) with `HapticFeedback.mediumImpact`; under `MediaQuery.disableAnimations` the dots only turn `cs.error` |
| `biometric_key.dart` | 29 | `BiometricKey(onPressed)` — the bottom-left key: a `KeypadIconKey` with `Icons.fingerprint` (Android) or `Icons.face` (iOS, from `Theme.platform`), size 32, `cs.primary`, tooltip `lockBiometricToggle`. The lock screen passes it as `PinKeypad.leading` only when biometrics are offered, so `enabled: false` (cooldown) never disables it |
| `lock_status_line.dart` | 62 | `LockStatusLine(message)` — fixed 40 dp, `bodyMedium`, centered, max 2 lines, `Semantics(liveRegion: true)`: `WrongPinMessage` → `lockWrongPin` and `CheckFailedMessage` → `lockErrorGeneric` in `cs.error`, `CooldownMessage` → `lockCooldown(m:ss)` in `cs.onSurfaceVariant`; `formatCooldown(Duration)` (`m:ss`, seconds rounded up) |

## Conventions in this slice

- **Every icon-only key has a tooltip**, and the tooltip is its accessible
  name. Tooltips need an Overlay: on the lock screen it comes from the lock
  layer's own Navigator.
- **Count only.** The entered digits are never passed to these widgets.
- **Errors in `cs.error`, waits in `cs.onSurfaceVariant`.** A cooldown is
  not a failure; its countdown never uses the error color.
- **Biometrics are an alternative path; the keypad is always available.**
  The biometric key only adds a way in; it never hides or disables a digit
  key, and without biometrics its slot is an empty 72 dp box so 0 stays
  centred.
- **Reduced motion keeps the meaning.** Without the shake, the error dots
  still show for the same 300 ms.

## Upstream dependencies

`generated/l10n/` (`lockDeleteDigit`, `lockBiometricToggle`, `lockDigitsEntered`, `lockWrongPin`,
`lockCooldown`, `lockErrorGeneric`) · `application/lock/lock_screen_state.dart`
(`LockMessage`).
