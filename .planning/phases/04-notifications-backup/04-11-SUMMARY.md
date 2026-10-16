---
phase: 04-notifications-backup
plan: 11
subsystem: backup-import
tags: [import, atomic-transaction, isar, json, csv, safety-backup, validation, category-resolution]
status: complete

requires:
  - phase: 04-notifications-backup
    provides: "04-04 BackupDao.readAll/isarService, BackupFile, backup envelope, strict *FromJson codecs, BackupJsonKeys"
  - phase: 04-notifications-backup
    provides: "04-08 decodeCsvTable, CsvRowReader, ParsedCsvRow, six mappers with signature/fromRow"
provides:
  - "BackupImporter.replace: ONE writeTxn that clears the supplied collections and putAlls rows with explicit ids (CSV category resolution inside the same transaction)"
  - "parseBackupFiles + maxImportFileBytes: size cap, UTF-8, JSON/CSV classification, version gates, mixed/duplicate/empty detection"
  - "validateSnapshot / ValidationReport and buildImportPreview: duplicate ids, budget keys, ranges, negative cents, row cap, dangling-link and soft-delete counts"
  - "SafetyBackupStore: generated names under <documents>/backups, keep-newest-3 rotation"
  - "resolveCsvCategories / CategoryResolution: id, then name, then create-custom, else invalid"
  - "BackupRepository.prepareImport / commitImport / discardImport / lastSafetyBackupPath, ImportPreview, ImportResult, ImportErrorCode, importErrorCodeOf, BackupEntity"
affects: [04-16, 04-17]

plan_head_before: f2bd51c71a5085f242581fa4f986d1c94d6d9950
commits: 3
actuals:
  tokens: 23000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Importer works on the collections directly inside one writeTxn and never catches inside it, so Isar aborts and restores every cleared collection"
    - "Prepare is a pure in-memory pipeline (parse, validate, dry-run category resolution); only commit touches disk or the database"
    - "Error codes travel as a message prefix '<code>: <detail>' on BackupFailure; details name a row or path, never cell content"
    - "Picked file names are never used: errors refer to files by position, safety files get clock-generated names"

key-files:
  created:
    - lib/domain/backup/backup_entity.dart
    - lib/domain/backup/import_preview.dart
    - lib/data/backup/import/backup_snapshot.dart
    - lib/data/backup/import/backup_importer.dart
    - lib/data/backup/import/snapshot_parser.dart
    - lib/data/backup/import/snapshot_validator.dart
    - lib/data/backup/import/import_preview_builder.dart
    - lib/data/backup/import/safety_backup_store.dart
    - lib/data/backup/import/csv_category_resolver.dart
    - lib/data/backup/csv/csv_snapshot_reader.dart
    - lib/infrastructure/backup/import_session.dart
    - test/support/backup_seed.dart
    - test/data/backup/import_atomicity_test.dart
    - test/data/backup/snapshot_parser_test.dart
    - test/data/backup/snapshot_validator_test.dart
    - test/data/backup/safety_backup_store_test.dart
    - test/data/backup/import_flow_test.dart
  modified:
    - lib/data/backup/dao/backup_dao.dart
    - lib/domain/backup/backup_repository.dart
    - lib/infrastructure/backup/backup_repository_impl.dart

key-decisions:
  - "Assumption A4 proven by test: after an explicit-id restore, a new auto-increment row gets an id above every imported id in all seven collections, so the id-remapping contingency was not needed"
  - "Import state lives in ImportSession (infrastructure) so BackupRepositoryImpl stays under the 150-line cap; the repository constructs BackupImporter and SafetyBackupStore itself and its constructor still takes only the BackupDao (no DI regeneration), but it is no longer const"
  - "commitImport consumes the prepared snapshot immediately; after a failed commit the user must prepare again, which also makes in-place categoryId rewriting during CSV resolution safe"
  - "CSV category resolution runs twice: as a dry run at prepare (unresolvable rows fail before any write) and again inside the commit transaction against the categories as they are then"
  - "SafetyBackupStore.directoryResolver is a visibleForTesting static hook, so repository-level tests can redirect the documents directory without changing the DI constructor"
  - "Validator keys unresolved CSV budgets by lower-cased category name so two rows with different names are not reported as one repeated key"

patterns-established:
  - "Shared import fixtures in test/support/backup_seed.dart (seedSnapshot, seedDatabase, rowsJson, snapshotJson, jsonFileOf, csvFilesOf) built with the real exporters"

requirements-completed: [DATA-04]

