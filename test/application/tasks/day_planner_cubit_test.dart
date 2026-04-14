import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('DayPlannerCubit', () {
    test('initial state has null bigTask, empty lists, no warning', () async {
      final cubit = DayPlannerCubit();
      expect(cubit.state.bigTask, isNull);
      expect(cubit.state.mediumTasks, isEmpty);
      expect(cubit.state.smallTasks, isEmpty);
      expect(cubit.state.slotLimitWarning, isFalse);
      await cubit.close();
    });

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignBig() sets bigTask to the given item',
      build: DayPlannerCubit.new,
      act: (cubit) => cubit.assignBig(makeItem(id: 1, title: 'Big')),
      expect: () => [
        isA<DayPlannerState>()
            .having((s) => s.bigTask?.id, 'bigTask.id', 1)
            .having((s) => s.slotLimitWarning, 'slotLimitWarning', false),
      ],
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignBig() when slot already full sets slotLimitWarning true',
      build: DayPlannerCubit.new,
      act: (cubit) {
        cubit
          ..assignBig(makeItem(id: 1, title: 'First'))
          ..assignBig(makeItem(id: 2, title: 'Second'));
      },
      expect: () => [
        isA<DayPlannerState>()
            .having((s) => s.bigTask?.id, 'bigTask.id', 1)
            .having((s) => s.slotLimitWarning, 'slotLimitWarning', false),
        isA<DayPlannerState>()
            .having((s) => s.bigTask?.id, 'bigTask.id', 2)
            .having((s) => s.slotLimitWarning, 'slotLimitWarning', true),
      ],
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignMedium() x3 fills the medium slot with 3 items',
      build: DayPlannerCubit.new,
      act: (cubit) {
        for (var i = 1; i <= AppConstants.rule135MediumTasks; i++) {
          cubit.assignMedium(makeItem(id: i));
        }
      },
      verify: (cubit) {
        expect(
          cubit.state.mediumTasks.length,
          AppConstants.rule135MediumTasks,
        );
        expect(cubit.state.areMediumSlotsFull, isTrue);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignMedium() x4 adds 4th item and sets slotLimitWarning true',
      build: DayPlannerCubit.new,
      act: (cubit) {
        for (var i = 1; i <= AppConstants.rule135MediumTasks + 1; i++) {
          cubit.assignMedium(makeItem(id: i));
        }
      },
      verify: (cubit) {
        expect(
          cubit.state.mediumTasks.length,
          AppConstants.rule135MediumTasks + 1,
        );
        expect(cubit.state.slotLimitWarning, isTrue);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignSmall() x5 fills the small slot with 5 items',
      build: DayPlannerCubit.new,
      act: (cubit) {
        for (var i = 1; i <= AppConstants.rule135SmallTasks; i++) {
          cubit.assignSmall(makeItem(id: i));
        }
      },
      verify: (cubit) {
        expect(
          cubit.state.smallTasks.length,
          AppConstants.rule135SmallTasks,
        );
        expect(cubit.state.areSmallSlotsFull, isTrue);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'assignSmall() x6 adds 6th item and sets slotLimitWarning true',
      build: DayPlannerCubit.new,
      act: (cubit) {
        for (var i = 1; i <= AppConstants.rule135SmallTasks + 1; i++) {
          cubit.assignSmall(makeItem(id: i));
        }
      },
      verify: (cubit) {
        expect(
          cubit.state.smallTasks.length,
          AppConstants.rule135SmallTasks + 1,
        );
        expect(cubit.state.slotLimitWarning, isTrue);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'remove() removes item from medium slot by id',
      build: DayPlannerCubit.new,
      act: (cubit) {
        cubit
          ..assignMedium(makeItem(id: 1))
          ..assignMedium(makeItem(id: 2))
          ..remove(1);
      },
      verify: (cubit) {
        expect(cubit.state.mediumTasks.length, 1);
        expect(cubit.state.mediumTasks.first.id, 2);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'remove() removes big task when it matches the id',
      build: DayPlannerCubit.new,
      act: (cubit) {
        cubit
          ..assignBig(makeItem(id: 99))
          ..remove(99);
      },
      verify: (cubit) {
        expect(cubit.state.bigTask, isNull);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'remove() removes item from small slot by id',
      build: DayPlannerCubit.new,
      act: (cubit) {
        cubit
          ..assignSmall(makeItem(id: 3))
          ..assignSmall(makeItem(id: 4))
          ..remove(3);
      },
      verify: (cubit) {
        expect(cubit.state.smallTasks.length, 1);
        expect(cubit.state.smallTasks.first.id, 4);
      },
    );

    blocTest<DayPlannerCubit, DayPlannerState>(
      'clearAll() resets to initial state',
      build: DayPlannerCubit.new,
      act: (cubit) {
        cubit
          ..assignBig(makeItem(id: 1))
          ..assignMedium(makeItem(id: 2))
          ..assignSmall(makeItem(id: 3))
          ..clearAll();
      },
      verify: (cubit) {
        expect(cubit.state.bigTask, isNull);
        expect(cubit.state.mediumTasks, isEmpty);
        expect(cubit.state.smallTasks, isEmpty);
        expect(cubit.state.slotLimitWarning, isFalse);
      },
    );

    test('isBigSlotFull is true when bigTask is assigned', () async {
      final cubit = DayPlannerCubit();
      expect(cubit.state.isBigSlotFull, isFalse);
      cubit.assignBig(makeItem(id: 1));
      expect(cubit.state.isBigSlotFull, isTrue);
      await cubit.close();
    });

    test(
      'areMediumSlotsFull is true when mediumTasks.length == '
      'AppConstants.rule135MediumTasks',
      () async {
        final cubit = DayPlannerCubit();
        for (var i = 1; i <= AppConstants.rule135MediumTasks; i++) {
          cubit.assignMedium(makeItem(id: i));
        }
        expect(cubit.state.areMediumSlotsFull, isTrue);
        await cubit.close();
      },
    );

    test(
      'areSmallSlotsFull is true when smallTasks.length == '
      'AppConstants.rule135SmallTasks',
      () async {
        final cubit = DayPlannerCubit();
        for (var i = 1; i <= AppConstants.rule135SmallTasks; i++) {
          cubit.assignSmall(makeItem(id: i));
        }
        expect(cubit.state.areSmallSlotsFull, isTrue);
        await cubit.close();
      },
    );
  });
}
