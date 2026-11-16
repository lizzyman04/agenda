# Phase 5: App Lock + Settings + Polish - Research

**Researched:** 2026-11-16
**Domain:** Flutter app lock (PIN + biometrics), app lifecycle privacy, secure on-device storage, settings UI, first-launch gate
**Confidence:** HIGH for Dart/Android (package source read from the pub cache, resolution dry-run done, SDK source read). MEDIUM for iOS (code-only: this Linux host cannot build or run iOS).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Lock timing
- **D-01:** Lock applies on **cold start AND on resume from background** after a timeout. Timeout persisted in `StorageKeys.lockTimeoutSeconds`.
- **D-02:** Default timeout **1 minute**, user-configurable in Settings: immediate, 30 s, 1 min, 5 min, 15 min.
- **D-03:** App-initiated excursions (file_picker for backup export/import, OS permission dialogs, local_auth prompt itself) **do not trigger a lock** on return. Needs a "suppress next lock" guard around those calls.
- **D-04:** When PIN is enabled, app content is **hidden in the app switcher**: privacy overlay on `AppLifecycleState.inactive`/`hidden`; on Android also `FLAG_SECURE` (blocks screenshots). When PIN is disabled, no overlay and no FLAG_SECURE.

#### PIN and biometrics
- **D-05:** PIN is **4 digits**. Stored only as a salted hash in `flutter_secure_storage` — never plain, never in SharedPreferences (`StorageKeys.pinConfigured` is a non-secret flag only).
- **D-06:** "Forgot PIN" → device credential check via `local_auth` (biometric or device PIN/pattern, `biometricOnly: false`). On success user sets a new PIN; data is kept. — **Reversibility:** reversible — policy only.
- **D-07:** Failed attempts: after **5 wrong PINs**, escalating cooldown **30 s → 1 min → 5 min → 15 min** (capped). Attempt count and cooldown end persist across app kills (secure storage), so killing the app does not reset them.
- **D-08:** Biometric prompt **auto-opens** when the lock screen appears; cancel falls back to PIN keypad. A **biometrics toggle** in Settings, default ON when the device supports enrolled biometrics, hidden/disabled otherwise.

#### Settings screen
- **D-09:** Entry point is a **gear icon in the AppBar**, replacing the temporary Phase 4 menu (`lib/presentation/tasks/widgets/task_list_settings_menu.dart`). Not a shell tab.
- **D-10:** Single scrollable list with sections, in order: **General** (language), **Security** (PIN on/off/change, biometrics toggle, lock timeout), **Notifications** (row opening existing `NotificationSettingsScreen`, per D-09 of Phase 4), **Data** (row opening existing `BackupScreen`), **About** (privacy statement re-read, app version).
- **D-11:** Language picker has **two options only**: Português (Brasil) / English, applied instantly via existing `LocaleCubit.setLocale`. No "follow system" option.

#### First-launch privacy statement
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

**Already resolved by the approved UI-SPEC (`05-UI-SPEC.md`, binding):** custom `PinKeypad` (no `flutter_screen_lock`); lock screen and privacy overlay mounted as `Stack` layers in `MaterialApp.builder` above the Navigator child; overlay above the lock; ARB keys and copy; `AppEmptyState` promotion.

### Deferred Ideas (OUT OF SCOPE)
- Dark theme (light/dark/system) — not in roadmap; future phase.
- "Follow system language" option — rejected for now.
- Multi-page onboarding (PIN offer, notification permission) — rejected; single screen only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-05 | User can set an optional PIN to lock access to the app on cold start | Pattern 1 (lock layer in `builder` with its own Navigator), Pattern 2 (`AppLockCubit` initial state computed synchronously from pre-resolved SharedPreferences, so frame 1 is the lock), Pattern 5 (PBKDF2 on `crypto`, verified vectors), Pattern 6 (attempt ladder), secure-storage options and fresh-install wipe |
| DATA-06 | User can unlock the app using biometrics (Face ID or fingerprint) when PIN is enabled | `local_auth` 3.0.1 API read from source, Android setup (USE_BIOMETRIC, AppCompat LaunchTheme, FragmentActivity already done), iOS `NSFaceIDUsageDescription`, localized `AndroidAuthMessages`, auto-prompt only when lifecycle is `resumed`, D-03 excursion guard, privacy overlay plus native backstops (FLAG_SECURE, iOS SceneDelegate cover) |
| UX-01 | App supports English and Portuguese (user-toggled in Settings) | Existing `LocaleCubit.setLocale` and `supportedLocales` reused as is; Settings language dialog; the existing `BlocListener` already reschedules notification text on locale change |
| UX-03 | Privacy statement on first launch | `OnboardingGate` as `home` content reading `StorageKeys.privacyStatementShown` synchronously; flag write-then-transition; read-only reuse from Settings > About; `widget_test.dart` must seed the flag |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

| Directive | Impact on this phase |
|-----------|----------------------|
| No data may leave the device (no analytics, crash reporting, cloud sync) | `local_auth`, `flutter_secure_storage` and `crypto` are on-device only. No new network package. CI's "Verify offline guarantee" grep must stay green. |
| Tech stack Flutter + Isar + BLoC/Cubit + GetIt is decided | Lock and settings state are Cubits registered through `injectable`. No Riverpod, Provider or GetX. |
| Mobile only (Android + iOS) | The FLAG_SECURE and cover channel is implemented for Android and iOS only. Other platforms return a no-op. |
| 100% offline | No feature here touches the network. |
| Code in English; UI in PT-BR with EN toggle | All new strings go into ARB files (PT-BR template, `app_pt.arb` mirror, `app_en.arb`). |
| Do not use `flutter_native_timezone`, `provider`, `riverpod`, `get`, `freezed`, `mockito`, `hive`, `firebase_*`, `sentry_flutter`, `connectivity_plus`, `dio`/`http` | Nothing in this research recommends them. |
| Testing with `bloc_test` + `mocktail` (not `mockito`) | Validation Architecture uses `blocTest`, `MockCubit`, `whenListen` and mocktail fakes. |
| `equatable` for state (no `freezed`) | Lock and settings states are `sealed`/`final class ... extends Equatable`. |
| GSD workflow enforcement | Planner output is executed via `/gsd-execute-phase`. |
| **Phase 6 architecture guard (binding, enforced in CI)** `[VERIFIED: tool/check_architecture.dart:28-29, header lines 4-8]` | `const maxLinesPerFile = 150;` `const maxFilesPerDirectory = 10;` Every directory under `lib/presentation/` and `lib/application/` needs a `README.md`. |

## Summary

The codebase is closer to "lock-ready" than the roadmap's draft plans assume. `MainActivity` already extends `FlutterFragmentActivity`, and there is no GoRouter in use (`go_router` is declared in `pubspec.yaml` but imported by 0 files). The draft tasks "FlutterFragmentActivity migration" and "GoRouter PIN guard" are therefore obsolete. `StorageKeys` already defines `privacyStatementShown`, `pinConfigured` and `lockTimeoutSeconds`. SharedPreferences is `@preResolve`d before `runApp`, so the lock decision for frame 1 can be made **synchronously** in a Cubit constructor, exactly like `LocaleCubit` does today. That is how SC-1 ("lock screen before any content is visible") is guaranteed without any async gap.

The approved UI-SPEC places the lock screen and privacy overlay in `MaterialApp.builder`. Research found one hard constraint there. `builder` output sits **inside** `ScaffoldMessenger`/`Theme`/`Localizations`, but **outside** the Navigator, so it has **no `Overlay`**. The keypad's tooltips (`Tooltip` → `RawTooltip` asserts `debugCheckHasOverlay`) and the forgot-PIN `showDialog`/reset-mode push all need one. The lock layer must therefore host its own `Navigator`. The second hard constraint is the lifecycle: Flutter **stops producing frames at `hidden`/`paused`**. The privacy overlay must be painted on `inactive`. iOS snapshots for the App Switcher only *after* `sceneDidEnterBackground`, and `sceneWillResignActive` reportedly does not always fire. So the Flutter overlay needs a native iOS cover view as a backstop, toggled over the same MethodChannel that sets Android's `FLAG_SECURE`.

**Version reality check.** `local_auth` 3.0.1 and `flutter_secure_storage` 10.0.0 (the CLAUDE.md pins) resolve cleanly on the project's pinned Flutter 3.41.4 / Dart 3.11.1. The dry run selected `local_auth_android 2.0.8`, because every `local_auth_android` ≥ 2.0.9 requires Flutter ≥ 3.44. Do **not** bump to `flutter_secure_storage` 11.x (needs Dart ≥ 3.8 and is outside the decided pin). For PIN hashing, use `crypto` 3.0.7: it comes from the `dart.dev` publisher and is already in `pubspec.lock` as a transitive dependency, so it adds zero new packages. A 14-line single-block PBKDF2-HMAC-SHA256 on top of it reproduces the RFC 7914 vectors exactly (verified this session).

**Primary recommendation:** Build one `AppLockCubit` that owns `{pinEnabled, locked, obscured, attempts}` and is driven by an `AppLifecycleListener` inside a `LockGate` widget in `MaterialApp.builder`. The cubit is seeded synchronously from SharedPreferences. It decides lock-on-resume from a wall-clock `hiddenAt` timestamp and an excursion flag, and emits `obscured→locked` in **one** state change so no content frame can slip through.

