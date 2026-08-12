import 'package:agenda/domain/finance/goal/savings_goal.dart';

/// Pure construction logic for the goal form screen's save flow.
///
/// Extracted from `_save()` — builds the [SavingsGoal] to persist, either as
/// a brand-new goal (create) or as a `copyWith` of [original] (edit). Does
/// not talk to any cubit and does not perform I/O; the caller remains
/// responsible for the `getIt<GoalCubit>()` orchestration (including the
/// create-path's try/catch fallback), which is deliberately left untouched.
SavingsGoal buildGoalToSave({
  required bool isEditing,
  required SavingsGoal? original,
  required String title,
  required int targetAmountCents,
  DateTime? deadline,
  required DateTime now,
}) {
  if (isEditing) {
    return original!.copyWith(
      title: title,
      targetAmountCents: targetAmountCents,
      deadline: deadline,
      updatedAt: now,
    );
  }
  return SavingsGoal(
    id: 0,
    title: title,
    targetAmountCents: targetAmountCents,
    contributions: const [],
    isCompleted: false,
    deadline: deadline,
    createdAt: now,
    updatedAt: now,
  );
}
