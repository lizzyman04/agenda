import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/task_detail_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

// TaskDetailFinanceChip resolves these two via getIt in initState to name the
// linked goal/debt instead of showing its raw id, so every test that mounts
// TaskDetailScreen must have them registered.
class MockGoalRepository extends Mock implements GoalRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

Widget _buildTestWidget(TaskListCubit cubit, Item item) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: TaskDetailScreen(item: item),
    ),
  );
}

/// Same as [_buildTestWidget], but pushes the detail screen onto a real
/// back stack so `Navigator.of(context).pop()` (called after a confirmed
/// delete) has somewhere to go, mirroring how the screen is reached from
/// the task list in production.
Widget _buildPushedTestWidget(TaskListCubit cubit, Item item) {
  return BlocProvider<TaskListCubit>.value(
    value: cubit,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskDetailScreen(item: item),
                ),
              ),
              child: const Text('open detail'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TaskDetailScreen', () {
    late MockTaskListCubit cubit;
    late MockGoalRepository goalRepo;
    late MockDebtRepository debtRepo;

    setUp(() {
      cubit = MockTaskListCubit();
      when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
      whenListen(
        cubit,
        const Stream<TaskListState>.empty(),
        initialState: const TaskListLoaded(items: []),
      );

      // TaskDetailFinanceChip.initState resolves these via getIt to name the
      // linked goal/debt; default them to empty so the widget mounts without a
      // real DI graph. Tests that need a real entity re-stub them.
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

    testWidgets(
        'renders hero card and all conditional sections when every field '
        'is populated', (tester) async {
      final item = Item(
        id: 1,
        type: ItemType.task,
        title: 'Plan the trip',
        description: 'Book flights and hotel',
        priority: Priority.urgent,
        sizeCategory: SizeCategory.medium,
        isUrgent: true,
        isImportant: true,
        isNextAction: true,
        gtdContext: '@home',
        waitingFor: 'Travel agent',
        dueDate: DateTime(2026, 9),
        dueTimeMinutes: 9 * 60,
        recurrenceRule: 'FREQ=WEEKLY',
        linkedGoalId: 7,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(_buildTestWidget(cubit, item));
      await tester.pump();

      // Hero card: title + description
      expect(find.text('Plan the trip'), findsOneWidget);
      expect(find.text('Book flights and hotel'), findsOneWidget);

      // Dates card
      expect(find.text('Dates'), findsOneWidget);

      // Flags card
      expect(find.text('Flags'), findsOneWidget);

      // GTD card
      expect(find.text('GTD'), findsOneWidget);
      expect(find.text('@home'), findsOneWidget);
      expect(find.text('Travel agent'), findsOneWidget);

      // Finance-link chip
      expect(find.byIcon(Icons.link), findsOneWidget);

      // Action bar
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets(
        'hides all conditional sections when the task carries no '
        'date/flag/gtd/finance data', (tester) async {
      final item = Item(
        id: 2,
        type: ItemType.task,
        title: 'Bare task',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(_buildTestWidget(cubit, item));
      await tester.pump();

      expect(find.text('Bare task'), findsOneWidget);
      expect(find.text('Dates'), findsNothing);
      expect(find.text('Flags'), findsNothing);
      expect(find.text('GTD'), findsNothing);
      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('tapping delete opens the confirm dialog and calls '
        'softDelete on confirm', (tester) async {
      final item = Item(
        id: 3,
        type: ItemType.task,
        title: 'Delete me',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      when(() => cubit.softDelete(3)).thenAnswer((_) async {});

      await tester.pumpWidget(_buildPushedTestWidget(cubit, item));
      await tester.pump();
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.deleteButton).last);
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(3)).called(1);
    });

    // Guards UAT test 9: the finance chip rendered "Ligado a Dívidas #1" —
    // the entity kind plus a raw Isar id — instead of naming the linked debt.
    // The fixture title stays PT-BR because that is the string the UAT
    // reported; the harness runs the `en` locale, so the prefix is "Linked to".
    testWidgets('finance chip names the linked debt instead of its raw id',
        (tester) async {
      final item = Item(
        id: 4,
        type: ItemType.task,
        title: 'Pay Joao back',
        linkedDebtId: 1,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      when(debtRepo.getDebts).thenAnswer(
        (_) async => Success(<Debt>[
          Debt(
            id: 1,
            title: 'Empréstimo Joao',
            amountCents: 50000,
            direction: DebtDirection.toPay,
            counterparty: 'Joao',
            dueDate: DateTime(2026, 3),
            isPaid: false,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ]),
      );

      await tester.pumpWidget(_buildTestWidget(cubit, item));
      // Settle so the loadFinanceLinks future resolves and the chip rebuilds.
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('${l10n.linkedTo} Empréstimo Joao'), findsOneWidget);
      expect(find.textContaining('#1'), findsNothing);
    });

    // Also UAT test 9: the degraded path must stay renderable rather than
    // crash or vanish when the linked debt has since been deleted.
    testWidgets(
        'finance chip falls back to the kind label and id when the entity '
        'is gone', (tester) async {
      final item = Item(
        id: 5,
        type: ItemType.task,
        title: 'Orphaned link',
        linkedDebtId: 1,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      // Repositories keep the empty setUp defaults: the debt no longer exists.

      await tester.pumpWidget(_buildTestWidget(cubit, item));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.textContaining('#1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