## Architectural Responsibility Map

Tiers for an offline mobile app: **Flutter UI** (widgets) · **Application** (Cubits) · **Domain** (pure rules and interfaces) · **Infrastructure** (plugins and channels) · **Native host** (Kotlin/Swift) · **Device storage** (SharedPreferences, Keystore/Keychain).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lock decision (cold start, resume timeout, excursion) | Application (`AppLockCubit`) | Domain (pure `shouldLockOnResume` fn) | State machine must be unit-testable with an injected clock; the widget only forwards lifecycle events |
| Lifecycle event capture | Flutter UI (`LockGate` with `AppLifecycleListener`) | — | Mirrors the existing `NotificationLifecycleObserver`/`NotificationSettingsScreen` observer pattern |
| Lock screen, keypad, privacy overlay rendering | Flutter UI (`MaterialApp.builder` Stack) | — | UI-SPEC locked; must cover every route, dialog and sheet |
| PIN hashing and verification | Infrastructure (`Pbkdf2PinHasher`) | Domain (`PinHasher` interface) | Crypto is a replaceable implementation detail; run off the UI isolate |
| PIN hash, salt, attempts, cooldown persistence | Device storage (Keystore/Keychain via `flutter_secure_storage`) | Infrastructure (`SecurePinStore`) | D-05 and D-07 require secure storage |
| Non-secret flags (`pinConfigured`, timeout, biometrics toggle, privacy shown) | Device storage (SharedPreferences) | — | Must be readable **synchronously** before frame 1 |
| Biometric and device-credential prompts | Infrastructure (`LocalAuthGateway`) | Native (BiometricPrompt / LAContext) | Plugin wrapper behind a domain interface for mocking |
| FLAG_SECURE / iOS snapshot cover | Native host (MainActivity.kt, SceneDelegate.swift) | Infrastructure (`SecureWindowChannel`) | No pub package needed; existing `agenda/system_settings` channel pattern |
| Excursion suppression (D-03) | Infrastructure (`ExcursionGuard` singleton) | Infrastructure call sites (file picker gateway, permission service, local_auth gateway) | Guard wraps the exact calls that launch external UI |
| Settings (language, security, links) | Flutter UI + Application (`SecuritySettingsCubit`; `LocaleCubit` reused) | — | Language state already owned by `LocaleCubit`; do not duplicate it |
| First-launch privacy gate | Flutter UI (`OnboardingGate` as `home`) | Device storage (`privacyStatementShown`) | Sync read; write flag before transition |

## Standard Stack

### Core (new in this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `local_auth` | **3.0.1** (pin; 3.0.2 exists) | Biometric and device-credential auth | Official flutter.dev plugin; pre-decided in CLAUDE.md `[VERIFIED: pub.dev API + pub cache source]` |
| `flutter_secure_storage` | **10.0.0** (pin; 11.2.0 exists but needs Dart ≥3.8 and is out of the decided stack) | Store PIN hash, salt and attempt state in Keystore/Keychain | Pre-decided; 160/160 pub points, 6.3M downloads per 30 days `[VERIFIED: pub.dev API]` |
| `crypto` | **3.0.7** (promote from transitive to direct; same version already in `pubspec.lock`) | HMAC-SHA256 for PBKDF2 | Publisher `dart.dev`; adds no new package to the graph `[VERIFIED: pubspec.lock:196-203, pub.dev API]` |

Resolution dry-run on the pinned toolchain (Flutter 3.41.4 / Dart 3.11.1), run this session in a scratch copy of `pubspec.yaml`: `[VERIFIED: flutter pub get --dry-run]`

```
+ flutter_secure_storage 10.0.0 (11.2.0 available)
+ flutter_secure_storage_darwin 0.2.0 (0.4.3 available)
+ local_auth 3.0.1 (3.0.2 available)
+ local_auth_android 2.0.8 (2.3.0 available)
+ local_auth_darwin 2.0.5
+ local_auth_platform_interface 1.1.0
```

`local_auth_android` 2.0.9 through 2.3.0 declare `'flutter': '>=3.44.0'`, so pub correctly stops at 2.0.8. `local_auth_darwin` 2.0.5 declares `'flutter': '>=3.41.0'`, which the pinned 3.41.4 satisfies `[VERIFIED: pub.dev API version list]`. **Do not upgrade Flutter in this phase.** CI pins `flutter-version: "3.41.4"` `[VERIFIED: .github/workflows/ci.yml]`.

### Supporting (already present, reused)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `shared_preferences` | 2.5.5 | `pinConfigured`, `lockTimeoutSeconds`, new `biometricUnlockEnabled`, `privacyStatementShown` | Every non-secret flag, read synchronously |
| `flutter_bloc` / `bloc` | 9.1.1 / 9.2.0 | `AppLockCubit`, `SecuritySettingsCubit`, `PinSetupCubit` | All state |
| `injectable` / `get_it` | 2.7.1+4 / 9.2.1 | DI; use `@ignoreParam` for the clock param `[VERIFIED: injectable-2.7.1+4/lib/src/injectable_annotations.dart:341]` | Registration |
| `bloc_test` / `mocktail` | 10.0.0 / 1.0.5 | Tests | All cubit and widget tests |

### Not used

| Package | Reason |
|---------|--------|
| `flutter_screen_lock` | UI-SPEC decision: custom `PinKeypad` (escalating, persisted cooldown display). Keep it commented out in `pubspec.yaml`. |
| `cryptography` 2.9.0 | Viable, but 130/160 pub points, adds `ffi`, `collection` and others, and is not needed for one PBKDF2 block `[VERIFIED: pub.dev API]` |
| `flutter_windowmanager(_plus)`, `screen_protector`, `secure_application`, `privacy_screen` | Unnecessary: a ~15-line method-channel handler on each side does the job, matching the existing `agenda/system_settings` channel |
| `package_info_plus` | Version row uses `AppConfig.version` (UI-SPEC) |
| `go_router` | Declared but unused; do not introduce it now |

**Installation (edit `pubspec.yaml`, keep exact pins as the file does):**

```yaml
  # --- Phase 5 (App Lock) ---
  # flutter_screen_lock: 9.2.2+2   # NOT USED (UI-SPEC: custom PinKeypad)
  crypto: 3.0.7
  flutter_secure_storage: 10.0.0
  local_auth: 3.0.1
  local_auth_android: 2.0.8   # direct only because AndroidAuthMessages is not re-exported by local_auth
```

Then `flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`.

## Package Legitimacy Audit

The `gsd-tools package-legitimacy` seam supports only npm, pypi and crates, and rejected `--ecosystem pub`. The equivalent signals below were pulled from the pub.dev API this session.

| Package | Registry | Age | Downloads (30 d) | Source Repo | Verdict | Disposition |
|---------|----------|-----|------------------|-------------|---------|-------------|
| `local_auth` | pub.dev (publisher `flutter.dev`) | since 2017-08 | 2,018,473 | github.com/flutter/packages | OK (160/160 pts) | Approved (pre-decided) |
| `flutter_secure_storage` | pub.dev (publisher `steenbakker.dev`) | since 2017-10 | 6,323,358 | github.com/mogol/flutter_secure_storage | OK (160/160 pts) | Approved (pre-decided) |
| `crypto` | pub.dev (publisher `dart.dev`) | since 2013-05 | 19,620,615 | github.com/dart-lang/core | OK (160/160 pts) | Approved; already a transitive dependency |
| `local_auth_android` | pub.dev (endorsed implementation of `local_auth`, same flutter/packages repo) | 2.0.8 released 2026-04-14 | (bundled with `local_auth`) | github.com/flutter/packages | OK | Approved as a direct dependency only for `AndroidAuthMessages` |
| `cryptography` | pub.dev (publisher `dint.dev`) | since 2019-09 | 1,428,100 | github.com/dint-dev/cryptography | OK (130/160 pts) | Not recommended (unneeded) |

Endorsed platform packages pulled in automatically: `local_auth_android` 2.0.8 (Android `api("androidx.biometric:biometric:1.1.0")`, minSdk 24), `local_auth_darwin` 2.0.5 (Swift Package Manager sources), `flutter_secure_storage_darwin` 0.2.0 `[VERIFIED: pub cache]`.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**Note:** `crypto` is not listed in CLAUDE.md's decided stack. It is the Dart team's own package and already in the lock graph, but promoting it to a direct dependency is a stack addition. Confirm it at plan review (Assumptions A1).

## Architecture Patterns

### System Architecture Diagram

