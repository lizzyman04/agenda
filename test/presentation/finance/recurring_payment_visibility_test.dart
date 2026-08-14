// Regression coverage for CR-02 (03-REVIEW.md, Critical).
//
// The defect: the only query behind the recurring payments screen was
// `RecurringPaymentDao.findAll()`, filtered
// `.isActiveEqualTo(true).and().deletedAtIsNull()`. The screen's per-row
// SwitchListTile writes `isActive: !isActive`, so pausing a subscription
// dropped it out of the one list that renders it — and the toggle that
// would switch it back is only drawn for rows that query still returns.
// The payment vanished with no screen anywhere able to show it again,
// which made "pause" an undocumented, unrecoverable delete.
//
// Route taken, following the precedent set by CR-04's regression suite:
// this project has no infrastructure for opening a real Isar instance in a
// test (`initializeIsarCore` appears nowhere, `item_dao_test.dart` is an
// empty stub), so the fix is pinned at two levels instead:
//   1. The DAO query shape itself, asserted from source — the
//      read-the-real-file pattern used by `transaction_dao_ordering_test`
//      and `l10n_test`. This is the level that fails if the isActive
//      filter is put back.
//   2. The screen, against a mocked cubit: a paused payment renders, is
//      visibly distinguished, and its toggle asks for isActive: true.
// Level 2 cannot see the DAO, so it is level 1 that carries the mutation
// check for the query; level 2 fails if the row is re-hidden or the
// toggle stops being able to resume.
//
// LOCALE: the MaterialApp below pins an explicit `locale:`, and every
// user-facing assertion goes through AppLocalizations rather than a
// literal — the paused label was hardcoded PT-BR before this plan.

import 'dart:async';
import 'dart:io';

import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/application/finance/recurring/recurring_payment_state.dart';
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringPaymentCubit extends MockCubit<RecurringPaymentState>
    implements RecurringPaymentCubit {}

const _daoPath = 'lib/data/finance/recurring/recurring_payment_dao.dart';

RecurringPayment _payment(int id, {required bool isActive}) =>
    RecurringPayment(
      id: id,
      title: 'Netflix',
      amountCents: 45000,
      categoryId: 1,
      cycle: RecurringCycle.monthly,
      nextDueDate: DateTime(2026, 9, 10),
      isActive: isActive,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

Widget _app(RecurringPaymentCubit cubit) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<RecurringPaymentCubit>.value(
        value: cubit,
        child: const Scaffold(body: RecurringPaymentScreen()),
      ),
    );

/// Returns the source text of the expression body of [signature] in
/// [source], i.e. everything from the signature up to its terminating `;`.
String _methodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: '"$signature" not found in $_daoPath',
  );
  final end = source.indexOf(';', start);
  expect(end, greaterThan(start), reason: 'unterminated body for $signature');
  return source.substring(start, end);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_payment(0, isActive: true));
  });

  group('CR-02 · DAO query shape', () {
    late String source;

    setUpAll(() {
      source = File(_daoPath).readAsStringSync();
    });

    test('findAll() does not filter on isActive', () {
      final body = _methodBody(
        source,
        'Future<List<RecurringPaymentModel>> findAll()',
      );

      expect(
        body.contains('isActiveEqualTo'),
        isFalse,
        reason: 'the list query must return paused payments — filtering '
            'them out is what made pausing an irreversible hide (CR-02).',
      );
    });

    test('findAll() still excludes soft-deleted rows', () {
      final body = _methodBody(
        source,
        'Future<List<RecurringPaymentModel>> findAll()',
      );

      expect(
        body.contains('deletedAtIsNull()'),
        isTrue,
        reason: 'deletedAt is the delete flag; unhiding paused rows must '
            'not also unhide deleted ones.',
      );
    });

    test('findAll() sorts before applying its cap', () {
      final body = _methodBody(
        source,
        'Future<List<RecurringPaymentModel>> findAll()',
      );

      final sortAt = body.indexOf('sortByIsActiveDesc()');
      final limitAt = body.indexOf('.limit(500)');

      expect(sortAt, greaterThanOrEqualTo(0));
      expect(limitAt, greaterThanOrEqualTo(0));
      expect(
        sortAt,
        lessThan(limitAt),
        reason: 'an unsorted cap selects rows in id order and can evict an '
            'active payment in favour of a paused one (the CR-04 lesson).',
      );
    });
  });

  group('RecurringPaymentScreen · paused payments', () {
    late AppLocalizations l10n;
    late MockRecurringPaymentCubit cubit;
    late StreamController<RecurringPaymentState> controller;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    void seed(List<RecurringPayment> payments) {
      cubit = MockRecurringPaymentCubit();
      controller = StreamController<RecurringPaymentState>();

      when(cubit.start).thenAnswer((_) async {});
      when(() => cubit.updatePayment(any())).thenAnswer((_) async {});

      whenListen(
        cubit,
        controller.stream,
        initialState: RecurringPaymentLoaded(payments: List.of(payments)),
      );
    }

    tearDown(() async {
      await controller.close();
    });

    testWidgets('a paused payment stays visible and reads as paused',
        (tester) async {
      seed([_payment(3, isActive: false)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('Netflix'),
        findsOneWidget,
        reason: 'a paused payment must still be listed — the screen holds '
            'the only control that can resume it (CR-02).',
      );
      expect(find.text(l10n.recurringPaused), findsOneWidget);
      expect(find.text(l10n.recurringActive), findsNothing);

      final opacity = tester.widget<Opacity>(
        find.byKey(const Key('recurring-dim-3')),
      );
      expect(
        opacity.opacity,
        lessThan(1.0),
        reason: 'a paused row must be visually distinct from an active one, '
            'or it reads as a broken active payment.',
      );
    });

    testWidgets('an active payment renders undimmed and reads as active',
        (tester) async {
      seed([_payment(4, isActive: true)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.recurringActive), findsOneWidget);
      expect(find.text(l10n.recurringPaused), findsNothing);

      final opacity = tester.widget<Opacity>(
        find.byKey(const Key('recurring-dim-4')),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('the toggle resumes a paused payment', (tester) async {
      seed([_payment(3, isActive: false)]);

      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final captured =
          verify(() => cubit.updatePayment(captureAny())).captured;
      expect(captured, hasLength(1));

      final updated = captured.single as RecurringPayment;
      expect(updated.id, 3);
      expect(
        updated.isActive,
        isTrue,
        reason: 'the same control that pauses a payment must resume it — '
            'that reversibility is the actual CR-02 fix.',
      );
    });
  });
}
