import 'dart:io';

import 'package:agenda/infrastructure/notifications/gateway/notification_permission_service_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(systemSettingsChannelName);

String _read(String path) => File(path).readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('openNotificationSettings', () {
    late NotificationPermissionServiceImpl service;
    late List<MethodCall> calls;

    void handle(Future<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) {
            calls.add(call);
            return handler(call);
          });
    }

    setUp(() {
      calls = [];
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      service = NotificationPermissionServiceImpl(
        FlutterLocalNotificationsPlugin(),
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('true when the platform launched the page', () async {
      handle((_) async => true);
      expect(await service.openNotificationSettings(), isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, openNotificationSettingsMethod);
      expect(calls.single.arguments, isNull);
    });

    test('false when the platform could not launch it', () async {
      handle((_) async => false);
      expect(await service.openNotificationSettings(), isFalse);
    });

    test('a null reply counts as false', () async {
      handle((_) async => null);
      expect(await service.openNotificationSettings(), isFalse);
    });

    test('a platform exception maps to false', () async {
      handle((_) async => throw PlatformException(code: 'boom'));
      expect(await service.openNotificationSettings(), isFalse);
    });

    test('no registered handler maps to false', () async {
      expect(await service.openNotificationSettings(), isFalse);
    });

    test('iOS uses the channel as well', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      handle((_) async => true);
      expect(await service.openNotificationSettings(), isTrue);
    });

    test('other platforms answer false without a channel call', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      handle((_) async => true);
      expect(await service.openNotificationSettings(), isFalse);
      expect(calls, isEmpty);
    });
  });

  group('cross-language contract', () {
    late String dart;
    late String kotlin;
    late String swift;

    setUpAll(() {
      dart = _read(
        'lib/infrastructure/notifications/gateway/'
        'notification_permission_service_impl.dart',
      );
      kotlin = _read(
        'android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt',
      );
      swift = _read('ios/Runner/AppDelegate.swift');
    });

    test('Dart, Kotlin and Swift share the channel name', () {
      expect(systemSettingsChannelName, 'agenda/system_settings');
      expect(dart, contains("'$systemSettingsChannelName'"));
      expect(kotlin, contains('"$systemSettingsChannelName"'));
      expect(swift, contains('"$systemSettingsChannelName"'));
    });

    test('Dart, Kotlin and Swift share the method name', () {
      expect(dart, contains("'$openNotificationSettingsMethod'"));
      expect(kotlin, contains('"$openNotificationSettingsMethod"'));
      expect(swift, contains('"$openNotificationSettingsMethod"'));
    });

    test('Kotlin opens the app notification settings', () {
      expect(kotlin, contains('ACTION_APP_NOTIFICATION_SETTINGS'));
      expect(kotlin, contains('super.configureFlutterEngine'));
      expect(
        kotlin,
        contains('class MainActivity : FlutterFragmentActivity()'),
      );
    });

    test('Swift opens the settings URL and keeps the backup exclusion', () {
      expect(swift, contains('openSettingsURLString'));
      expect(swift, contains('applicationRegistrar.messenger()'));
      expect(swift, contains('excludeUserDataFromBackup()'));
    });
  });
}
