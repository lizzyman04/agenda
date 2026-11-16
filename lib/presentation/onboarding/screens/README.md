# presentation/onboarding/screens

The privacy statement page.

## Responsibility

Lay out the UI-SPEC column (hero icon, headline, intro, four bullets) in both
modes. The page holds no persistence logic: the first-launch caller passes
`onGetStarted`, and the page only disables its button while that runs.

## Files

| File | Lines | Role |
|------|------:|------|
| `privacy_statement_screen.dart` | 132 | `PrivacyStatementScreen` — first launch (`readOnly` false): language switch on top of the scroll view and a pinned "Começar" button that calls `onGetStarted` and is disabled while it runs (no double write). Read-only (D-14): `AppBar` titled `settingsPrivacyLabel` with the default back arrow, no switch, no button. The private `_StatementContent` is shared by both modes |

## Conventions in this slice

- **Persist first, then transition.** The page never navigates on its own;
  the gate decides, and only after the flag write succeeded.
- **Scroll, never overflow.** The content sits in a `SingleChildScrollView`
  above the pinned button, so 200% text on a 320x568 viewport scrolls and the
  button stays visible.

## Upstream dependencies

`../widgets/` (`PrivacyBullet`, `PrivacyLanguageSwitch`) · `generated/l10n/`.
