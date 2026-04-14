import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/eisenhower_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

Item _makeItem(
  int id, {
  String title = 'Task',
  bool isUrgent = false,
  bool isImportant = false,
}) =>
    Item(
      id: id,
      type: ItemType.task,
      title: title,
      isUrgent: isUrgent,
      isImportant: isImportant,
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
      child: const EisenhowerScreen(),
    ),
  );
}

void main() {
  group('EisenhowerScreen', () {
    late MockTaskListCubit cubit;

    setUp(() {
      cubit = MockTaskListCubit();
    });

    testWidgets('renders all four quadrant sections', (tester) async {
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

      // Quadrant labels from l10n (EN): Do Now, Schedule, Delegate, Eliminate
      expect(find.text('Do Now'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Delegate'), findsOneWidget);
      expect(find.text('Eliminate'), findsOneWidget);
    });

    testWidgets(
        'task with isUrgent=true and isImportant=true appears in Do Now section',
        (tester) async {
      final urgentImportant = _makeItem(
        1,
        title: 'Fix production bug',
        isUrgent: true,
        isImportant: true,
      );

      when(() => cubit.state).thenReturn(
        TaskListLoaded(
          items: [urgentImportant],
          filter: TaskListFilter.empty,
        ),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(
            items: [urgentImportant],
            filter: TaskListFilter.empty,
          ),
        ]),
        initialState: TaskListLoaded(
          items: [urgentImportant],
          filter: TaskListFilter.empty,
        ),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // The task title should appear inside the Do Now quadrant card
      expect(find.text('Fix production bug'), findsOneWidget);
    });
  });
}
