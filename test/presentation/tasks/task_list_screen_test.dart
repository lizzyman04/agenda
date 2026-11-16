import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

// TaskFormScreen (pushed by the empty-state CTA) resolves these via getIt.
class MockGoalRepository extends Mock implements GoalRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

/// Records every route pushed so a test can assert navigation happened.
class _RecordingObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

Item _makeItem(int id, {String title = 'Task'}) => Item(
      id: id,
      type: ItemType.task,
      title: title,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildTestWidget(
  TaskListCubit cubit, {
  List<NavigatorObserver> observers = const [],
}) {
  return MaterialApp(
    navigatorObservers: observers,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: const TaskListScreen(),
    ),
  );
}

void main() {
  group('TaskListScreen', () {
    late MockTaskListCubit cubit;

    setUp(() {
      cubit = MockTaskListCubit();
      // start() is called in initState — suppress it with a no-op stub
      when(() => cubit.start()).thenAnswer((_) async {});
    });

    testWidgets('shows empty state when TaskListLoaded with no items',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const TaskListLoaded(items: []),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          const TaskListLoaded(items: []),
        ]),
        initialState:
            const TaskListLoaded(items: []),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // Empty state text "No tasks" from l10n.noTasks
      expect(find.text('No tasks'), findsOneWidget);
    });

    testWidgets('empty state shows the body and an "Add task" CTA',
        (tester) async {
      when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([const TaskListLoaded(items: [])]),
        initialState: const TaskListLoaded(items: []),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(find.text('Add your first task or project.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add task'), findsOneWidget);
    });

    testWidgets('tapping the empty-state CTA pushes the create route',
        (tester) async {
      final goalRepo = MockGoalRepository();
      final debtRepo = MockDebtRepository();
      when(goalRepo.getActiveGoals)
          .thenAnswer((_) async => const Success(<SavingsGoal>[]));
      when(debtRepo.getDebts).thenAnswer((_) async => const Success(<Debt>[]));
      getIt
        ..registerSingleton<GoalRepository>(goalRepo)
        ..registerSingleton<DebtRepository>(debtRepo);
      addTearDown(getIt.reset);

      when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([const TaskListLoaded(items: [])]),
        initialState: const TaskListLoaded(items: []),
      );
      final observer = _RecordingObserver();

      await tester.pumpWidget(
        _buildTestWidget(cubit, observers: [observer]),
      );
      await tester.pump();
      final before = observer.pushed.length;

      await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
      await tester.pumpAndSettle();

      expect(observer.pushed.length, before + 1);
    });

    testWidgets('shows TaskCard when TaskListLoaded with one item',
        (tester) async {
      final item = _makeItem(1, title: 'Buy groceries');
      when(() => cubit.state).thenReturn(
        TaskListLoaded(items: [item]),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item]),
        ]),
        initialState:
            TaskListLoaded(items: [item]),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('shows SnackBar when state is TaskListWithPendingUndo',
        (tester) async {
      final item = _makeItem(1, title: 'Buy groceries');

      // Start in Loaded, then transition to PendingUndo to fire the listener
      when(() => cubit.state).thenReturn(
        TaskListLoaded(items: [item]),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item]),
          const TaskListWithPendingUndo(
            deletedItemId: 1,
            items: [],
          ),
        ]),
        initialState:
            TaskListLoaded(items: [item]),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump(); // process stream

      // SnackBar with "Task deleted" text
      expect(find.text('Task deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('tapping delete on TaskCard calls cubit.softDelete',
        (tester) async {
      final item = _makeItem(42, title: 'Delete me');
      when(() => cubit.state).thenReturn(
        TaskListLoaded(items: [item]),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item]),
        ]),
        initialState:
            TaskListLoaded(items: [item]),
      );
      when(() => cubit.softDelete(42)).thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // TaskCard renders a delete icon button
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pump();

      verify(() => cubit.softDelete(42)).called(1);
    });
  });
}
