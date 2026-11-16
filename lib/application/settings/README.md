# application/settings

State for the Settings screen sections that own preferences (SC-3, DATA-05,
DATA-06, D-02, D-08). The language row uses the app-wide `LocaleCubit` in
`application/shared/locale/`; this nest holds the Security section.

## Responsibility

Mirror whether the app-lock PIN is on, report what biometric unlock the
device can offer, and persist the biometric and lock-timeout preferences.
PIN writes stay in `application/lock/setup/` (`PinLifecycle`); this nest
never enables or disables the lock itself.

## Files

| File | Role |
|------|------|
| `security_settings_state.dart` | `SecuritySettingsState(pinEnabled, availability, biometricEnabled, timeoutSeconds)` (Equatable) with `copyWith`. Defaults: PIN off, availability null (unknown), biometrics on (D-08), 60 s (D-02) |
| `security_settings_cubit.dart` | `SecuritySettingsCubit(SharedPreferences, AppLockCubit, DeviceAuthGateway)` (`@injectable`, one per Settings screen). Seeds from `AppLockCubit.state` and prefs (a throwing read is the default). `start()` follows `AppLockCubit.stream` (re-reading the biometric preference, which `disable()` removes) and calls `refreshAvailability()`; `refreshAvailability()` (a failed check is `noHardware`); `hasDeviceCredential()` (a failure is false); `setBiometricEnabled(enabled:)` and `setTimeoutSeconds(int)` persist first and emit only after a successful write; a timeout outside `LockPolicy.timeoutOptionsSeconds` is ignored |

## Conventions in this slice

- **The switch never lies** (T-05-40). `pinEnabled` only mirrors
  `AppLockCubit`, which `PinLifecycle` updates after `pin_configured` is
  written. There is no setter for it here.
- **Persist, then emit.** A failed write leaves the screen unchanged.
- **Fail to defaults.** Unreadable prefs mean PIN off, 1 min, biometrics on.

## Upstream dependencies

`application/lock/` (`AppLockCubit`) · `domain/lock/` (`DeviceAuthGateway`,
`LockPolicy`) · `core/constants/storage_keys.dart` · `core/utils/guarded.dart`.
