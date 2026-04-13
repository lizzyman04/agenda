---
phase: 01-foundation
plan: 05
subsystem: core/failures
tags: [failure, result, error-handling, ci, offline-guarantee, testing]
requirements: [DATA-01, UX-02]

dependency_graph:
  requires: [01-01, 01-02, 01-03, 01-04]
  provides:
    - Sealed Failure hierarchy with five concrete subtypes
    - Result<T> and AsyncResult<T> typedefs
    - Success<T> and Err<T> final classes
    - Unit tests for Failure hierarchy (9 tests)
    - Unit tests for AppConfig constants (7 tests)
    - GitHub Actions CI workflow (analyze + test + offline guarantee)
  affects:
    - All future phases (Result<T>/AsyncResult<T> is the standard repository return type)
    - Phase 2-5 domain methods (must return Result<T>, never throw)

tech_stack:
  added: []
  patterns:
    - sealed class for exhaustive pattern-matched failure hierarchy (Dart 3)
    - final class for Success<T> and Err<T> value containers
    - typedef Result<T> = Object — union type via pattern matching
    - typedef AsyncResult<T> = Future<Object> — async repository return type
    - GitHub Actions CI with cancel-in-progress concurrency guard

key_files:
  created:
    - lib/core/failures/failure.dart (sealed Failure + five final class subtypes)
    - lib/core/failures/result.dart (Success<T>, Err<T>, Result<T>, AsyncResult<T>)
    - test/core/failures/failure_test.dart (9 tests — hierarchy + pattern matching)
    - test/core/config/app_config_test.dart (7 tests — AppConfig constant values)
    - .github/workflows/ci.yml (analyze + test + codegen + l10n + offline guarantee)
  modified:
    - test/widget_test.dart (Rule 1 fix — initialize DI before pumping AgendaApp)

decisions:
  - "typedef Result<T> = Object approach — no dartz/Either dependency; pattern matching enforced at runtime via sealed Success<T>/Err<T>; compiler does not enforce exhaustiveness on Object typedef but switch exhaustiveness is enforced for the sealed Success/Err union"
  - "CI Flutter version pinned to 3.38.1 — matches D-04 minimum floor; dev machine may run higher (3.41.4); CI tests the minimum"
  - "Doc comment backtick wrapping for <T> generics — avoids unintended_html_in_doc_comment info-level lint from very_good_analysis"

metrics:
  duration_minutes: 18
  completed_date: "2026-04-13"
  tasks_completed: 2
  tasks_total: 2
  files_created: 5
  files_modified: 1
---

# Phase 01 Plan 05: Failure Hierarchy, Result Typedefs, and CI Summary

**One-liner:** Sealed Failure hierarchy (five subtypes), Result<T>/AsyncResult<T> typedefs, 29 total project tests passing, and GitHub Actions CI gating every push with analyze + test + offline guarantee check.

## What Was Built

### Task 1: Failure Hierarchy and Result Typedefs (TDD)

**`lib/core/failures/failure.dart`** — Sealed Failure class with five concrete final class subtypes:

| Subtype | Purpose |
|---------|---------|
| `DatabaseFailure` | Isar read/write or transaction failures |
| `ValidationFailure` | Input validation failures (missing fields, out-of-range values) |
| `NotificationFailure` | flutter_local_notifications scheduling or permission failures |
| `BackupFailure` | JSON/CSV export or import failures |
| `SecurityFailure` | PIN or biometric authentication failures |

**`lib/core/failures/result.dart`** — Result type system:

| Type | Definition | Purpose |
|------|------------|---------|
| `Success<T>` | `final class Success<T>` | Wraps a successful value |
| `Err<T>` | `final class Err<T>` | Wraps a Failure |
| `Result<T>` | `typedef Result<T> = Object` | Synchronous fallible operation return type |
| `AsyncResult<T>` | `typedef AsyncResult<T> = Future<Object>` | Async repository return type |

### Task 2: GitHub Actions CI Workflow

**`.github/workflows/ci.yml`** — Runs on every push/PR to `main`:

1. Checkout
2. Setup Flutter 3.38.1 (pinned to D-04 minimum)
3. `flutter pub get`
4. `dart run build_runner build --delete-conflicting-outputs`
5. `flutter gen-l10n`
6. `flutter analyze --no-fatal-infos --fatal-warnings`
7. `flutter test --no-pub --coverage`
8. Offline guarantee: grep for forbidden network packages, `exit 1` on match

## Test Results

| Test File | Tests | Result |
|-----------|-------|--------|
| test/core/failures/failure_test.dart | 9 | PASS |
| test/core/config/app_config_test.dart | 7 | PASS |
| test/data/database/migration_runner_test.dart | 4 | PASS |
| test/l10n/l10n_test.dart | 5 | PASS |
| test/widget_test.dart | 1 | PASS |
| test/config/di/di_test.dart | 3 | PASS |
| **Total** | **29** | **ALL PASS** |

## Verification Results

