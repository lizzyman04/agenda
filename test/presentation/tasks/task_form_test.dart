import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
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

// Finance-link repositories the TaskFormScreen resolves via getIt in initState
// (added in phase 03). The form only reads active goals/debts, so empty stubs
// are sufficient for these task-form tests.
class MockGoalRepository extends Mock implements GoalRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

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
    late MockGoalRepository goalRepo;
    late MockDebtRepository debtRepo;

    setUp(() {
      cubit = MockTaskListCubit();
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

      // TaskFormScreen.initState resolves these via getIt to load finance
      // links; stub them to empty so the widget mounts without a real DI graph.
      goalRepo = MockGoalRepository();
      debtRepo = MockDebtRepository();
      when(goalRepo.getActiveGoals)
          .thenAnswer((_) async => const Success(<SavingsGoal>[]));
      when(debtRepo.getDebts)
          .thenAnswer((_) async => const Success(<Debt>[]));
      getIt
        ..registerSingleton<GoalRepository>(goalRepo)
        ..registerSingleton<DebtRepository>(debtRepo);
    });

    tearDown(() async {
      await getIt.reset();
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
