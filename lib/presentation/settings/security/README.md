# presentation/settings/security

Settings > Security (SC-3, DATA-05, DATA-06, D-02, D-08): the PIN lock
switch and the rows that depend on it.

## Responsibility

Let the user turn the app lock on and off from Settings. Every PIN change
goes through `PinSetupScreen` (`presentation/lock/screens/`); this nest only
opens it and confirms the outcome.

## Files

| File | Role |
|------|------|
| `security_section.dart` | `SecuritySection` — reads `SecuritySettingsCubit` from context. `SettingsSectionHeader(settingsSectionSecurity)` and the `SwitchListTile` (`Icons.lock_outline`, `lockPinToggle`, `lockPinToggleDesc`, value `state.pinEnabled`). On: push `PinSetupScreen(mode: create)`, `pinEnabledSnack` on true. Off: `showPinDisableDialog`, then `PinSetupScreen(mode: verify)`, `pinDisabledSnack` on true. SnackBars float |
| `pin_disable_dialog.dart` | `showPinDisableDialog` — `AlertDialog(pinDisableTitle, pinDisableBody)` with Cancel (false) and an error-coloured `FilledButton(pinDisableConfirm)` (true). Dismissal is false |

## Conventions in this slice

- **No optimistic switch** (T-05-40). The value comes only from the cubit,
  which mirrors `AppLockCubit`; a cancel at any step leaves it unchanged.
- **Turning the lock off needs the current PIN** (T-05-41): the confirm
  dialog, then verify mode with the shared attempt counter.
- **Wrap, never ellipsize.** Dialog bodies and subtitles set no `maxLines`.

## Upstream dependencies

`application/settings/` (`SecuritySettingsCubit`) ·
`application/lock/setup/` (`PinSetupMode`) · `presentation/lock/screens/`
(`PinSetupScreen`) · `../widgets/` (`SettingsSectionHeader`) ·
`generated/l10n/`.
