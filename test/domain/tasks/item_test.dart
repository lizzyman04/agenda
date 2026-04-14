import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final _now = DateTime(2026, 4, 14);

  Item _makeItem({
    int id = 0,
    ItemType type = ItemType.task,
    String title = 'Test item',
    bool isUrgent = false,
    bool isImportant = false,
    int? parentId,
  }) {
    return Item(
      id: id,
      type: type,
      title: title,
      createdAt: _now,
      updatedAt: _now,
      isUrgent: isUrgent,
      isImportant: isImportant,
      parentId: parentId,
    );
  }

  group('Item — default field values', () {
    late Item item;

    setUp(() {
      item = _makeItem();
    });

    test('priority defaults to Priority.medium', () {
      expect(item.priority, Priority.medium);
    });

    test('isUrgent defaults to false', () {
      expect(item.isUrgent, isFalse);
    });

    test('isImportant defaults to false', () {
      expect(item.isImportant, isFalse);
    });

    test('sizeCategory defaults to SizeCategory.none', () {
      expect(item.sizeCategory, SizeCategory.none);
    });

    test('isNextAction defaults to false', () {
      expect(item.isNextAction, isFalse);
    });

    test('isCompleted defaults to false', () {
      expect(item.isCompleted, isFalse);
    });

    test('deletedAt is nullable and defaults to null', () {
      expect(item.deletedAt, isNull);
    });

    test('linkedGoalId is null in a freshly created item', () {
      expect(item.linkedGoalId, isNull);
    });

    test('linkedDebtId is null in a freshly created item', () {
      expect(item.linkedDebtId, isNull);
    });
  });

  group('Item — EisenhowerQuadrant getter', () {
    test('returns doNow when isUrgent=true, isImportant=true', () {
      final item = _makeItem(isUrgent: true, isImportant: true);
      expect(item.eisenhowerQuadrant, EisenhowerQuadrant.doNow);
    });

    test('returns schedule when isUrgent=false, isImportant=true', () {
      final item = _makeItem(isUrgent: false, isImportant: true);
      expect(item.eisenhowerQuadrant, EisenhowerQuadrant.schedule);
    });

    test('returns delegate when isUrgent=true, isImportant=false', () {
      final item = _makeItem(isUrgent: true, isImportant: false);
      expect(item.eisenhowerQuadrant, EisenhowerQuadrant.delegate);
    });

    test('returns eliminate when isUrgent=false, isImportant=false', () {
      final item = _makeItem(isUrgent: false, isImportant: false);
      expect(item.eisenhowerQuadrant, EisenhowerQuadrant.eliminate);
    });
  });

  group('Item — subtask with parentId', () {
    test('ItemType.subtask with non-null parentId is valid', () {
      final subtask = _makeItem(
        type: ItemType.subtask,
        parentId: 42,
      );
      expect(subtask.type, ItemType.subtask);
      expect(subtask.parentId, 42);
    });
  });
}