```
                      ┌──────────────── main() ────────────────┐
 process start ──────►│ ensureInitialized → configureDependencies │ (SharedPreferences pre-resolved)
                      │ → Isar open → startNotifications          │
                      │ → bootstrapAppLock():                     │
                      │     fresh-install? → secureStorage.deleteAll│
                      │     setSecureWindow(pinConfigured) ──────────► MethodChannel agenda/app_privacy
                      │ → runApp                                  │        │ Android: window FLAG_SECURE
                      └───────────────────────────────────────────┘        │ iOS: PrivacyShield.enabled
                                        │                                   ▼
                  MultiBlocProvider (above MaterialApp)          SceneDelegate: cover UIView on
                  ├─ LocaleCubit (existing)                      willResignActive/didEnterBackground,
                  └─ AppLockCubit  ◄── seeded SYNC from prefs     removed on didBecomeActive
                         ▲   │         (pinConfigured → locked=true on frame 1)
     lifecycle events    │   │ state {pinEnabled, locked, obscured, attempts}
 (inactive/hidden/       │   ▼
  resumed) ──► LockGate (MaterialApp.builder)
               Stack[
                 Offstage(locked) + TickerMode ─► app Navigator ─► home: OnboardingGate
                 │                                                   ├─ !privacyShown → PrivacyStatementScreen
                 │                                                   └─ AppShell (tabs) ─► Settings (gear)
                 if locked:  Navigator(own Overlay) ─► LockScreen ─► PinKeypad
                 │             │ auto biometric (when resumed) ─► LocalAuthGateway ─► BiometricPrompt / LAContext
                 │             │ forgot PIN ─► device credential ─► PinSetupScreen(reset)
                 │             ▼
                 │       verify PIN ─► PinHasher (Isolate.run PBKDF2) ─► SecurePinStore (Keystore/Keychain)
                 if obscured: PrivacyOverlay
               ]
 File picker / permission / local_auth calls ─► ExcursionGuard.run(...) ─► AppLockCubit reads guard on `hidden`
```

### Recommended Project Structure

Respect the 10-files-per-directory cap and add a README in every new presentation/application directory.

```
lib/
├── core/constants/
│   ├── storage_keys.dart          # + biometricUnlockEnabled, secureStorageInitialized
│   └── secure_storage_keys.dart   # NEW: pin_hash, pin_salt, pin_iterations, pin_failures, pin_lockouts, pin_cooldown_until
├── domain/lock/                   # pure Dart, no Flutter
│   ├── pin_hasher.dart            # interface
│   ├── pin_store.dart             # interface (hash record + attempt state)
│   ├── device_auth_gateway.dart   # interface + BiometricAvailability enum + DeviceAuthResult
│   ├── secure_window_gateway.dart # interface setSecure(bool)
│   ├── excursion_guard.dart       # interface
│   ├── lock_attempts.dart         # value object + pure ladder fn (D-07)
│   └── lock_policy.dart           # pure shouldLockOnResume(...)
├── infrastructure/lock/
│   ├── pbkdf2_pin_hasher.dart     # crypto Hmac(sha256), Isolate.run
│   ├── secure_pin_store.dart      # flutter_secure_storage 10
│   ├── local_auth_gateway.dart    # local_auth 3.0.1, maps LocalAuthException
│   ├── secure_window_channel.dart # MethodChannel 'agenda/app_privacy'
│   ├── excursion_guard_impl.dart  # @LazySingleton(as: ExcursionGuard)
│   └── app_lock_bootstrap.dart    # fresh-install wipe + initial setSecure (or in config/startup/)
├── application/lock/              # AppLockCubit + state, PinSetupCubit + state, README
├── application/settings/          # SecuritySettingsCubit + state, README
├── presentation/lock/{screens,widgets,keypad}/   # LockGate, LockScreen, PinSetupScreen, PrivacyOverlay, PinKeypad, PinDots, ...
├── presentation/settings/{screens,widgets}/       # SettingsScreen, section header, language/timeout dialogs, security section
├── presentation/onboarding/{screens,widgets}/     # OnboardingGate, PrivacyStatementScreen, PrivacyBullet
└── presentation/shared/widgets/app_empty_state.dart
android/app/src/main/kotlin/.../MainActivity.kt   # + 'agenda/app_privacy' channel
android/app/src/main/res/values/styles.xml         # LaunchTheme parent → Theme.AppCompat.Light.NoActionBar
android/app/src/main/AndroidManifest.xml           # + USE_BIOMETRIC (explicit)
ios/Runner/AppDelegate.swift, SceneDelegate.swift, Info.plist  # channel, cover view, NSFaceIDUsageDescription
```

### Pattern 1: Lock layer in `MaterialApp.builder` with its own Navigator

**What:** `builder: (context, child) => LockGate(child: child!)`. `LockGate` renders `Stack[Offstage(offstage: locked, child: TickerMode(enabled: !locked, child: child)), if (locked) _LockNavigator(), if (obscured) const PrivacyOverlay()]`.

