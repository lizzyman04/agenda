import 'package:agenda/data/tasks/item_mapper.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart' as domain;
import 'package:agenda/domain/tasks/priority.dart' as domain;
import 'package:agenda/domain/tasks/size_category.dart' as domain;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ItemMapper();

  final now = DateTime(2024, 6, 15, 10, 30);

  Item makeItem({
    int id = 1,
    domain.ItemType type = domain.ItemType.task,
    String title = 'Test Item',
    domain.Priority priority = domain.Priority.medium,
    domain.SizeCategory sizeCategory = domain.SizeCategory.none,
    int? dueTimeMinutes,
    String? recurrenceRule,
    double? amount,
    String? currencyCode,
  }) {
    return Item(
      id: id,
      type: type,
      title: title,
      priority: priority,
      sizeCategory: sizeCategory,
      dueTimeMinutes: dueTimeMinutes,
      recurrenceRule: recurrenceRule,
      amount: amount,
      currencyCode: currencyCode,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ItemMapper', () {
    group('toDomain', () {
      test('maps all scalar fields correctly', () {
        final model = ItemModel()
          ..id = 42
          ..type = ItemType.task
          ..title = 'My Task'
          ..description = 'desc'
          ..parentId = 10
          ..priority = Priority.high
          ..isUrgent = true
          ..isImportant = true
          ..sizeCategory = SizeCategory.big
          ..isNextAction = true
          ..gtdContext = '@home'
          ..waitingFor = 'Alice'
          ..dueDate = now
          ..isCompleted = true
          ..completedAt = now
          ..deletedAt = now
          ..createdAt = now
          ..updatedAt = now
          ..linkedGoalId = 5
          ..linkedDebtId = 6;

        final item = mapper.toDomain(model);

        expect(item.id, 42);
        expect(item.type, domain.ItemType.task);
        expect(item.title, 'My Task');
        expect(item.description, 'desc');
        expect(item.parentId, 10);
        expect(item.priority, domain.Priority.high);
        expect(item.isUrgent, isTrue);
        expect(item.isImportant, isTrue);
        expect(item.sizeCategory, domain.SizeCategory.big);
        expect(item.isNextAction, isTrue);
        expect(item.gtdContext, '@home');
        expect(item.waitingFor, 'Alice');
        expect(item.dueDate, now);
        expect(item.isCompleted, isTrue);
        expect(item.completedAt, now);
        expect(item.deletedAt, now);
        expect(item.createdAt, now);
        expect(item.updatedAt, now);
        expect(item.linkedGoalId, 5);
        expect(item.linkedDebtId, 6);
      });

      test('extracts dueTimeMinutes and recurrenceRule from timeInfo', () {
        final model = ItemModel()
          ..id = 1
          ..type = ItemType.task
          ..title = 'T'
          ..createdAt = now
          ..updatedAt = now
          ..timeInfo =
              TimeInfo(dueTimeMinutes: 570, recurrenceRule: 'FREQ=DAILY');

        final item = mapper.toDomain(model);

        expect(item.dueTimeMinutes, 570);
        expect(item.recurrenceRule, 'FREQ=DAILY');
      });

      test('extracts amount and currencyCode from moneyInfo', () {
        final model = ItemModel()
          ..id = 1
          ..type = ItemType.task
          ..title = 'T'
          ..createdAt = now
          ..updatedAt = now
          ..moneyInfo = MoneyInfo(amount: 99.99, currencyCode: 'MZN');

        final item = mapper.toDomain(model);

        expect(item.amount, 99.99);
        expect(item.currencyCode, 'MZN');
      });
    });

    group('toModel', () {
      test('maps all scalar fields correctly', () {
        final item = Item(
          id: 7,
          type: domain.ItemType.project,
          title: 'Project Alpha',
          description: 'desc',
          parentId: 3,
          priority: domain.Priority.critical,
          isUrgent: true,
          sizeCategory: domain.SizeCategory.small,
          gtdContext: '@office',
          waitingFor: 'Bob',
          dueDate: now,
          completedAt: now,
          deletedAt: now,
          createdAt: now,
          updatedAt: now,
          linkedGoalId: 11,
          linkedDebtId: 12,
        );

        final model = mapper.toModel(item);

        expect(model.id, 7);
        expect(model.type, ItemType.project);
        expect(model.title, 'Project Alpha');
        expect(model.description, 'desc');
        expect(model.parentId, 3);
        expect(model.priority, Priority.critical);
        expect(model.isUrgent, isTrue);
        expect(model.sizeCategory, SizeCategory.small);
        expect(model.gtdContext, '@office');
        expect(model.waitingFor, 'Bob');
        expect(model.dueDate, now);
        expect(model.linkedGoalId, 11);
        expect(model.linkedDebtId, 12);
      });

      test('timeInfo is null when dueTimeMinutes and recurrenceRule are null',
          () {
        final model = mapper.toModel(makeItem());
        expect(model.timeInfo, isNull);
      });

      test('timeInfo is set when dueTimeMinutes is provided', () {
        final model = mapper.toModel(makeItem(dueTimeMinutes: 480));
        expect(model.timeInfo, isNotNull);
        expect(model.timeInfo!.dueTimeMinutes, 480);
      });

      test('timeInfo is set when recurrenceRule is provided', () {
        final model = mapper.toModel(makeItem(recurrenceRule: 'FREQ=WEEKLY'));
        expect(model.timeInfo, isNotNull);
        expect(model.timeInfo!.recurrenceRule, 'FREQ=WEEKLY');
      });

      test('moneyInfo is null when amount and currencyCode are null', () {
        final model = mapper.toModel(makeItem());
        expect(model.moneyInfo, isNull);
      });

      test('moneyInfo is set when amount is provided', () {
        final model = mapper.toModel(makeItem(amount: 50));
        expect(model.moneyInfo, isNotNull);
        expect(model.moneyInfo!.amount, 50);
      });

      test('moneyInfo is set when currencyCode is provided', () {
        final model = mapper.toModel(makeItem(currencyCode: 'USD'));
        expect(model.moneyInfo, isNotNull);
        expect(model.moneyInfo!.currencyCode, 'USD');
      });
    });

    group('round-trip', () {
      test('toDomain(toModel(item)).title == item.title', () {
        final item = makeItem(title: 'Round Trip Test');
        final result = mapper.toDomain(mapper.toModel(item));
        expect(result.title, item.title);
      });
    });

    group('Priority mapping covers all 5 values', () {
      final cases = {
        domain.Priority.low: Priority.low,
        domain.Priority.medium: Priority.medium,
        domain.Priority.high: Priority.high,
        domain.Priority.critical: Priority.critical,
        domain.Priority.urgent: Priority.urgent,
      };

      for (final entry in cases.entries) {
        test('${entry.key} -> ${entry.value} -> ${entry.key}', () {
          final item = makeItem(priority: entry.key);
          final model = mapper.toModel(item);
          expect(model.priority, entry.value);
          final roundTrip = mapper.toDomain(model);
          expect(roundTrip.priority, entry.key);
        });
      }
    });

    group('SizeCategory mapping covers all 4 values', () {
      final cases = {
        domain.SizeCategory.big: SizeCategory.big,
        domain.SizeCategory.medium: SizeCategory.medium,
        domain.SizeCategory.small: SizeCategory.small,
        domain.SizeCategory.none: SizeCategory.none,
      };

      for (final entry in cases.entries) {
        test('${entry.key} -> ${entry.value} -> ${entry.key}', () {
          final item = makeItem(sizeCategory: entry.key);
          final model = mapper.toModel(item);
          expect(model.sizeCategory, entry.value);
          final roundTrip = mapper.toDomain(model);
          expect(roundTrip.sizeCategory, entry.key);
        });
      }
    });
  });
}
