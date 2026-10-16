// Behavioral regression coverage for the reminder-planning item reads
// (plan 04-09, Research Pitfall 2).
//
// Every list query on `ItemDao` applies `.limit(500)` with no `sortBy`. Isar
// returns unsorted rows in id order, so that cap keeps the OLDEST 500 rows and
// silently drops the rest (the BL-01 / CR-04 class). A reminder read built on
// it would plan notifications for the lowest ids rather than the soonest due
// dates. These tests run against a real Isar collection (via
// `IsarTestHarness`), with ids deliberately in the OPPOSITE order of due
// dates, so an id-ordered cap returns visibly wrong rows. Only `IsarService`
// (a thin wrapper whose `db` getter the DAO calls) is mocked.

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_dao.dart';
import 'package:agenda/data/tasks/item_mapper.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:agenda/infrastructure/tasks/item_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

class MockItemDao extends Mock implements ItemDao {}

class MockRecurrenceEngine extends Mock implements RecurrenceEngine {}

final DateTime _day0 = DateTime(2026, 3);

ItemModel _item(
  int id, {
  DateTime? dueDate,
  ItemType type = ItemType.task,
  bool isCompleted = false,
  DateTime? deletedAt,
}) =>
    ItemModel()
      ..id = id
      ..type = type
      ..title = 'item $id'
      ..dueDate = dueDate
      ..isCompleted = isCompleted
      ..deletedAt = deletedAt
      ..createdAt = _day0
      ..updatedAt = _day0;

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late MockIsarService mockIsarService;
  late ItemDao dao;

  setUpAll(() => registerFallbackValue(_day0));

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open([ItemModelSchema]);
    mockIsarService = MockIsarService();
    when(() => mockIsarService.db).thenReturn(isar);
    dao = ItemDao(mockIsarService);
  });

  tearDown(() async {
    await harness.close();
  });

  group('findRemindable sorts by due date BEFORE it limits', () {
    test('700 open tasks: returns the 60 EARLIEST due, not the 60 lowest ids',
        () async {
      // id 1 is due LATEST (hour 700), id 700 is due earliest (hour 1).
      final open = [
        for (var id = 1; id <= 700; id++)
          _item(
            id,
            // One subtask among them: subtasks are remindable too.
            type: id == 700 ? ItemType.subtask : ItemType.task,
            dueDate: _day0.add(Duration(hours: 701 - id)),
          ),
      ];
      // A task due exactly at `from` is included (hour 0, the very soonest).
      final atFrom = _item(800, dueDate: _day0);
      // Everything below must be excluded even though it is due very soon.
      final excluded = [
        _item(801, dueDate: _day0, isCompleted: true),
        _item(802, dueDate: _day0, deletedAt: _day0),
        _item(803, dueDate: _day0, type: ItemType.project),
        _item(804),
        _item(805, dueDate: _day0.subtract(const Duration(seconds: 1))),
      ];
      await isar.writeTxn(
        () => isar.collection<ItemModel>().putAll([
          ...open,
          atFrom,
          ...excluded,
        ]),
      );

      final result = await dao.findRemindable(from: _day0, limit: 60);

      expect(result.length, 60);
      // 800 (hour 0) followed by ids 700 down to 642 (hours 1 to 59).
      expect(result.first.id, 800);
      expect(
        result.map((m) => m.id).toList(),
        [800, for (var id = 700; id >= 642; id--) id],
        reason: 'an id-ordered cap would return ids 1..60 (the LATEST due)',
      );
      final due = result.map((m) => m.dueDate!).toList();
      expect(
        [...due]..sort(),
        due,
        reason: 'result must be ascending by due date',
      );
      expect(
        result.map((m) => m.id),
        isNot(anyOf(contains(801), contains(802), contains(803))),
      );
      expect(result.map((m) => m.id), isNot(contains(804)));
      expect(result.map((m) => m.id), isNot(contains(805)));
      expect(
        result.any((m) => m.type == ItemType.subtask),
        isTrue,
        reason: 'subtask 700 is among the earliest and must be included',
      );
    });
  });

  group('findDueInWindow is uncapped', () {
    test('650 tasks in a 7-day window plus 50 outside: returns all 650',
        () async {
      final toExclusive = _day0.add(const Duration(days: 7));
      // Ids descend as due dates ascend, so id order differs from due order.
      final inside = [
        for (var i = 0; i < 650; i++)
          _item(1000 - i, dueDate: _day0.add(Duration(minutes: i * 15))),
      ];
      final outside = [
        for (var i = 0; i < 50; i++)
          _item(2000 + i, dueDate: toExclusive.add(Duration(hours: 24 + i))),
      ];
      final atBoundary = _item(3000, dueDate: toExclusive);
      final beforeWindow = _item(
        3001,
        dueDate: _day0.subtract(const Duration(minutes: 1)),
      );
      await isar.writeTxn(
        () => isar.collection<ItemModel>().putAll([
          ...inside,
          ...outside,
          atBoundary,
          beforeWindow,
        ]),
      );

      final result = await dao.findDueInWindow(
        from: _day0,
        toExclusive: toExclusive,
      );

      expect(
        result.length,
        650,
        reason: 'the window read must not be capped at 500 (BL-01 class)',
      );
      final due = result.map((m) => m.dueDate!).toList();
      expect([...due]..sort(), due, reason: 'ascending by due date');
      expect(result.map((m) => m.id), isNot(contains(3000)));
      expect(result.map((m) => m.id), isNot(contains(3001)));
      expect(
        result.every((m) => m.id <= 1000 && m.id > 350),
        isTrue,
        reason: 'only the 650 inside rows may appear',
      );
    });
  });

  group('ItemRepositoryImpl reminder reads', () {
    test('getRemindableItems returns Err(DatabaseFailure) when the DAO throws',
        () async {
      final mockDao = MockItemDao();
      when(
        () => mockDao.findRemindable(
          from: any(named: 'from'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('boom'));
      final repo = ItemRepositoryImpl(
        mockDao,
        const ItemMapper(),
        MockRecurrenceEngine(),
      );

      final result = await repo.getRemindableItems(from: _day0, limit: 60);

      expect(result, isA<Err<List<Item>>>());
      expect((result as Err).failure, isA<DatabaseFailure>());
    });

    test('getItemsDueInWindow returns Err(DatabaseFailure) when the DAO throws',
        () async {
      final mockDao = MockItemDao();
      when(
        () => mockDao.findDueInWindow(
          from: any(named: 'from'),
          toExclusive: any(named: 'toExclusive'),
        ),
      ).thenThrow(Exception('boom'));
      final repo = ItemRepositoryImpl(
        mockDao,
        const ItemMapper(),
        MockRecurrenceEngine(),
      );

      final result = await repo.getItemsDueInWindow(
        from: _day0,
        toExclusive: _day0.add(const Duration(days: 1)),
      );

      expect((result as Err).failure, isA<DatabaseFailure>());
    });

    test('getRemindableItems maps real rows to domain items', () async {
      await isar.writeTxn(
        () => isar.collection<ItemModel>().putAll([
          _item(1, dueDate: _day0.add(const Duration(hours: 2))),
          _item(2, dueDate: _day0.add(const Duration(hours: 1))),
        ]),
      );
      final repo = ItemRepositoryImpl(
        dao,
        const ItemMapper(),
        MockRecurrenceEngine(),
      );

      final result = await repo.getRemindableItems(from: _day0, limit: 10);

      expect(result, isA<Success<List<Item>>>());
      final items = (result as Success<List<Item>>).value;
      expect(items.map((i) => i.id).toList(), [2, 1]);
    });
  });
}
