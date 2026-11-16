import 'dart:io';

import 'package:agenda/infrastructure/lock/secure_window_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(appPrivacyChannelName);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('channel and method names match the native hosts', () {
    expect(appPrivacyChannelName, 'agenda/app_privacy');
    expect(setSecureMethod, 'setSecure');
    final dart =
        File(
          'lib/infrastructure/lock/secure_window_channel.dart',
        ).readAsStringSync();
    expect(dart, contains("'$appPrivacyChannelName'"));
    expect(dart, contains("'$setSecureMethod'"));
  });

  group('setSecure', () {
    late SecureWindowChannel gateway;
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
      gateway = SecureWindowChannel();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('Android: enable sends one call with argument true', () async {
      handle((_) async => true);
      expect(await gateway.setSecure(enabled: true), isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, setSecureMethod);
      expect(calls.single.arguments, isTrue);
    });

    test('Android: disable sends argument false', () async {
      handle((_) async => true);
      expect(await gateway.setSecure(enabled: false), isTrue);
      expect(calls.single.arguments, isFalse);
    });

    test('iOS uses the channel as well', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      handle((_) async => true);
      expect(await gateway.setSecure(enabled: true), isTrue);
      expect(calls, hasLength(1));
    });

    test('a platform exception maps to false', () async {
      handle((_) async => throw PlatformException(code: 'bad_args'));
      expect(await gateway.setSecure(enabled: true), isFalse);
    });

    test('a null reply counts as false', () async {
      handle((_) async => null);
      expect(await gateway.setSecure(enabled: true), isFalse);
    });

    test('no registered handler maps to false', () async {
      expect(await gateway.setSecure(enabled: true), isFalse);
    });

    test('other platforms answer false without a channel call', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      handle((_) async => true);
      expect(await gateway.setSecure(enabled: true), isFalse);
      expect(calls, isEmpty);
    });
  });
}
