import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/task_form_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

// Required so mocktail can register the Item fallback value
class FakeItem extends Fake implements Item {}

Widget _buildTestWidget(TaskListCubit cubit, {Item? item}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: TaskFormScreen(item: item),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItem());
  });

  group('TaskFormScreen', () {
    late MockTaskListCubit cubit;

    setUp(() {
      cubit = MockTaskListCubit();
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
    });

    testWidgets('title field is present', (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // Title field label from l10n.fieldTitle
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('submitting with empty title shows validation error',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // Tap the Save button with an empty title field
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Validation error from l10n.fieldTitleRequired
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('submitting with valid title calls cubit.createItem',
        (tester) async {
      when(() => cubit.createItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // Enter a valid title
      await tester.enterText(find.byType(TextFormField).first, 'My new task');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      // createItem should have been called once
      verify(() => cubit.createItem(any())).called(1);
    });
  });
}
