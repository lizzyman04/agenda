---
phase: 04-notifications-backup
plan: 04
subsystem: backup
tags: [backup, json, export, isar, codecs, envelope, strict-decoding, di]
status: complete

requires:
  - phase: 03-finance-core
    provides: "Isar finance models (transaction, category, budget, goal, debt, recurring payment) and the BL-01 uncapped-read lesson"
  - phase: 06-architecture-compliance
    provides: "150-line / 10-file guard and the real-Isar IsarTestHarness"
provides:
  - "BackupRepository.exportJson: versioned JSON bytes plus agenda-backup-YYYY-MM-DD.json name, never throws"
  - "BackupDao.readAll: uncapped, unfiltered, single read-transaction snapshot of all seven collections (BackupRows)"
  - "JsonObjectReader: strict path-aware decoder (typing, 20000-char string cap, 9e15 int bound, enum by name, ISO dates)"
  - "Per-entity codecs item/transaction/category/budget/goal/debt/payment, each with a ToJson and a strict FromJson"
  - "buildBackupEnvelope / parseBackupEnvelope / ParsedEnvelope, backupFormatVersion = 1, backupAppId, BackupJsonKeys"
  - "BackupDao.isarService public field so the import engine reuses the DI graph"
affects:
  - "04-08 CSV export reuses BackupDao and the repository interface"
  - "04-11 import engine points the FromJson decoders and parseBackupEnvelope at untrusted files and adds version gating, size and row caps"
  - "04-16 backup cubit and screen call BackupRepository.exportJson and hand BackupFile to the file-picker gateway"

tech-stack:
  added: []
  patterns:
    - "Explicit codecs with JSON keys equal to Dart field names, independent of Isar generated code"
    - "Decoders return FormatException whose message starts with the full field path (items[3].dueDate)"
    - "Backup reads are deliberately uncapped and unfiltered; soft-deleted rows are exported so foreign keys survive"
    - "Export failures carry only the exception runtimeType, never a value-bearing message"

key-files:
  created:
    - lib/domain/backup/backup_file.dart
    - lib/domain/backup/backup_repository.dart
    - lib/data/backup/dao/backup_dao.dart
    - lib/data/backup/json/json_fields.dart
    - lib/data/backup/json/backup_envelope.dart
    - lib/data/backup/json/item_json_codec.dart
    - lib/data/backup/json/transaction_json_codec.dart
    - lib/data/backup/json/category_json_codec.dart
    - lib/data/backup/json/budget_json_codec.dart
    - lib/data/backup/json/goal_json_codec.dart
    - lib/data/backup/json/debt_json_codec.dart
    - lib/data/backup/json/payment_json_codec.dart
    - lib/infrastructure/backup/backup_repository_impl.dart
    - lib/config/di/backup_module.dart
    - test/data/backup/json_fields_test.dart
    - test/data/backup/export_items_test.dart
    - test/data/backup/json_roundtrip_test.dart
    - test/data/backup/export_completeness_test.dart
  modified:
    - lib/config/di/injection.config.dart

key-decisions:
  - "ParsedEnvelope exposes per-collection List<JsonObjectReader> (re-rooted so paths read items[3].field) rather than raw lists, so the import engine decodes rows without re-wrapping them"
  - "Export failure message is 'exportJson failed: <runtimeType>' only; an encoding error's own message can quote the offending value, which would leak content (T-04-04-02)"
  - "BackupDao.readItems was dropped once readAll existed; one read path means one place the no-cap, no-filter rule can be broken"
  - "BackupRepository carries an ignore for one_member_abstracts: it is a single-member interface only until import lands in 04-11"

patterns-established:
  - "Real-Isar export tests open all seven schemas whenever readAll is exercised, because a read transaction needs every collection it touches"
  - "Completeness tests seed 600 rows per collection with a tenth soft-deleted, the BL-01 regression shape"

requirements-completed: [DATA-02]

