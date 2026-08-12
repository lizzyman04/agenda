import 'package:agenda/application/finance/budget/budget_cubit.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/budget_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockCategoryRepository extends Mock
    implements TransactionCategoryRepository {}

Transaction _expense() => Transaction(
      id: 1,
      type: TransactionType.expense,
      amountCents: 3000,
      categoryId: 1,
      date: DateTime(2026, 1, 10),
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 1, 10),
    );

TransactionCategory _category() => TransactionCategory(
      id: 1,
      namePtBr: 'Alimentação',
      type: TransactionType.expense,
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    );

Budget _budget() => Budget(
      id: 1,
      categoryId: 1,
      month: 1,
      year: 2026,
      limitCents: 10000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockTransactionRepository txRepo;
  late MockBudgetRepository budgetRepo;
  late MockCategoryRepository catRepo;

  setUp(() {
    txRepo = MockTransactionRepository();
    budgetRepo = MockBudgetRepository();
    catRepo = MockCategoryRepository();

    when(() => txRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(() => txRepo.getByMonth(any(), any()))
        .thenAnswer((_) async => Success([_expense()]));
    when(() => budgetRepo.getForMonth(any(), any()))
        .thenAnswer((_) async => Success([_budget()]));
    when(() => catRepo.getByType(TransactionType.expense))
        .thenAnswer((_) async => Success([_category()]));
    when(() => budgetRepo.setLimit(any(), any(), any(), any()))
        .thenAnswer((_) async => Success(_budget()));
  });

  Widget harness(BudgetCubit cubit) {
    // Mirror app.dart: cubit provided ABOVE MaterialApp.
    return BlocProvider<BudgetCubit>.value(
      value: cubit,
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('pt'), Locale('en')],
        home: Scaffold(body: BudgetOverviewScreen()),
      ),
    );
  }

  // NOTE: never pumpAndSettle here — the autofocused TextField's blinking
  // cursor is a periodic timer that never settles and would hang the test.
  testWidgets('saving a budget limit does not throw and calls setLimit',
      (tester) async {
    final cubit = BudgetCubit(txRepo, budgetRepo, catRepo);
    await tester.pumpWidget(harness(cubit));
    await tester.pump(); // initState -> start()
    await tester.pump(const Duration(milliseconds: 50)); // async reload emits

    // Category row visible
    expect(find.text('Alimentação'), findsOneWidget);

    // Open the limit sheet
    await tester.tap(find.text('Alimentação'));
    await tester.pump(); // schedule sheet route
    await tester.pump(const Duration(milliseconds: 400)); // open animation

    expect(find.byType(TextField), findsOneWidget);

    // Enter a value and save
    await tester.enterText(find.byType(TextField), '250,00');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump(); // pop(value) + await setLimit
    await tester.pump(const Duration(milliseconds: 50)); // setLimit reload
    await tester.pump(const Duration(milliseconds: 400)); // dismiss animation

    // No exception during open/save/dismiss (this is where the old
    // use-after-dispose + _dependents.isEmpty cascade fired).
    expect(tester.takeException(), isNull);

    // Save path actually applied the limit: 250,00 -> 25000 cents.
    verify(() => budgetRepo.setLimit(1, any(), any(), 25000)).called(1);

    // Sheet is gone.
    expect(find.byType(TextField), findsNothing);

    // Unmount the tree so EditableText's periodic cursor timer is cancelled
    // before the test ends (otherwise teardown waits on the pending timer).
    await tester.pumpWidget(const SizedBox());
  });
}
