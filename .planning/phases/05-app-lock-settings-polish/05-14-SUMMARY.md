---
phase: 05-app-lock-settings-polish
plan: 14
subsystem: testing
tags: [flutter, smoke-test, release-build, uat, app-lock, local_auth, flag_secure, android]

requires:
  - phase: 05-04
    provides: first-launch privacy statement gate (privacy_statement_shown)
  - phase: 05-06
    provides: AppLockCubit, LockScreen in MaterialApp.builder, cold-start lock
  - phase: 05-12
    provides: PinSetupScreen create/change/verify, forgot-PIN reset
  - phase: 05-13
    provides: Settings Security section (PIN switch, biometrics, lock timeout)
provides:
  - Full-app smoke cases in test/widget_test.dart (first launch -> Settings sections; PIN cold start -> unlock)
  - Release APK validated with all Phase 5 plugins (R8 keeps local_auth / flutter_secure_storage)
  - Layer READMEs listing every Phase 5 nest (presentation lock/settings/onboarding/shared; application lock, lock/setup, settings)
  - Recorded Android device UAT (11/11 PASS on Infinix X6831, Android 13, release build); iOS items human_needed
affects: [verify-work phase 05, phase 05 VERIFICATION, Phase 03 outstanding UAT]

actuals:
  tokens: 1725
  tasks: 2
  commits: 1
plan_head_before: 0efd593feb48d3a0c086fde91f777b73bceba65e
plan_head_after: a6dc9d1

tech-stack:
  added: []
  patterns:
    - "Full-app smoke seeds SharedPreferences + FlutterSecureStorage mock values and pumps const AgendaApp(); PBKDF2 record creation and verification run inside tester.runAsync"
    - "Device UAT driven over adb (uiautomator dump, input tap, screencap, dumpsys window) with the human only for the fingerprint sensor"

key-files:
  created: []
  modified:
    - test/widget_test.dart
    - lib/presentation/README.md
    - lib/application/README.md

key-decisions:
  - "Device UAT item 7 was run stricter than written: lock timeout set to Imediatamente so any ordinary Home trip locks, proving file-picker and permission excursions are exempt"
  - "Android Back on the forced PIN-reset screen backgrounds the app instead of being ignored; accepted as fail-safe (reopening returns to the same reset screen, nothing exposed) and recorded as a note, not a failure"
  - "iOS checks (Runner compile, Face ID with NSFaceIDUsageDescription, App Switcher cover) recorded as human_needed per user decision 4 (no Mac available)"

patterns-established:
  - "Phase-closing plan: tracer smoke + release build + README refresh, then a blocking device checklist whose per-item results live in the SUMMARY"

requirements-completed: [DATA-05, DATA-06, UX-01, UX-03]

coverage:
  - id: D1
    description: "First launch end to end in the real app tree: privacy statement, Começar, shell, gear, Settings sections General/Security/Notifications/Data/About with only the PIN switch in Security"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#first launch smoke"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT item 1 (Infinix X6831, release APK)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cold start with a configured PIN shows LockScreen on the first frame with no NavigationBar; the correct PIN reveals the shell"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#PIN cold start smoke"
        status: pass
      - kind: manual_procedural
        ref: "Device UAT items 3, 4, 8, 9, 11"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release APK builds with all Phase 5 plugins; suite, analyzer (64 <= 65), architecture guard and CI offline grep green"
    verification:
      - kind: other
        ref: "flutter test --no-pub (1226 pass); flutter analyze (64 issues); dart run tool/check_architecture.dart (PASS); flutter build apk --release (exit 0, 64,909,801 bytes)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Fingerprint unlock via system BiometricPrompt on the release build"
    requirement: DATA-06
    verification:
      - kind: manual_procedural
        ref: "Device UAT item 4 (user touched the sensor)"
        status: pass
    human_judgment: true
    rationale: "Biometric hardware cannot run on the host; verified by a human on the device"
  - id: D5
    description: "Language switch in Settings changes the whole app at once (PT-BR <-> EN)"
    requirement: UX-01
    verification:
      - kind: manual_procedural
        ref: "Device UAT item 2"
        status: pass
    human_judgment: false
  - id: D6
    description: "iOS: Runner compiles, Face ID unlock with NSFaceIDUsageDescription prompt, App Switcher shows the privacy cover"
    verification: []
    human_judgment: true
    rationale: "human_needed: requires a Mac and an iOS device; none available (user decision 4)"

