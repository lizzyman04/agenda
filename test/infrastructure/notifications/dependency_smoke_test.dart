// Wave 0 compile spike for the Phase 4 packages (plan 04-05).
//
// Compiling this file against flutter_local_notifications 21.0.0,
// file_picker 11.0.2, flutter_timezone 5.0.2 and csv 8.0.0 proves the API
// names later plans (04-08, 04-10, 04-11, 04-16) code against. No platform
// channel is called; the only runtime assertions are the csv round trip and
// the in-package timezone database.

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('flutter_local_notifications 21.0.0 API names compile', () {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'Channel name',
        channelDescription: 'Channel description',
        importance: Importance.high,
        visibility: NotificationVisibility.private,
      ),
    );
    final plugin = FlutterLocalNotificationsPlugin();

    // Tear-offs only: referencing them proves the named parameters exist at
    // compile time without invoking a platform channel.
    Future<void> shape() async {
      await plugin.initialize(settings: settings);
      await plugin.show(
        id: 1,
        title: 't',
        body: 'b',
        notificationDetails: details,
        payload: 'p',
      );
      await plugin.cancel(id: 1);
      await plugin.cancelAll();
      await plugin.zonedSchedule(
        id: 2,
        scheduledDate: tz.TZDateTime.utc(2026),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 't',
        body: 'b',
        payload: 'p',
        matchDateTimeComponents: DateTimeComponents.time,
      );
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.canScheduleExactNotifications();
      await android?.requestExactAlarmsPermission();
      await plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    expect(shape, isA<Function>());
    expect(AndroidScheduleMode.inexactAllowWhileIdle, isNotNull);
  });

  test('file_picker 11.0.2 exposes static saveFile and pickFiles', () {
    const tearOffs = <Object>[FilePicker.saveFile, FilePicker.pickFiles];
    expect(tearOffs, hasLength(2));
  });

  test('flutter_timezone 5.0.2 returns a TimezoneInfo with identifier', () {
    const tearOff = FlutterTimezone.getLocalTimezone;
    expect(tearOff, isNotNull);
    expect(TimezoneInfo(identifier: 'Africa/Maputo').identifier,
        'Africa/Maputo');
  });

  test('csv 8.0.0 top-level instance round-trips rows', () {
    final rows = <List<dynamic>>[
      ['id', 'amount', 'note'],
      ['1', '1.234,56', 'a, "quoted" note'],
    ];
    final encoded = csv.encode(rows);
    expect(encoded, contains('"a, ""quoted"" note"'));
    expect(csv.decode(encoded), rows);
  });

  test('timezone data initialises offline from the package', () {
    tzdata.initializeTimeZones();
    final maputo = tz.getLocation('Africa/Maputo');
    final date = tz.TZDateTime(maputo, 2026, 1, 15, 8);
    expect(date.timeZoneOffset, const Duration(hours: 2));
  });
}
