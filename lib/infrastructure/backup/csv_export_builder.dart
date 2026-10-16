import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/budget_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/debt_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/goal_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/payment_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/task_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/domain/backup/backup_file.dart';

/// Builds the six per-entity CSV files from a snapshot.
///
/// Order: tasks, transactions, budgets, goals, debts, recurring_payments.
/// Active rows only (budgets have no `deletedAt` and are all exported),
/// ordered by id. Content is never logged.
List<BackupFile> buildCsvExport(
  BackupRows rows, {
  required String languageCode,
  required DateTime at,
}) {
  final english = languageCode == 'en';
  final ctx = CsvContext(
    dialect: CsvDialect.forLanguage(languageCode),
    categoryNames: {
      for (final c in rows.categories)
        c.id: english && c.nameEn != null ? c.nameEn! : c.namePtBr,
    },
  );

  BackupFile file(
    String stem,
    List<String> header,
    List<List<Object?>> data,
  ) => BackupFile(
    name: 'agenda-$stem-${_isoDate(at)}.csv',
    bytes: Uint8List.fromList(
      utf8.encode(
        encodeCsvTable(header: header, rows: data, dialect: ctx.dialect),
      ),
    ),
  );

  return [
    file(TaskCsvMapper.fileStem, TaskCsvMapper.header, [
      for (final m in _byId(rows.items, (m) => m.id, (m) => m.deletedAt))
        const TaskCsvMapper().toRow(m, ctx),
    ]),
    file(TransactionCsvMapper.fileStem, TransactionCsvMapper.header, [
      for (final m in _byId(
        rows.transactions,
        (m) => m.id,
        (m) => m.deletedAt,
      ))
        const TransactionCsvMapper().toRow(m, ctx),
    ]),
    file(BudgetCsvMapper.fileStem, BudgetCsvMapper.header, [
      for (final m in _byId(rows.budgets, (m) => m.id, (_) => null))
        const BudgetCsvMapper().toRow(m, ctx),
    ]),
    file(GoalCsvMapper.fileStem, GoalCsvMapper.header, [
      for (final m in _byId(rows.goals, (m) => m.id, (m) => m.deletedAt))
        const GoalCsvMapper().toRow(m, ctx),
    ]),
    file(DebtCsvMapper.fileStem, DebtCsvMapper.header, [
      for (final m in _byId(rows.debts, (m) => m.id, (m) => m.deletedAt))
        const DebtCsvMapper().toRow(m, ctx),
    ]),
    file(PaymentCsvMapper.fileStem, PaymentCsvMapper.header, [
      for (final m in _byId(
        rows.recurringPayments,
        (m) => m.id,
        (m) => m.deletedAt,
      ))
        const PaymentCsvMapper().toRow(m, ctx),
    ]),
  ];
}

/// Rows whose `deletedAt` is null, sorted by ascending id.
List<T> _byId<T>(
  List<T> all,
  int Function(T) id,
  DateTime? Function(T) deletedAt,
) =>
    all.where((m) => deletedAt(m) == null).toList()
      ..sort((a, b) => id(a).compareTo(id(b)));

String _isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
