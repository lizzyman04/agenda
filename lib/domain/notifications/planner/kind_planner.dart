import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';

/// Plans the notifications of one kind from a [PlannerInput].
///
/// Implementations return raw fire times; toggles, quiet hours,
/// de-duplication and the slot budget are applied by `ReminderPlanner`.
// A named interface keeps the planners injectable and test-stubbable.
// ignore: one_member_abstracts
abstract interface class KindPlanner {
  List<PlannedNotification> plan(PlannerInput input);
}
