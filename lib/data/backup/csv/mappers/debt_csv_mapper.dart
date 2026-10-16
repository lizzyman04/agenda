import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes and decodes [DebtModel] rows for `debts.csv`.
final class DebtCsvMapper {
  const DebtCsvMapper();

  static const String fileStem = 'debts';

  /// Columns that must all be present for a file to be read as debts.
  static const Set<String> signature = {'title', 'direction'};

  static const List<String> header = [
    'id',
    'title',
    'amount',
    'amount_cents',
    'direction',
    'counterparty',
    'due_date',
    'is_paid',
    'paid_at',
    'created_at',
    'updated_at',
  ];

  List<Object?> toRow(DebtModel m, CsvContext ctx) => [
    m.id,
    guardCsvText(m.title),
    formatAmountCell(m.amountCents, ctx.dialect.decimalSeparator),
    m.amountCents,
    m.direction.name,
    guardCsvText(m.counterparty),
    formatCsvDate(m.dueDate),
    m.isPaid,
    formatCsvDateOrEmpty(m.paidAt),
    formatCsvDate(m.createdAt),
    formatCsvDate(m.updatedAt),
  ];

  /// Decodes one row; a blank `counterparty` becomes an empty string.
  ParsedCsvRow<DebtModel> fromRow(CsvRowReader r, {required DateTime now}) {
    final model =
        DebtModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..title = r.requireText('title')
          ..amountCents = r.requireAmountCents('amount_cents', 'amount')
          ..direction = r.enumByName('direction', DebtDirection.values)
          ..counterparty = r.optText('counterparty') ?? ''
          ..dueDate = r.requireDate('due_date')
          ..isPaid = r.boolOr('is_paid', fallback: false)
          ..paidAt = r.optDate('paid_at')
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(model: model, rowNumber: r.rowNumber);
  }
}
