import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';

/// Where a notification tap should land.
sealed class TapTarget {
  const TapTarget();
}

/// The detail screen of task [taskId].
final class OpenTask extends TapTarget {
  const OpenTask(this.taskId);

  final int taskId;
}

/// The Tasks tab (morning briefing).
final class OpenBriefing extends TapTarget {
  const OpenBriefing();
}

/// Finance tab, Budgets sub-tab.
final class OpenBudgets extends TapTarget {
  const OpenBudgets();
}

/// Finance tab, Debts sub-tab.
final class OpenDebts extends TapTarget {
  const OpenDebts();
}

/// Finance tab, Recurring payments sub-tab.
final class OpenPayments extends TapTarget {
  const OpenPayments();
}

/// Finance tab, Goals sub-tab, then the detail of goal [goalId].
final class OpenGoal extends TapTarget {
  const OpenGoal(this.goalId);

  final int goalId;
}

/// Only bring the app forward.
final class AppOnly extends TapTarget {
  const AppOnly();
}

/// Maps an untrusted tap [payload] to a [TapTarget].
///
/// Uses the strict payload decoder; anything null, malformed, from an
/// unknown version or of an unknown kind resolves to [AppOnly]. Pure and
/// never throws.
TapTarget resolveTapTarget(String? payload) {
  final decoded = decodePayload(payload);
  if (decoded == null) return const AppOnly();
  return switch (decoded.kind) {
    NotificationKind.taskReminder ||
    NotificationKind.recurringTaskReminder => OpenTask(decoded.entityId),
    NotificationKind.morningBriefing => const OpenBriefing(),
    NotificationKind.budgetAlert => const OpenBudgets(),
    NotificationKind.debtReminder => const OpenDebts(),
    NotificationKind.recurringPayment => const OpenPayments(),
    NotificationKind.goalOffTrack => OpenGoal(decoded.entityId),
    NotificationKind.motivationalQuote => const AppOnly(),
  };
}
