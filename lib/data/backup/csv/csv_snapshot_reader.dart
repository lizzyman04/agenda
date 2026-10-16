import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/budget_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/debt_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/goal_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/payment_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/task_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';

const _signatures = <(String, Set<String>)>[
  (TaskCsvMapper.fileStem, TaskCsvMapper.signature),
  (TransactionCsvMapper.fileStem, TransactionCsvMapper.signature),
  (BudgetCsvMapper.fileStem, BudgetCsvMapper.signature),
  (GoalCsvMapper.fileStem, GoalCsvMapper.signature),
  (DebtCsvMapper.fileStem, DebtCsvMapper.signature),
  (PaymentCsvMapper.fileStem, PaymentCsvMapper.signature),
];

BackupImportException _bad(String code, String detail) =>
    BackupImportException(code, detail);

// The entity a file holds, chosen by header signature (never by file name).
String _entityOf(CsvTable table, int index) {
  final header = table.header.toSet();
  final hits = [
    for (final (stem, signature) in _signatures)
      if (header.containsAll(signature)) stem,
  ];
  if (hits.length != 1) {
    throw _bad(ImportErrorCode.unsupported, 'file $index: unknown layout');
  }
  return hits.single;
}

List<ParsedCsvRow<T>> _rows<T>(
  CsvTable table,
  String stem,
  ParsedCsvRow<T> Function(CsvRowReader, {required DateTime now}) fromRow,
  DateTime now,
) {
  final out = <ParsedCsvRow<T>>[];
  for (var i = 0; i < table.rows.length; i++) {
    final reader = CsvRowReader(table.header, table.rows[i], i + 2);
    try {
      out.add(fromRow(reader, now: now));
    } on FormatException catch (e) {
      throw _bad(ImportErrorCode.invalid, '$stem: ${e.message}');
    }
  }
  return out;
}

/// Decodes [texts] (one per CSV file, BOM already removed) into a partial
/// snapshot holding only the entities that were supplied.
BackupSnapshot readCsvSnapshot(List<String> texts, {required DateTime now}) {
  final seen = <String>{};
  List<ParsedCsvRow<ItemModel>>? tasks;
  List<ParsedCsvRow<TransactionModel>>? trs;
  List<ParsedCsvRow<BudgetModel>>? budgets;
  List<ParsedCsvRow<SavingsGoalModel>>? goals;
  List<ParsedCsvRow<DebtModel>>? debts;
  List<ParsedCsvRow<RecurringPaymentModel>>? payments;
  for (var i = 0; i < texts.length; i++) {
    final CsvTable table;
    try {
      table = decodeCsvTable(texts[i]);
    } on FormatException catch (e) {
      throw _bad(ImportErrorCode.unsupported, 'file $i: ${e.message}');
    }
    final stem = _entityOf(table, i);
    if (!seen.add(stem)) {
      throw _bad(ImportErrorCode.duplicate, 'two files hold $stem');
    }
    switch (stem) {
      case TaskCsvMapper.fileStem:
        tasks = _rows(table, stem, const TaskCsvMapper().fromRow, now);
      case TransactionCsvMapper.fileStem:
        trs = _rows(table, stem, const TransactionCsvMapper().fromRow, now);
      case BudgetCsvMapper.fileStem:
        budgets = _rows(table, stem, const BudgetCsvMapper().fromRow, now);
      case GoalCsvMapper.fileStem:
        goals = _rows(table, stem, const GoalCsvMapper().fromRow, now);
      case DebtCsvMapper.fileStem:
        debts = _rows(table, stem, const DebtCsvMapper().fromRow, now);
      default:
        payments = _rows(table, stem, const PaymentCsvMapper().fromRow, now);
    }
  }
  return BackupSnapshot(
    source: ImportSource.csv,
    items: tasks?.map((r) => r.model).toList(),
    transactions: trs?.map((r) => r.model).toList(),
    transactionCategoryNames: trs?.map((r) => r.categoryName).toList(),
    budgets: budgets?.map((r) => r.model).toList(),
    budgetCategoryNames: budgets?.map((r) => r.categoryName).toList(),
    goals: goals?.map((r) => r.model).toList(),
    debts: debts?.map((r) => r.model).toList(),
    recurringPayments: payments?.map((r) => r.model).toList(),
    paymentCategoryNames: payments?.map((r) => r.categoryName).toList(),
  );
}