coverage:
  - id: D1
    description: "A snapshot replaces the supplied collections in one transaction with explicit ids preserved; a failure after the clears restores every collection"
    requirement: "DATA-04"
    verification:
      - kind: integration
        ref: "test/data/backup/import_atomicity_test.dart#BackupImporter.replace replaces every collection, preserving explicit ids"
        status: pass
      - kind: integration
        ref: "test/data/backup/import_atomicity_test.dart#BackupImporter.replace a failure after the clears restores every collection"
        status: pass
    human_judgment: false
  - id: D2
    description: "Auto-increment keeps working after explicit-id writes (assumption A4)"
    requirement: "DATA-04"
    verification:
      - kind: integration
        ref: "test/data/backup/import_atomicity_test.dart#BackupImporter.replace auto-increment passes every imported id (assumption A4)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hostile or malformed input is rejected before any write with explicit codes: size, UTF-8, app id, newer versions, mixed, duplicate, unknown enums, duplicate ids and budget keys, ranges, negative cents, row cap"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/data/backup/snapshot_parser_test.dart"
        status: pass
      - kind: unit
        ref: "test/data/backup/snapshot_validator_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Two-phase pipeline: prepare writes nothing; commit writes a safety backup of the replaced data and then restores the file; JSON replaces everything, CSV only what it supplied"
    requirement: "DATA-04"
    verification:
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#JSON round trip prepare shows A and writes nothing; commit restores A"
        status: pass
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#CSV a goals-only CSV leaves every other collection untouched"
        status: pass
    human_judgment: false
  - id: D5
    description: "CSV category resolution by name (case-insensitive, type-compatible) or one created custom category; unresolvable rows are invalid"
    requirement: "DATA-04"
    verification:
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#CSV known category names resolve to existing categories"
        status: pass
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#CSV a brand-new category name creates exactly one custom category"
        status: pass
    human_judgment: false
  - id: D6
    description: "Safety backup rotation keeps the newest three, handles collisions and never touches unrelated files; a failed commit keeps the safety path and leaves data unchanged"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/data/backup/safety_backup_store_test.dart"
        status: pass
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#CSV a category deleted after prepare fails the commit cleanly"
        status: pass
      - kind: integration
        ref: "test/data/backup/import_flow_test.dart#a safety backup that cannot be written aborts before any change"
        status: pass
    human_judgment: false
  - id: D7
    description: "Safety backups are excluded from Android Auto Backup and never leave the app-private directory"
    verification: []
    human_judgment: true
    rationale: "The exclusion is configured in Android XML by plan 04-05; only a device-level backup run proves it, and the tests here only assert the file location."

duration: 17 min
completed: 2026-10-16
---

# Phase 4 Plan 11: Import Engine Summary

**Two-phase JSON/CSV import: prepare parses and validates everything in memory into a typed snapshot and preview, commit writes a rotated safety backup and then replaces data inside one Isar write transaction that rolls back completely on any failure.**

## Performance

- **Duration:** 17 min (2026-10-16T07:14:58Z to 07:31Z, plus summary and state updates)
- **Tasks:** 3 of 3 (Task 1 tracer, Task 2 and 3 auto)
- **Files:** 20 (17 created, 3 modified)

## Accomplishments

- Tracer first: a snapshot replaces a seeded database in one `writeTxn`, a duplicate budget key forced after the clears leaves all seven collections exactly as they were, and a partial snapshot touches only its own collection. The tracer gate (end-of-phase mode, automated-only verify) was re-run end to end and passed before expansion.
- Assumption A4 holds in this Isar version: the next auto-increment id is above every imported id in every collection, with no imported row overwritten. The documented id-remapping contingency was therefore not built.
- `parseBackupFiles` checks byte length before any decode, rejects invalid UTF-8, mixes of JSON and CSV, two JSON files, repeated CSV entities and unrecognised layouts, and gates `formatVersion`/`schemaVersion` before decoding the rows. JSON rows go through the plan 04-04 strict codecs and CSV rows through the plan 04-08 mappers, detected by header signature rather than file name.
- `validateSnapshot` reports duplicate explicit ids (auto-increment rows are never duplicates), repeated budget keys, bad months, `dueTimeMinutes` outside 0..1439, negative cents in every money field and the 200000-row cap; dangling foreign keys are only counted, matching the app's hard-deleted custom categories.
- `commitImport` order is verified end to end: export the current data, write it through `SafetyBackupStore`, then replace atomically. A safety write failure aborts before any change; a replace failure keeps `lastSafetyBackupPath`.
- CSV rows with unknown or blank category ids resolve by name (case-insensitive, trimmed, `namePtBr` or `nameEn`, type-compatible) or create one de-duplicated custom category inside the same transaction; a row with neither is `invalid`.
- Full suite 618/618; `test/data/backup` 124/124.

## Task Commits

1. **Task 1 (tracer): atomic snapshot replace, auto-increment proven** - `2e253e4` (feat)
2. **Task 2: parser, validator, preview, domain contracts** - `54abb1c` (feat)
3. **Task 3: safety backup, CSV category resolution, repository pipeline** - `bc74166` (feat)

