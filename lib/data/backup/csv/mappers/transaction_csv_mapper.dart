import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';

/// Encodes [TransactionModel] rows for `transactions.csv`.
final class TransactionCsvMapper {
  const TransactionCsvMapper();

  static const String fileStem = 'transactions';

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
}
