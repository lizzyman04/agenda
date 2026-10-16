// Pure round-trip tests (plan 04-08, Task 3): every mapper decodes what it
// encodes, in both dialects, through the real table codec.

import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/budget_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/debt_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/goal_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/payment_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/task_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2030);
final _created = DateTime(2026, 3, 4, 5, 6, 7, 8);
final _updated = DateTime(2026, 3, 5, 6, 7, 8, 9);
const _hostile = '=HYPERLINK("x","y")';
const _messy = 'line one;\n"quoted", two\r\nthree';

ParsedCsvRow<T> _trip<T>(
  CsvDialect dialect,
  List<String> header,
  List<Object?> row,
  ParsedCsvRow<T> Function(CsvRowReader) fromRow,
) {
  final text = encodeCsvTable(header: header, rows: [row], dialect: dialect);
  expect(text.startsWith(csvBom), isTrue);
  final table = decodeCsvTable(text);
  expect(table.header, header);
  expect(table.rows, hasLength(1));
  return fromRow(CsvRowReader(table.header, table.rows.single, 2));
}

void _same(DateTime? actual, DateTime? expected, [String? reason]) {
  if (expected == null) {
    expect(actual, isNull, reason: reason);
  } else {
    expect(actual, isNotNull, reason: reason);
    expect(actual!.isAtSameMomentAs(expected), isTrue, reason: reason);
  }
}

