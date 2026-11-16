# presentation/onboarding/widgets

The first-launch gate and the statement's building blocks.

## Responsibility

Decide whether the statement or the main UI is the root, and render the
statement's bullets and language switch.

## Files

| File | Lines | Role |
|------|------:|------|
| `onboarding_gate.dart` | 62 | `OnboardingGate` — reads `privacyStatementShown` synchronously in `initState` (null or a throw means not shown); builds `child` when shown, else `PrivacyStatementScreen(onGetStarted: _accept)`. `_accept` awaits `setBool` and transitions only when it returned true and the gate is still mounted |
| `privacy_bullet.dart` | 25 | `PrivacyBullet` — icon (24, `onSurfaceVariant`) plus `Expanded` `bodyLarge` text; no `maxLines`, no ellipsis, so long translations wrap |
| `privacy_language_switch.dart` | 41 | `PrivacyLanguageSwitch` — `SegmentedButton<Locale>` "Português" / "English" that calls `LocaleCubit.setLocale`. The labels are literal endonym constants, not the l10n `languageNamePtBr` / `languageNameEn` keys, because `languageNamePtBr` reads "Português (Brasil)" |

## Conventions in this slice

- **Persist first, then transition.** A false or throwing write keeps the
  statement up; the app never enters the shell with the flag unset.
- **The gate swaps its own subtree** instead of pushing a route, so the
  statement is the navigator root and no route leads back to it.

## Upstream dependencies

`application/shared/locale/` (`LocaleCubit`) · `core/constants/`
(`StorageKeys`) · `config/di/injection.dart` (`getIt`) · `../screens/`.
