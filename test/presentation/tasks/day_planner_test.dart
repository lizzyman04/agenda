import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/day_planner_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDayPlannerCubit extends MockCubit<DayPlannerState>
    implements DayPlannerCubit {}

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

Widget _buildTestWidget(
  DayPlannerCubit plannerCubit,
  TaskListCubit taskListCubit,
) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<DayPlannerCubit>.value(value: plannerCubit),
        BlocProvider<TaskListCubit>.value(value: taskListCubit),
      ],
      child: const DayPlannerScreen(),
    ),
  );
}

void main() {
  group('DayPlannerScreen', () {
    late MockDayPlannerCubit plannerCubit;
    late MockTaskListCubit taskListCubit;

    setUp(() {
      plannerCubit = MockDayPlannerCubit();
      taskListCubit = MockTaskListCubit();

      // TaskListCubit is read via context.watch — needs a stable state
      when(() => taskListCubit.state).thenReturn(
        const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );
      whenListen(
        taskListCubit,
        Stream<TaskListState>.fromIterable([
          const TaskListLoaded(items: [], filter: TaskListFilter.empty),
        ]),
        initialState:
            const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );
    });

    testWidgets('renders three slot sections (big, medium, small)',
        (tester) async {
      when(() => plannerCubit.state).thenReturn(const DayPlannerState());
      whenListen(
        plannerCubit,
        Stream<DayPlannerState>.fromIterable([const DayPlannerState()]),
        initialState: const DayPlannerState(),
      );

      await tester.pumpWidget(_buildTestWidget(plannerCubit, taskListCubit));
      await tester.pump();

      // Slot section headers contain their labels from l10n
      expect(find.textContaining('1 Big Task'), findsOneWidget);
      expect(find.textContaining('3 Medium Tasks'), findsOneWidget);
      expect(find.textContaining('5 Small Tasks'), findsOneWidget);
    });

    testWidgets('warning banner visible when slotLimitWarning is true',
        (tester) async {
      const warningState = DayPlannerState(slotLimitWarning: true);
      when(() => plannerCubit.state).thenReturn(warningState);
      whenListen(
        plannerCubit,
        Stream<DayPlannerState>.fromIterable([warningState]),
        initialState: warningState,
      );

      await tester.pumpWidget(_buildTestWidget(plannerCubit, taskListCubit));
      await tester.pump();

      // Warning banner text from l10n.slotLimitWarning: "Slot limit exceeded"
      expect(find.text('Slot limit exceeded'), findsOneWidget);
    });

    testWidgets('warning banner absent when slotLimitWarning is false',
        (tester) async {
      when(() => plannerCubit.state).thenReturn(const DayPlannerState());
      whenListen(
        plannerCubit,
        Stream<DayPlannerState>.fromIterable([const DayPlannerState()]),
        initialState: const DayPlannerState(),
      );

      await tester.pumpWidget(_buildTestWidget(plannerCubit, taskListCubit));
      await tester.pump();

      expect(find.text('Slot limit exceeded'), findsNothing);
    });
  });
}
