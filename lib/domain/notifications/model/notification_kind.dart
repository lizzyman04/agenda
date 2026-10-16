import 'package:agenda/core/config/app_config.dart';

/// Every notification the app can raise (NOTF-01..NOTF-11).
///
/// Each kind knows its payload [code], the id namespace it lives in
/// ([idBase] + [idType]) and whether the schedule planner owns it.
/// Pure Dart: no localized text lives here.
enum NotificationKind {
  taskReminder(
    code: 'tk',
    idBase: AppConfig.taskNotificationBase,
    idType: 0,
  ),
  recurringTaskReminder(
    code: 'rt',
    idBase: AppConfig.taskNotificationBase,
    idType: 1,
  ),
  morningBriefing(
    code: 'mb',
    idBase: AppConfig.systemNotificationBase,
    idType: 0,
  ),
  budgetAlert(
    code: 'bd',
    idBase: AppConfig.financeNotificationBase,
    idType: 3,
    plannerOwned: false,
  ),
  debtReminder(
    code: 'db',
    idBase: AppConfig.financeNotificationBase,
    idType: 0,
  ),
  goalOffTrack(
    code: 'gl',
    idBase: AppConfig.financeNotificationBase,
    idType: 2,
  ),
  recurringPayment(
    code: 'rp',
    idBase: AppConfig.financeNotificationBase,
    idType: 1,
  ),
  motivationalQuote(
    code: 'qt',
    idBase: AppConfig.systemNotificationBase,
    idType: 1,
  );

  const NotificationKind({
    required this.code,
    required this.idBase,
    required this.idType,
    this.plannerOwned = true,
  });

  /// Two-letter code used in the tap payload grammar.
  final String code;

  /// Id namespace multiplier (10 task, 20 finance, 30 system).
  final int idBase;

  /// Last id digit that tells kinds of one namespace apart.
  final int idType;

  /// False for kinds raised by the evaluator instead of the planner.
  final bool plannerOwned;

  /// Resolves a payload [code], or null when it is unknown.
  static NotificationKind? fromCode(String code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}
