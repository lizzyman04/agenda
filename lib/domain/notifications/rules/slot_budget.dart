import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';

/// The outcome of fitting a plan into the platform slot budget.
final class SlotSelection {
  const SlotSelection({required this.kept, required this.truncated});

  /// Entries to schedule, sorted by fire time then id.
  final List<PlannedNotification> kept;

  /// How many input entries were left out.
  final int truncated;
}

int _byTime(PlannedNotification a, PlannedNotification b) {
  final byTime = a.fireAt.compareTo(b.fireAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

/// Fits [planned] into [budget] slots.
///
/// Up to [AppConstants.maxBriefingSlots] briefings and
/// [AppConstants.maxQuoteSlots] quotes (soonest first) are reserved first,
/// briefings before quotes; every other kind competes soonest-first for the
/// remainder. If the reserve alone exceeds the budget, the far quotes drop
/// first, then briefings.
SlotSelection selectWithinBudget(
  List<PlannedNotification> planned, {
  required int budget,
}) {
  if (budget <= 0) {
    return SlotSelection(kept: const [], truncated: planned.length);
  }
  final sorted = [...planned]..sort(_byTime);
  List<PlannedNotification> ofKind(NotificationKind k) => [
    for (final p in sorted)
      if (p.kind == k) p,
  ];
  final briefings = ofKind(
    NotificationKind.morningBriefing,
  ).take(AppConstants.maxBriefingSlots).take(budget).toList();
  final quotes = ofKind(NotificationKind.motivationalQuote)
      .take(AppConstants.maxQuoteSlots)
      .take(budget - briefings.length)
      .toList();
  final others = [
    for (final p in sorted)
      if (p.kind != NotificationKind.morningBriefing &&
          p.kind != NotificationKind.motivationalQuote)
        p,
  ].take(budget - briefings.length - quotes.length);
  final kept = [...briefings, ...quotes, ...others]..sort(_byTime);
  return SlotSelection(kept: kept, truncated: planned.length - kept.length);
}
