import 'dart:async';

import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/debt_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Regression suite for code-review finding CR-01 — a swipe-deleted debt
/// was unrecoverable.
///
/// Before the fix, `debt_list_screen.dart` wired the `Dismissible`'s
/// `onDismissed` straight to `DebtCubit.softDelete`. There was no
/// `confirmDismiss`, no SnackBar, no undo, and no restore method at any
/// layer — so one stray horizontal drag set `deletedAt` on a real debt and
/// stranded the row in Isar, unreachable from every screen in the app.
///
/// Debts are money owed and owing, so silent unrecoverable deletion is the
/// most damaging class of bug this app can have. Both tests below fail
/// against the pre-fix code: no SnackBar is ever shown, so there is nothing
/// to tap and `restoreDebt` is never called.
///
/// LOCALE: the `MaterialApp` below pins an explicit `locale:`. A
/// locale-less `MaterialApp` resolves to **en** in this project's widget
/// tests, so the locale is stated rather than left to that default, and
/// every assertion goes through `AppLocalizations` instead of a literal.
class MockDebtCubit extends MockCubit<DebtState> implements DebtCubit {}

Debt _debt(int id) => Debt(
      id: id,
      title: 'Debt $id',
      amountCents: 250000,
      direction: DebtDirection.toPay,
      counterparty: 'Counterparty $id',
      dueDate: DateTime(2026, 9, 15),
      isPaid: false,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

Widget _app(DebtCubit cubit) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<DebtCubit>.value(
        value: cubit,
        child: const Scaffold(body: DebtListScreen()),
      ),
    );

void main() {
  late AppLocalizations l10n;
  late MockDebtCubit cubit;
  late StreamController<DebtState> controller;
  late List<Debt> remaining;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// A fresh state carrying a COPY of [remaining].
  ///
  /// `DebtLoaded` is `Equatable` over `debts`, so emitting the same mutated
  /// `List` instance twice would make the two states compare equal and the
  /// `BlocBuilder` would not rebuild.
  DebtLoaded snapshot() => DebtLoaded(debts: List.of(remaining));

  /// Mocks a cubit whose state actually shrinks as ids are soft-deleted.
  ///
  /// A `Dismissible` that is dismissed and then rebuilt from an unchanged
  /// list throws "A dismissed Dismissible widget is still part of the
  /// tree", so `softDelete` must really remove the id and push a new state.
  void seed(List<Debt> initial) {
    remaining = List.of(initial);
    cubit = MockDebtCubit();
    controller = StreamController<DebtState>();

    when(cubit.start).thenAnswer((_) async {});
    when(() => cubit.restoreDebt(any())).thenAnswer((_) async {});
    when(() => cubit.softDelete(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as int;
      remaining.removeWhere((d) => d.id == id);
      controller.add(snapshot());
    });

    whenListen(cubit, controller.stream, initialState: snapshot());
  }

  tearDown(() async {
    await controller.close();
  });

  group('DebtListScreen undo SnackBar', () {
    testWidgets('swipe-deleting a debt shows an undo SnackBar that '
        'restores it', (tester) async {
      seed([_debt(4)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('debt-4')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(4)).called(1);
      expect(find.text(l10n.debtDeleted), findsOneWidget,
          reason: 'a swipe that destroys a financial record must offer a '
              'way back');

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();

      verify(() => cubit.restoreDebt(4)).called(1);
    });

    testWidgets('a second delete inside the undo window replaces the first '
        'SnackBar', (tester) async {
      seed([_debt(7), _debt(8)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('debt-7')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(7)).called(1);
      expect(find.text(l10n.debtDeleted), findsOneWidget);

      // One second is well inside AppConstants.undoSnackbarDuration (5s),
      // so the first SnackBar is definitely still on screen when the
      // second swipe lands.
      await tester.pump(const Duration(seconds: 1));

      await tester.drag(
        find.byKey(const Key('debt-8')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(8)).called(1);
      expect(find.text(l10n.debtDeleted), findsOneWidget,
          reason: 'the second delete must replace the first SnackBar, not '
              'stack on top of it');

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();

      verify(() => cubit.restoreDebt(8)).called(1);
      verifyNever(() => cubit.restoreDebt(7));
      expect(find.text(l10n.debtDeleted), findsNothing,
          reason: 'no queued SnackBar may pop up once the visible undo has '
              'been used');
    });
  });
}
