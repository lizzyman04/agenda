---
phase: 04-notifications-backup
plan: 08
subsystem: backup-csv
tags: [csv, export, import-decode, injection-guard, locale, isar, backup]

requires:
  - phase: 04-notifications-backup
    provides: "04-04 BackupRepository, BackupDao.readAll, BackupFile, json_fields (maxJsonStringLength, JsonObjectReader, encodeJsonDate)"
  - phase: 04-notifications-backup
    provides: "04-05 csv 8.0.0 pinned and its confirmed API names (top-level Csv class)"
provides:
  - "CsvDialect (PT ';' and ',', EN ',' and '.'), csvBom, csvLineDelimiter, CsvContext, formatCsvDate, formatCsvDateOrEmpty, parseCsvDate"
  - "needsCsvGuard / guardCsvText / unguardCsvText: lossless CWE-1236 injection guard"
  - "formatAmountCell and strict parseAmountCell (rejects signs, ambiguous thousands groups, over-long numbers)"
  - "encodeCsvTable (BOM + CRLF) and decodeCsvTable (BOM strip, delimiter sniffed from header, row cap, ragged-row errors), CsvTable"
  - "CsvRowReader and ParsedCsvRow with row/column FormatExceptions"
  - "Six mappers (tasks, transactions, budgets, goals, debts, recurring_payments), each with fileStem, header, signature, toRow, fromRow"
  - "BackupRepository.exportCsv: six per-entity files, active rows only, uncapped"
affects: [04-11, 04-16]

plan_head_before: 3cdc6b420435f16d23f46520a717c8a78467578a
commits: 4
actuals:
  tokens: 18000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Each CSV mapper writes toRow and fromRow together so the round trip is provable in one place"
    - "Text columns are guarded on export and unguarded on import; ids, enums, dates and numbers are never guarded"
    - "Decoder errors always start 'row <n>, column <name>:' and never echo cell content"
    - "Spreadsheet row numbering: the header is row 1, the first data row is row 2"

key-files:
  created:
    - lib/data/backup/csv/csv_format.dart
    - lib/data/backup/csv/csv_text_guard.dart
    - lib/data/backup/csv/csv_amount.dart
    - lib/data/backup/csv/csv_table_codec.dart
    - lib/data/backup/csv/csv_row_reader.dart
    - lib/data/backup/csv/mappers/transaction_csv_mapper.dart
    - lib/data/backup/csv/mappers/task_csv_mapper.dart
    - lib/data/backup/csv/mappers/budget_csv_mapper.dart
    - lib/data/backup/csv/mappers/goal_csv_mapper.dart
    - lib/data/backup/csv/mappers/debt_csv_mapper.dart
    - lib/data/backup/csv/mappers/payment_csv_mapper.dart
    - lib/infrastructure/backup/csv_export_builder.dart
    - test/data/backup/csv_primitives_test.dart
    - test/data/backup/csv_decode_test.dart
    - test/data/backup/csv_roundtrip_test.dart
    - test/data/backup/csv_export_test.dart
  modified:
    - lib/domain/backup/backup_repository.dart
    - lib/infrastructure/backup/backup_repository_impl.dart

key-decisions:
  - "Blank category_id decodes to 0 (unresolved) and the unguarded category_name travels in ParsedCsvRow; a row with neither is rejected, so plan 04-11 resolves categories by name"
  - "The integer *_cents column is authoritative and may be negative; the display amount column is strict and never accepts a sign"
  - "Money amounts on tasks round-trip as (amount * 100).round() cents, so more than two decimals are not preserved in CSV"
  - "contributions_json errors forward only JsonObjectReader path messages, never jsonDecode text, because that text can quote cell content"
  - "Unknown priority or size names fall back to medium or none; unknown task type, direction, cycle or transaction type are errors"

patterns-established:
  - "Export builder lives in lib/infrastructure/backup/csv_export_builder.dart so the repository stays under the 150-line cap"

requirements-completed: [DATA-03, DATA-04]

coverage:
  - id: D1
    description: "exportCsv returns six per-entity files, active rows only, uncapped (600 rows each), canonical English headers, BOM and CRLF"
    requirement: "DATA-03"
    verification:
      - kind: integration
        ref: "test/data/backup/csv_export_test.dart#exportCsv completeness six uncapped, active-only files (pt)"
        status: pass
      - kind: integration
        ref: "test/data/backup/csv_export_test.dart#exportCsv completeness six uncapped, active-only files (en)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Locale dialects: PT writes ';' and ',', EN writes ',' and '.', amount_cents written beside the display amount"
    requirement: "DATA-03"
    verification:
      - kind: unit
        ref: "test/data/backup/csv_primitives_test.dart#encodeCsvTable PT dialect: BOM, semicolons, CRLF, quoting"
        status: pass
      - kind: integration
        ref: "test/data/backup/csv_export_test.dart#exportCsv completeness six uncapped, active-only files (pt)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Lossless formula-injection guard and strict amount parser that never flips a sign"
    requirement: "DATA-03"
    verification:
      - kind: unit
        ref: "test/data/backup/csv_primitives_test.dart#CSV text guard guard then unguard is lossless for every input"
        status: pass
      - kind: unit
        ref: "test/data/backup/csv_decode_test.dart#parseAmountCell rejects everything else, never flipping a sign"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every mapper decodes what it encodes in both dialects; hand-edited files with reordered or missing columns decode; bad cells name row and column"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/data/backup/csv_roundtrip_test.dart"
        status: pass
      - kind: unit
        ref: "test/data/backup/csv_decode_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "Exported files open correctly in real spreadsheet software (Excel, LibreOffice) in both locales"
    verification: []
    human_judgment: true
    rationale: "Only the file bytes are asserted; how Excel or LibreOffice interpret the BOM, delimiter and decimal separator needs a human with the applications."

