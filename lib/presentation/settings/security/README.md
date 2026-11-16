# presentation/settings/security

Settings > Security (SC-3, DATA-05, DATA-06, D-02, D-08): the PIN lock
switch and the rows that depend on it.

## Responsibility

Let the user turn the app lock on and off, change the PIN, switch
biometric unlock and choose the lock timeout from Settings. Every PIN change
goes through `PinSetupScreen` (`presentation/lock/screens/`); this nest only
opens it and confirms the outcome.

## Files

| File | Role |
|------|------|
| `security_section.dart` | `SecuritySection` — reads `SecuritySettingsCubit` from context. `SettingsSectionHeader(settingsSectionSecurity)` and the `SwitchListTile` (`Icons.lock_outline`, `lockPinToggle`, `lockPinToggleDesc`, value `state.pinEnabled`). On: when `hasDeviceCredential()` is false, `showNoDeviceLockDialog` first (Cancel aborts); then push `PinSetupScreen(mode: create)`, `pinEnabledSnack` on true. Off: `showPinDisableDialog`, then `PinSetupScreen(mode: verify)`, `pinDisabledSnack` on true. Only while the PIN is on (removed, not disabled, otherwise): Alterar PIN (`Icons.password`, chevron, `PinSetupScreen(mode: change)`, `pinChangedSnack`), `BiometricTile`, Bloquear após (`Icons.timer_outlined`, subtitle = current option, chevron, `showLockTimeoutDialog` wired to `setTimeoutSeconds`). SnackBars float |
| `biometric_tile.dart` | `BiometricTile` — nothing while availability is null or `noHardware`; `enrolled`: `SwitchListTile(Icons.fingerprint, lockBiometricToggle, lockBiometricToggleDesc)` over `biometricEnabled`, `onChanged` → `setBiometricEnabled(enabled:)`; `notEnrolled`: the same tile, OFF, `onChanged: null`, subtitle `lockBiometricNotEnrolled` |
| `timeout_dialog.dart` | `lockTimeoutLabel(l10n, seconds)` and `showLockTimeoutDialog(context, current:, onSelected:)` — a `scrollable: true` `AlertDialog(lockTimeoutDialogTitle)` with five `RadioListTile<int>` under one `RadioGroup<int>` in `LockPolicy.timeoutOptionsSeconds` order (0, 30, 60, 300, 900). Selecting calls `onSelected` and pops; the only action is Cancel |
| `no_device_lock_dialog.dart` | `showNoDeviceLockDialog` — `AlertDialog(pinNoDeviceLockTitle, pinNoDeviceLockBody)` with Cancel (false) and `FilledButton(pinNoDeviceLockContinue)` (true). Dismissal is false |
| `pin_disable_dialog.dart` | `showPinDisableDialog` — `AlertDialog(pinDisableTitle, pinDisableBody)` with Cancel (false) and an error-coloured `FilledButton(pinDisableConfirm)` (true). Dismissal is false |

## Conventions in this slice

- **No optimistic switch** (T-05-40). The value comes only from the cubit,
  which mirrors `AppLockCubit`; a cancel at any step leaves it unchanged.
- **Turning the lock off needs the current PIN** (T-05-41): the confirm
  dialog, then verify mode with the shared attempt counter.
- **Wrap, never ellipsize.** Dialog bodies and subtitles set no `maxLines`.
- **Dialogs scroll whole** at 200% text when the title and actions alone
  could outgrow a small screen (timeout dialog).
- **Honest biometrics** (D-08): the row reflects the device as of the last
  start or resume; a not-enrolled device never shows the switch ON.

## Upstream dependencies

`application/settings/` (`SecuritySettingsCubit`) ·
`application/lock/setup/` (`PinSetupMode`) · `domain/lock/`
(`BiometricAvailability`, `LockPolicy`) · `presentation/lock/screens/`
(`PinSetupScreen`) · `../widgets/` (`SettingsSectionHeader`) ·
`generated/l10n/`.
