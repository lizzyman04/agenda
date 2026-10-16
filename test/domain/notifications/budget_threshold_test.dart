import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/planning/budget_threshold.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('crossedBudgetThreshold', () {
    int? crossed(int spent, {int limit = 10000}) =>
        crossedBudgetThreshold(spentCents: spent, limitCents: limit);

    test('below 80 percent crosses nothing', () {
      expect(crossed(7900), isNull);
      expect(crossed(0), isNull);
    });

    test('exactly 80 percent crosses 80', () {
      expect(crossed(8000), 80);
    });

    test('between 80 and 100 percent crosses 80', () {
      expect(crossed(9999), 80);
    });

    test('exactly 100 percent crosses 100', () {
      expect(crossed(10000), 100);
    });

    test('over 100 percent crosses 100', () {
      expect(crossed(10001), 100);
      expect(crossed(25000), 100);
    });

    test('uses integer cents so odd limits do not round the edge', () {
      // 80% of 12345 is 9876 exactly; 9875 stays below.
      expect(crossed(9875, limit: 12345), isNull);
      expect(crossed(9876, limit: 12345), 80);
      expect(crossed(1, limit: 1), 100);
    });

    test('a zero or negative limit never crosses', () {
      expect(crossed(5000, limit: 0), isNull);
      expect(crossed(5000, limit: -100), isNull);
    });
  });

  group('keys', () {
    test('budgetAlertKey zero pads the month', () {
      expect(budgetAlertKey(2026, 3, 7, 80), 'b:2026-03:7:80');
      expect(budgetAlertKey(2026, 12, 42, 100), 'b:2026-12:42:100');
    });

    test('budgetSeededKey zero pads the month', () {
      expect(budgetSeededKey(2026, 1), 'seeded:2026-01');
      expect(budgetSeededKey(2026, 10), 'seeded:2026-10');
    });
  });

  group('plannedBudgetAlert', () {
    final at = DateTime(2026, 10, 16, 12);

    test('threshold 80 uses the budget80 id and carries name and percent', () {
      final p = plannedBudgetAlert(
        categoryId: 7,
        name: 'Food',
        threshold: 80,
        at: at,
      );
      expect(p.kind, NotificationKind.budgetAlert);
      expect(
        p.id,
        notificationId(
          base: 20,
          entityId: 7,
          type: NotificationIdTypes.budget80,
        ),
      );
      expect(p.subject, 'Food');
      expect(p.count, 80);
      expect(p.entityId, 7);
      expect(p.extras, isEmpty);
    });

    test('threshold 100 uses the budget100 id', () {
      final p = plannedBudgetAlert(
        categoryId: 7,
        name: 'Food',
        threshold: 100,
        at: at,
      );
      expect(
        p.id,
        notificationId(
          base: 20,
          entityId: 7,
          type: NotificationIdTypes.budget100,
        ),
      );
      expect(isPlannerOwnedId(p.id), isFalse);
    });
  });
}
