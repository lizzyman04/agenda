/// A manual contribution toward a SavingsGoal.
///
/// Value object — no id, no copyWith needed. Const constructor.
/// Stored as an embedded list on SavingsGoal.
///
/// Pure Dart — zero Flutter and zero Isar imports.
class SavingsGoalContribution {
  const SavingsGoalContribution({
    required this.amountCents,
    required this.date,
    this.note,
  });

  /// Contribution amount in smallest currency unit (cents). Never double.
  final int amountCents;

  /// Date of the contribution.
  final DateTime date;

  /// Optional note describing this contribution.
  final String? note;
}
