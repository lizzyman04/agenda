import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class _FakeContribution extends Fake implements SavingsGoalContribution {}

SavingsGoal _goal({List<SavingsGoalContribution> contributions = const []}) =>
    SavingsGoal(
      id: 1,
      title: 'Fundo Emergencia',
      targetAmountCents: 100000,
      contributions: contributions,
      isCompleted: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

const addLabel = 'Adicionar contribuição';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeContribution());
  });

  late MockGoalRepository goalRepo;
  late MockTransactionRepository txRepo;

  setUp(() {
    goalRepo = MockGoalRepository();
    txRepo = MockTransactionRepository();

    when(() => goalRepo.getGoal(any()))
        .thenAnswer((_) async => Success(_goal()));
    when(() => txRepo.getByLinkedGoal(any()))
        .thenAnswer((_) async => Success(<Transaction>[]));
    when(() => goalRepo.addContribution(any(), any())).thenAnswer(
      (_) async => Success(
        _goal(
          contributions: [
            SavingsGoalContribution(
              amountCents: 25000,
              date: DateTime(2026, 8, 11),
            ),
          ],
        ),
      ),
    );

    // GoalDetailScreen builds its own BlocProvider from getIt<GoalCubit>(),
    // so the cubit has to be resolvable there rather than injected above it.
    getIt.registerFactory<GoalCubit>(() => GoalCubit(goalRepo, txRepo));
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget harness() {
    return const MaterialApp(
      locale: Locale('pt'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt'), Locale('en')],
      home: GoalDetailScreen(goalId: 1),
    );
  }

  // NOTE: never pumpAndSettle here — the autofocused TextField's blinking
  // cursor is a periodic timer that never settles and would hang the test.
  testWidgets('adding a contribution does not throw and calls addContribution',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(); // loadGoal emits
    await tester.pump(const Duration(milliseconds: 50));

    // Goal loaded — the "Adicionar contribuição" button is on screen.
    final addButton =
        find.widgetWithText(FilledButton, 'Adicionar contribuição');
    expect(addButton, findsOneWidget);

    // Open the contribution sheet.
    await tester.tap(addButton);
    await tester.pump(); // schedule sheet route
    await tester.pump(const Duration(milliseconds: 400)); // open animation

    // Amount + note fields.
    expect(find.byType(TextField), findsNWidgets(2));

    // Enter an amount and submit via the sheet's own button.
    await tester.enterText(find.byType(TextField).first, '250,00');
    await tester.pump();
    await tester
        .tap(find.widgetWithText(FilledButton, addLabel).last);
    await tester.pump(); // pop(contribution) + await addContribution
    await tester.pump(const Duration(milliseconds: 50)); // repo + reload
    await tester.pump(const Duration(milliseconds: 400)); // dismiss animation

    // No exception during open/submit/dismiss — this is where the old
    // use-after-dispose + _dependents.isEmpty cascade fired.
    expect(tester.takeException(), isNull);

    // Save path actually persisted: 250,00 -> 25000 cents.
    final captured = verify(
      () => goalRepo.addContribution(1, captureAny()),
    ).captured.single as SavingsGoalContribution;
    expect(captured.amountCents, 25000);

    // Sheet is gone.
    expect(find.byType(TextField), findsNothing);

    // Unmount the tree so EditableText's periodic cursor timer is cancelled
    // before the test ends (otherwise teardown waits on the pending timer).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dismissing the sheet with an empty amount saves nothing',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.widgetWithText(FilledButton, addLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Submit with an empty amount — sheet closes, nothing is written.
    await tester
        .tap(find.widgetWithText(FilledButton, addLabel).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    verifyNever(() => goalRepo.addContribution(any(), any()));
    expect(find.byType(TextField), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
