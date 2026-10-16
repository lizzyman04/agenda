import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Outcome of [validateSnapshot].
final class ValidationReport {
  const ValidationReport({
    required this.errors,
    required this.danglingLinks,
    required this.softDeleted,
  });

  /// Blocking problems, each naming the collection (and row where known).
  final List<String> errors;

  /// Foreign keys pointing at nothing in the file. Warnings, never errors.
  final int danglingLinks;

  /// Rows that carry a deletion mark.
  final int softDeleted;
}

const int _maxReportedErrors = 25;

/// Checks a decoded snapshot BEFORE anything is written: row caps, duplicate
/// explicit ids, repeated budget keys, ranges and negative amounts.
///
/// Rows without an explicit id (the Isar auto-increment sentinel) are never
/// duplicates of each other.
ValidationReport validateSnapshot(
  BackupSnapshot s, {
  int maxRowsPerCollection = 200000,
}) {
  final errors = <String>[];
  void fail(String message) {
    if (errors.length < _maxReportedErrors) errors.add(message);
  }

  void ids(String name, List<int>? all) {
    if (all == null) return;
    if (all.length > maxRowsPerCollection) {
      return fail('$name: more than $maxRowsPerCollection rows');
    }
    final seen = <int>{};
    for (final id in all.where((i) => i != Isar.autoIncrement)) {
      if (!seen.add(id)) fail('$name: duplicate id $id');
    }
  }

  void negative(String name, Iterable<int>? cents) {
    if (cents != null && cents.any((c) => c < 0)) {
      fail('$name: negative amount');
    }
  }

  ids('items', s.items?.map((m) => m.id).toList());
  ids('transactions', s.transactions?.map((m) => m.id).toList());
  ids('categories', s.categories?.map((m) => m.id).toList());
  ids('budgets', s.budgets?.map((m) => m.id).toList());
  ids('goals', s.goals?.map((m) => m.id).toList());
  ids('debts', s.debts?.map((m) => m.id).toList());
  ids('recurringPayments', s.recurringPayments?.map((m) => m.id).toList());

  for (final m in s.items ?? const <ItemModel>[]) {
    final minutes = m.timeInfo?.dueTimeMinutes;
    if (minutes != null && (minutes < 0 || minutes > 1439)) {
      fail('items: dueTimeMinutes out of range for id ${m.id}');
    }
  }
  final budgets = s.budgets;
  if (budgets != null) {
    final keys = <String>{};
    for (var i = 0; i < budgets.length; i++) {
      final b = budgets[i];
      if (b.month < 1 || b.month > 12) fail('budgets: month out of range');
      final name = s.budgetCategoryNames?[i]?.trim().toLowerCase();
      final category = b.categoryId != 0 ? 'id:${b.categoryId}' : 'name:$name';
      if (!keys.add('${b.year}-${b.month}-$category')) {
        fail('budgets: duplicate month, year and category');
      }
    }
  }
  negative('transactions', s.transactions?.map((m) => m.amountCents));
  negative('budgets', s.budgets?.map((m) => m.limitCents));
  negative('goals', s.goals?.map((m) => m.targetAmountCents));
  negative(
    'goals',
    s.goals?.expand((g) => g.contributions).map((c) => c.amountCents),
  );
  negative('debts', s.debts?.map((m) => m.amountCents));
  negative('recurringPayments', s.recurringPayments?.map((m) => m.amountCents));

  return ValidationReport(
    errors: errors,
    danglingLinks: _dangling(s),
    softDeleted: _softDeleted(s),
  );
}

int _softDeleted(BackupSnapshot s) =>
    (s.items ?? const []).where((m) => m.deletedAt != null).length +
    (s.transactions ?? const []).where((m) => m.deletedAt != null).length +
    (s.goals ?? const []).where((m) => m.deletedAt != null).length +
    (s.debts ?? const []).where((m) => m.deletedAt != null).length +
    (s.recurringPayments ?? const []).where((m) => m.deletedAt != null).length;

// Counts references to a collection that IS in the file but lacks the id.
int _dangling(BackupSnapshot s) {
  final itemIds = s.items?.map((m) => m.id).toSet();
  final goalIds = s.goals?.map((m) => m.id).toSet();
  final debtIds = s.debts?.map((m) => m.id).toSet();
  final categoryIds = s.categories?.map((m) => m.id).toSet();
  int missing(Iterable<int?> refs, Set<int>? targets) =>
      targets == null
          ? 0
          : refs
              .where((r) => r != null && r != 0 && !targets.contains(r))
              .length;
  final items = s.items ?? const [];
  return missing(items.map((m) => m.parentId), itemIds) +
      missing(items.map((m) => m.linkedGoalId), goalIds) +
      missing(items.map((m) => m.linkedDebtId), debtIds) +
      missing(
        (s.transactions ?? const []).map((m) => m.categoryId),
        categoryIds,
      ) +
      missing(
        (s.transactions ?? const []).map((m) => m.linkedGoalId),
        goalIds,
      ) +
      missing((s.budgets ?? const []).map((m) => m.categoryId), categoryIds) +
      missing(
        (s.recurringPayments ?? const []).map((m) => m.categoryId),
        categoryIds,
      );
}
