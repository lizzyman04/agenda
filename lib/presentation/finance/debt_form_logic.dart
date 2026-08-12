import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';

/// Pure function that builds the [Debt] to persist from validated form
/// field values.
///
/// Extracted verbatim from `DebtFormScreen._save()` so the create/update
/// branching (including the `isPaid: false` create-default) can be reasoned
/// about — and tested — independently of widget state and `BuildContext`.
Debt buildDebtToSave({
  required bool isEditing,
  required Debt? original,
  required String title,
  required int amountCents,
  required DebtDirection direction,
  required String counterparty,
  required DateTime dueDate,
  required DateTime now,
}) {
  if (isEditing) {
    return original!.copyWith(
      title: title,
      amountCents: amountCents,
      direction: direction,
      counterparty: counterparty,
      dueDate: dueDate,
      updatedAt: now,
    );
  }
  return Debt(
    id: 0,
    title: title,
    amountCents: amountCents,
    direction: direction,
    counterparty: counterparty,
    dueDate: dueDate,
    isPaid: false,
    createdAt: now,
    updatedAt: now,
  );
}
