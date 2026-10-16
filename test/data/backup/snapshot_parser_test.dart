// parseBackupFiles (plan 04-11): inputs are produced by the real exporters
// from plans 04-04 and 04-08 so the parser meets genuinely exported bytes.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/goal_csv_mapper.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/snapshot_parser.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backup_seed.dart';

Matcher failsWith(String code) => throwsA(
  isA<BackupImportException>().having((e) => e.code, 'code', code),
);

BackupSnapshot parse(List<BackupFile> files, {int? maxBytes}) =>
    parseBackupFiles(
      files,
      now: seedNow,
      maxBytes: maxBytes ?? maxImportFileBytes,
    );

BackupFile jsonWith(void Function(Map<String, Object?> envelope) edit) {
  final envelope = envelopeOf(seedSnapshot());
  edit(envelope);
  return fileOfText(jsonEncode(envelope));
}

void main() {
  group('JSON', () {
    test('a real export parses into an equal snapshot', () {
      final source = seedSnapshot();
      final parsed = parse([jsonFileOf(source)]);

      expect(parsed.source, ImportSource.json);
      expect(parsed.exportedAt, isNotNull);
      expect(snapshotJson(parsed), snapshotJson(source));
    });

    test('a BOM before the document is tolerated', () {
      final file = fileOfText('﻿${jsonEncode(envelopeOf(seedSnapshot()))}');
      expect(parse([file]).source, ImportSource.json);
    });

    test('missing collection, wrong app, non-object and bad UTF-8', () {
      expect(
        () => parse([
          jsonWith(
            (e) => (e['collections']! as Map<String, Object?>).remove('goals'),
          ),
        ]),
        failsWith(ImportErrorCode.unsupported),
      );
      expect(
        () => parse([jsonWith((e) => e['app'] = 'other')]),
        failsWith(ImportErrorCode.unsupported),
      );
      expect(
        () => parse([fileOfText('[1, 2]')]),
        failsWith(ImportErrorCode.unsupported),
      );
      expect(
        () => parse([fileOfText('{"app": ')]),
        failsWith(ImportErrorCode.unsupported),
      );
      expect(
        () => parse([
          BackupFile(
            name: 'x.json',
            bytes: Uint8List.fromList([0x7B, 0xFF, 0xFE, 0x7D]),
          ),
        ]),
        failsWith(ImportErrorCode.unsupported),
      );
    });

    test('newer formatVersion or schemaVersion is rejected', () {
      expect(
        () => parse([jsonWith((e) => e['formatVersion'] = 2)]),
        failsWith(ImportErrorCode.newerVersion),
      );
      expect(
        () => parse([jsonWith((e) => e['schemaVersion'] = 999)]),
        failsWith(ImportErrorCode.newerVersion),
      );
    });

    test('an unknown enum name is invalid and names its path', () {
      final file = jsonWith((e) {
        final collections = e['collections']! as Map<String, Object?>;
        final items = collections['items']! as List<Object?>;
        (items.first! as Map<String, Object?>)['type'] = 'epic';
      });
      expect(
        () => parse([file]),
        throwsA(
          isA<BackupImportException>()
              .having((e) => e.code, 'code', ImportErrorCode.invalid)
              .having((e) => e.detail, 'detail', contains('items[0].type')),
        ),
      );
    });
  });

  group('limits and mixing', () {
    test('an oversize file is rejected before any decoding', () {
      final huge = BackupFile(
        name: 'a',
        bytes: Uint8List(2000)..fillRange(0, 2000, 0xFF),
      );
      expect(
        () => parse([huge], maxBytes: 1000),
        failsWith(ImportErrorCode.tooLarge),
      );
      expect(maxImportFileBytes, 26214400);
    });

    test('no files, JSON plus CSV, and two JSON files', () {
      expect(() => parse([]), failsWith(ImportErrorCode.empty));
      final json = jsonFileOf(seedSnapshot());
      final csv = csvFilesOf(seedSnapshot()).first;
      expect(() => parse([json, csv]), failsWith(ImportErrorCode.mixed));
      expect(() => parse([json, json]), failsWith(ImportErrorCode.mixed));
    });
  });

  group('CSV', () {
    for (final language in ['pt', 'en']) {
      test('six exported files parse ($language)', () {
        final source = seedSnapshot();
        final parsed = parse(csvFilesOf(source, languageCode: language));

        expect(parsed.source, ImportSource.csv);
        expect(parsed.exportedAt, isNull);
        expect(parsed.categories, isNull);
        expect(parsed.items, hasLength(2));
        expect(parsed.transactions, hasLength(1));
        expect(parsed.budgets, hasLength(1));
        expect(parsed.goals, hasLength(1));
        expect(parsed.debts, hasLength(1));
        expect(parsed.recurringPayments, hasLength(1));
        final name = language == 'en' ? 'Grocery B' : 'Mercado B';
        expect(parsed.transactionCategoryNames, [name]);
        expect(parsed.budgetCategoryNames, hasLength(1));
        expect(parsed.paymentCategoryNames, hasLength(1));
      });
    }

    test('entities are detected by header, whatever the file is named', () {
      final files = csvFilesOf(seedSnapshot());
      final renamed = [
        for (var i = 0; i < files.length; i++)
          BackupFile(name: 'file-$i.txt', bytes: files[i].bytes),
      ];
      expect(parse(renamed).goals, hasLength(1));
      final onlyGoals = parse([renamed[3]]);
      expect(onlyGoals.goals, hasLength(1));
      expect(onlyGoals.items, isNull);
      expect(onlyGoals.transactions, isNull);
    });

    test('a tab-delimited file with a BOM is read', () {
      final goal = seedSnapshot().goals!.single;
      final text = encodeCsvTable(
        header: GoalCsvMapper.header,
        rows: [
          const GoalCsvMapper().toRow(
            goal,
            const CsvContext(
              dialect: CsvDialect(delimiter: '\t', decimalSeparator: ','),
            ),
          ),
        ],
        dialect: const CsvDialect(delimiter: '\t', decimalSeparator: ','),
      );
      expect(text.startsWith(csvBom), isTrue);
      expect(parse([fileOfText(text)]).goals!.single.title, goal.title);
    });

    test('two files of one entity are a duplicate', () {
      final files = csvFilesOf(seedSnapshot());
      expect(
        () => parse([files[1], files[1]]),
        failsWith(ImportErrorCode.duplicate),
      );
    });

    test('unknown layouts and bad rows are rejected', () {
      expect(
        () => parse([fileOfText('foo,bar\r\n1,2\r\n')]),
        failsWith(ImportErrorCode.unsupported),
      );
      expect(
        () => parse([fileOfText('plain text, not a table')]),
        failsWith(ImportErrorCode.unsupported),
      );
      const bad =
          'id,type,amount_cents,category_id,date\r\n'
          '1,transfer,100,5,2026-01-01\r\n';
      expect(
        () => parse([fileOfText(bad)]),
        throwsA(
          isA<BackupImportException>()
              .having((e) => e.code, 'code', ImportErrorCode.invalid)
              .having((e) => e.detail, 'detail', contains('row 2')),
        ),
      );
    });
  });
}
