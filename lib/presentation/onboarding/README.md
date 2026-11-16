# presentation/onboarding

Presentation slice for the **first-launch privacy statement** (UX-03).

## Responsibility

Show the one-screen privacy statement once per install, before any main UI,
and let Settings > About re-open the same statement read-only. The statement
promises only what the app does: on-device storage, no account, no tracking
and no cloud backup. It makes no encryption claim (the Isar database is not
encrypted at rest; the optional PIN is a privacy gate).

## Layout

```
onboarding/
├── screens/   PrivacyStatementScreen (first-launch and read-only modes)
└── widgets/   OnboardingGate (root gate), PrivacyBullet, PrivacyLanguageSwitch
```

## Conventions in this slice

- **Persist first, then transition.** "Começar" writes
  `StorageKeys.privacyStatementShown`; only a successful write swaps in the
  shell. A failed or throwing write leaves the statement on screen.
- **The flag is read synchronously.** `SharedPreferences` is pre-resolved in
  DI, so a later launch builds the shell on the very first frame.
- **No Isar-backed cubit starts under the statement.** `app.dart` places the
  task cubits inside the gate's child.
- Each subdirectory carries its own README (architecture guard).

## Upstream dependencies

`application/shared/locale/` (`LocaleCubit`) · `core/constants/`
(`StorageKeys`) · `config/di/injection.dart` (`getIt`) · `generated/l10n/`.