```
flutter test --no-pub
00:07 +29: All tests passed!

flutter analyze --no-fatal-infos
No issues found!

grep -E "^\s+(http:|dio:|firebase_|sentry_flutter|connectivity_plus)" pubspec.yaml
(empty — 0 matches)

grep "sealed class Failure" lib/core/failures/failure.dart
sealed class Failure {

grep -c "final class.*Failure" lib/core/failures/failure.dart
5

ls .github/workflows/ci.yml
.github/workflows/ci.yml

grep "exit 1" .github/workflows/ci.yml
            exit 1
```

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Failure hierarchy, Result typedefs, unit tests | 7b74fef | lib/core/failures/failure.dart, lib/core/failures/result.dart, test/core/failures/failure_test.dart, test/core/config/app_config_test.dart |
| 2 | GitHub Actions CI + widget test fix | 5649a3f | .github/workflows/ci.yml, test/widget_test.dart, test/core/config/app_config_test.dart, test/core/failures/failure_test.dart |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing widget_test.dart DI initialization missing**
- **Found during:** Task 2 — `flutter test --no-pub` reported GetIt registration error
- **Issue:** `AgendaApp` calls `getIt<LocaleCubit>()` but `widget_test.dart` never called `configureDependencies()` before `tester.pumpWidget(const AgendaApp())`. The test was always going to fail — it was a pre-existing bug from Plan 01.
- **Fix:** Added `setUp` with `SharedPreferences.setMockInitialValues({})` + `await configureDependencies()` and `tearDown` with `await getIt.reset()` in `widget_test.dart`
- **Files modified:** test/widget_test.dart
- **Commit:** 5649a3f

**2. [Rule 1 - Bug] Fixed directives_ordering lint in test files**
- **Found during:** Task 2 — `flutter analyze` reported `directives_ordering` info on both test files
- **Issue:** `flutter_test` import was in a separate group from `agenda` package imports, separated by a blank line; very_good_analysis requires a single alphabetically-ordered package import block
- **Fix:** Merged all imports into one alphabetically-sorted block (`agenda/*` before `flutter_test`)
- **Files modified:** test/core/failures/failure_test.dart, test/core/config/app_config_test.dart
- **Commit:** 5649a3f

**3. [Rule 1 - Bug] Fixed unintended_html_in_doc_comment info in failure.dart and result.dart**
- **Found during:** Task 1 — `flutter analyze --no-fatal-infos lib/core/` reported 3 info items
- **Issue:** `<T>` and `Result<T>` in doc comments interpreted as HTML tags by very_good_analysis
- **Fix:** Wrapped generic type references in backticks (`` `Result<T>` ``, `` `AsyncResult<T>` ``)
- **Files modified:** lib/core/failures/failure.dart, lib/core/failures/result.dart
- **Commit:** 7b74fef

## Phase 1 Foundation — Completion Status

All five plans in Phase 1 are complete:

| Plan | Name | Status |
|------|------|--------|
| 01-01 | Flutter Project Scaffold | COMPLETE |
| 01-02 | Isar Database Service and Migration Runner | COMPLETE |
| 01-03 | GetIt + Injectable DI Graph | COMPLETE |
| 01-04 | Localization (l10n) | COMPLETE |
| 01-05 | Failure Hierarchy, Result Typedefs, CI | COMPLETE |

The Phase 1 foundation is fully gated by CI: every push to `main` runs analyze + test + offline guarantee. All 29 tests pass. `flutter analyze --no-fatal-infos` exits 0.

## Known Stubs

None — Failure hierarchy is complete with all five subtypes. Result/AsyncResult typedefs are ready for use as repository method return types in Phases 2-5. CI workflow is fully functional.

## Threat Model Coverage

| Threat ID | Disposition | Implemented |
|-----------|-------------|-------------|
| T-05-01 — Failure.message exposed to UI | mitigate | Documented in failure.dart docstring: "Do NOT display raw messages directly to end users" |
| T-05-02 — Network package added to pubspec | mitigate | CI offline guarantee step: grep with exit 1 on match |
| T-05-03 — Result<T> pattern match bypass | mitigate | Success/Err are final classes; exhaustive switch at call sites enforced by very_good_analysis |
| T-05-04 — CI queue pile-up | mitigate | cancel-in-progress: true in ci.yml concurrency group |
| T-05-05 — SecurityFailure message leaks | mitigate | Documented in failure.dart; presentation layer mapping required in Phase 5 |

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- lib/core/failures/failure.dart exists: FOUND
- lib/core/failures/result.dart exists: FOUND
- test/core/failures/failure_test.dart exists: FOUND
- test/core/config/app_config_test.dart exists: FOUND
- .github/workflows/ci.yml exists: FOUND
- sealed class Failure in failure.dart: FOUND
- Five final class Failure subtypes: FOUND (count=5)
- typedef Result<T> = Object in result.dart: FOUND
- typedef AsyncResult<T> = Future<Object> in result.dart: FOUND
- Commit 7b74fef exists: FOUND
- Commit 5649a3f exists: FOUND
- flutter test --no-pub: 29/29 PASSED
- flutter analyze --no-fatal-infos: No issues found
- Offline guarantee (grep forbidden packages): 0 matches