duration: 11min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 08: CSV engine and exportCsv Summary

**Locale-aware, injection-guarded CSV engine on csv 8.0.0: six per-entity mappers that encode and strictly decode, a BOM/CRLF table codec with header-sniffed delimiters, and `BackupRepository.exportCsv` returning all active rows uncapped.**

## Performance

- **Duration:** 11 min (2026-10-16T06:52:08Z to 07:03Z, plus summary and state updates)
- **Tasks:** 3 of 3 (Task 1 tracer, Task 2 TDD, Task 3)
- **Files:** 18 (16 created, 2 modified)

## Accomplishments

- Tracer: transactions rendered end to end through `exportCsv` for both dialects before any expansion; the tracer feedback gate (end-of-phase mode, automated-only verify) was re-run and passed.
- `guardCsvText` / `unguardCsvText` are lossless for every input including `'=x` and `''=x`, closing T-04-08-01.
- `parseAmountCell` accepts `12,50`, `12.5`, `1.250,50`, `1,250.50` and rejects `-5`, `1.250`, `abc`, empty and 14-digit numbers; the legacy `lib/core/utils/amount_parser.dart` is not referenced anywhere under `lib/data/backup` (T-04-08-04).
- `decodeCsvTable` strips the BOM, sniffs `;`, `,` or tab from the header row, keeps every cell a String, caps at 100000 data rows and names the 1-based row of a ragged line.
- All six mappers round-trip in both dialects with every field populated and with every nullable field null, including hostile `=HYPERLINK(...)` text and notes containing newline, quote and semicolon.
- 600 active rows plus 40 soft-deleted rows per entity in real Isar: the export holds exactly the 600 active rows in every file (no 500 cap).

## Task Commits

1. **Task 1 (tracer): transactions export, dialects, guard** - `ce88a80` (feat)
2. **Task 2 RED: failing decode and mapper tests** - `72d1e52` (test)
3. **Task 2 GREEN: strict decoding, row reader, task/budget/transaction mappers** - `a7824cd` (feat)
4. **Task 3: goal/debt/payment mappers, six-file export, round-trip and completeness tests** - `58e3595` (feat)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extracted the six-file export into `lib/infrastructure/backup/csv_export_builder.dart`**
- **Found during:** Task 3
- **Issue:** Adding six mappers to `BackupRepositoryImpl.exportCsv` would push the file past the repository's 150-line architecture cap (`tool/check_architecture.dart`, enforced in CI).
- **Fix:** `buildCsvExport(BackupRows, languageCode:, at:)` holds the mapping; `exportCsv` stays a thin try/catch wrapper. The plan's `key_links` pattern (`toRow` reached from the infrastructure layer) still holds, now through the builder.
- **Files modified:** lib/infrastructure/backup/csv_export_builder.dart (new), lib/infrastructure/backup/backup_repository_impl.dart
- **Commit:** 58e3595

**2. [Rule 3 - Blocking] Tracer commit already contained the strict `parseAmountCell` and `parseCsvDate`**
- **Found during:** Task 1
- **Issue:** Both live next to the formatters in `csv_amount.dart` and `csv_format.dart`, so writing those files for the tracer included them. Their dedicated tests arrived with Task 2's RED commit.
- **Impact:** None on behavior; the Task 2 RED commit still failed to compile (missing row reader and mappers) and went green in `a7824cd`.

**3. [Process] Accidental repo-wide `dart format test`**
- **Found during:** Task 2
- **Issue:** A format command ran over all of `test/` and reformatted 40 unrelated test files.
- **Fix:** Reverted exactly those files with `git checkout -- <file>` before committing; none of them is in any plan commit.

**Total deviations:** 2 auto-fixed (Rule 3), 1 process slip, all corrected. **Impact:** none on scope.

## Issues Encountered

- `flutter test` prints a "Building Linux applications requires..." notice on this host; it is unrelated and tests run normally.
- The task format and the `rtk` output filter truncated some command output; results were re-verified through exit codes.

## Verification

| Check | Result |
|-------|--------|
| `flutter test --no-pub -j 1 test/data/backup` | 74/74 pass (plans 04-04 and 04-08 together) |
| `flutter analyze lib/data/backup lib/domain/backup lib/infrastructure/backup test/data/backup` | no issues |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 63 issues (budget 65, same as before this plan) |
| `dart run tool/check_architecture.dart` | PASS (`csv/` 5 files, `csv/mappers/` 6) |
| `grep -rn amount_parser lib/data/backup` | no match |
| `grep growable lib/data/backup/csv/mappers/goal_csv_mapper.dart` | match |
| `grep package:csv/csv.dart lib/data/backup/csv/csv_table_codec.dart` | match |

## Threat Flags

None. The plan's threat register (T-04-08-01, -02, -04) is mitigated as listed; T-04-08-03 (plaintext CSV in user storage) is accepted. The file-size cap before decoding belongs to plan 04-11.

## Known Stubs

None.

## Next Phase Readiness

Plan 04-11 can detect a file's entity from the `signature` sets, decode with `decodeCsvTable` plus `CsvRowReader`, and call each mapper's `fromRow`. It must resolve `categoryId == 0` rows from `ParsedCsvRow.categoryName`, enforce a file-size cap before decoding, and run all validation before any write. Plan 04-16 only has to hand the six `BackupFile`s to the file picker.

## Self-Check: PASSED

All 16 created files exist on disk; commits `ce88a80`, `72d1e52`, `a7824cd` and `58e3595` are present in `git log`.
