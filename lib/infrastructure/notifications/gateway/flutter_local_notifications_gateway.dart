import 'dart:async';

import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/model/schedule_request.dart';
import 'package:agenda/infrastructure/notifications/gateway/notification_channels.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// [LocalNotificationGateway] over `flutter_local_notifications`.
///
/// The only class that talks to the plugin's scheduling API. Every call is
/// wrapped so a single failure becomes an `Err(NotificationFailure)` instead
/// of aborting a batch (T-04-10-03). Payload and body text are never logged.
@LazySingleton(as: LocalNotificationGateway)
class FlutterLocalNotificationsGateway implements LocalNotificationGateway {
  FlutterLocalNotificationsGateway(this._plugin, this._prefs);

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferences _prefs;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _initialized = false;

  AppLocalizations get _l10n =>
      notificationL10n(_prefs.getString(StorageKeys.locale));

  @override
  AsyncResult<void> initialize() async {
    if (_initialized) return const Success(null);
    try {
      // The three request flags stay false: the iOS prompt is raised later,
      // in context (Pitfall 10, T-04-10-04).
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) _taps.add(payload);
        },
      );
      final android =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (android != null) {
        for (final channel in androidChannels(_l10n)) {
          await android.createNotificationChannel(channel);
        }
      }
      _initialized = true;
      return const Success(null);
    } on Object catch (error) {
      return Err(
        NotificationFailure('Notification init failed (${error.runtimeType})'),
      );
    }
  }

  @override
  AsyncResult<List<PendingNotification>> pending() async {
    try {
      final requests = await _plugin.pendingNotificationRequests();
      return Success([
        for (final r in requests)
          PendingNotification(
            id: r.id,
            title: r.title ?? '',
            body: r.body ?? '',
            payload: r.payload ?? '',
          ),
      ]);
    } on Object catch (error) {
      return Err(
        NotificationFailure('Pending read failed (${error.runtimeType})'),
      );
    }
  }

  @override
  AsyncResult<void> schedule(ScheduleRequest request) =>
      _run('Schedule ${request.id}', () async {
        await _plugin.zonedSchedule(
          id: request.id,
          scheduledDate: tz.TZDateTime.from(request.fireAt, tz.local),
          notificationDetails: detailsFor(request.kind, _l10n),
          androidScheduleMode:
              request.exact
                  ? AndroidScheduleMode.exactAllowWhileIdle
                  : AndroidScheduleMode.inexactAllowWhileIdle,
          title: request.title,
          body: request.body,
          payload: request.payload,
        );
      });

  @override
  AsyncResult<void> showNow(ScheduleRequest request) =>
      _run('Show ${request.id}', () async {
        await _plugin.show(
          id: request.id,
          title: request.title,
          body: request.body,
          notificationDetails: detailsFor(request.kind, _l10n),
          payload: request.payload,
        );
      });

  @override
  AsyncResult<void> cancel(int id) =>
      _run('Cancel $id', () => _plugin.cancel(id: id));

  /// Runs [body], turning any throw into `Err(NotificationFailure)`. Only the
  /// exception type is reported: its message could quote user text.
  AsyncResult<void> _run(String what, Future<void> Function() body) async {
    try {
      await body();
      return const Success(null);
    } on Object catch (error) {
      return Err(NotificationFailure('$what failed (${error.runtimeType})'));
    }
  }

  @override
  Stream<String> get tapPayloads => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } on Object {
      return null;
    }
  }
}
