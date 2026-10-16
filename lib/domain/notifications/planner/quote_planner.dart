import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planning/quote_picker.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';

/// Plans the next `AppConstants.quoteSlotsAhead` motivational quotes
/// (NOTF-08, D-07).
///
/// Off by default: it emits nothing unless the quote kind is enabled and
/// [PlannerInput.quotes] is non-empty. Daily mode uses every day at the
/// chosen time; weekly mode uses Mondays (a discretionary choice, D-07 gives
/// no weekday). Slots whose time has already passed are skipped and replaced
/// by a later one, so the full count is always planned. The quote of a slot
/// comes from a permutation seeded by the persisted `quoteSeed`, so it is
/// stable and does not repeat within one cycle of the list.
final class QuotePlanner implements KindPlanner {
  const QuotePlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    const kind = NotificationKind.motivationalQuote;
    final prefs = input.prefs;
    if (!prefs.isEnabled(kind) || input.quotes.isEmpty) return const [];
    final weekly = prefs.quoteFrequency == QuoteFrequency.weekly;
    final step = weekly ? 7 : 1;
    var fire = weekly
        ? nextWeekdayAt(
            input.now,
            weekday: DateTime.monday,
            minutes: prefs.quoteMinutes,
          )
        : atMinutes(startOfDay(input.now), prefs.quoteMinutes);
    final planned = <PlannedNotification>[];
    while (planned.length < AppConstants.quoteSlotsAhead) {
      if (fire.isAfter(input.now)) {
        final day = epochDay(fire);
        planned.add(
          PlannedNotification(
            kind: kind,
            id: notificationId(
              base: kind.idBase,
              entityId: day,
              type: kind.idType,
            ),
            fireAt: fire,
            entityId: day,
            subject:
                pickQuote(
                  input.quotes,
                  weekly ? day ~/ 7 : day,
                  prefs.quoteSeed,
                ) ??
                '',
          ),
        );
      }
      fire = addDays(fire, step);
    }
    return planned;
  }
}
