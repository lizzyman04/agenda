---
phase: 05-app-lock-settings-polish
plan: 04
subsystem: ui
tags: [flutter, onboarding, privacy, shared_preferences, l10n, segmented-button]

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-01 privacy ARB strings (privacyStatement, privacyIntro, four bullets, privacyGetStarted, settingsPrivacyLabel) and StorageKeys.privacyStatementShown"
provides:
  - "OnboardingGate: synchronous first-launch flag read, persist-then-transition into the shell"
  - "PrivacyStatementScreen with first-launch and readOnly modes (readOnly is ready for Settings > About)"
  - "PrivacyBullet and PrivacyLanguageSwitch widgets"
  - "app.dart home wraps TaskListCubit/DayPlannerCubit + AppShell in OnboardingGate"
affects: [05-settings-screen, app-lock-root, widget_test]

actuals:
  tokens: 5171
  tasks: 2
  commits: 2
plan_head_before: 5b96a0c5886221749890146d2a8fc86919cf9e53
plan_head_after: e1bbb85b5d2970a0dde22f5fcbe37b5eb80bd001

tech-stack:
  added: []
  patterns:
    - "Root gate swaps its own subtree (no pushed route) so there is no back route to the statement"
    - "Persist first, then transition: setBool must return true before setState"

key-files:
  created:
    - lib/presentation/onboarding/widgets/onboarding_gate.dart
    - lib/presentation/onboarding/screens/privacy_statement_screen.dart
    - lib/presentation/onboarding/widgets/privacy_bullet.dart
    - lib/presentation/onboarding/widgets/privacy_language_switch.dart
    - lib/presentation/onboarding/README.md
    - lib/presentation/onboarding/screens/README.md
    - lib/presentation/onboarding/widgets/README.md
    - test/presentation/onboarding/privacy_statement_test.dart
  modified:
    - lib/app.dart
    - test/widget_test.dart

key-decisions:
  - "Language segment labels are literal endonym constants ('Português' / 'English'), not languageNamePtBr / languageNameEn, because languageNamePtBr reads 'Português (Brasil)'"
  - "PrivacyStatementScreen stays a StatelessWidget; the in-flight disable lives in a private _GetStartedButton StatefulWidget in the same file"
  - "First-launch full-app tests clear the getIt SharedPreferences instance instead of re-seeding mock values, since setUp has already pre-resolved it"

patterns-established:
  - "Onboarding gate: sync prefs read in initState, null or throw means not shown"

requirements-completed: [UX-03]

coverage:
  - id: D1
    description: "First launch shows the privacy statement before any main UI; Começar persists the flag and enters the shell; a later launch skips it"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/widget_test.dart#First launch (UX-03)"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#OnboardingGate first launch"
        status: pass
    human_judgment: false
  - id: D2
    description: "Headline, intro and the four D-13 bullets render in order"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#renders headline, intro and the four bullets in order"
        status: pass
    human_judgment: false
  - id: D3
    description: "Português / English switch re-renders the statement and sets LocaleCubit"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#English re-renders the statement and sets the locale"
        status: pass
    human_judgment: false
  - id: D4
    description: "Read-only mode: AppBar 'Privacidade' with back arrow, no switch, no Começar"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#read-only mode: AppBar with back, no switch, no button"
        status: pass
    human_judgment: false
  - id: D5
    description: "Failed flag write (false or throw) keeps the statement; 200% text on 320x568 scrolls and keeps Começar visible"
    requirement: UX-03
    verification:
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#a failed flag write keeps the statement (backstop)"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/onboarding/privacy_statement_test.dart#320x568 at 200% text scrolls and keeps Começar (backstop)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Statement copy makes no encryption or over-reaching privacy claim (T-05-13)"
    requirement: UX-03
    verification: []
    human_judgment: true
    rationale: "Transparency of the privacy promise is a copy judgment; tests only pin that the four reviewed ARB bullets render"

duration: 7min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 04: First-Launch Privacy Statement Summary

**OnboardingGate reads `privacy_statement_shown` synchronously and shows a one-screen, four-bullet privacy statement (with a Português/English switch) until "Começar" successfully persists the flag; the same screen has a read-only mode for Settings > About.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-16T19:02:26Z
- **Completed:** 2026-11-16T19:09:28Z
- **Tasks:** 2
- **Files modified:** 10 (8 created, 2 modified)