duration: 189min
completed: 2026-11-17
status: complete
---

# Phase 5 Plan 14: Full-App Smoke, Release Build and Device UAT Summary

**Two full-app smoke tests (first launch through to Settings, and a PIN cold start that unlocks into the shell), a 64.9 MB release APK that builds with all Phase 5 plugins, refreshed layer READMEs, and an Android device UAT on the Infinix X6831 release build in which all 11 items passed: PIN and fingerprint lock, FLAG_SECURE, the lock timeout, file-picker and permission trips that do not lock, a cooldown that survives a kill, forgot PIN, language and the first-launch statement. The three iOS items are recorded as human_needed.**

## Performance

- **Duration:** about 189 min wall clock, most of it the human-driven device UAT
- **Started:** 2026-11-16T23:08:38Z
- **Completed:** 2026-11-17T02:17:29Z
- **Tasks:** 2 of 2 (Task 1 auto/tracer, Task 2 human-verify checkpoint, approved)
- **Files modified:** 3

## Accomplishments
- `test/widget_test.dart` gains two full-app smoke cases. **First launch:** empty prefs and secure storage, privacy statement, Começar, the NavigationBar, the gear, then Settings with sections General, Security, Notifications, Data, About, and only the PIN switch in Security. **PIN cold start:** a real PBKDF2 record for 1234, LockScreen on the first frame, then 1-2-3-4 unlocks into the shell.
- `flutter build apk --release` exits 0 and produces `app-release.apk` (64,909,801 bytes). R8 kept the `local_auth` and `flutter_secure_storage` classes, and the device run confirmed the lock, biometrics and forgot PIN on the release build (T-05-43).
- The CI offline grep finds no network package (T-05-44). The full suite (1226 tests) passes, the analyzer reports 64 issues (cap 65) and the architecture guard passes.
- `lib/presentation/README.md` lists every nest (tasks, finance, backup, notifications, shell, lock, settings, onboarding, shared) and adds the rule that the lock layer sits in MaterialApp.builder. `lib/application/README.md` adds backup, notifications, lock, lock/setup and settings.
- Device UAT passed all 11 Android items (table below).

## Task Commits

1. **Task 1: Tracer - full-app smoke for first launch and PIN cold start, release build, layer READMEs** - `a6dc9d1` (test)
2. **Task 2: Device UAT** - no code commit (manual verification, results recorded here)

## Device UAT (Task 2)

Device: Infinix X6831, Android 13, release APK installed fresh. The earlier debug install was uninstalled after its data was backed up to `build/device-backup-2026-11-17/`. The checklist was driven over adb (uiautomator dumps, input taps, screencap, dumpsys); the user touched the fingerprint sensor for the biometric steps.

