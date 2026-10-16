import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// Where a CSV row's category comes from: an existing row, or the n-th
/// category [CategoryResolution.created] will create.
final class CategoryRef {
  const CategoryRef.existing(int this.id) : createdIndex = null;
  const CategoryRef.created(int this.createdIndex) : id = null;

  final int? id;
  final int? createdIndex;
}

/// Category decisions for every row of a CSV snapshot, in row order.
final class CategoryResolution {
  const CategoryResolution({
    required this.created,
    required this.transactions,
    required this.budgets,
    required this.payments,
  });

  /// Custom categories the import must create (ids not yet assigned).
  final List<TransactionCategoryModel> created;
  final List<CategoryRef> transactions;
  final List<CategoryRef> budgets;
  final List<CategoryRef> payments;
}

/// Resolves the categories of CSV rows against [existing] without writing.
///
/// Per row: keep a known `categoryId`; else match the category name
/// (trimmed, case-insensitive, `namePtBr` or `nameEn`) among categories of
/// the compatible type (transactions use their own type, budgets and
/// payments are expense); else create a custom category, de-duplicated by
/// lower-cased name and type; else the row is invalid.
CategoryResolution resolveCsvCategories(
  BackupSnapshot snapshot,
  List<TransactionCategoryModel> existing, {
  required DateTime now,
}) {
  final known = existing.map((c) => c.id).toSet();
  final created = <TransactionCategoryModel>[];
  final createdIndex = <String, int>{};

  CategoryRef resolve(
    String entity,
    int row,
    int categoryId,
    String? rawName,
    TransactionType type,
  ) {
    if (categoryId > 0 && known.contains(categoryId)) {
      return CategoryRef.existing(categoryId);
    }
    final name = rawName?.trim() ?? '';
    if (name.isEmpty) {
      throw BackupImportException(
        ImportErrorCode.invalid,
        '$entity row ${row + 2}: unknown category',
      );
    }
    final lower = name.toLowerCase();
    for (final c in existing) {
      if (c.type != type) continue;
      if (c.namePtBr.trim().toLowerCase() == lower ||
          c.nameEn?.trim().toLowerCase() == lower) {
        return CategoryRef.existing(c.id);
      }
    }
    final key = '${type.name}|$lower';
    final index = createdIndex.putIfAbsent(key, () {
      created.add(
        TransactionCategoryModel()
          ..namePtBr = name
          ..type = type
          ..isDefault = false
          ..createdAt = now,
      );
      return created.length - 1;
    });
    return CategoryRef.created(index);
  }

  final transactions = snapshot.transactions;
  final budgets = snapshot.budgets;
  final payments = snapshot.recurringPayments;
  return CategoryResolution(
    transactions: [
      for (var i = 0; i < (transactions?.length ?? 0); i++)
        resolve(
          'transactions',
          i,
          transactions![i].categoryId,
          snapshot.transactionCategoryNames?[i],
          transactions[i].type,
        ),
    ],
    budgets: [
      for (var i = 0; i < (budgets?.length ?? 0); i++)
        resolve(
          'budgets',
          i,
          budgets![i].categoryId,
          snapshot.budgetCategoryNames?[i],
          TransactionType.expense,
        ),
    ],
    payments: [
      for (var i = 0; i < (payments?.length ?? 0); i++)
        resolve(
          'recurringPayments',
          i,
          payments![i].categoryId,
          snapshot.paymentCategoryNames?[i],
          TransactionType.expense,
        ),
    ],
    created: created,
  );
}