**Plan metadata:** committed separately as `docs(04-11): complete import engine plan`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Import state moved into `lib/infrastructure/backup/import_session.dart`**
- **Found during:** Task 3
- **Issue:** Adding prepare/commit/discard, the pending snapshot and the committing flag to `BackupRepositoryImpl` would push it past the 150-line architecture cap (it had 83 lines).
- **Fix:** `ImportSession` holds the pending snapshot, flag and safety path. The repository still builds `BackupImporter(_dao.isarService)` and `SafetyBackupStore()` as a `late final` field, so the plan's key link and `grep "BackupImporter("` hold.
- **Files modified:** lib/infrastructure/backup/import_session.dart (new), lib/infrastructure/backup/backup_repository_impl.dart
- **Commit:** bc74166

**2. [Rule 3 - Blocking] CSV decoding placed in `lib/data/backup/csv/csv_snapshot_reader.dart`**
- **Found during:** Task 2
- **Issue:** JSON and CSV decoding together in `snapshot_parser.dart` would exceed 150 lines.
- **Fix:** `parseBackupFiles` keeps the gating and the JSON path; the CSV entity detection and row decoding live in the csv directory (6 files). This keeps `data/backup/import/` at exactly 7 files as the plan's acceptance criterion says.
- **Commit:** 54abb1c

**3. [Rule 3 - Blocking] `BackupRepositoryImpl` constructor is no longer `const`**
- **Issue:** The repository now owns mutable import state through its lazy session. The constructor still takes only the `BackupDao`, and the generated DI call `BackupRepositoryImpl(gh<BackupDao>())` is unchanged, so no regeneration was needed (DI tests pass).
- **Commit:** bc74166

**4. [Rule 3 - Blocking] `BackupImporter` and `SafetyBackupStore` are plain classes, not `final`**
- **Issue:** They are non-final so tests and later plans can substitute them; `SafetyBackupStore.directoryResolver` is a `@visibleForTesting` static so repository tests can redirect the documents directory without changing the DI constructor.
- **Commit:** 2e253e4, bc74166

**5. [Process] Task 2 was not committed as RED then GREEN**
- **Issue:** Task 2 carries `tdd="true"`, but implementation and tests were written together and committed once. The tests were checked against the genuinely exported bytes of plans 04-04 and 04-08 and all 28 pass; there is no separate failing-test commit.

**Added test support (not in the plan's file list):** `test/support/backup_seed.dart` shares one internally consistent seven-collection fixture and the JSON/CSV builders across the new tests.

**Total deviations:** 4 auto-fixed (Rule 3), 1 process slip. **Impact:** none on scope or behavior; all keep the architecture guard green.

## Issues Encountered

- The `rtk` shell filter emptied or condensed `ls`, `grep` and `find` output in places; file reads and `rtk proxy` were used instead. `flutter test` prints an unrelated "Building Linux applications requires..." notice on this host.
- A first draft of the A4 test compared every collection against one id (102); single-row collections legitimately end at 101. The assertion was corrected to the per-collection maximum, not weakened.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub -j 1 test/data/backup/import_atomicity_test.dart` | 4/4 pass |
| `flutter test --no-pub test/data/backup/snapshot_parser_test.dart test/data/backup/snapshot_validator_test.dart` | 28/28 pass |
| `flutter test --no-pub -j 1 test/data/backup` | 124/124 pass (plans 04-04, 04-08, 04-11) |
| `flutter test --no-pub -j 1` (full suite) | 618/618 pass |
| `flutter analyze` on backup lib and test directories | no issues |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 64 issues (budget 65) |
| `dart run tool/check_architecture.dart` | PASS (`data/backup/import/` holds 7 files) |
| `grep -n writeTxn lib/data/backup/import/backup_importer.dart` | one call site |
| `grep -n 26214400 lib/data/backup/import/snapshot_parser.dart` | match; the `bytes.length` check precedes `jsonDecode` |
| `grep -n "BackupImporter(" lib/infrastructure/backup/backup_repository_impl.dart` | match; constructor still takes only the BackupDao |

## Threat Flags

None beyond the plan's register. T-04-11-01 to -03 are covered by tests (hostile input, size cap before decode, rollback after forced unique-key failure); -04 and -05 by generated names and the app-private directory; -06 by the abort-before-change test.

## Known Stubs

None.

## Next Phase Readiness

Plan 04-17 can call `prepareImport`, show `ImportPreview` (counts, date range, warnings, `isPartial`), then `commitImport`, mapping `importErrorCodeOf` codes to localized text and showing `lastSafetyBackupPath` on `importFailed`. After a successful import it still has to run its post-import alert and reconcile hooks. A failed commit consumes the prepared import, so the UI must offer picking the file again.

## Self-Check: PASSED

All 17 created files exist on disk; commits `2e253e4`, `54abb1c` and `bc74166` are present in `git log`; `git rev-list --count f2bd51c..HEAD` measured 3 before this SUMMARY commit.
