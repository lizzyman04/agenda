import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes [TransactionModel] rows for `transactions.csv`.
final class TransactionCsvMapper {
  const TransactionCsvMapper();

  static const String fileStem = 'transactions';

  /// Columns that must all be present for a file to be read as transactions.
  static const Set<String> signature = {'type', 'date'};

  static const List<String> header = [
    'id',
    'type',
    'amount',
    'amount_cents',
    'category_id',
    'category_name',
    'date',
    'note',
    'linked_goal_id',
    'created_at',
    'updated_at',
  ];

  List<Object?> toRow(TransactionModel m, CsvContext ctx) => [
    m.id,
    m.type.name,
    formatAmountCell(m.amountCents, ctx.dialect.decimalSeparator),
    m.amountCents,
    m.categoryId,
    guardCsvText(ctx.categoryNames[m.categoryId] ?? ''),
    formatCsvDate(m.date),
    guardCsvText(m.note ?? ''),
    m.linkedGoalId,
    formatCsvDate(m.createdAt),
    formatCsvDate(m.updatedAt),
  ];

  /// Decodes one row. A blank `category_id` becomes 0 (unresolved); the
  /// importer resolves it from [ParsedCsvRow.categoryName]. A blank id keeps
  /// the Isar auto-increment sentinel; blank timestamps become [now].
  ParsedCsvRow<TransactionModel> fromRow(
    CsvRowReader r, {
    required DateTime now,
  }) {
    final categoryId = r.optInt('category_id');
    final categoryName = r.optText('category_name');
    if (categoryId == null && categoryName == null) {
      r.fail('category_id', 'category_id or category_name is required');
    }
    final model =
        TransactionModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..type = r.enumByName('type', TransactionType.values)
          ..amountCents = r.requireAmountCents('amount_cents', 'amount')
          ..categoryId = categoryId ?? 0
          ..date = r.requireDate('date')
          ..note = r.optText('note')
          ..linkedGoalId = r.optInt('linked_goal_id')
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(
      model: model,
      categoryName: categoryName,
      rowNumber: r.rowNumber,
    );
  }
}
