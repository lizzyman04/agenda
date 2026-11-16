# Phase 5: App Lock + Settings + Polish - Context

**Gathered:** 2026-11-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Optional 4-digit PIN app lock with biometric unlock, a unified Settings screen (language, security, notifications, data, about), and a one-time first-launch privacy statement. Covers DATA-05, DATA-06, UX-01, UX-03, plus final polish (empty states, smoke test, release build validation) per ROADMAP plan 05-04. No dark theme, no new data features.

</domain>

<decisions>
## Implementation Decisions

### Lock timing
- **D-01:** Lock applies on **cold start AND on resume from background** after a timeout. Timeout persisted in `StorageKeys.lockTimeoutSeconds`.
- **D-02:** Default timeout **1 minute**, user-configurable in Settings: immediate, 30 s, 1 min, 5 min, 15 min.
- **D-03:** App-initiated excursions (file_picker for backup export/import, OS permission dialogs, local_auth prompt itself) **do not trigger a lock** on return. Needs a "suppress next lock" guard around those calls.
- **D-04:** When PIN is enabled, app content is **hidden in the app switcher**: privacy overlay on `AppLifecycleState.inactive`/`hidden`; on Android also `FLAG_SECURE` (blocks screenshots). When PIN is disabled, no overlay and no FLAG_SECURE.

### PIN and biometrics
- **D-05:** PIN is **4 digits**. Stored only as a salted hash in `flutter_secure_storage` — never plain, never in SharedPreferences (`StorageKeys.pinConfigured` is a non-secret flag only).
- **D-06:** "Forgot PIN" → device credential check via `local_auth` (biometric or device PIN/pattern, `biometricOnly: false`). On success user sets a new PIN; data is kept. — **Reversibility:** reversible — policy only.
- **D-07:** Failed attempts: after **5 wrong PINs**, escalating cooldown **30 s → 1 min → 5 min → 15 min** (capped). Attempt count and cooldown end persist across app kills (secure storage), so killing the app does not reset them.
- **D-08:** Biometric prompt **auto-opens** when the lock screen appears; cancel falls back to PIN keypad. A **biometrics toggle** in Settings, default ON when the device supports enrolled biometrics, hidden/disabled otherwise.

### Settings screen
- **D-09:** Entry point is a **gear icon in the AppBar**, replacing the temporary Phase 4 menu (`lib/presentation/tasks/widgets/task_list_settings_menu.dart`). Not a shell tab.
- **D-10:** Single scrollable list with sections, in order: **General** (language), **Security** (PIN on/off/change, biometrics toggle, lock timeout), **Notifications** (row opening existing `NotificationSettingsScreen`, per D-09 of Phase 4), **Data** (row opening existing `BackupScreen`), **About** (privacy statement re-read, app version).
- **D-11:** Language picker has **two options only**: Português (Brasil) / English, applied instantly via existing `LocaleCubit.setLocale`. No "follow system" option.

### First-launch privacy statement
- **D-12:** **One screen**, shown once before main UI (gated by `StorageKeys.privacyStatementShown`): headline "Seus dados nunca saem deste aparelho" / "Your data never leaves this device", a language switch at the top, short bullets, and a "Começar"/"Get started" button that sets the flag.
- **D-13:** Bullets: (1) works offline, no account; (2) no analytics or crash reporting; (3) no cloud backup — export a JSON backup to keep your data safe (ties to Phase 4 D-13 `allowBackup=false`); (4) optional PIN available in Settings.
- **D-14:** Same screen reachable read-only from **Settings > About**.

### Claude's Discretion
- Lock screen UI details (use `flutter_screen_lock` or a custom keypad if it fits better with cooldown display).
- PIN hash algorithm/salt (e.g. PBKDF2/SHA-256 with random salt) and secure-storage key names.
- Where the lock gate sits in the widget tree (above `AppShell`, below `MaterialApp`) given there is no GoRouter — routing is Navigator + `AppShell`.
- Behaviour when the device has no screen-lock credential (forgot-PIN unavailable): warn at PIN setup to keep a JSON backup.
- Ordering on first launch: privacy statement first; PIN cannot exist yet, so no conflict.
- Scope of final polish (05-04): remaining empty states, smoke test, release build check.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 5 — goal, success criteria, draft plan split 05-01..05-04
- `.planning/REQUIREMENTS.md` — DATA-05, DATA-06, UX-01, UX-03
- `.planning/PROJECT.md` — privacy-first constraints (no data leaves device)

### Prior decisions that constrain this phase
- `.planning/phases/04-notifications-backup/04-CONTEXT.md` — D-09 (notification settings page mounts into Settings), D-12/D-13 (backup location, allowBackup=false), D-15 (temporary settings entry point)
- `.planning/phases/01-foundation/01-CONTEXT.md` — locale default PT-BR (D-21), storage keys

### Stack notes
- `CLAUDE.md` §Security — App Lock — flutter_screen_lock 9.2.2+2, local_auth 3.0.1, flutter_secure_storage 10.0.0 (currently commented out in `pubspec.yaml`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/application/shared/locale/locale_cubit.dart`: `LocaleCubit.setLocale` + `supportedLocales` — drive the language picker and privacy-screen switch.
- `lib/core/constants/storage_keys.dart`: `privacyStatementShown`, `pinConfigured`, `lockTimeoutSeconds` already defined.
- `lib/presentation/notifications/screens/notification_settings_screen.dart`: mounted as Settings > Notifications.
- `lib/presentation/backup/screens/` (`BackupScreen`): mounted as Settings > Data.
- `lib/config/startup/notification_lifecycle_observer.dart`: existing `WidgetsBindingObserver` pattern to mirror for the lock lifecycle observer.

### Established Patterns
- Cubits registered with `@injectable` via `injectable`/GetIt; app-wide cubits provided above `MaterialApp` in `lib/app.dart` (see comment there about provider placement).
- SharedPreferences for non-sensitive prefs; secure storage required for PIN material.
- l10n via ARB + `flutter gen-l10n` (`lib/generated/l10n/`), PT-BR default.

### Integration Points
- `android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt` already extends `FlutterFragmentActivity` (local_auth requirement satisfied) — FLAG_SECURE toggle goes here or via a method channel.
- `lib/presentation/tasks/widgets/task_list_settings_menu.dart`: temporary entry to remove/replace with gear → SettingsScreen.
- `lib/presentation/backup/` and notification permission flow: wrap file_picker / permission calls with the lock-suppression guard (D-03).
- iOS: `NSFaceIDUsageDescription` in Info.plist needed.

</code_context>

<specifics>
## Specific Ideas

- Lock timeout model similar to banking apps.
- Privacy headline exact text: "Seus dados nunca saem deste aparelho" / "Your data never leaves this device".

</specifics>

<deferred>
## Deferred Ideas

- Dark theme (light/dark/system) — not in roadmap; future phase.
- "Follow system language" option — rejected for now.
- Multi-page onboarding (PIN offer, notification permission) — rejected; single screen only.

</deferred>

---

*Phase: 05-app-lock-settings-polish*
