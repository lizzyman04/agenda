import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/tasks/item.dart';

/// A savings goal with the cents saved so far (contributions + tagged).
final class GoalProgress {
  const GoalProgress({required this.goal, required this.savedCents});

  final SavingsGoal goal;
  final int savedCents;
}

/// Everything a `KindPlanner` may read. [now] is injected so every rule is
/// testable without a clock.
final class PlannerInput {
  const PlannerInput({
    required this.now,
    required this.prefs,
    this.localeCode = 'en',
    this.items = const [],
    this.windowItems = const [],
    this.debts = const [],
    this.goals = const [],
    this.payments = const [],
    this.quotes = const [],
    this.firedAlertKeys = const {},
    this.slotBudget = AppConstants.androidPlannerSlotBudget,
  });

  final DateTime now;
  final NotificationPrefs prefs;

  /// 'en' or 'pt'.
  final String localeCode;

  /// Soonest remindable items.
  final List<Item> items;

  /// Every item due inside the briefing horizon, uncapped.
  final List<Item> windowItems;
  final List<Debt> debts;
  final List<GoalProgress> goals;
  final List<RecurringPayment> payments;

  /// Quote list of the active locale.
  final List<String> quotes;

  /// Goal-week markers planners must skip.
  final Set<String> firedAlertKeys;

  /// Platform cap on planner-owned notifications.
  final int slotBudget;
}
