import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
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

Item _makeItem(int id, {String title = 'Task'}) => Item(
      id: id,
      type: ItemType.task,
      title: title,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildTestWidget(TaskListCubit cubit) {
  return MaterialApp(
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
        const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          const TaskListLoaded(items: [], filter: TaskListFilter.empty),
        ]),
        initialState:
            const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // Empty state text "No tasks" from l10n.noTasks
      expect(find.text('No tasks'), findsOneWidget);
    });

    testWidgets('shows TaskCard when TaskListLoaded with one item',
        (tester) async {
      final item = _makeItem(1, title: 'Buy groceries');
      when(() => cubit.state).thenReturn(
        TaskListLoaded(items: [item], filter: TaskListFilter.empty),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item], filter: TaskListFilter.empty),
        ]),
        initialState:
            TaskListLoaded(items: [item], filter: TaskListFilter.empty),
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
        TaskListLoaded(items: [item], filter: TaskListFilter.empty),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item], filter: TaskListFilter.empty),
          const TaskListWithPendingUndo(
            deletedItemId: 1,
            items: [],
            filter: TaskListFilter.empty,
          ),
        ]),
        initialState:
            TaskListLoaded(items: [item], filter: TaskListFilter.empty),
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
        TaskListLoaded(items: [item], filter: TaskListFilter.empty),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [item], filter: TaskListFilter.empty),
        ]),
        initialState:
            TaskListLoaded(items: [item], filter: TaskListFilter.empty),
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