## Accomplishments

- `OnboardingGate` makes the statement the root on first launch and swaps in the shell only after `setBool` returns true. A write that returns false or throws keeps the statement on screen.
- `app.dart` now creates `TaskListCubit` and `DayPlannerCubit` inside the gate's child, so no Isar-backed task cubit starts under the privacy screen. The providers above `MaterialApp` are unchanged.
- `PrivacyStatementScreen` follows the UI-SPEC column: shield hero, headline, intro, four wrapping bullets and a pinned 48dp "Começar" that is disabled while the write runs. `readOnly` adds an AppBar titled "Privacidade" and drops the switch and button.
- `PrivacyLanguageSwitch` drives `LocaleCubit.setLocale`, and the statement re-renders right away.
- Added tests: 2 full-app first-launch tests in `widget_test.dart` and 8 gate/screen tests. The full suite passes (990 tests). Analyze is unchanged at 64 issues and the architecture guard passes.

## Task Commits

1. **Task 1 (tracer): first launch shows the statement, Começar persists and enters the shell, second launch skips it** - `661b6f3` (feat)
2. **Task 2: language switch, read-only mode, failure and overflow backstops, READMEs** - `e1bbb85` (feat)

## Files Created/Modified

- `lib/presentation/onboarding/widgets/onboarding_gate.dart` - root gate with sync read and persist-then-transition
- `lib/presentation/onboarding/screens/privacy_statement_screen.dart` - statement page, both modes (132 lines)
- `lib/presentation/onboarding/widgets/privacy_bullet.dart` - icon plus wrapping text row
- `lib/presentation/onboarding/widgets/privacy_language_switch.dart` - Português/English SegmentedButton
- `lib/presentation/onboarding/{,screens/,widgets/}README.md` - slice docs (architecture guard)
- `lib/app.dart` - `home: OnboardingGate(child: MultiBlocProvider(task cubits, AppShell))`
- `test/widget_test.dart` - seeds `privacy_statement_shown: true` and adds the first-launch and later-launch tests
- `test/presentation/onboarding/privacy_statement_test.dart` - order, persistence, second launch, language, read-only, two failure cases and an overflow test

## Decisions Made

- The segment labels are literal endonyms rather than ARB keys, because `languageNamePtBr` is "Português (Brasil)". This is documented in the widget and in its README.
- The in-flight disable lives in a private `_GetStartedButton` StatefulWidget, so `PrivacyStatementScreen` keeps its StatelessWidget contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] First-launch full-app tests clear prefs instead of re-seeding mock values**
- **Found during:** Task 1
- **Issue:** The plan says to override the mock values to `{}` inside the new tests, but the shared `setUp` has already pre-resolved `SharedPreferences` into getIt with the seeded flag, so re-seeding afterwards would have no effect.
- **Fix:** The first-launch test calls `getIt<SharedPreferences>().clear()` before pumping, which gives the same empty-prefs state.
- **Files modified:** test/widget_test.dart
- **Commit:** 661b6f3

**2. [Rule 1 - Lint] discarded_futures in the failure-test setUp**
- **Found during:** Task 2 verification (analyze went from 64 to 65)
- **Fix:** `setUp` is now async and awaits `getIt.unregister` before registering the mock. Analyze is back to the 64 baseline.
- **Files modified:** test/presentation/onboarding/privacy_statement_test.dart
- **Commit:** e1bbb85

## Issues Encountered

None.

## Known Stubs

None. `readOnly` mode is complete. Nothing pushes it yet: the Settings > About entry point belongs to the later Settings plan.

## Next Phase Readiness

- The Settings screen can push `const PrivacyStatementScreen(readOnly: true)` from its About section.
- Any future full-app test must seed `privacy_statement_shown: true`, or the statement is the first frame.

## Self-Check: PASSED

- All 8 created files found on disk.
- Commits 661b6f3 and e1bbb85 are ancestors of HEAD.
- `grep -c OnboardingGate lib/app.dart` returns 1 and `grep -c privacy_statement_shown test/widget_test.dart` returns 2.