coverage:
  - id: D1
    description: "exportJson returns every row of all seven collections, soft-deleted included, with no row-count cap"
    requirement: DATA-02
    verification:
      - kind: integration
        ref: "test/data/backup/export_completeness_test.dart#600 rows per collection, soft-deleted included, all decode"
        status: pass
      - kind: integration
        ref: "test/data/backup/export_items_test.dart#exports all 600 items, soft-deleted included, field for field"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every model round-trips field for field, including embedded timeInfo/moneyInfo and ordered goal contributions, with a growable decoded list"
    requirement: DATA-02
    verification:
      - kind: integration
        ref: "test/data/backup/json_roundtrip_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Envelope carries app, formatVersion 1, schemaVersion and exportedAt; decoders reject wrong types, unknown enums, bad dates and over-long strings with a path-naming FormatException"
    requirement: DATA-02
    verification:
      - kind: unit
        ref: "test/data/backup/json_fields_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Single read transaction snapshot and DI registration without opening Isar"
    requirement: DATA-02
    verification:
      - kind: integration
        ref: "test/data/backup/json_roundtrip_test.dart#readAll returns all 600 rows of every collection"
        status: pass
      - kind: integration
        ref: "test/data/backup/export_completeness_test.dart#BackupRepository resolves without opening Isar"
        status: pass
    human_judgment: false
  - id: D5
    description: "Nothing in the export path writes payload content to logs"
    requirement: DATA-02
    verification: []
    human_judgment: true
    rationale: "Absence of logging is a property of the code, not of any assertion; a reviewer confirms there is no logging call in the export path."

actuals:
  tokens: 13000
  tasks: 3
  commits: 3
plan_head_before: 20d314767abbdc305d4b752be709b1edacf4c0c9

duration: 9 min
completed: 2026-10-16
---

# Phase 04 Plan 04: JSON Export Engine Summary

**Explicit, versioned codecs over all seven Isar models, read through one uncapped single-transaction snapshot into a formatVersion-1 envelope, exposed as `BackupRepository.exportJson` and proven lossless against 600 real rows per collection.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-16T05:53:25Z
- **Completed:** 2026-10-16T06:02:00Z
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files created/modified:** 19 (18 created, 1 regenerated)

## Accomplishments

- Tracer slice first: items traveled DAO, codec, envelope, repository, bytes, verified against 600 real Isar rows with 100 soft-deleted, before any other collection was added.
- Seven strict codecs share one `JsonObjectReader`, so the import engine in 04-11 can point the same decoders at hostile files. Every violation names its field path.
- `BackupDao.readAll` reads all seven collections in one `isar.txn`, with no `limit` and no `deletedAt` filter, and says why in its class doc (CR-04 / BL-01).
- `BackupRepositoryImpl` self-registers via `@LazySingleton(as: BackupRepository)`; `BackupModule` provides the DAO. A DI test resolves the repository without opening Isar.
- Full suite 403/403, `flutter analyze --no-fatal-infos --fatal-warnings` exit 0 at the 65-issue budget, architecture guard PASS (`lib/data/backup/json` holds 9 files).

## Task Commits

1. **Task 1: Tracer, items collection end to end** - `55fbe01` (feat)
2. **Task 2: Transaction, category, budget and goal codecs; single-transaction readAll** - `0d624c3` (feat)
3. **Task 3: Debt and payment codecs, full export, DI registration, completeness test** - `73bb8e0` (feat)

**Plan metadata:** committed separately as `docs(04-04): complete JSON export engine plan`.

The tracer gate ran in the default `end-of-phase` mode with an automated-only `<verify>`: the command was re-run end to end and passed, so no human checkpoint was synthesized.

## Files Created/Modified

- `lib/domain/backup/backup_file.dart`, `backup_repository.dart` - domain contract: file value type and `exportJson`
- `lib/data/backup/dao/backup_dao.dart` - `BackupDao.readAll` and `BackupRows`
- `lib/data/backup/json/json_fields.dart` - `JsonObjectReader`, `encodeJsonDate`, `maxJsonStringLength`
- `lib/data/backup/json/backup_envelope.dart` - envelope build and parse, `BackupJsonKeys`
- `lib/data/backup/json/*_json_codec.dart` (7) - per-entity encode and strict decode
- `lib/infrastructure/backup/backup_repository_impl.dart` - `exportJson`
- `lib/config/di/backup_module.dart`, `injection.config.dart` - DI wiring
- `test/data/backup/*` (4) - strictness, items tracer, round-trip, 600-row completeness plus DI

