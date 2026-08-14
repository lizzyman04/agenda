import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/transaction_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Regression suite for UAT test 2 — the raw-category-id half of the defect.
///
/// Before the fix, `transaction_list_screen.dart`'s `_categoryName` stub
/// always returned `'#${tx.categoryId}'`, so every card in the Transações
/// list was titled `#10`, `#1`, `#2` instead of the category name.
///
/// `'resolves categoryId to the category name, never the raw id'` FAILS
/// against the pre-fix screen: it renders `#10` there, so `'Alimentação'`
/// is `findsNothing` and `find.textContaining('#10')` matches.
///
/// LOCALE: every `MaterialApp` below passes an explicit `locale:`. A
/// locale-less `MaterialApp` in this project's widget tests resolves to
/// **en**, and `resolveCategoryDisplay` returns `nameEn` under `en` — so
/// omitting the locale would silently render `'Food'` instead of
/// `'Alimentação'`.
class MockTransactionCubit extends MockCubit<TransactionState>
    implements TransactionCubit {}

Transaction _transaction({int categoryId = 10}) => Transaction(
      id: 7,
      type: TransactionType.expense,
      amountCents: 120000,
      categoryId: categoryId,
      date: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

TransactionCategory _category({int id = 10}) => TransactionCategory(
      id: id,
      namePtBr: 'Alimentação',
      nameEn: 'Food',
      type: TransactionType.expense,
      isDefault: true,
      createdAt: DateTime(2026),
    );

Widget _app({
  required Locale locale,
  required TransactionCubit cubit,
}) =>
    MaterialApp(
      locale: locale,
      // GlobalCupertinoLocalizations is required as well: without it a
      // pt_BR MaterialApp emits a "not supported by all of its localization
      // delegates" warning, which flutter_test records as a pending
      // exception and fails the test.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<TransactionCubit>.value(
        value: cubit,
        child: const Scaffold(body: TransactionListScreen()),
      ),
    );

MockTransactionCubit _cubitWith(TransactionLoaded state) {
  final cubit = MockTransactionCubit();
  when(cubit.start).thenAnswer((_) async {});
  when(() => cubit.state).thenReturn(state);
  whenListen(
    cubit,
    const Stream<TransactionState>.empty(),
    initialState: state,
  );
  return cubit;
}

void main() {
  group('TransactionListScreen category resolution', () {
    testWidgets('resolves categoryId to the category name, never the raw id',
        (tester) async {
      final cubit = _cubitWith(
        TransactionLoaded(
          transactions: [_transaction()],
          categories: [_category()],
        ),
      );

      await tester.pumpWidget(
        _app(locale: const Locale('pt', 'BR'), cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alimentação'), findsOneWidget);
      expect(
        find.textContaining('#10'),
        findsNothing,
        reason: 'the raw categoryId must never reach the card when the '
            'category exists — that was the UAT test 2 defect',
      );
    });

    testWidgets('falls back to #<id> when no category matches',
        (tester) async {
      final cubit = _cubitWith(
        TransactionLoaded(
          transactions: [_transaction()],
          categories: const [],
        ),
      );

      await tester.pumpWidget(
        _app(locale: const Locale('pt', 'BR'), cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('#10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the English name under the en locale', (tester) async {
      final cubit = _cubitWith(
        TransactionLoaded(
          transactions: [_transaction()],
          categories: [_category()],
        ),
      );

      await tester.pumpWidget(
        _app(locale: const Locale('en'), cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Alimentação'), findsNothing);
    });
  });
}
