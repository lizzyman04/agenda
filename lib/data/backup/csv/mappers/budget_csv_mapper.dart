import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes and decodes [BudgetModel] rows for `budgets.csv`.
final class BudgetCsvMapper {
  const BudgetCsvMapper();

  static const String fileStem = 'budgets';

  /// Columns that must all be present for a file to be read as budgets.
  static const Set<String> signature = {'month', 'year'};

  static const List<String> header = [
    'id',
    'category_id',
    'category_name',
    'month',
    'year',
    'limit',
    'limit_cents',
    'created_at',
    'updated_at',
  ];

  List<Object?> toRow(BudgetModel m, CsvContext ctx) => [
    m.id,
    m.categoryId,
    guardCsvText(ctx.categoryNames[m.categoryId] ?? ''),
    m.month,
    m.year,
    formatAmountCell(m.limitCents, ctx.dialect.decimalSeparator),
    m.limitCents,
    formatCsvDate(m.createdAt),
    formatCsvDate(m.updatedAt),
  ];

  /// Decodes one row; `month` must be 1..12. Category and default rules are
  /// the same as for transactions: a blank `category_id` becomes 0 and the
  /// importer resolves it from the returned category name.
  ParsedCsvRow<BudgetModel> fromRow(CsvRowReader r, {required DateTime now}) {
    final categoryId = r.optInt('category_id');
    final categoryName = r.optText('category_name');
    if (categoryId == null && categoryName == null) {
      r.fail('category_id', 'category_id or category_name is required');
    }
    final month = r.requireInt('month');
    if (month < 1 || month > 12) r.fail('month', 'expected 1 to 12');
    final model =
        BudgetModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..categoryId = categoryId ?? 0
          ..month = month
          ..year = r.requireInt('year')
          ..limitCents = r.requireAmountCents('limit_cents', 'limit')
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(
      model: model,
      categoryName: categoryName,
      rowNumber: r.rowNumber,
    );
  }
}