**Why each piece is needed:**
- `builder` output is wrapped by `ScaffoldMessenger`, `Theme` and `Localizations` but is **not** under the app Navigator `[VERIFIED: flutter/lib/src/material/app.dart:1019-1045 — "childWidget = Builder(... widget.builder!(context, child)) ... childWidget = ScaffoldMessenger(key: widget.scaffoldMessengerKey, ..."]`. There is therefore no `Overlay`. `Tooltip` (used by the keypad's backspace and biometric keys) asserts one: `[VERIFIED: flutter/lib/src/widgets/raw_tooltip.dart:845 — "assert(debugCheckHasOverlay(context));"]`. `showDialog` and `Navigator.push` (forgot-PIN dialog, reset-mode PIN setup) also need a Navigator. **Wrap the lock layer in its own `Navigator`** (e.g. `Navigator(onGenerateRoute: (_) => PageRouteBuilder(pageBuilder: (_, __, ___) => const LockScreen()))`). It provides the Overlay and keeps lock dialogs above app content.
- `Offstage` keeps the app's navigation state (D-01: "continues where it was"), skips painting and hit-testing, and drops the semantics of hidden content so TalkBack/VoiceOver cannot read tasks behind the lock. `TickerMode(enabled: false)` stops hidden animations.
- On lock, call `FocusManager.instance.primaryFocus?.unfocus()` so a soft keyboard opened by a hidden `TextField` closes.
- `find.byType` skips offstage widgets by default (`skipOffstage = true`) `[VERIFIED: flutter_test/lib/src/finders.dart:103]`, which makes "no app content visible on frame 1" directly testable.

### Pattern 2: Synchronous seeding for frame 1 (SC-1)

**What:** `AppLockCubit(SharedPreferences prefs, ...)` computes its initial state in the constructor: `locked = prefs.getBool(StorageKeys.pinConfigured) ?? false`. This mirrors `LocaleCubit` `[VERIFIED: lib/application/shared/locale/locale_cubit.dart:17-22 — "LocaleCubit(this._prefs) : super(LocaleState(_resolveInitialLocale(_prefs)));"]`. SharedPreferences is pre-resolved before `runApp` `[VERIFIED: lib/config/di/core_module.dart:24-26 — "@preResolve Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();"]`.

**Attempt state** (secure storage, async) loads after frame 1. Until it loads, the keypad state is `loadingAttempts` and ignores input, so a cold start during cooldown cannot be raced. This keeps `main()` free of Keystore latency for users without a PIN.

**Provide** `AppLockCubit` in the existing `MultiBlocProvider` above `MaterialApp` in `lib/app.dart`, beside `LocaleCubit`. Register it `@lazySingleton` (one instance app-wide, also reachable by the settings cubit), or `@injectable` provided exactly once. Do not create a second instance anywhere.

### Pattern 3: Lifecycle state machine (D-01, D-03, D-04)

Verified lifecycle facts:
- `inactive` on Android includes **window-focus loss while resumed**: notification shade, system dialogs, app switcher `[VERIFIED: sky_engine/lib/ui/platform_dispatcher.dart:2374-2384]`. On iOS it covers "responding to a TouchID request, when entering the app switcher or the control center" `[VERIFIED: same file 2368-2372]`.
- `hidden` is **synthesized** right before `paused` on iOS and Android `[VERIFIED: same file 2395-2400]`, so it is the "went to background" signal.
- **Frames stop at `hidden` and `paused`:** `case AppLifecycleState.hidden: case AppLifecycleState.paused: ... _setFramesEnabledState(false);` `[VERIFIED: flutter/lib/src/scheduler/binding.dart:414-427]`. The overlay therefore **must be painted on `inactive`**. Setting it at `hidden` paints nothing.
- Valid transitions are asserted by `AppLifecycleListener`: `resumed ⇄ inactive ⇄ hidden ⇄ paused` `[VERIFIED: flutter/lib/src/widgets/app_lifecycle_listener.dart:222-266]`.

Recommended cubit API (all take `DateTime now` from an injected clock):

```
onInactive()  → if pinEnabled: emit(obscured: true)
onHidden()    → hiddenAt = now; hiddenDuringExcursion = excursionGuard.isActive(now)
onResumed()   → final lock = pinEnabled && shouldLockOnResume(hiddenAt, now, timeout, hiddenDuringExcursion)
                emit(obscured: false, locked: state.locked || lock)   // ONE emit: overlay → lock, no content frame
                hiddenAt = null
```

- **No `hidden` means no lock.** Notification shade, BiometricPrompt and the iOS Face ID sheet only reach `inactive`. With "Immediately", only a real background trip locks.
- **Timeout uses wall clock (`DateTime.now`), fail-closed.** If `now.isBefore(hiddenAt)` (clock moved back), lock. Do not use `Stopwatch` (monotonic); see Pitfall 7.
- Cold start always locks when `pinConfigured` (SC-1), whatever the timeout.

### Pattern 4: Excursion guard (D-03)

The call sites that launch external UI, verified this session:
- `FilePickerBackupFileGateway.saveFile` / `pickFiles` (`FilePicker.saveFile`, `FilePicker.pickFiles`) `[VERIFIED: lib/infrastructure/backup/file_picker_backup_file_gateway.dart:29,49]`
- `NotificationPermissionServiceImpl.requestNotificationPermission` / `requestExactAlarmPermission` / `openNotificationSettings` `[VERIFIED: lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart:64-115]`. Reached from `NotificationSettingsCubit` (lines 102, 109, 116) and from `PermissionGate.ensureAsked` (`permission_gate.dart:29`), which can prompt contextually after a data change.
- `LocalAuthGateway.authenticate` (new). Device-credential fallback launches a separate Activity on Android, which goes through `hidden`.

Design: `ExcursionGuard.run<T>(Future<T> Function() f)` marks the excursion active for the duration of `f`, plus a short grace window after it completes (e.g. 2 s). The grace window covers platforms that resolve the future **before** delivering `resumed`, and fire-and-forget calls such as `openNotificationSettings`, which returns as soon as the Settings activity starts. `AppLockCubit.onHidden` samples `guard.isActive(now)`. On `onResumed`, a hidden-during-excursion trip locks only if `elapsed > max(timeout, excursionCap)`, with `excursionCap = 5 min` (Assumption A3). Without a cap, a user who opens the file picker and walks away would come back unlocked hours later.

Inject `ExcursionGuard` into the two infrastructure classes (new constructor param). Update the one test that constructs `NotificationPermissionServiceImpl(` directly (`test/infrastructure/notifications/system_settings_channel_test.dart:31`). Then re-run `build_runner`.

### Pattern 5: PIN hashing (D-05, discretion)

**Recommendation:** PBKDF2-HMAC-SHA256, 16-byte random salt from `Random.secure()`, **10,000 iterations**, 32-byte output. Store a versioned record (`v1`, iterations, base64 salt, base64 hash) so iterations can be raised later. Run it via `Isolate.run`. Compare in constant time.

Evidence this session:
- The implementation in Code Examples reproduces RFC 7914 §11 `P="passwd", S="salt", c=1` → `55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc` and `P="Password", S="NaCl", c=80000` → `4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56`. Both match Python `hashlib.pbkdf2_hmac` output (first 32 bytes) `[VERIFIED: ran dart (JIT and AOT) and python3 this session]`.
- Cost on this desktop: 10k iterations ≈ 55–66 ms, 100k ≈ 614–687 ms. Expect several times slower on the low-end Android test device (Infinix X6831). 100k would add a visible delay to every unlock.

**Threat-model note (state this in the plan):** A 4-digit PIN has 10⁴ values. Anyone holding hash plus salt can brute-force it offline whatever the iteration count. The real protections are (a) Keystore/Keychain encryption of the record and (b) the online attempt ladder. The Isar database is **not encrypted at rest**, so the app lock is a privacy gate against casual access (a borrowed or unattended phone), not protection against forensic extraction. Iterations are defense in depth, not the control.

### Pattern 6: Attempt ladder (D-07)

Pure function over `LockAttempts {int failures; int lockouts; DateTime? cooldownUntil}`:

```
onFailure(now): failures += 1
  if (lockouts > 0 || failures >= 5) { lockouts += 1; cooldownUntil = now + ladder[min(lockouts-1, 3)] }
  ladder = [30s, 60s, 300s, 900s]
remaining = lockouts == 0 ? 5 - failures : 0         // drives lockWrongPin(remaining) for n = 1..4
onSuccess / biometric success / forgot-PIN success: reset all
isCoolingDown(now) = cooldownUntil != null && now.isBefore(cooldownUntil)
```

This matches UI-SPEC: "after wrong PIN number n (n = 1–4), the status line shows `lockWrongPin(5 − n)`. The 5th wrong PIN starts a cooldown of 30 s, and each later failure after a cooldown escalates it to 1 min, 5 min, then 15 min (cap)."

**Persist the new attempt state to secure storage BEFORE showing the result.** If the process is killed mid-verify, the attacker learns nothing and loses nothing. Persisting after display would let a kill erase the counted failure.

### Pattern 7: Secure window channel (D-04)

One new channel `agenda/app_privacy`, method `setSecure` with a `bool` argument. Validate the type natively; anything else → `result.error`. It follows the existing channel's style `[VERIFIED: lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart:9,12 — "const String systemSettingsChannelName = 'agenda/system_settings';" / "const String openNotificationSettingsMethod = 'openNotificationSettings';"]`. A new channel keeps the concern separate. Adding a method to `agenda/system_settings` is equally valid but mixes concerns.

- **Android:** `window.addFlags/clearFlags(WindowManager.LayoutParams.FLAG_SECURE)`. Call it from `main()` before `runApp` when `pinConfigured`, and on PIN enable/disable. The manifest's `configChanges` already avoids Activity recreation on rotation, locale and uiMode `[VERIFIED: AndroidManifest.xml:19]`. Any recreation also restarts the Dart side in this app, which re-applies the flag.
- **iOS:** the channel sets a static `PrivacyShield.enabled`. `SceneDelegate` (currently an empty `FlutterSceneDelegate` subclass `[VERIFIED: ios/Runner/SceneDelegate.swift]`) adds an opaque cover `UIView` in `sceneWillResignActive` **and** `sceneDidEnterBackground` (idempotent), and removes it in `sceneDidBecomeActive`, calling `super` in every override. Rationale: Apple says "Shortly after this method returns, UIKit takes a snapshot of your scene's interface for display in the app switcher" (the background callback), and `sceneWillResignActive` is reported as not always called `[CITED: developer.apple.com/forums/thread/798618]`. Channels on this app are created in `didInitializeImplicitFlutterEngine` `[VERIFIED: ios/Runner/AppDelegate.swift:35-56]` `[CITED: docs.flutter.dev/release/breaking-changes/uiscenedelegate]`.

### Pattern 8: Biometrics (DATA-06, D-06, D-08)

API read from source `[VERIFIED: local_auth-3.0.1/lib/src/local_auth.dart:48-58]`:

```dart
Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[ IOSAuthMessages(), AndroidAuthMessages(), WindowsAuthMessages(), ],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  })
```

Also: `stopAuthentication()`, `Future<bool> get canCheckBiometrics` (hardware), `isDeviceSupported()`, `getAvailableBiometrics()` (enrolled) `[VERIFIED: same file 72-96]`. In 3.x `AuthenticationOptions`/`stickyAuth` are no longer public parameters; `persistAcrossBackgrounding` maps to the old `stickyAuth` (`stickyAuth: persistAcrossBackgrounding`, line 63).

Errors throw `LocalAuthException { LocalAuthExceptionCode code; String? description; Object? details }` with codes `authInProgress, uiUnavailable, userCanceled, timeout, systemCanceled, noCredentialsSet, noBiometricsEnrolled, noBiometricHardware, biometricHardwareTemporarilyUnavailable, temporaryLockout, biometricLockout, userRequestedFallback, deviceError, unknownError` `[VERIFIED: local_auth_platform_interface-1.1.0/lib/types/auth_exception.dart:10-125]`. `BiometricType { face, fingerprint, iris, strong, weak }` `[VERIFIED: .../biometric_type.dart:8-27]`.

Android semantics `[VERIFIED: local_auth_android-2.0.8 LocalAuthPlugin.java:55-192]`:
- `isDeviceSupported() = isDeviceSecure() || canAuthenticateWithBiometrics()`. "Device has no screen lock" (UI-SPEC forgot-unavailable and no-device-lock dialogs) ⇔ `isDeviceSupported() == false`.
- `deviceCanSupportBiometrics()` (`canCheckBiometrics`) = hardware present (`!= BIOMETRIC_ERROR_NO_HARDWARE`).
- `getEnrolledBiometrics()` returns only `weak`/`strong` on Android, never `face`/`fingerprint`. Pick the keypad icon by platform (`Icons.fingerprint` Android / `Icons.face` iOS), as the UI-SPEC does.
- Fails with `NOT_FRAGMENT_ACTIVITY` unless the activity is a `FragmentActivity`. This is already satisfied `[VERIFIED: MainActivity.kt:23 — "class MainActivity : FlutterFragmentActivity()"]`.

Mapping for the gateway: `true` → success. `false`, `userCanceled`, `systemCanceled`, `userRequestedFallback` or `timeout` → silent fallback to keypad. `noBiometricsEnrolled` or `noBiometricHardware` → refresh availability and hide the biometric key. `temporaryLockout` or `biometricLockout` → keypad only (the OS has already explained). `noCredentialsSet` (forgot-PIN) → `lockForgotUnavailable*` dialog. Anything else → keypad, no crash.

Call settings:
- Unlock: `biometricOnly: true, persistAcrossBackgrounding: false`, localized `AndroidAuthMessages`.
- Forgot PIN: `biometricOnly: false`.
- Consider `sensitiveTransaction: false` for unlock: it skips Android's face-unlock "confirm" step. This is a UX choice (A5).
- Auto-prompt only when `WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed`, otherwise wait for the next `resumed`. Wrap every call in `ExcursionGuard.run`.

### Pattern 9: First-launch gate (UX-03)

Make `home:` a constant `OnboardingGate` that rebuilds itself from a sync-read flag (a small Cubit or `ValueNotifier` seeded from `prefs.getBool(StorageKeys.privacyStatementShown)`). Swapping the `home` widget instance itself is less robust. Keep the existing `MultiBlocProvider(TaskListCubit, DayPlannerCubit)` **inside** the gate's post-onboarding branch, so no Isar-backed cubit starts under the privacy screen. "Começar": `await prefs.setBool(...)`. On `false` or a throw, stay on the screen (UI-SPEC backstop); on success, transition. The read-only variant is pushed from Settings with `readOnly: true`.

### Pattern 10: Settings

- Language row: read and write `LocaleCubit` directly (`supportedLocales` = `[Locale('pt', 'BR'), Locale('en')]`, `setLocale(Locale)` persists `languageCode`) `[VERIFIED: lib/application/shared/locale/locale_cubit.dart:27-30, 45-49]`. Do not add language state to a new cubit.
- `SecuritySettingsCubit`: `{pinEnabled, biometricAvailability (noHardware | notEnrolled | enrolled), biometricEnabled, timeoutSeconds}`. Refresh biometric availability on `resumed`, because the user may enroll a fingerprint in device settings. Mirror `NotificationSettingsScreen`'s `WidgetsBindingObserver` `[VERIFIED: lib/presentation/notifications/screens/notification_settings_screen.dart:21-45]`.
- PIN switch never flips optimistically (UI-SPEC). It reflects `AppLockCubit.state.pinEnabled` after the setup or verify flow returns success.
- Enable order: write hash record to secure storage → write `biometricUnlockEnabled` (default = enrolled, D-08) → `setSecure(true)` → **last** set `pinConfigured=true`. Disable order: `pinConfigured=false` **first** → `setSecure(false)` → delete secure keys. A crash between steps then leaves either "no flag" (unlocked, stale hash overwritten next time) or "flag but no hash" (handled by the recovery path, Pitfall 5).
- Notifications and Data rows push the existing self-contained screens unchanged. Both own their cubits `[VERIFIED: notification_settings_screen.dart:11-12 "Owns its cubit so the Phase 5 Settings screen can mount it unchanged."; backup_screen.dart:16-17]`.
- Remove `TaskListSettingsMenu` and its test `test/presentation/tasks/task_list_settings_menu_test.dart`, and update `lib/presentation/tasks/widgets/README.md:30` and `lib/presentation/tasks/screens/README.md:16`.

### Anti-Patterns to Avoid

- **Lock as a pushed route.** It cannot cover dialogs and sheets, and back gestures fight it. Use the builder Stack (UI-SPEC).
- **Lock layer without its own Navigator/Overlay.** Tooltip assertion, and `showDialog` fails.
- **Deciding the lock on `inactive`.** Notification shade, Face ID and BiometricPrompt would relock-loop.
- **Showing the overlay only on `hidden`/`paused`.** No frame is produced.
- **Two emits on resume** (`obscured=false`, then `locked=true`). One content frame can paint between them.
- **Async read of `pinConfigured` before deciding.** A frame of content before the lock.
- **Hashing on the UI isolate** at higher iteration counts. Keypad jank.
- **`flutter_secure_storage` `encryptedSharedPreferences: true`.** Deprecated in 10.0.0 and ignored.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC / SHA-256 | Your own hash | `crypto` `Hmac(sha256, key)` | Audited, dart.dev-maintained. Only the ~14-line PBKDF2 loop sits on top, validated by RFC 7914 vectors in a unit test. |
| Key storage / encryption at rest | AES in Dart + key in prefs | `flutter_secure_storage` 10 (Keystore RSA-OAEP + AES-GCM; Keychain) | Hardware-backed keys, handled migration |
| Biometric prompt / device credential | Platform channels to BiometricPrompt/LAContext | `local_auth` 3.0.1 | FragmentActivity handling, error codes, device-credential fallback |
| Random salt | `Random()` | `Random.secure()` | Cryptographically secure source |
| Lifecycle tracking | Raw `SystemChannels.lifecycle` listener | `AppLifecycleListener` (`onInactive`/`onHide`/`onResume`) | Synthesizes `hidden` and asserts valid transitions |
| Locale persistence | New language cubit | Existing `LocaleCubit` | Already wired to `MaterialApp` and the notification reconcile listener |

**Key insight:** The only "custom" security code this phase needs is policy (ladder, timeout, excursion), the PBKDF2 loop and a constant-time compare. All three are pure functions that unit tests can pin exactly.

## Runtime State Inventory

Not a rename phase. This phase **introduces** runtime state that outlives the code, so the inventory is relevant for planning:

| Category | Items | Action Required |
|----------|-------|-----------------|
| Stored data | Keychain/Keystore: PIN hash record, salt, iterations, failures, lockouts, cooldownUntil. SharedPreferences: `pin_configured`, `lock_timeout_seconds`, new `biometric_unlock_enabled`, `privacy_statement_shown`, new `secure_storage_initialized`. | Code: fresh-install wipe (Pitfall 4). No migration of existing data; no prior PIN data exists. |
| Live service config | None — no server. Verified: app has no network packages (CI grep). | none |
| OS-registered state | Android window FLAG_SECURE (per Activity, in-memory); iOS `PrivacyShield.enabled` (in-memory) | Re-applied from Dart in `main()` on every process start |
| Secrets/env vars | None | none |
| Build artifacts | `injection.config.dart` regenerated (new `@LazySingleton`s and new constructor params); `lib/generated/l10n/*` regenerated; iOS `GeneratedPluginRegistrant` / SwiftPM resolution on next Mac build | Run `build_runner` and `gen-l10n`; iOS needs a Mac build (Environment) |

## Common Pitfalls

### Pitfall 1: Existing `test/widget_test.dart` breaks
**What goes wrong:** It pumps `AgendaApp` with `SharedPreferences.setMockInitialValues({})` and expects `NavigationBar` `[VERIFIED: test/widget_test.dart:273-318]`. After this phase an empty prefs map means the privacy statement shows first, so the test fails.
**How to avoid:** Seed `{'privacy_statement_shown': true}` in that test. Add separate tests for first launch and for cold-start lock. Also call `FlutterSecureStorage.setMockInitialValues({})` in any test that builds the full app `[VERIFIED: flutter_secure_storage-10.0.0/lib/flutter_secure_storage.dart:397]`.

### Pitfall 2: Lock layer has no Overlay or Navigator
**What goes wrong:** "No Overlay widget found" assertion from keypad tooltips; `showDialog` throws.
**How to avoid:** Pattern 1 (own Navigator).
**Warning signs:** Assertion in the first lock-screen widget test.

### Pitfall 3: Relock loop from biometrics or device credential
**What goes wrong:** With "Immediately", forgot-PIN's device-credential screen (a separate Activity) produces `hidden` → `resumed` → lock again, forever.
**How to avoid:** Wrap with `ExcursionGuard`, and decide only at `hidden`.

### Pitfall 4: iOS Keychain survives uninstall
**What goes wrong:** After reinstall, SharedPreferences is empty but the Keychain still holds the old hash and a cooldown. A newly created PIN can then start in a stale cooldown. Multiple reports, including an Apple engineer on the dev forums, confirm Keychain values persist after uninstall, and the standard fix is a first-run flag `[CITED: developer.apple.com/forums/thread/36442; stackoverflow 70089955]`.
**How to avoid:** In `main()`, if `StorageKeys.secureStorageInitialized` (new) is absent: `await secureStorage.deleteAll()`, then set the flag. Also reset attempt state when a new PIN is created. Android already has `android:allowBackup="false"` `[VERIFIED: AndroidManifest.xml:10]`, which flutter_secure_storage recommends to avoid `Failed to unwrap key` `[CITED: pub.dev/packages/flutter_secure_storage]`.

### Pitfall 5: `resetOnError` silently wipes the PIN
**What goes wrong:** In 10.0.0 `AndroidOptions()` defaults to `resetOnError = true` (the doc comment says false, but the code says true) `[VERIFIED: android_options.dart:51 — "bool resetOnError = true,"]`. A Keystore failure erases all entries, leaving `pinConfigured == true` with no hash.
**How to avoid:** Treat "flag set, hash missing" or a storage exception as **fail-closed recovery**. The lock stays up, the status line shows `lockErrorGeneric`, and "Esqueci meu PIN" (device credential) leads to reset mode. If the device has no credential, show the `lockForgotUnavailable*` dialog (reinstall + JSON backup), which the UI-SPEC copy already describes. The user decides whether to fail open instead (Open Question 1).

### Pitfall 6: Overlay missing from the iOS App Switcher
**What goes wrong:** If `inactive` is skipped or no frame is rasterized before the snapshot, the card shows tasks and finances.
**How to avoid:** Pattern 7 native cover (backstop). Verify on device (manual UAT).

### Pitfall 7: Monotonic timer under-counts sleep
**What goes wrong:** Measuring background time with `Stopwatch` may not advance while the device sleeps on Android, so a phone asleep for 10 min appears to have been away ~0 s and never locks. `[ASSUMED]`
**How to avoid:** Use wall clock (`DateTime.now()` via injected clock), and lock when the result is negative.

### Pitfall 8: Android defaults to English prompt text
**What goes wrong:** The BiometricPrompt shows "Authentication required" / "Verify identity" / "Cancel" in a PT-BR app `[VERIFIED: local_auth_android-2.0.8/lib/src/auth_messages_android.dart:63-84 — Intl.message('Verify identity' / 'Cancel' / 'Authentication required')]`.
**How to avoid:** Pass `AndroidAuthMessages(signInTitle:, signInHint:, cancelButton:)` from l10n. **These keys are not in the UI-SPEC copy table.** Add e.g. `lockBiometricSheetTitle` ("Desbloquear o AGENDA"), `lockBiometricSheetHint`, `lockUsePin` ("Usar PIN") to all three ARB files (Open Question 2).

### Pitfall 9: AppCompat theme for the biometric dialog
**What goes wrong:** The README requires `LaunchTheme`'s parent to be `Theme.AppCompat` "to prevent crashes on Android 8 and below" `[VERIFIED: local_auth_android-2.0.8/README.md "Android theme"]`. The current parent is `@android:style/Theme.Light.NoTitleBar` `[VERIFIED: android/app/src/main/res/values/styles.xml]`, and minSdk is 24 (Android 7.0) `[VERIFIED: flutter_tools FlutterExtension.kt:26 "val minSdkVersion: Int = 24"]`.
**How to avoid:** Change both `values/styles.xml` LaunchTheme and NormalTheme to `Theme.AppCompat.Light.NoActionBar` (light only: no dark theme in scope). Check `values-night/styles.xml` too if present. AppCompat is on the classpath through `androidx.biometric:biometric:1.1.0` → `androidx.appcompat:appcompat:1.2.0` `[VERIFIED: dl.google.com maven biometric-1.1.0.pom]`.

### Pitfall 10: Biometric auto-prompt fires before the app is active
**What goes wrong:** On cold start, iOS may render frame 1 before the scene is active, and LAContext fails (`uiUnavailable`/`systemCanceled`). `[ASSUMED]`
**How to avoid:** Prompt only when the lifecycle is `resumed` (Pattern 8). Prompt once per lock episode. A failure does not re-prompt automatically.

### Pitfall 11: Parallel-wave merge hotspots
**What goes wrong:** The three ARB files, `lib/config/di/injection.config.dart`, `lib/app.dart` and `pubspec.yaml` are touched by several plans.
**How to avoid:** Land **all** new ARB keys and `pubspec` changes in the first plan. Regenerate `injection.config.dart` after each merge rather than merging it by hand. Serialize the plans that touch `app.dart`.

### Pitfall 12: Back button while locked
**What goes wrong:** `WidgetsApp.didPopRoute` pops the **app** Navigator `[VERIFIED: flutter/lib/src/widgets/app.dart:1604-1617]`, not the lock layer's. Android back while locked pops hidden routes (e.g. closes Settings) or exits the app at the root. `PopScope` on the lock screen does not intercept this, because it is in a different Navigator. This is not a leak, since the lock stays up.
**How to avoid:** Accept and document it, or have `LockGate` register a `WidgetsBindingObserver` whose `didPopRoute` returns `true` while locked. Observers are called in registration order (`handlePopRoute` iterates `_observers`) `[VERIFIED: flutter/lib/src/widgets/binding.dart:983-991]`, and WidgetsApp registers first, so that override needs care. Recommendation: accept, and test that the lock is still shown after back.

### Pitfall 13: First release build ever
**What goes wrong:** No release APK has been built in this project (only `app-debug.apk` in `build/`). R8 surprises surface late.
**How to avoid:** Run `flutter build apk --release` right after the dependencies land in plan 05-01 (smoke), and again in 05-04. `file_picker` ships consumer ProGuard rules. The notification icon `@mipmap/ic_launcher` is also the manifest icon, so resource shrinking keeps it.

## Code Examples

### PBKDF2-HMAC-SHA256 (verified against RFC 7914 this session)

```dart
// Source: verified this session (dart JIT+AOT vs python hashlib); crypto 3.0.7 API.
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Single-block PBKDF2-HMAC-SHA256 (dkLen = 32 = hLen).
Uint8List pbkdf2Sha256(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

/// Constant-time equality: no early return on the first differing byte.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
// Off the UI isolate: await Isolate.run(() => pbkdf2Sha256(pin, salt, 10000));
```

Unit-test vectors: `('passwd','salt',1)` → `55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc`; `('1234', 16×0x00, 10000)` → `e0b2a2774733c736d54c2aaddc7b90c3d15edc575c6ac20e011e58940866ba15` (fast enough for CI). The 80,000-iteration vector takes ~0.5 s; optional.

### Secure storage instance

```dart
// Source: flutter_secure_storage-10.0.0 lib/options (read this session)
const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(), // RSA-OAEP key wrap + AES-GCM; resetOnError defaults to true
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

`KeychainAccessibility` values are `passcode, unlocked, unlocked_this_device, first_unlock, first_unlock_this_device`. The default is `unlocked` `[VERIFIED: apple_options.dart:5-31, 72]`. `_this_device` keeps the PIN record out of device-to-device migration. `first_unlock_this_device` vs `unlocked_this_device` is a discretion call (A4).

### local_auth gateway call

```dart
// Source: local_auth-3.0.1/lib/src/local_auth.dart:48-58 (read this session)
try {
  final ok = await _guard.run(() => _auth.authenticate(
        localizedReason: l10n.lockBiometricReason,
        biometricOnly: true,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: l10n.lockBiometricSheetTitle, // NEW key (Pitfall 8)
            cancelButton: l10n.lockUsePin,             // NEW key
          ),
          // iOS: default IOSAuthMessages; localizedReason is the visible text.
        ],
      ));
  return ok ? DeviceAuthResult.success : DeviceAuthResult.cancelled;
} on LocalAuthException catch (e) {
  return switch (e.code) {
    LocalAuthExceptionCode.noBiometricsEnrolled ||
    LocalAuthExceptionCode.noBiometricHardware => DeviceAuthResult.unavailable,
    LocalAuthExceptionCode.noCredentialsSet => DeviceAuthResult.noDeviceCredential,
    LocalAuthExceptionCode.temporaryLockout ||
    LocalAuthExceptionCode.biometricLockout => DeviceAuthResult.lockedOut,
    _ => DeviceAuthResult.cancelled,
  };
}
```

`package:local_auth/local_auth.dart` exports **only** `LocalAuthentication`, `BiometricType`, `LocalAuthException` and `LocalAuthExceptionCode` `[VERIFIED: local_auth-3.0.1/lib/local_auth.dart — "export 'package:local_auth/src/local_auth.dart' show LocalAuthentication; export 'package:local_auth_platform_interface/local_auth_platform_interface.dart' show BiometricType, LocalAuthException, LocalAuthExceptionCode;"]`. `AndroidAuthMessages` lives in `package:local_auth_android/local_auth_android.dart`. To localize the Android sheet, add **`local_auth_android: 2.0.8`** as a direct dependency (the version the solver already picks). The README says to do so when importing it directly, and `depend_on_referenced_packages` (very_good_analysis) would flag it otherwise. iOS can rely on the default `IOSAuthMessages()` (the `localizedReason` is the visible text), so `local_auth_darwin` need not be imported.

### Android FLAG_SECURE channel (MainActivity.kt addition)

```kotlin
// Source: pattern of the existing 'agenda/system_settings' handler in MainActivity.kt:24-33
import android.view.WindowManager

MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agenda/app_privacy")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "setSecure" -> {
                val secure = call.arguments as? Boolean
                if (secure == null) { result.error("bad_args", null, null); return@setMethodCallHandler }
                if (secure) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
```

### iOS cover (SceneDelegate.swift) — compile-unverified on this host

```swift
// [ASSUMED] FlutterSceneDelegate exposes `window` and these overridable scene callbacks.
// Verify on a Mac build; if `override` fails, drop `override`/`super` per the compiler.
import Flutter
import UIKit

enum PrivacyShield { static var enabled = false }

class SceneDelegate: FlutterSceneDelegate {
  private var cover: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene); showCover()
  }
  override func sceneDidEnterBackground(_ scene: UIScene) {
    super.sceneDidEnterBackground(scene); showCover()
  }
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene); cover?.removeFromSuperview(); cover = nil
  }
  private func showCover() {
    guard PrivacyShield.enabled, cover == nil, let window = window else { return }
    let v = UIView(frame: window.bounds)
    v.backgroundColor = .systemBackground
    v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(v); cover = v
  }
}
```

Info.plist addition `[VERIFIED: local_auth_darwin-2.0.5/README.md]`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>AGENDA uses Face ID to unlock the app instead of the PIN.</string>
```

The current `Info.plist` has no such key `[VERIFIED: ios/Runner/Info.plist]`. PT-BR localization of the string needs `pt-BR.lproj/InfoPlist.strings` registered in the Xcode project (Open Question 3).