void main() {
  for (final dialect in [CsvDialect.pt, CsvDialect.en]) {
    group('round trip (${dialect.delimiter})', () {
      final ctx = CsvContext(
        dialect: dialect,
        categoryNames: {3: 'Food; "dinner"'},
      );

      test('transactions, populated and nulled', () {
        const mapper = TransactionCsvMapper();
        for (final note in [_hostile, "'=x", _messy, null]) {
          final m =
              TransactionModel()
                ..id = 42
                ..type = TransactionType.income
                ..amountCents = 125050
                ..categoryId = 3
                ..date = note == null ? DateTime(2026, 10, 12) : _created
                ..note = note
                ..linkedGoalId = note == null ? null : 9
                ..createdAt = _created
                ..updatedAt = _updated;
          final p = _trip(
            dialect,
            TransactionCsvMapper.header,
            mapper.toRow(m, ctx),
            (r) => mapper.fromRow(r, now: _now),
          );
          expect(p.model.id, 42);
          expect(p.model.type, m.type);
          expect(p.model.amountCents, 125050);
          expect(p.model.categoryId, 3);
          expect(p.categoryName, 'Food; "dinner"');
          expect(p.model.note, note);
          expect(p.model.linkedGoalId, m.linkedGoalId);
          _same(p.model.date, m.date);
          _same(p.model.createdAt, _created);
          _same(p.model.updatedAt, _updated);
        }
      });

      test('tasks, populated', () {
        const mapper = TaskCsvMapper();
        final m =
            ItemModel()
              ..id = 5
              ..type = ItemType.subtask
              ..parentId = 4
              ..title = _hostile
              ..description = _messy
              ..priority = Priority.urgent
              ..isUrgent = true
              ..isImportant = true
              ..sizeCategory = SizeCategory.big
              ..isNextAction = true
              ..gtdContext = '@home'
              ..waitingFor = "'=x"
              ..isCompleted = true
              ..completedAt = _updated
              ..dueDate = DateTime(2026, 5, 6)
              ..timeInfo = TimeInfo(
                dueTimeMinutes: 90,
                recurrenceRule: 'FREQ=DAILY',
              )
              ..moneyInfo = MoneyInfo(amount: 12.5, currencyCode: 'MZN')
              ..linkedGoalId = 7
              ..linkedDebtId = 8
              ..createdAt = _created
              ..updatedAt = _updated;
        final r =
            _trip(
              dialect,
              TaskCsvMapper.header,
              mapper.toRow(m, ctx),
              (r) => mapper.fromRow(r, now: _now),
            ).model;
        expect(r.id, 5);
        expect(r.type, ItemType.subtask);
        expect(r.parentId, 4);
        expect(r.title, _hostile);
        expect(r.description, _messy);
        expect(r.priority, Priority.urgent);
        expect([r.isUrgent, r.isImportant, r.isNextAction], [true, true, true]);
        expect(r.sizeCategory, SizeCategory.big);
        expect(r.gtdContext, '@home');
        expect(r.waitingFor, "'=x");
        expect(r.isCompleted, isTrue);
        _same(r.completedAt, _updated);
        _same(r.dueDate, DateTime(2026, 5, 6));
        expect(r.timeInfo!.dueTimeMinutes, 90);
        expect(r.timeInfo!.recurrenceRule, 'FREQ=DAILY');
        expect(r.moneyInfo!.amount, 12.5);
        expect(r.moneyInfo!.currencyCode, 'MZN');
        expect([r.linkedGoalId, r.linkedDebtId], [7, 8]);
        _same(r.createdAt, _created);
        _same(r.updatedAt, _updated);
      });

      test('tasks, every nullable field null', () {
        const mapper = TaskCsvMapper();
        final m =
            ItemModel()
              ..id = 6
              ..type = ItemType.project
              ..title = 'Plain'
              ..createdAt = _created
              ..updatedAt = _updated;
        final r =
            _trip(
              dialect,
              TaskCsvMapper.header,
              mapper.toRow(m, ctx),
              (r) => mapper.fromRow(r, now: _now),
            ).model;
        expect(r.description, isNull);
        expect(r.parentId, isNull);
        expect(r.gtdContext, isNull);
        expect(r.waitingFor, isNull);
        expect(r.completedAt, isNull);
        expect(r.dueDate, isNull);
        expect(r.timeInfo, isNull);
        expect(r.moneyInfo, isNull);
        expect(r.priority, Priority.medium);
        expect(r.sizeCategory, SizeCategory.none);
        expect(r.isCompleted, isFalse);
      });

      test('budgets', () {
        const mapper = BudgetCsvMapper();
        final m =
            BudgetModel()
              ..id = 11
              ..categoryId = 3
              ..month = 12
              ..year = 2026
              ..limitCents = 99999905
              ..createdAt = _created
              ..updatedAt = _updated;
        final p = _trip(
          dialect,
          BudgetCsvMapper.header,
          mapper.toRow(m, ctx),
          (r) => mapper.fromRow(r, now: _now),
        );
        expect(p.model.id, 11);
        expect([p.model.month, p.model.year], [12, 2026]);
        expect(p.model.limitCents, 99999905);
        expect(p.categoryName, 'Food; "dinner"');
        _same(p.model.updatedAt, _updated);
      });

      test('goals, with and without contributions', () {
        const mapper = GoalCsvMapper();
        final full =
            SavingsGoalModel()
              ..id = 2
              ..title = _hostile
              ..targetAmountCents = 500000
              ..deadline = DateTime(2027, 1, 31)
              ..isCompleted = true
              ..contributions = [
                GoalContribution()
                  ..amountCents = 1000
                  ..date = _created
                  ..note = _messy,
                GoalContribution()
                  ..amountCents = 25
                  ..date = _updated,
              ]
              ..createdAt = _created
              ..updatedAt = _updated;
        final bare =
            SavingsGoalModel()
              ..id = 3
              ..title = 'Bare'
              ..targetAmountCents = 1
              ..createdAt = _created
              ..updatedAt = _updated;
        final a =
            _trip(
              dialect,
              GoalCsvMapper.header,
              mapper.toRow(full, ctx),
              (r) => mapper.fromRow(r, now: _now),
            ).model;
        expect(a.title, _hostile);
        expect(a.targetAmountCents, 500000);
        _same(a.deadline, DateTime(2027, 1, 31));
        expect(a.isCompleted, isTrue);
        expect(a.contributions, hasLength(2));
        expect(a.contributions[0].amountCents, 1000);
        expect(a.contributions[0].note, _messy);
        _same(a.contributions[0].date, _created);
        expect(a.contributions[1].note, isNull);
        a.contributions.add(GoalContribution()..date = _now); // growable
        final b =
            _trip(
              dialect,
              GoalCsvMapper.header,
              mapper.toRow(bare, ctx),
              (r) => mapper.fromRow(r, now: _now),
            ).model;
        expect(b.deadline, isNull);
        expect(b.contributions, isEmpty);
        b.contributions.add(GoalContribution()..date = _now); // growable
      });

      test('debts, paid and unpaid', () {
        const mapper = DebtCsvMapper();
        for (final paid in [true, false]) {
          final m =
              DebtModel()
                ..id = 8
                ..title = "'=x"
                ..amountCents = 333
                ..direction = DebtDirection.toPay
                ..counterparty = paid ? _messy : ''
                ..dueDate = DateTime(2026, 11, 2)
                ..isPaid = paid
                ..paidAt = paid ? _updated : null
                ..createdAt = _created
                ..updatedAt = _updated;
          final r =
              _trip(
                dialect,
                DebtCsvMapper.header,
                mapper.toRow(m, ctx),
                (r) => mapper.fromRow(r, now: _now),
              ).model;
          expect(r.title, "'=x");
          expect(r.amountCents, 333);
          expect(r.direction, DebtDirection.toPay);
          expect(r.counterparty, m.counterparty);
          _same(r.dueDate, DateTime(2026, 11, 2));
          expect(r.isPaid, paid);
          _same(r.paidAt, m.paidAt);
        }
      });

      test('recurring payments', () {
        const mapper = PaymentCsvMapper();
        final m =
            RecurringPaymentModel()
              ..id = 9
              ..title = _hostile
              ..amountCents = 4990
              ..categoryId = 3
              ..cycle = RecurringCycle.biweekly
              ..nextDueDate = DateTime(2026, 12, 24)
              ..isActive = false
              ..createdAt = _created
              ..updatedAt = _updated;
        final p = _trip(
          dialect,
          PaymentCsvMapper.header,
          mapper.toRow(m, ctx),
          (r) => mapper.fromRow(r, now: _now),
        );
        expect(p.model.title, _hostile);
        expect(p.model.amountCents, 4990);
        expect(p.model.cycle, RecurringCycle.biweekly);
        expect(p.model.isActive, isFalse);
        expect(p.categoryName, 'Food; "dinner"');
        _same(p.model.nextDueDate, DateTime(2026, 12, 24));
      });
    });
  }

  group('hand-edited files', () {
    test('reordered columns, missing optional columns, amount only', () {
      const text =
          '﻿date;category_name;type;amount\r\n'
          '2026-10-12;Food;expense;1.250,50\r\n'
          '12/10/2026;Food;expense;5\r\n';
      final table = decodeCsvTable(text);
      const mapper = TransactionCsvMapper();
      final ok = mapper.fromRow(
        CsvRowReader(table.header, table.rows[0], 2),
        now: _now,
      );
      expect(ok.model.amountCents, 125050);
      expect(ok.model.type, TransactionType.expense);
      expect(ok.model.note, isNull);
      expect(ok.model.createdAt, _now);
      expect(
        () => mapper.fromRow(
          CsvRowReader(table.header, table.rows[1], 3),
          now: _now,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('row 3, column date:'),
          ),
        ),
      );
    });

    test('invalid contributions JSON names the row and column', () {
      const mapper = GoalCsvMapper();
      for (final bad in ['not json', '{}', '[1]', '[{"amountCents":"x"}]']) {
        final r = CsvRowReader(
          ['title', 'deadline', 'target_cents', 'contributions_json'],
          ['G', '', '100', bad],
          4,
        );
        expect(
          () => mapper.fromRow(r, now: _now),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('row 4, column contributions_json:'),
            ),
          ),
          reason: bad,
        );
      }
    });
  });
}