## Decisions Made

See `key-decisions` above. The two that matter downstream: `ParsedEnvelope` hands out re-rooted `JsonObjectReader` rows, and failure messages never include value-bearing exception text.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 1 test had to open all seven schemas once Task 2 landed**
- **Found during:** Task 2 (verification after switching `exportJson` to `readAll`)
- **Issue:** `export_items_test.dart` opened only `ItemModelSchema`. `readAll` reads seven collections in one transaction, so Isar failed on the unopened collections and `exportJson` returned `Err`.
- **Fix:** The test now opens all seven schemas and says why in a comment. Still seeds and asserts only items.
- **Files modified:** `test/data/backup/export_items_test.dart`
- **Verification:** `flutter test --no-pub -j 1 test/data/backup` passes.
- **Commit:** `0d624c3`

**2. [Rule 1 - Bug] Plan said 100 soft-deleted items; the first draft seeded 99**
- **Found during:** Task 1
- **Issue:** `i < 100` over ids 1..600 yields 99 deleted rows, not the 100 the plan specifies.
- **Fix:** `i <= 100`, asserted as 100.
- **Files modified:** `test/data/backup/export_items_test.dart`
- **Commit:** `55fbe01`

**3. [Rule 2 - Missing critical] `readItems` removed after `readAll` replaced it**
- **Issue:** Plan says to replace the `readItems` usage; leaving the method would keep a second uncapped read path and dead code.
- **Fix:** Deleted it in Task 2. `grep readItems` across `lib` and `test` is empty.
- **Commit:** `0d624c3`

**4. [Rule 3 - Blocking] `one_member_abstracts` lint on the repository interface**
- **Issue:** The plan requires `analyze` to report no issues, and a one-method interface trips this lint.
- **Fix:** Documented `// ignore: one_member_abstracts` (same approach as `KindPlanner` in 04-03), because 04-11 adds `importJson`.
- **Files modified:** `lib/domain/backup/backup_repository.dart`
- **Commit:** `55fbe01`

**Total deviations:** 4 auto-fixed (2 blocking, 1 bug, 1 missing-critical). **Impact:** none on scope or behavior; all are test or lint housekeeping implied by the plan.

## Authentication Gates

None.

## Issues Encountered

- The `rtk` shell hook rewrote some `ls` and `grep` output to empty or condensed text. Worked around with `find`, `rtk proxy grep`, and direct file reads. No effect on the code.
- `dart format` on the new backup files produced the tall style used by the formatter rather than the older compact style visible elsewhere in the tree. Only files owned by this plan were formatted.

## Known Stubs

None. Every collection is exported and covered by a test.

## Threat Flags

None. No new network endpoint, auth path, or trust boundary beyond the plan's threat model. T-04-04-02 (no logging of export content) is honored by emitting only `runtimeType` on failure; T-04-04-03 (hostile decoder input) is mitigated by `JsonObjectReader`'s typing, length cap and integer bound.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for the next plan in wave order. 04-11 can reuse every `*FromJson`, `parseBackupEnvelope`, and `BackupDao.isarService` unchanged; it still owns version gating, file-size and row-count caps, and validate-before-write.

## Self-Check: PASSED

- All 18 created files exist on disk (`[ -f ]` verified).
- Commits `55fbe01`, `0d624c3`, `73bb8e0` present in `git log`.
- `git rev-list --count 20d3147..HEAD` measured 3 before this SUMMARY commit.
- `flutter test --no-pub -j 1 test/data/backup test/config/di`: 22 passed. Full suite: 403 passed.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 65 issues (budget held); new files report none.
- `dart run tool/check_architecture.dart`: PASS.
