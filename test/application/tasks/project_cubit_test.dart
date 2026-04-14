import 'package:agenda/application/tasks/project/project_cubit.dart';
import 'package:agenda/application/tasks/project/project_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class FakeItem extends Fake implements Item {}

Item makeProject({int id = 10}) {
  final now = DateTime(2026);
  return Item(
    id: id,
    type: ItemType.project,
    title: 'Project',
    createdAt: now,
    updatedAt: now,
  );
}

Item makeSubtask({int id = 1, int parentId = 10, bool completed = false}) {
  final now = DateTime(2026);
  return Item(
    id: id,
    type: ItemType.subtask,
    title: 'Subtask $id',
    parentId: parentId,
    isCompleted: completed,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockItemRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeItem());
  });

  setUp(() {
    repository = MockItemRepository();
  });

  group('ProjectCubit', () {
    test('initial state is ProjectInitial', () {
      expect(
        ProjectCubit(repository).state,
        const ProjectInitial(),
      );
    });

    blocTest<ProjectCubit, ProjectState>(
      'loadProject() emits ProjectLoaded with correct subtask list and rollup',
      build: () {
        final project = makeProject();
        final subtasks = [
          makeSubtask(completed: true),
          makeSubtask(id: 2),
        ];
        when(() => repository.getItem(10))
            .thenAnswer((_) async => Success<Item>(project));
        when(() => repository.getSubtaskCounts(10))
            .thenAnswer((_) async => const Success<(int, int)>((1, 2)));
        when(() => repository.getSubtasks(10))
            .thenAnswer((_) async => Success<List<Item>>(subtasks));
        return ProjectCubit(repository);
      },
      act: (cubit) => cubit.loadProject(10),
      expect: () => [
        const ProjectLoading(),
        isA<ProjectLoaded>()
            .having((s) => s.subtasks.length, 'subtasks.length', 2)
            .having((s) => s.completedCount, 'completedCount', 1)
            .having((s) => s.totalCount, 'totalCount', 2),
      ],
    );

    blocTest<ProjectCubit, ProjectState>(
      'addSubtask() creates item with ItemType.subtask and correct parentId',
      build: () {
        final project = makeProject();
        when(() => repository.getItem(10))
            .thenAnswer((_) async => Success<Item>(project));
        when(() => repository.getSubtaskCounts(10))
            .thenAnswer((_) async => const Success<(int, int)>((0, 0)));
        when(() => repository.getSubtasks(10))
            .thenAnswer((_) async => Success<List<Item>>([]));
        when(() => repository.createItem(any()))
            .thenAnswer((_) async => Success<Item>(makeSubtask()));
        return ProjectCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProject(10);
        await cubit.addSubtask(projectId: 10, title: 'New subtask');
      },
      verify: (_) {
        final captured =
            verify(() => repository.createItem(captureAny())).captured;
        final created = captured.last as Item;
        expect(created.type, ItemType.subtask);
        expect(created.parentId, 10);
      },
    );

    blocTest<ProjectCubit, ProjectState>(
      'completeSubtask() emits ProjectLoaded with updated completedCount',
      build: () {
        final project = makeProject();
        final subtask = makeSubtask();
        when(() => repository.getItem(10))
            .thenAnswer((_) async => Success<Item>(project));
        when(() => repository.getSubtaskCounts(10))
            .thenAnswerMany([
          (_) async => const Success<(int, int)>((0, 1)),
          (_) async => const Success<(int, int)>((1, 1)),
        ]);
        when(() => repository.getSubtasks(10))
            .thenAnswer((_) async => Success<List<Item>>([subtask]));
        when(() => repository.updateItem(any()))
            .thenAnswer((_) async => Success<Item>(subtask));
        return ProjectCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProject(10);
        await cubit.completeSubtask(makeSubtask());
      },
      expect: () => [
        const ProjectLoading(),
        isA<ProjectLoaded>().having(
          (s) => s.completedCount,
          'completedCount',
          0,
        ),
        isA<ProjectLoaded>().having(
          (s) => s.completedCount,
          'completedCount',
          1,
        ),
      ],
    );

    blocTest<ProjectCubit, ProjectState>(
      'deleteSubtask() calls repository.softDelete and refreshes rollup',
      build: () {
        final project = makeProject();
        when(() => repository.getItem(10))
            .thenAnswer((_) async => Success<Item>(project));
        when(() => repository.getSubtaskCounts(10))
            .thenAnswer((_) async => const Success<(int, int)>((0, 0)));
        when(() => repository.getSubtasks(10))
            .thenAnswer((_) async => Success<List<Item>>([]));
        when(() => repository.softDelete(any()))
            .thenAnswer((_) async => Success<Item>(makeSubtask()));
        return ProjectCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProject(10);
        await cubit.deleteSubtask(1);
      },
      verify: (_) {
        verify(() => repository.softDelete(1)).called(1);
        verify(() => repository.getSubtaskCounts(10)).called(greaterThan(1));
      },
    );
  });
}

// Extension to allow multiple sequential answers in a single when().thenAnswer
extension _WhenMultiple<T> on When<T> {
  void thenAnswerMany(List<Answer<T>> answers) {
    var index = 0;
    thenAnswer((invocation) {
      final answer = answers[index < answers.length ? index++ : index - 1];
      return answer(invocation);
    });
  }
}
