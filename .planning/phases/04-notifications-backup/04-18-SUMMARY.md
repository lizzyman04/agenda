---
phase: 04-notifications-backup
plan: 18
subsystem: backup
tags: [ios, icloud, privacy, l10n, gap-closure]
requires: []
provides:
  - iOS launch-time exclusion of the Documents directory from iCloud/iTunes backup
  - iOS exclusion and storage-root contract test
  - Reinstall note true on both platforms
  - ARB strings for plans 04-20 and 04-21
affects: [04-20, 04-21]
tech-stack:
  added: []
  patterns: [source-text contract test for native config]
key-files:
  created:
    - test/data/backup/ios_backup_exclusion_contract_test.dart
  modified:
    - ios/Runner/AppDelegate.swift
    - lib/config/l10n/app_en.arb
    - lib/config/l10n/app_pt.arb
    - lib/config/l10n/app_pt_BR.arb
    - lib/generated/l10n/app_localizations.dart
    - lib/generated/l10n/app_localizations_en.dart
    - lib/generated/l10n/app_localizations_pt.dart
    - test/l10n/phase4_strings_test.dart
key-decisions:
  - "Exclude the Documents directory itself (plus backups) so Isar files and safety backups are covered without per-file calls"
requirements-completed: [DATA-04]
status: complete
commits: 2
plan_head_before: 81e22c8ba96754e2a4eb5ec55f3d97af40235aaf
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
metrics:
  completed: 2026-10-17
---

# Phase 4 Plan 18: iOS backup exclusion and gap-closure strings Summary

iOS now excludes the Documents directory (Isar database and `backups` safety copies) from iCloud and iTunes backup at every launch, pinned by a source-text contract test, and the Backup screen's reinstall note is accurate for both platforms.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: contract test, then AppDelegate exclusion | e114d45 |
| 2 | Privacy note and shared gap-closure strings | cc177f2 |

### Task 1
`AppDelegate.excludeUserDataFromBackup()` is the first statement in `didFinishLaunchingWithOptions`. It resolves the documents URL (returns if none), creates `backups` with `try?`, and sets `isExcludedFromBackup = true` through `setResourceValues` on both URLs. The class declaration, notification delegate line, `return super.application(...)` and `didInitializeImplicitFlutterEngine` are untouched.

RED evidence (run before the Swift edit), four of six cases failed:
- marks the documents directory excluded from backup
- declares excludeUserDataFromBackup
- runs the exclusion on every launch before Dart starts
- the backups directory name matches SafetyBackupStore

After the edit all 6 cases pass, as does `manifest_contract_test.dart` (iOS delegate group intact). `flutter analyze` on the new test: no issues.

Case 6 scans lib/ (excluding lib/generated/) for the forbidden path_provider roots, built from name parts so only the test spells them, and its failure message tells the reader to extend the exclusion in AppDelegate.swift first.

### Task 2
- `backupReinstallNote` now names Android Auto Backup and iCloud; `backupErrorTooLarge` covers the whole selection.
- 11 `backupSafety*` keys (including the `backupSafetyCount` plural with `=0`, `one`, `other`) and `notifSettingsOpenSettingsButton` added to all three ARB files with identical key sets.
- `flutter gen-l10n` regenerated the three committed l10n files.
- `test/l10n/phase4_strings_test.dart` extended per locale: non-empty strings, count for 0/1/7, iCloud in the note, open-settings differs from allow button.

## Verification
- `flutter test --no-pub test/data/backup/ios_backup_exclusion_contract_test.dart test/infrastructure/notifications/manifest_contract_test.dart`: all passed.
- `flutter test --no-pub test/l10n test/presentation/backup/backup_screen_test.dart`: all 49 passed.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (limit 65), all pre-existing infos.
- `dart run tool/check_architecture.dart`: PASS.

## Deviations from Plan

**1. [Rule 3 - Blocking] Worktree base was stale.** The worktree started at a57c4c8, which predates the commit that added 04-18-PLAN.md. Fast-forwarded the agent branch to `main` (81e22c8) with `git merge --ff-only`; no commits were lost. Also ran `flutter pub get --offline` because `.dart_tool` is not present in a fresh worktree.

Otherwise the plan was executed as written.

## Not verified here
- Device or simulator confirmation that Documents and `backups` report `isExcludedFromBackup = true`, and the Xcode compile of AppDelegate.swift, remain in 04-VERIFICATION.md human_verification (no Xcode on this host).
- NSFileProtectionComplete on the safety files was out of scope per the plan.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
Created test file, AppDelegate edits and ARB keys exist; commits e114d45 and cc177f2 present.