### Lifecycle test sequence (widget test)

```dart
// Valid order is asserted by AppLifecycleListener (app_lifecycle_listener.dart:222-266).
final b = tester.binding;
b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
await tester.pump();                       // overlay must be visible NOW (frames still on)
expect(find.byType(PrivacyOverlay), findsOneWidget);
b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
b.handleAppLifecycleStateChanged(AppLifecycleState.paused);
clock.advance(const Duration(minutes: 2)); // injected fake clock
b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
await tester.pump();
expect(find.byType(PrivacyOverlay), findsNothing);
expect(find.byType(LockScreen), findsOneWidget);
expect(find.byType(NavigationBar), findsNothing); // offstage → skipped by finder
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `authenticate(options: AuthenticationOptions(stickyAuth:, useErrorDialogs:))` | Named params `biometricOnly`, `sensitiveTransaction`, `persistAcrossBackgrounding`; errors as `LocalAuthException` codes | local_auth 3.0.0 (2025-10) | Old tutorials won't compile; `PlatformException` codes are replaced |
| `AndroidOptions(encryptedSharedPreferences: true)` | Default custom ciphers (RSA-OAEP + AES-GCM), auto-migration | flutter_secure_storage 10.0.0 | Don't pass the deprecated flag |
| `AppDelegate` window lifecycle (`applicationWillResignActive`) | UIScene: `SceneDelegate` callbacks; channels in `didInitializeImplicitFlutterEngine` | Flutter 3.38 APIs, 3.41 default | Privacy cover lives in `SceneDelegate`, not `AppDelegate` |
| `AppLifecycleState` without `hidden` | `hidden` synthesized before `paused` | Flutter 3.13 | Use `hidden` as the background signal |

**Deprecated/outdated in the roadmap draft:** "FlutterFragmentActivity migration" (done in Phase 1) and "GoRouter PIN guard" (no GoRouter in use). Replace them with the builder-Stack gate.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Promoting `crypto` 3.0.7 to a direct dependency is acceptable (not in CLAUDE.md's decided list, though already transitive) | Standard Stack | Low. The alternative is the heavier `cryptography` package. Needs user OK. |
| A2 | 10,000 PBKDF2 iterations is the right cost/latency balance on the Infinix X6831 | Pattern 5 | Unlock feels slow (raise or lower after an on-device measurement) |
| A3 | Excursion cap 5 min and post-excursion grace 2 s | Pattern 4 | Too short: relock after a long file pick. Too long: unattended unlocked window. |
| A4 | `KeychainAccessibility.first_unlock_this_device` for the PIN record | Code Examples | Low; `unlocked_this_device` is also valid |
| A5 | `sensitiveTransaction: false` for unlock | Pattern 8 | UX only (extra confirm tap on Android face unlock) |
| A6 | `FlutterSceneDelegate` exposes `window` and overridable `scene*` callbacks that must call `super` | Code Examples (iOS) | iOS compile error. Fix on first Mac build. |
| A7 | Dart `Stopwatch` does not advance during Android deep sleep | Pitfall 7 | None if wall clock is used as recommended |
| A8 | iOS cold-start frame 1 can precede scene activation, so LAContext may fail if called immediately | Pitfall 10 | None if gated on `resumed` |
| A9 | FLAG_SECURE blanks Flutter's surface in screenshots and the Recents thumbnail on the test device | Pattern 7 | Must be confirmed in manual UAT |
| A10 | Fail-closed when `pinConfigured` is set but the hash is missing | Pitfall 5 | User decision (Open Question 1) |

## Open Questions

1. **Lost PIN material (Keystore reset) on a device without a screen lock.**
   - What we know: `resetOnError=true` can wipe the hash. Forgot-PIN needs a device credential.
   - What's unclear: whether to fail closed (reinstall + JSON backup, per the existing `lockForgotUnavailableBody` copy) or fail open (disable the lock and notify).
   - Recommendation: fail closed. It matches the UI-SPEC copy and the privacy posture. Confirm with the user.
2. **Extra ARB keys for the Android biometric sheet.**
   - The UI-SPEC copy table has `lockBiometricReason` but no sheet title or cancel label. The Android defaults are English.
   - Recommendation: add `lockBiometricSheetTitle` and `lockUsePin` (plus optional `lockBiometricSheetHint`) to all three ARB files in the first plan.
3. **iOS work cannot be built or tested here.**
   - What we know: no Xcode on this Linux host. The iOS cover, channel, Info.plist and Face ID can only be checked on a Mac with a device.
   - Recommendation: implement the iOS code paths, mark SC-2's "iOS App Switcher" part as `human_needed` UAT, and keep the Face ID string in English in `Info.plist` until a Mac session can add `InfoPlist.strings`.
4. **Overlay during app-initiated system dialogs (Android).**
   - Per D-04, the overlay shows on every `inactive`, so the notification-permission dialog and BiometricPrompt appear over a blank AGENDA cover instead of the app.
   - Recommendation: keep the spec as written (simplest, safe). Optionally suppress the overlay while `ExcursionGuard.isActive`. This is a UX refinement for UAT to decide, not a blocker.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | everything | ✓ | 3.41.4 stable (Dart 3.11.1), matches CI pin | — |
| Android SDK / build-tools | Android build, release APK | ✓ | Platform android-36, build-tools 35.0.0 (some licenses not accepted) | Run `flutter doctor --android-licenses` if a build complains |
| JDK | Gradle | ✓ | OpenJDK 17.0.2 | — |
| adb + physical Android device (Infinix X6831, Android 13) | Biometric, FLAG_SECURE, Recents, timeout UAT | adb ✓ / device ✗ (not attached now) | — | Host tests cover logic. Device checks become `human_needed` UAT. |
| Android emulator | optional | ✗ (no AVD images) | — | Use the physical device |
| Xcode / iOS simulator / iOS device | iOS build, Face ID, App Switcher overlay | ✗ (Linux host) | — | **None on this machine.** iOS items are code-only and deferred to a Mac UAT. |
| pub.dev network | `flutter pub get` for the 3 dependencies | ✓ (resolution dry-run succeeded, packages now in pub cache) | — | — |

**Missing dependencies with no fallback:**
- macOS + Xcode for any iOS verification (SC-2's iOS App Switcher clause, Face ID, `NSFaceIDUsageDescription`, SceneDelegate compile).

**Missing dependencies with fallback:**
- Android device: logic is fully testable on the host. Lock, biometric and FLAG_SECURE behavior go to the device UAT list (same practice as Phase 4).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 |
| Config file | none (defaults); analysis via `analysis_options.yaml` (very_good_analysis 10.2.0) |
| Quick run command | `flutter test --no-pub test/application/lock test/infrastructure/lock test/presentation/lock test/presentation/settings test/presentation/onboarding test/domain/lock` |
| Full suite command | `flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart` |

Capture the test-count baseline at plan start (STATE.md's last recorded figure was 306/306; re-measure, don't assume). Hold the analyzer budget at 65 infos.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-05 | PBKDF2 matches RFC 7914 vectors; constant-time compare | unit | `flutter test --no-pub test/infrastructure/lock/pbkdf2_pin_hasher_test.dart` | ❌ Wave 0 |
| DATA-05 | Attempt ladder: n=1..4 remaining; 5th → 30 s; then 60/300/900 cap; reset on success | unit | `flutter test --no-pub test/domain/lock/lock_attempts_test.dart` | ❌ Wave 0 |
| DATA-05 | `shouldLockOnResume`: timeouts 0/30/60/300/900, negative elapsed locks, excursion cap | unit | `flutter test --no-pub test/domain/lock/lock_policy_test.dart` | ❌ Wave 0 |
| DATA-05 | `SecurePinStore` round-trip, attempts persisted before the result, fresh-install wipe | unit (`FlutterSecureStorage.setMockInitialValues`) | `flutter test --no-pub test/infrastructure/lock/secure_pin_store_test.dart` | ❌ Wave 0 |
| DATA-05 | `AppLockCubit`: initial locked from prefs; verify ok/wrong/cooldown; single-emit resume; inactive without hidden never locks | bloc_test | `flutter test --no-pub test/application/lock/app_lock_cubit_test.dart` | ❌ Wave 0 |
| DATA-05 / SC-1 | Cold start with `pin_configured: true`: after the first `pump`, `LockScreen` found and `NavigationBar` not found | widget | `flutter test --no-pub test/presentation/lock/lock_gate_cold_start_test.dart` | ❌ Wave 0 |
| DATA-05 | Keypad: auto-submit on 4th digit, cooldown disables keys, status line text, tooltips render (Overlay present) | widget | `flutter test --no-pub test/presentation/lock/lock_screen_test.dart` | ❌ Wave 0 |
| DATA-05 | PIN setup modes create/confirm-mismatch/change/verify/reset; cancel leaves state unchanged | bloc_test + widget | `flutter test --no-pub test/application/lock/pin_setup_cubit_test.dart test/presentation/lock/pin_setup_screen_test.dart` | ❌ Wave 0 |
| DATA-06 | Biometric auto-prompt only when resumed; success unlocks; cancel → keypad; exception codes mapped | bloc_test (mock `DeviceAuthGateway`) | `flutter test --no-pub test/application/lock/app_lock_biometric_test.dart` | ❌ Wave 0 |
| DATA-06 / D-03 | `ExcursionGuard`: active during call plus grace; hidden-during-excursion does not lock within the cap | unit | `flutter test --no-pub test/infrastructure/lock/excursion_guard_test.dart` | ❌ Wave 0 |
| DATA-06 / D-04 | Overlay appears on `inactive` (PIN on), never when PIN off; resume → lock in the same frame | widget (lifecycle sequence) | `flutter test --no-pub test/presentation/lock/lock_gate_lifecycle_test.dart` | ❌ Wave 0 |
| DATA-06 / D-04 | `setSecure` channel name/method/arg contract (mirrors `system_settings_channel_test`) | unit (`TestDefaultBinaryMessengerBinding`) | `flutter test --no-pub test/infrastructure/lock/secure_window_channel_test.dart` | ❌ Wave 0 |
| UX-01 | Language dialog switches `LocaleCubit`; Settings re-renders in EN | widget | `flutter test --no-pub test/presentation/settings/settings_screen_test.dart` | ❌ Wave 0 |
| UX-01 / SC-3 | Settings rows: Security rows hidden when PIN off; biometric row disabled when not enrolled; Notifications/Backup rows push existing screens; gear replaces menu | widget | same file | ❌ Wave 0 |
| UX-01 | ARB parity (en vs pt_BR) still green with new keys | unit | `flutter test --no-pub test/l10n/l10n_test.dart` | ✅ |
| UX-03 | First launch shows the privacy screen; "Começar" persists the flag and shows the shell; the second launch skips it; read-only mode omits switch and button | widget | `flutter test --no-pub test/presentation/onboarding/privacy_statement_test.dart` | ❌ Wave 0 |
| UX-03 | Full-app smoke still renders the shell when the flag is seeded | widget | `flutter test --no-pub test/widget_test.dart` | ✅ (needs edit: seed flag + secure-storage mock) |
| 05-04 | Empty states (task list, search, GTD) via `AppEmptyState` | widget | `flutter test --no-pub test/presentation/shared/app_empty_state_test.dart` | ❌ Wave 0 |
| 05-04 | Release build compiles | build | `flutter build apk --release` | n/a |
| SC-1/SC-2 device | Process kill → lock first; fingerprint unlock; FLAG_SECURE blank screenshot and Recents; file picker does not relock; iOS App Switcher cover; Face ID | **manual UAT** | — (device; iOS needs a Mac) | — |

### Sampling Rate
- **Per task commit:** the quick run command for the touched area, plus `flutter analyze --no-fatal-infos --fatal-warnings`.
- **Per wave merge:** full suite command (tests + analyze + architecture guard).
- **Phase gate:** full suite green, `flutter build apk --release` succeeds, and the UAT list is recorded before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/support/fake_clock.dart`: mutable `DateTime Function()` for the cubit and policy tests (pattern exists: `SafetyBackupStore({DateTime Function()? clock})` `[VERIFIED: lib/data/backup/import/safety_backup_store.dart:15-33]`)
- [ ] `test/support/lock_fakes.dart`: mocktail mocks for `PinHasher`, `PinStore`, `DeviceAuthGateway`, `SecureWindowGateway`, `ExcursionGuard`; `MockAppLockCubit extends MockCubit<AppLockState>`
- [ ] Update `test/widget_test.dart` setUp: `SharedPreferences.setMockInitialValues({'privacy_statement_shown': true})` and `FlutterSecureStorage.setMockInitialValues({})`
- [ ] Delete `test/presentation/tasks/task_list_settings_menu_test.dart` together with the widget
- [ ] Update `test/infrastructure/notifications/system_settings_channel_test.dart:31` for the new `ExcursionGuard` constructor param
- [ ] All test files listed ❌ above

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (local app PIN + biometrics) | PBKDF2-HMAC-SHA256 with 16-byte `Random.secure()` salt; persisted attempt ladder (D-07); `local_auth` for biometrics and device credential |
| V3 Session Management | yes (lock timeout = session) | Wall-clock timeout from `hidden`, fail-closed on clock skew; cold start always locks |
| V4 Access Control | partial | Lock layer covers all routes; `Offstage` removes hidden semantics |
| V5 Input Validation | yes | PIN = exactly 4 digits from the keypad only; channel args type-checked natively (`as? Boolean`) |
| V6 Cryptography | yes | `crypto` HMAC-SHA256 (never hand-rolled hash), constant-time compare, Keystore/Keychain via `flutter_secure_storage` |
| V7 Error Handling / Logging | yes | Never log the PIN, hash or salt; failures carry the exception type only (existing project convention `T-04-16-03`) |
| V8 Data Protection | yes | FLAG_SECURE + overlay + iOS cover; `_this_device` Keychain accessibility; `allowBackup=false` already set |

