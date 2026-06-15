import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockRecurrenceEngine extends Mock implements RecurrenceEngine {}

class FakeItem extends Fake implements Item {}

Item makeItem({required int id, String title = 'Task'}) {
  final now = DateTime(2026);
  return Item(
    id: id,
    type: ItemType.task,
    title: title,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockItemRepository repository;
  late MockRecurrenceEngine recurrenceEngine;

  setUpAll(() {
    registerFallbackValue(FakeItem());
    registerFallbackValue(TaskListFilter.empty);
  });

  setUp(() {
    repository = MockItemRepository();
    recurrenceEngine = MockRecurrenceEngine();
    when(() => repository.watchChanges())
        .thenAnswer((_) => const Stream.empty());
    when(
      () => repository.filterItems(
        type: any(named: 'type'),
        quadrant: any(named: 'quadrant'),
        gtdContext: any(named: 'gtdContext'),
        dueDateFrom: any(named: 'dueDateFrom'),
        dueDateTo: any(named: 'dueDateTo'),
        parentId: any(named: 'parentId'),
        showCompleted: any(named: 'showCompleted'),
      ),
    ).thenAnswer((_) async => const Success<List<Item>>([]));
  });

  group('TaskListCubit', () {
    test('initial state is TaskListInitial', () async {
      final cubit = TaskListCubit(repository, recurrenceEngine);
      expect(cubit.state, const TaskListInitial());
      await cubit.close();
    });

    blocTest<TaskListCubit, TaskListState>(
      'start() emits TaskListLoaded with items from repository',
      build: () {
        final items = [makeItem(id: 1), makeItem(id: 2)];
        when(
          () => repository.filterItems(
            type: any(named: 'type'),
            quadrant: any(named: 'quadrant'),
            gtdContext: any(named: 'gtdContext'),
            dueDateFrom: any(named: 'dueDateFrom'),
            dueDateTo: any(named: 'dueDateTo'),
            parentId: any(named: 'parentId'),
            showCompleted: any(named: 'showCompleted'),
          ),
        ).thenAnswer((_) async => Success<List<Item>>(items));
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<TaskListLoaded>().having(
          (s) => s.items.length,
          'items.length',
          2,
        ),
      ],
    );

    blocTest<TaskListCubit, TaskListState>(
      'search() calls repository.searchByTitle with query',
      build: () {
        when(() => repository.searchByTitle(any()))
            .thenAnswer((_) async => const Success<List<Item>>([]));
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.search('meeting');
      },
      verify: (_) {
        verify(() => repository.searchByTitle('meeting')).called(1);
      },
    );

    blocTest<TaskListCubit, TaskListState>(
      'applyFilter() calls repository.filterItems with correct params',
      build: () => TaskListCubit(repository, recurrenceEngine),
      act: (cubit) async {
        await cubit.start();
        await cubit.applyFilter(
          const TaskListFilter(itemType: ItemType.task),
        );
      },
      verify: (_) {
        verify(
          () => repository.filterItems(
            type: ItemType.task,
            quadrant: any(named: 'quadrant'),
            gtdContext: any(named: 'gtdContext'),
            dueDateFrom: any(named: 'dueDateFrom'),
            dueDateTo: any(named: 'dueDateTo'),
            parentId: any(named: 'parentId'),
            showCompleted: any(named: 'showCompleted'),
          ),
        ).called(1);
      },
    );

    blocTest<TaskListCubit, TaskListState>(
      'softDelete() emits TaskListWithPendingUndo with deletedItemId',
      build: () {
        final items = [makeItem(id: 1), makeItem(id: 2)];
        when(
          () => repository.filterItems(
            type: any(named: 'type'),
            quadrant: any(named: 'quadrant'),
            gtdContext: any(named: 'gtdContext'),
            dueDateFrom: any(named: 'dueDateFrom'),
            dueDateTo: any(named: 'dueDateTo'),
            parentId: any(named: 'parentId'),
            showCompleted: any(named: 'showCompleted'),
          ),
        ).thenAnswer((_) async => Success<List<Item>>(items));
        when(() => repository.softDelete(any()))
            .thenAnswer((_) async => Success<Item>(makeItem(id: 1)));
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.softDelete(1);
      },
      expect: () => [
        isA<TaskListLoaded>(),
        isA<TaskListWithPendingUndo>()
            .having((s) => s.deletedItemId, 'deletedItemId', 1)
            .having((s) => s.items.length, 'items.length', 1),
      ],
    );

    blocTest<TaskListCubit, TaskListState>(
      'restoreItem() calls repository.restoreItem and emits TaskListLoaded',
      build: () {
        when(() => repository.softDelete(any()))
            .thenAnswer((_) async => Success<Item>(makeItem(id: 1)));
        when(() => repository.restoreItem(any()))
            .thenAnswer((_) async => Success<Item>(makeItem(id: 1)));
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.softDelete(1);
        await cubit.restoreItem(1);
      },
      verify: (_) {
        verify(() => repository.restoreItem(1)).called(1);
      },
      expect: () => [
        isA<TaskListLoaded>(),
        isA<TaskListWithPendingUndo>(),
        isA<TaskListLoaded>(),
      ],
    );

    blocTest<TaskListCubit, TaskListState>(
      'completeItem() calls repository.updateItem with isCompleted == true',
      build: () {
        when(() => repository.updateItem(any()))
            .thenAnswer((_) async => Success<Item>(makeItem(id: 1)));
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.completeItem(makeItem(id: 1));
      },
      verify: (_) {
        final captured =
            verify(() => repository.updateItem(captureAny())).captured;
        final updatedItem = captured.last as Item;
        expect(updatedItem.isCompleted, isTrue);
      },
    );

    blocTest<TaskListCubit, TaskListState>(
      'repository returning Err emits TaskListError',
      build: () {
        when(
          () => repository.filterItems(
            type: any(named: 'type'),
            quadrant: any(named: 'quadrant'),
            gtdContext: any(named: 'gtdContext'),
            dueDateFrom: any(named: 'dueDateFrom'),
            dueDateTo: any(named: 'dueDateTo'),
            parentId: any(named: 'parentId'),
            showCompleted: any(named: 'showCompleted'),
          ),
        ).thenAnswer(
          (_) async => const Err<List<Item>>(DatabaseFailure('db error')),
        );
        return TaskListCubit(repository, recurrenceEngine);
      },
      act: (cubit) => cubit.start(),
      expect: () => [isA<TaskListError>()],
    );

    // WR-01 regression: create/update must report their own outcome via the
    // returned bool, not via post-await state. Success emits nothing here (the
    // watchChanges() stream drives the reload), so callers cannot infer success
    // from state — a stale TaskListError would otherwise read as a failure.
    test('createItem returns true and emits nothing on success', () async {
      final item = makeItem(id: 1);
      when(() => repository.createItem(any()))
          .thenAnswer((_) async => Success(item));
      final cubit = TaskListCubit(repository, recurrenceEngine);
      final emissions = <TaskListState>[];
      final sub = cubit.stream.listen(emissions.add);

      final result = await cubit.createItem(item);

      expect(result, isTrue);
      expect(emissions, isEmpty);
      await sub.cancel();
      await cubit.close();
    });

    test('createItem returns false and emits TaskListError on failure',
        () async {
      when(() => repository.createItem(any())).thenAnswer(
        (_) async => const Err<Item>(DatabaseFailure('db error')),
      );
      final cubit = TaskListCubit(repository, recurrenceEngine);

      final result = await cubit.createItem(makeItem(id: 1));

      expect(result, isFalse);
      expect(cubit.state, isA<TaskListError>());
      await cubit.close();
    });

    test('updateItem returns true and emits nothing on success', () async {
      final item = makeItem(id: 1);
      when(() => repository.updateItem(any()))
          .thenAnswer((_) async => Success(item));
      final cubit = TaskListCubit(repository, recurrenceEngine);
      final emissions = <TaskListState>[];
      final sub = cubit.stream.listen(emissions.add);

      final result = await cubit.updateItem(item);

      expect(result, isTrue);
      expect(emissions, isEmpty);
      await sub.cancel();
      await cubit.close();
    });

    test('updateItem returns false and emits TaskListError on failure',
        () async {
      when(() => repository.updateItem(any())).thenAnswer(
        (_) async => const Err<Item>(DatabaseFailure('db error')),
      );
      final cubit = TaskListCubit(repository, recurrenceEngine);

      final result = await cubit.updateItem(makeItem(id: 1));

      expect(result, isFalse);
      expect(cubit.state, isA<TaskListError>());
      await cubit.close();
    });
  });
}
