import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes and decodes [RecurringPaymentModel] rows for
/// `recurring_payments.csv`.
final class PaymentCsvMapper {
  const PaymentCsvMapper();

  static const String fileStem = 'recurring_payments';

  /// Columns that must all be present for a file to be read as payments.
  static const Set<String> signature = {'title', 'cycle'};

  static const List<String> header = [
    'id',
    'title',
    'amount',
    'amount_cents',
    'category_id',
    'category_name',
    'cycle',
    'next_due_date',
    'is_active',
    'created_at',
    'updated_at',
  ];

  List<Object?> toRow(RecurringPaymentModel m, CsvContext ctx) => [
    m.id,
    guardCsvText(m.title),
    formatAmountCell(m.amountCents, ctx.dialect.decimalSeparator),
    m.amountCents,
    m.categoryId,
    guardCsvText(ctx.categoryNames[m.categoryId] ?? ''),
    m.cycle.name,
    formatCsvDate(m.nextDueDate),
    m.isActive,
    formatCsvDate(m.createdAt),
    formatCsvDate(m.updatedAt),
  ];

  /// Decodes one row. A blank `category_id` becomes 0 (unresolved); the
  /// importer resolves it from the returned category name. `is_active`
  /// defaults to true.
  ParsedCsvRow<RecurringPaymentModel> fromRow(
    CsvRowReader r, {
    required DateTime now,
  }) {
    final categoryId = r.optInt('category_id');
    final categoryName = r.optText('category_name');
    if (categoryId == null && categoryName == null) {
      r.fail('category_id', 'category_id or category_name is required');
    }
    final model =
        RecurringPaymentModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..title = r.requireText('title')
          ..amountCents = r.requireAmountCents('amount_cents', 'amount')
          ..categoryId = categoryId ?? 0
          ..cycle = r.enumByName('cycle', RecurringCycle.values)
          ..nextDueDate = r.requireDate('next_due_date')
          ..isActive = r.boolOr('is_active', fallback: true)
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(
      model: model,
      categoryName: categoryName,
      rowNumber: r.rowNumber,
    );
  }
}
