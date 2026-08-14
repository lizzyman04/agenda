import 'dart:async';

import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
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

/// Regression suite for UAT test 3 — the undo SnackBar that belonged to an
/// earlier delete.
///
/// `ScaffoldMessenger` queues SnackBars FIFO. Before the fix,
/// `_handleDelete` called `showSnackBar` with no `hideCurrentSnackBar()`
/// first, so a second swipe inside the 5-second undo window waited behind
/// the first SnackBar instead of replacing it. The user saw one SnackBar,
/// believed it belonged to the swipe just made, tapped Desfazer — and the
/// FIRST transaction came back while the one actually just deleted stayed
/// deleted.
///
/// Both defect assertions in the first test below FAIL against the pre-fix
/// code: `restoreTransaction(8)` is never called (the visible action
/// closure still captured id 7), and the SnackBar does not go away after
/// the Undo tap (dismissing the first one lets the queued second one pop
/// straight back up).
///
/// Not covered here: the separate auto-dismiss defect (`persist: false`),
/// which `test/presentation/undo_snackbar_auto_dismiss_test.dart` owns.
///
/// LOCALE: the `MaterialApp` below pins an explicit `locale:`. A
/// locale-less `MaterialApp` resolves to **en** in this project's widget
/// tests, so the locale is stated rather than left to that default, and
/// every assertion goes through `AppLocalizations` instead of a literal.
class MockTransactionCubit extends MockCubit<TransactionState>
    implements TransactionCubit {}

Transaction _transaction(int id) => Transaction(
      id: id,
      type: TransactionType.expense,
      amountCents: 120000,
      categoryId: 1,
      date: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

Widget _app(TransactionCubit cubit) => MaterialApp(
      locale: const Locale('en'),
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

void main() {
  late AppLocalizations l10n;
  late MockTransactionCubit cubit;
  late StreamController<TransactionState> controller;
  late List<Transaction> remaining;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// A fresh state carrying a COPY of [remaining].
  ///
  /// `TransactionLoaded` is `Equatable` over `transactions`, so emitting
  /// the same mutated `List` instance twice would make the two states
  /// compare equal and leave the rebuild to `BlocBuilder`'s `buildWhen`.
  TransactionLoaded snapshot() => TransactionLoaded(
        transactions: List.of(remaining),
        categories: const [],
      );

  /// Mocks a cubit whose state actually shrinks as ids are soft-deleted.
  ///
  /// A `Dismissible` that is dismissed and then rebuilt from an unchanged
  /// list throws "A dismissed Dismissible widget is still part of the
  /// tree", so `softDelete` must really remove the id and push a new
  /// state.
  void seed(List<Transaction> initial) {
    remaining = List.of(initial);
    cubit = MockTransactionCubit();
    controller = StreamController<TransactionState>();

    when(cubit.start).thenAnswer((_) async {});
    when(() => cubit.restoreTransaction(any())).thenAnswer((_) async {});
    when(() => cubit.softDelete(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as int;
      remaining.removeWhere((t) => t.id == id);
      controller.add(snapshot());
    });

    whenListen(cubit, controller.stream, initialState: snapshot());
  }

  tearDown(() async {
    await controller.close();
  });

  group('TransactionListScreen undo SnackBar lifecycle', () {
    testWidgets(
        'a second delete inside the undo window replaces the first SnackBar '
        'and its Undo restores the most recent transaction', (tester) async {
      seed([_transaction(7), _transaction(8)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('tx-7')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(7)).called(1);
      expect(find.text(l10n.transactionDeleted), findsOneWidget);

      // One second is well inside AppConstants.undoSnackbarDuration (5s),
      // so the first SnackBar is definitely still on screen when the
      // second swipe lands.
      await tester.pump(const Duration(seconds: 1));

      await tester.drag(find.byKey(const Key('tx-8')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(8)).called(1);
      expect(find.text(l10n.transactionDeleted), findsOneWidget,
          reason: 'the second delete must replace the first SnackBar, not '
              'stack on top of it');

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();

      verify(() => cubit.restoreTransaction(8)).called(1);
      verifyNever(() => cubit.restoreTransaction(7));
      expect(find.text(l10n.transactionDeleted), findsNothing,
          reason: 'no queued SnackBar may pop up once the visible undo has '
              'been used');
    });

    testWidgets('a single delete in isolation still shows the undo SnackBar',
        (tester) async {
      seed([_transaction(5)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('tx-5')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(5)).called(1);
      expect(find.text(l10n.transactionDeleted), findsOneWidget,
          reason: 'hiding the current SnackBar must not suppress the undo '
              'for a delete that has no predecessor');

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();

      verify(() => cubit.restoreTransaction(5)).called(1);
    });
  });
}