### Known Threat Patterns for Flutter app lock

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Online PIN guessing | Spoofing | 5-attempt ladder with escalating, kill-persistent cooldown; persist before revealing the result |
| Kill-app to reset counter | Tampering | Attempt state in secure storage, written before the result is shown |
| Clock change to skip cooldown or timeout | Tampering | Negative elapsed → lock. Cooldown bypass by moving the clock forward is accepted risk (needs an unlocked device; ~2000 clock changes for the full PIN space). Document it. |
| App Switcher / screenshot leak | Information disclosure | Overlay on `inactive` + iOS native cover + Android FLAG_SECURE |
| Content painted before lock on cold start | Information disclosure | Synchronous seed from pre-resolved prefs; `Offstage` app Navigator |
| Accessibility tree exposes hidden content | Information disclosure | `Offstage` (no semantics) |
| Stale Keychain data after reinstall | Tampering / DoS | Fresh-install `deleteAll()` |
| Offline brute force of an extracted hash | Information disclosure | Inherent to a 4-digit PIN. Rely on Keystore/Keychain. Isar is unencrypted, so document the lock as a privacy gate, not encryption. |
| Excursion abused to dodge the lock | Elevation | Excursion cap (max(timeout, 5 min)) |

## Sources

### Primary (HIGH confidence)
- pub cache source, read this session: `local_auth-3.0.1/lib/src/local_auth.dart`; `local_auth_platform_interface-1.1.0/lib/types/{auth_exception,biometric_type}.dart`; `local_auth_android-2.0.8` (README, `LocalAuthPlugin.java`, `auth_messages_android.dart`, `build.gradle.kts`, `AndroidManifest.xml`); `local_auth_darwin-2.0.5` README and `LocalAuthPlugin.swift`; `flutter_secure_storage-10.0.0/lib/{flutter_secure_storage.dart, options/android_options.dart, options/apple_options.dart}`
- Flutter 3.41.4 SDK source: `material/app.dart`, `widgets/app.dart`, `widgets/raw_tooltip.dart`, `widgets/app_lifecycle_listener.dart`, `widgets/binding.dart`, `scheduler/binding.dart`, `sky_engine/lib/ui/platform_dispatcher.dart`, `flutter_tools/gradle/.../FlutterExtension.kt`
- pub.dev API (`/api/packages/<name>`, `/publisher`, `/score`): versions, SDK constraints, publishers, scores
- `flutter pub get --dry-run` on the project pubspec with the Phase 5 dependencies enabled
- Maven POM: https://dl.google.com/android/maven2/androidx/biometric/biometric/1.1.0/biometric-1.1.0.pom
- RFC 7914 §11 vectors, reproduced with Python `hashlib` and Dart `crypto` this session
- Repo files cited inline (`lib/app.dart`, `main.dart`, `storage_keys.dart`, `locale_cubit.dart`, `core_module.dart`, the notification and backup infrastructure, `MainActivity.kt`, `AppDelegate.swift`, `SceneDelegate.swift`, `Info.plist`, `AndroidManifest.xml`, `styles.xml`, `tool/check_architecture.dart`, `.github/workflows/ci.yml`, tests)

