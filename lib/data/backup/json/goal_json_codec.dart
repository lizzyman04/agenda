import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';

/// Encodes a [SavingsGoalModel], contributions in order.
Map<String, Object?> goalToJson(SavingsGoalModel m) => {
  'id': m.id,
  'title': m.title,
  'targetAmountCents': m.targetAmountCents,
  'deadline': encodeJsonDateOrNull(m.deadline),
  'contributions': [
    for (final c in m.contributions)
      {
        'amountCents': c.amountCents,
        'date': encodeJsonDate(c.date),
        'note': c.note,
      },
  ],
  'isCompleted': m.isCompleted,
  'deletedAt': encodeJsonDateOrNull(m.deletedAt),
  'createdAt': encodeJsonDate(m.createdAt),
  'updatedAt': encodeJsonDate(m.updatedAt),
};

/// Strictly decodes a [SavingsGoalModel], keeping the explicit `id`.
SavingsGoalModel goalFromJson(JsonObjectReader r) {
  // Explicitly growable: a fixed-length or const list throws "Cannot add to
  // a fixed-length list" at the next contribution write (Phase 03 UAT bug).
  final contributions = List<GoalContribution>.empty(growable: true);
  for (final c in r.requireList('contributions')) {
    contributions.add(
      GoalContribution()
        ..amountCents = c.requireInt('amountCents')
        ..date = c.requireDate('date')
        ..note = c.optString('note'),
    );
  }
  return SavingsGoalModel()
    ..id = r.requireInt('id')
    ..title = r.requireString('title')
    ..targetAmountCents = r.requireInt('targetAmountCents')
    ..deadline = r.optDate('deadline')
    ..contributions = contributions
    ..isCompleted = r.requireBool('isCompleted')
    ..deletedAt = r.optDate('deletedAt')
    ..createdAt = r.requireDate('createdAt')
    ..updatedAt = r.requireDate('updatedAt');
}