| # | Item | Result | Observed |
|---|------|--------|----------|
| 1 | First-launch privacy statement | PASS | "Seus dados nunca saem deste aparelho". The English toggle switched it to "Your data never leaves this device" and back. "Começar" opened Tarefas (empty state with "Adicionar tarefa"). After force-stop and relaunch the app opened straight to Tarefas with no statement. |
| 2 | Language switch | PASS | Settings showed Geral / Segurança / Notificações / Dados / Sobre. The dialog "Escolher idioma" offered exactly Português (Brasil) / English / Cancelar. English switched the whole screen at once, and switching back to Português worked. |
| 3 | Turn on PIN | PASS | Criar PIN 1234, then "Digite o PIN de novo para confirmar". The switch turned ON with the snackbar "Bloqueio com PIN ativado". The rows Alterar PIN, Desbloquear com biometria (ON, 3 fingerprints enrolled) and Bloquear após 1 minuto appeared. |
| 4 | Cold-start lock + fingerprint | PASS | After force-stop and launch, the system BiometricPrompt ("Desbloquear o AGENDA", "USAR PIN") showed over the lock screen. The UI tree had only lock nodes (no task or amount visible). USAR PIN opened the keypad, and 1234 unlocked. The fingerprint also unlocked on a later auto-prompt. |
| 5 | FLAG_SECURE / Recents | PASS | `adb screencap` returned 0 bytes, dumpsys showed MainActivity with the SECURE flag, and the Recents card was blank while other apps showed their content. |
| 6 | Lock timeout 30 s | PASS | After 10 s on Home: no lock. After 45 s on Home: lock. |
| 7 | Excursions don't lock | PASS (stricter) | The timeout was set to Imediatamente, and a normal Home trip did lock. The JSON export save picker wrote `/sdcard/Download/agenda-backup-2026-11-17.json` (1861 B) without locking. Backing out of the import picker did not lock. The notification permission trip (GrantPermissionsActivity, then Permitir) did not lock. |
| 8 | Wrong-PIN cooldown across a kill | PASS | The messages counted down: "Restam 4/3/2 tentativas", then "Resta 1 tentativa". The 5th wrong PIN showed "Muitas tentativas. Tente de novo em 0:27." and disabled the keys. After force-stop and relaunch the countdown continued at 0:02 instead of resetting. "Esqueci meu PIN" stayed enabled throughout. |
| 9 | Forgot PIN | PASS | The BiometricPrompt "Confirme que é você para criar um novo PIN" appeared, and cancelling it returned to the keypad silently. After confirming, the reset screen opened with no relock. The new PIN 5678 brought back Tarefas with the "PIN alterado" snackbar and the task "UAT data check" intact. The old PIN 1234 was rejected and 5678 unlocked. |
| 10 | Unlock latency | PASS (caveat) | The shell was already present in the first snapshot after the 4th digit. Tap to shell took 2.6 s in total, of which the uiautomator dump alone takes 2.4 s, so unlock is well under about 1 s. No stall was visible. |
| 11 | Turn off PIN | PASS | The dialog "Desativar o bloqueio com PIN?", then Desativar, then the current PIN 5678 turned the switch off. The dependent rows were hidden and the snackbar "Bloqueio com PIN desativado" appeared. `adb screencap` returned a 195 KB image again, and relaunch went straight to Tarefas. |
| iOS-1 | Runner compiles | human_needed | No Mac available. |
| iOS-2 | Face ID unlock with NSFaceIDUsageDescription prompt | human_needed | No Mac or iOS device. |
| iOS-3 | App Switcher shows the cover with the PIN on | human_needed | No Mac or iOS device. |

**Notes:**
- **Back on the forced reset screen (item 9):** Android Back on the "Crie um PIN de 4 dígitos" screen sends the app to the launcher instead of being ignored. Reopening the app returns to the same reset screen, so nothing is exposed and the behaviour is fail-safe. Recorded as an observation, not a failure.
- **Item 10 measurement caveat:** latency was bounded through uiautomator, not timed directly. "Feels instant" is a judgement based on the under-1 s bound.

## Files Created/Modified
- `test/widget_test.dart` - two Phase 5 full-app smoke cases (+84 lines)
- `lib/presentation/README.md` - complete nest layout, plus the rule that the lock layer sits in MaterialApp.builder
- `lib/application/README.md` - adds backup, notifications, lock, lock/setup, settings

## Decisions Made
See `key-decisions` in the frontmatter. Item 7 was tested more strictly than the plan asked, and the Back-on-reset-screen behaviour was accepted as fail-safe.

## Deviations from Plan

None. The plan was executed as written. Item 7's stricter timeout setting strengthens the check without changing scope.

## Issues Encountered
None. All Android items passed on the first run.

## Known Stubs
None.

## Verification
- `flutter test --no-pub`: 1226 tests, all passed (includes 2 new smoke cases)
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (cap 65)
- `dart run tool/check_architecture.dart`: PASS
- CI offline grep (ci.yml "Verify offline guarantee"): clean
- `flutter build apk --release`: exit 0, `build/app/outputs/flutter-apk/app-release.apk` 64,909,801 bytes
- Device UAT: 11/11 Android PASS; 3 iOS items human_needed

## Next Phase Readiness
- All 14 plans in Phase 5 are complete. Phase verification (`/gsd-verify-work 05`) should treat the three iOS items as human_needed, pending a Mac session.
- Optional follow-up: decide whether Back on the forced reset screen should be swallowed, for example with PopScope(canPop: false), instead of backgrounding the app. This is a UX polish item, not a security gap.

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-17*

## Self-Check: PASSED
- test/widget_test.dart, lib/presentation/README.md, lib/application/README.md exist; `pin_configured` and `onboarding/` greps hit.
- Commit a6dc9d1 is an ancestor of HEAD.
