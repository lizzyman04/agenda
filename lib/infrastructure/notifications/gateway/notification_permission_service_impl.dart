import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Platform channel that opens the system settings; the Kotlin and Swift
/// handlers must use the same names (pinned by system_settings_channel_test).
const String systemSettingsChannelName = 'agenda/system_settings';

/// The channel method that opens this app's notification settings page.
const String openNotificationSettingsMethod = 'openNotificationSettings';

/// [NotificationPermissionService] over the plugin's platform hooks.
///
/// Android asks for POST_NOTIFICATIONS (13+) and the exact-alarm screen
/// (12+); iOS asks for alert and sound, never badge. Every call is guarded
/// and falls back to the safe answer (denied, or false for exact alarms).
@LazySingleton(as: NotificationPermissionService)
class NotificationPermissionServiceImpl
    implements NotificationPermissionService {
  NotificationPermissionServiceImpl(this._plugin);

  static const MethodChannel _settingsChannel = MethodChannel(
    systemSettingsChannelName,
  );

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

  NotificationPermission _from(bool? granted) =>
      granted ?? false
          ? NotificationPermission.granted
          : NotificationPermission.denied;

  @override
  Future<NotificationPermission> notificationPermission() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _from(await _android?.areNotificationsEnabled());
        case TargetPlatform.iOS:
          return _from((await _ios?.checkPermissions())?.isEnabled);
        case _:
          return NotificationPermission.denied;
      }
    } on Object {
      return NotificationPermission.denied;
    }
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _from(await _android?.requestNotificationsPermission());
        case TargetPlatform.iOS:
          return _from(
            await _ios?.requestPermissions(alert: true, sound: true),
          );
        case _:
          return NotificationPermission.denied;
      }
    } on Object {
      return NotificationPermission.denied;
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } on Object {
      // Nothing to recover: the caller re-reads canScheduleExact.
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await _settingsChannel.invokeMethod<bool>(
            openNotificationSettingsMethod,
          ) ??
          false;
    } on Object {
      return false;
    }
  }
}