### Secondary (MEDIUM confidence)
- https://pub.dev/packages/local_auth, https://pub.dev/packages/flutter_secure_storage (README)
- https://docs.flutter.dev/release/breaking-changes/uiscenedelegate (UIScene migration, implicit-engine channels)
- https://docs.flutter.dev/release/breaking-changes/add-applifecyclestate-hidden

### Tertiary (LOW confidence; used only for risk framing)
- https://developer.apple.com/forums/thread/798618 (snapshot timing; no Apple reply)
- https://developer.apple.com/forums/thread/36442 and the Stack Overflow "flutter secure storage ios data still persists even after uninstalling" thread (Keychain persistence after uninstall)
- https://pub.dev/packages/flutter_windowmanager_plus (FLAG_SECURE equivalence; not adopted)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. Versions, constraints and resolution were verified against the registry and a dry run on the pinned toolchain.
- Architecture: HIGH for the Flutter/Android mechanics (SDK source read). MEDIUM for iOS snapshot behavior (Apple docs quote via forum; device-unverified).
- Pitfalls: HIGH for 1, 2, 5, 8, 9, 11, 12 and 13 (read in source). MEDIUM for 4 and 6 (multiple community reports). LOW for 7 and 10 (assumed; mitigations are safe either way).

**Research date:** 2026-11-16
**Valid until:** 2026-12-16 (pins are exact. Re-check only if the Flutter toolchain is upgraded, since that unlocks `local_auth_android` ≥ 2.0.9.)
