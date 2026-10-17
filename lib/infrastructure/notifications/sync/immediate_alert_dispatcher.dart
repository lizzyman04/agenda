import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/notifications/rules/quiet_hours.dart';
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart';
import 'package:agenda/infrastructure/notifications/gateway/notification_channels.dart';
import 'package:agenda/infrastructure/notifications/sync/permission_gate.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raises one alert that depends on an in-app event instead of a timestamp
/// (budget thresholds, an off-track goal on open).
///
/// It applies the kind toggle, the permission and quiet hours (D-08): an
/// alert raised inside the window is scheduled for the window end rather than
/// shown or dropped. In-event callers that run in context (budget alerts) may
/// raise the permission prompt; the app-open path must not (Pitfall 10).
/// Nothing here ever throws.
@lazySingleton
class ImmediateAlertDispatcher {
  ImmediateAlertDispatcher(
    this._gateway,
    this._prefs,
    this._permissions,
    this._gate,
    this._content,
    this._store,
  );

  final LocalNotificationGateway _gateway;
  final NotificationPrefsRepository _prefs;
  final NotificationPermissionService _permissions;
  final PermissionGate _gate;
  final NotificationContentBuilder _content;
  final SharedPreferences _store;

  /// Shows or defers [p]. Returns false when its kind is off, the permission
  /// is missing or the gateway call failed, true when the alert was handed to
  /// the operating system. A false return means nothing was raised.
  ///
  /// With [promptIfNeeded] false the permission prompt is never raised: the
  /// alert is dropped unless the permission is already granted.
  Future<bool> dispatch(
    PlannedNotification p, {
    required DateTime now,
    bool promptIfNeeded = true,
  }) async {
    try {
      final prefs = _prefs.load();
      if (!prefs.isEnabled(p.kind)) return false;
      if (promptIfNeeded) {
        await _gate.ensureAsked();
      } else if (await _permissions.notificationPermission() !=
          NotificationPermission.granted) {
        return false;
      }
      final fire =
          prefs.quietHoursEnabled
              ? deferOutOfQuietHours(
                now,
                startMinutes: prefs.quietStartMinutes,
                endMinutes: prefs.quietEndMinutes,
              )
              : now;
      final exact = await _permissions.canScheduleExact();
      final text = _content.build(
        p,
        notificationL10n(_store.getString(StorageKeys.locale)),
      );
      final request = ScheduleRequest(
        id: p.id,
        kind: p.kind,
        fireAt: fire,
        title: text.title,
        body: text.body,
        payload: encodePayload(
          kind: p.kind,
          entityId: p.entityId,
          fireAt: fire,
          exact: exact,
        ),
        exact: exact,
      );
      final result =
          fire.isAfter(now)
              ? await _gateway.schedule(request)
              : await _gateway.showNow(request);
      return result is Success<void>;
    } on Object {
      return false;
    }
  }
}
