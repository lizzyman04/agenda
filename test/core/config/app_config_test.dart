import 'package:flutter_test/flutter_test.dart';

import 'package:agenda/core/config/app_config.dart';

void main() {
  group('AppConfig constants', () {
    test('appName is AGENDA', () {
      expect(AppConfig.appName, 'AGENDA');
    });

    test('packageName is com.omeu.space.agenda', () {
      expect(AppConfig.packageName, 'com.omeu.space.agenda');
    });

    test('schemaVersion is 1 (initial)', () {
      expect(AppConfig.schemaVersion, 1);
    });

    test('taskNotificationBase is 10', () {
      expect(AppConfig.taskNotificationBase, 10);
    });

    test('financeNotificationBase is 20', () {
      expect(AppConfig.financeNotificationBase, 20);
    });

    test('systemNotificationBase is 30', () {
      expect(AppConfig.systemNotificationBase, 30);
    });

    test('notification bases are distinct', () {
      expect(
        AppConfig.taskNotificationBase,
        isNot(AppConfig.financeNotificationBase),
      );
      expect(
        AppConfig.financeNotificationBase,
        isNot(AppConfig.systemNotificationBase),
      );
    });
  });
}
