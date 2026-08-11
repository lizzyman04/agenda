import 'package:isar_community/isar.dart';

part 'savings_goal_model.g.dart';

/// Embedded value object for a single manual contribution to a savings goal.
///
/// Stored as List<GoalContribution> on SavingsGoalModel — no separate
/// collection. MUST be initialized as List.empty(growable: true) to allow
/// appending contributions at runtime.
@embedded
class GoalContribution {
  GoalContribution();

  /// Contribution amount in smallest currency unit (cents). Never double.
  int amountCents = 0;

  /// Date this contribution was made.
  late DateTime date;

  /// Optional note describing the contribution.
  String? note;
}

/// Isar @Collection for savings goals.
///
/// Goal progress is computed from two sources (D-11):
/// 1. contributions — list of manual contributions embedded here.
/// 2. Tagged transactions (linkedGoalId) — aggregated by the caller.
@Collection()
class SavingsGoalModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int targetAmountCents;
  DateTime? deadline;

  /// CRITICAL: List.empty(growable: true) — NOT [].
  ///
  /// Isar's code-generated writer requires the list to be explicitly growable.
  /// Using [] compiles but throws "Cannot add to a fixed-length list" at write
  /// time.
  /// See: github.com/isar/isar/discussions/781
  ///
  /// EQUALLY CRITICAL: this initializer only covers freshly constructed
  /// models. Isar's generated deserializer ASSIGNS over this field with the
  /// fixed-length list returned by `readObjectList`, so a model loaded via
  /// `findById` has a NON-growable list. Never call `.add()` on it — build a
  /// new list instead (`model.contributions = [...model.contributions, x]`).
  /// Getting this wrong is what broke goal contributions in Phase 03 UAT.
  List<GoalContribution> contributions = List.empty(growable: true);

  bool isCompleted = false;

  /// Soft delete — non-null means this goal is deleted.
  @Index()
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}
