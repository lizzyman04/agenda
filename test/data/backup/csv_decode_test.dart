// Pure tests for the strict CSV decoding primitives and the transaction, task
// and budget mappers (plan 04-08, Task 2).

import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/budget_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/task_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

CsvRowReader _row(Map<String, String> cells, {int number = 2}) =>
    CsvRowReader(cells.keys.toList(), cells.values.toList(), number);

Matcher _formatError(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  final now = DateTime(2026, 10, 16, 9);

  group('parseAmountCell', () {
    test('accepts well-formed amounts', () {
      const ok = {
        '12,50': 1250,
        '12.5': 1250,
        '12': 1200,
        '0': 0,
        '1.250,50': 125050,
        '1,250.50': 125050,
        ' 7,05 ': 705,
      };
      for (final e in ok.entries) {
        expect(parseAmountCell(e.key), e.value, reason: e.key);
      }
    });

    test('rejects everything else, never flipping a sign', () {
      for (final raw in [
        '',
        '-5',
        '+5',
        '1.250',
        '1,250',
        '12,345',
        '1.2.3',
        'abc',
        r'R$ 5',
        '5 ,00',
        '12345678901234',
      ]) {
        expect(parseAmountCell(raw), isNull, reason: raw);
      }
    });
  });

  group('parseCsvDate', () {
    test('date-only is local midnight', () {
      expect(parseCsvDate('2026-10-12'), DateTime(2026, 10, 12));
    });

    test('date-time without offset is local', () {
      expect(
        parseCsvDate('2026-10-12T08:30:00.000'),
        DateTime(2026, 10, 12, 8, 30),
      );
    });

    test('a Z value is converted to local', () {
      final parsed = parseCsvDate('2026-10-12T08:30:00.000Z');
      expect(parsed, isNotNull);
      expect(parsed!.isAtSameMomentAs(DateTime.utc(2026, 10, 12, 8, 30)), true);
      expect(parsed.isUtc, isFalse);
    });

    test('other shapes and impossible dates are rejected', () {
      for (final raw in ['12/10/2026', '', 'x', '2026-02-30', '2026-13-01']) {
        expect(parseCsvDate(raw), isNull, reason: raw);
      }
    });
  });

  group('decodeCsvTable', () {
    test('strips the BOM and sniffs a semicolon', () {
      final t = decodeCsvTable('﻿id;Title\r\n1;a\r\n2;b\r\n');
      expect(t.header, ['id', 'title']);
      expect(t.rows, [
        ['1', 'a'],
        ['2', 'b'],
      ]);
    });

    test('sniffs comma and tab', () {
      expect(decodeCsvTable('a,b\n1,2').header, ['a', 'b']);
      expect(decodeCsvTable('a\tb\n1\t2').rows.single, ['1', '2']);
    });

    test('keeps every cell a String and preserves quoted content', () {
      final t = decodeCsvTable('a;b\r\n007;"x;y ""q""\nz"\r\n');
      expect(t.rows.single, ['007', 'x;y "q"\nz']);
    });

    test('a short or long data row names its 1-based row', () {
      expect(
        () => decodeCsvTable('a;b\r\n1;2\r\n3\r\n'),
        _formatError('row 3'),
      );
      expect(() => decodeCsvTable('a;b\r\n1;2;3\r\n'), _formatError('row 2'));
    });

    test('empty input, an unrecognisable header and too many rows throw', () {
      expect(() => decodeCsvTable(''), throwsFormatException);
      expect(() => decodeCsvTable('﻿\r\n'), throwsFormatException);
      expect(() => decodeCsvTable('1;2\r\n3;4'), throwsFormatException);
      final big = StringBuffer('a;b\r\n');
      for (var i = 0; i <= maxCsvDataRows; i++) {
        big.write('x;y\r\n');
      }
      expect(() => decodeCsvTable('$big'), _formatError('too many rows'));
    });
  });

  group('CsvRowReader', () {
    test('requireText unguards, optText is null for blank or missing', () {
      final r = _row({'t': "'=x", 'blank': '  '});
      expect(r.requireText('t'), '=x');
      expect(r.optText('blank'), isNull);
      expect(r.optText('missing'), isNull);
      expect(
        () => r.requireText('blank'),
        _formatError('row 2, column blank:'),
      );
    });

    test('amountCents prefers the integer column', () {
      expect(_row({'c': '1250', 'a': '99,00'}).amountCents('c', 'a'), 1250);
      expect(_row({'c': '', 'a': '12,50'}).amountCents('c', 'a'), 1250);
      expect(_row({'a': '1.250,50'}).amountCents('c', 'a'), 125050);
      expect(_row({'c': '', 'a': ''}).amountCents('c', 'a'), isNull);
    });

    test('amountCents reports row and column for bad values', () {
      expect(
        () => _row({'c': '1.5'}).amountCents('c', 'a'),
        _formatError('column c'),
      );
      expect(
        () => _row({'a': '-5'}, number: 7).amountCents('c', 'a'),
        _formatError('row 7, column a:'),
      );
    });

    test('booleans accept true/false and 1/0', () {
      final r = _row({'a': 'true', 'b': '0', 'c': 'FALSE', 'd': '1'});
      expect(r.boolOr('a', fallback: false), isTrue);
      expect(r.boolOr('b', fallback: true), isFalse);
      expect(r.boolOr('c', fallback: true), isFalse);
      expect(r.boolOr('d', fallback: false), isTrue);
      expect(r.boolOr('missing', fallback: true), isTrue);
      expect(
        () => _row({'a': 'yes'}).boolOr('a', fallback: false),
        throwsFormatException,
      );
    });

    test('enumByName throws on unknown unless a fallback is given', () {
      final r = _row({'t': 'bogus', 'ok': 'income'});
      expect(
        r.enumByName('ok', TransactionType.values),
        TransactionType.income,
      );
      expect(
        () => r.enumByName('t', TransactionType.values),
        _formatError('column t'),
      );
      expect(
        r.enumByName(
          't',
          TransactionType.values,
          fallback: TransactionType.expense,
        ),
        TransactionType.expense,
      );
    });

    test('strings longer than the cap are rejected', () {
      expect(
        () => _row({'t': 'x' * 20001}).optText('t'),
        _formatError('too long'),
      );
    });
  });

  group('TransactionCsvMapper.fromRow', () {
    const mapper = TransactionCsvMapper();
    final base = {
      'type': 'expense',
      'date': '2026-10-12',
      'amount': '12,50',
      'category_name': 'Food',
    };

    test('decodes, carries the category name, defaults id and timestamps', () {
      final parsed = mapper.fromRow(_row(base), now: now);
      expect(parsed.model.id, Isar.autoIncrement);
      expect(parsed.model.type, TransactionType.expense);
      expect(parsed.model.amountCents, 1250);
      expect(parsed.model.date, DateTime(2026, 10, 12));
      expect(parsed.categoryName, 'Food');
      expect(parsed.model.createdAt, now);
      expect(parsed.model.updatedAt, now);
      expect(parsed.model.deletedAt, isNull);
    });

    test('rejects an unknown type with row and column', () {
      expect(
        () => mapper.fromRow(
          _row({...base, 'type': 'loan'}, number: 5),
          now: now,
        ),
        _formatError('row 5, column type:'),
      );
    });

    test('requires an amount and a category', () {
      expect(
        () => mapper.fromRow(_row({...base, 'amount': ''}), now: now),
        _formatError('column amount_cents'),
      );
      expect(
        () => mapper.fromRow(_row({...base, 'category_name': ''}), now: now),
        throwsFormatException,
      );
    });
  });

  group('TaskCsvMapper.fromRow', () {
    const mapper = TaskCsvMapper();

    test('defaults priority to medium and size to none', () {
      final m = mapper.fromRow(_row({'title': 'T', 'type': 'task'}), now: now);
      expect(m.model.priority, Priority.medium);
      expect(m.model.sizeCategory, SizeCategory.none);
      expect(m.model.timeInfo, isNull);
      expect(m.model.moneyInfo, isNull);
    });

    test('decodes embedded time and money info', () {
      final m =
          mapper
              .fromRow(
                _row({
                  'title': 'T',
                  'type': 'subtask',
                  'due_time_minutes': '90',
                  'recurrence_rule': 'FREQ=DAILY',
                  'money_amount': '12,5',
                  'money_currency': 'MZN',
                }),
                now: now,
              )
              .model;
      expect(m.timeInfo!.dueTimeMinutes, 90);
      expect(m.timeInfo!.recurrenceRule, 'FREQ=DAILY');
      expect(m.moneyInfo!.amount, 12.5);
      expect(m.moneyInfo!.currencyCode, 'MZN');
    });

    test('an unknown type throws', () {
      expect(
        () => mapper.fromRow(_row({'title': 'T', 'type': 'epic'}), now: now),
        _formatError('column type'),
      );
    });
  });

  group('BudgetCsvMapper.fromRow', () {
    const mapper = BudgetCsvMapper();

    test('decodes month, year and limit', () {
      final p = mapper.fromRow(
        _row({
          'month': '2',
          'year': '2026',
          'limit': '1.000,00',
          'category_name': 'Food',
        }),
        now: now,
      );
      expect(p.model.month, 2);
      expect(p.model.year, 2026);
      expect(p.model.limitCents, 100000);
      expect(p.categoryName, 'Food');
    });

    test('month outside 1..12 throws', () {
      for (final bad in ['0', '13']) {
        expect(
          () => mapper.fromRow(
            _row({
              'month': bad,
              'year': '2026',
              'limit_cents': '1',
              'category_name': 'Food',
            }),
            now: now,
          ),
          _formatError('column month'),
        );
      }
    });
  });
}
