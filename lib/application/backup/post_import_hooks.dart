import 'package:agenda/application/notifications/budget_alert_evaluator.dart';
import 'package:agenda/application/notifications/goal_alert_evaluator.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';

/// Runs the follow-ups of a committed import, in order: silent reseed of the
/// budget markers, silent reseed of the goal markers, then a reconcile.
///
/// Each step has its own try/catch so one failing step neither skips the
/// others nor masks the import that already succeeded (T-04-17-04).
Future<void> runPostImportHooks({
  required BudgetAlertEvaluator budgetAlerts,
  required GoalAlertEvaluator goalAlerts,
  required NotificationReconciler reconciler,
}) async {
  final hooks = <Future<void> Function()>[
    budgetAlerts.reseedAfterImport,
    goalAlerts.reseedAfterImport,
    () => reconciler.reconcileNow(ReconcileReason.afterImport),
  ];
  for (final hook in hooks) {
    try {
      await hook();
    } on Object {
      // Intentionally swallowed: the data is already restored.
    }
  }
}
