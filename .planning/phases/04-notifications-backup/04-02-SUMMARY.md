---
phase: 04-notifications-backup
plan: 02
subsystem: l10n
tags: [l10n, arb, gen-l10n, notifications, backup, plurals]
status: complete

requires: []
provides:
  - "100 Phase 4 l10n keys (16 channel, 19 notification content, 22 settings page, 43 backup/import) in app_pt_BR.arb, app_pt.arb and app_en.arb"
  - "Regenerated lib/generated/l10n/app_localizations{,_en,_pt}.dart"
  - "test/l10n/phase4_strings_test.dart: lookup, plural and placeholder assertions in pt_BR and en"
affects:
  - "Plans 04-12..04-17 reference these exact key names and must not edit any ARB file"

tech-stack:
  added: []
  patterns:
    - "Notification text is produced with lookupAppLocalizations(locale) at schedule time, no BuildContext"
    - "Plural branches print {count} rather than a literal 1, so pt (where 0 is singular) never renders a wrong number"

key-files:
  created:
    - test/l10n/phase4_strings_test.dart
  modified:
    - lib/config/l10n/app_pt_BR.arb
    - lib/config/l10n/app_pt.arb
    - lib/config/l10n/app_en.arb
    - lib/generated/l10n/app_localizations.dart
    - lib/generated/l10n/app_localizations_en.dart
    - lib/generated/l10n/app_localizations_pt.dart

key-decisions:
  - "ICU plural 'one' branches interpolate {count} instead of a hardcoded 1, because Portuguese plural rules put 0 in the 'one' category"
  - "No notification string takes a money amount placeholder (T-04-02-01); a test regex asserts no currency symbol or decimal amount appears"

requirements-completed: [NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05, NOTF-06, NOTF-07, NOTF-08, NOTF-09, NOTF-10, DATA-02, DATA-03, DATA-04]

duration: 25 min
completed: 2026-10-16
commits: 2
plan_head_before: 859c4bc03d00eee2261d0cb9b07c3a7cdc3e2d7d
actuals:
  tokens: 30000
  tasks: 2
  commits: 2

coverage:
  - deliverable: "Channel and notification-content strings resolve through lookupAppLocalizations in both locales"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/l10n/phase4_strings_test.dart#Phase 4 notification strings"
        status: pass
  - deliverable: "Settings-page and backup/import strings with plurals and placeholders"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/l10n/phase4_strings_test.dart#Phase 4 settings and backup strings"
        status: pass
  - deliverable: "Wording and Portuguese naturalness of the 100 strings"
    human_judgment: true
    rationale: "Copy quality is not asserted by any test; a native reader should skim the UI strings on device."
---

# Phase 4 Plan 02: Phase 4 String Catalog Summary

**100 Phase 4 l10n keys (notification channels and content, notification settings, backup/export/import) added once to the pt_BR, pt and en ARB files and regenerated, so no later plan touches an ARB file.**

## Performance

- **Duration:** 25 min
- **Tasks:** 2 of 2
- **Files:** 6 modified, 1 created

## Accomplishments

- Task 1 (tracer): 16 Android channel keys and 19 notification content keys, with `phase4_strings_test.dart` proving both locales resolve them through `lookupAppLocalizations` without a `BuildContext`.
- Task 2: 22 notification-settings keys and 43 backup/export/import keys, including five ICU plurals (`notifSettingsWaiting`, `backupExportCsvDone`, `backupConfirmDeletedIncluded`, `backupWarnDanglingLinks`, `backupImportDoneCount`).
- Test file covers: channel strings non-empty, placeholders carried through, plural forms for 0/1/N, seven entity labels pairwise distinct, and no currency symbol or decimal amount in any notification content string.
- Catalog key list was diffed against the generated getters: 100 of 100 present, none absent.

## Task Commits

1. **Task 1: channel and notification content strings** - `abee08c` (feat)
2. **Task 2: settings page and backup/import strings** - `7bf03d5` (feat)

## Verification

- `flutter gen-l10n`: exit 0 after each task.
- `flutter test --no-pub test/l10n`: 29 tests passing (existing parity and LocaleCubit tests plus 24 new, 12 per locale).
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 65 issues (baseline held).
- `dart run tool/check_architecture.dart`: PASS.
- `app_pt.arb` and `app_pt_BR.arb` are identical apart from `@@locale`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plural 'one' branches use {count} rather than a literal 1**
- **Found during:** Task 1 (authoring the ARB entries)
- **Issue:** The catalog wrote `one{1 task due today}`. In Portuguese, ICU puts 0 in the `one` category, so a hardcoded "1" would render "1 registro importado" for a count of 0, violating the plan truth that plurals resolve correctly for 0, 1 and N.
- **Fix:** Every `one{...}` branch prints `{count}`. English output for 1 is unchanged; pt_BR output for 0 is now "0 registro importado."
- **Files modified:** lib/config/l10n/app_pt_BR.arb, app_pt.arb, app_en.arb
- **Commit:** abee08c, 7bf03d5

**2. [Process] Commits made on `main`**
- `git.base-branch --is-protected main` reports true. The orchestrator explicitly dispatched this plan as a sequential executor on the main working tree (`branching_strategy: none`, as with earlier phase 03 plans), so the commits were made there. No protected ref was rewritten.

**Total deviations:** 1 auto-fixed (Rule 1), 1 process note. **Impact:** none on scope; the string contract (key names, placeholders, English and Portuguese wording) is as planned.

## Known Stubs

None.

## Threat Flags

None. T-04-02-01 (no amounts in notification text) is mitigated and asserted by test; T-04-02-02 accepted as planned.

## Issues Encountered

None.

## Next Phase Readiness

Ready for the next Phase 4 plan. Later plans reference keys only, with the signatures as generated, for example `notifTaskReminderBody(String title, String time)`, `notifBriefingTitle(int count)`, `backupCountLine(String label, int count)`.

## Self-Check: PASSED

- test/l10n/phase4_strings_test.dart: FOUND
- Commits abee08c and 7bf03d5: FOUND
- Acceptance criteria re-run: gen-l10n, l10n tests, analyze (65), architecture guard, pt/pt_BR parity: all PASS
