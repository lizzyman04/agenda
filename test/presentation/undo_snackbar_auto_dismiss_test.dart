import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/transaction_list_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_detail_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Regression suite for the undo-SnackBar auto-dismiss defect.
///
/// Flutter 3.38 changed `SnackBar.persist` to default to `action != null`
/// (snack_bar.dart: `persist = persist ?? action != null`). With persist
/// true, `ScaffoldMessengerState`'s timeout timer still fires but returns
/// early instead of calling `hideCurrentSnackBar`, so every SnackBar that
/// carries a `SnackBarAction` stays on screen forever. That silently broke
/// all three undo SnackBars, which must expire after
/// [AppConstants.undoSnackbarDuration].
///
/// Every test here fails without the explicit `persist: false` on the
/// SnackBar under test.
class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

class MockTransactionCubit extends MockCubit<TransactionState>
    implements TransactionCubit {}

/// One second past the undo window — long enough for the timeout to fire,
/// short enough that a regression cannot pass by accident.
final Duration _pastUndoWindow =
    AppConstants.undoSnackbarDuration + const Duration(seconds: 1);

Item _item(int id, {String title = 'Delete me'}) => Item(
      id: id,
      type: ItemType.task,
      title: title,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Transaction _transaction(int id) => Transaction(
      id: id,
      type: TransactionType.expense,
      amountCents: 120000,
      categoryId: 1,
      date: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('undo SnackBar auto-dismiss', () {
    testWidgets('TaskListScreen undo SnackBar disappears after the undo '
        'window', (tester) async {
      final cubit = MockTaskListCubit();
      when(cubit.start).thenAnswer((_) async {});
      when(() => cubit.state).thenReturn(TaskListLoaded(items: [_item(1)]));
      whenListen(
        cubit,
        Stream<TaskListState>.fromIterable([
          TaskListLoaded(items: [_item(1)]),
          const TaskListWithPendingUndo(deletedItemId: 1, items: []),
        ]),
        initialState: TaskListLoaded(items: [_item(1)]),
      );

      await tester.pumpWidget(
        _app(
          BlocProvider<TaskListCubit>.value(
            value: cubit,
            child: const TaskListScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskDeleted), findsOneWidget,
          reason: 'undo SnackBar should be visible immediately after delete');

      await tester.pump(_pastUndoWindow);
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskDeleted), findsNothing,
          reason: 'SnackBar must auto-dismiss once the undo window expires');
      expect(find.text(l10n.undo), findsNothing,
          reason: 'a stale Undo button must not stay tappable on screen');
    });

    testWidgets('TransactionListScreen undo SnackBar disappears after the '
        'undo window', (tester) async {
      final cubit = MockTransactionCubit();
      when(cubit.start).thenAnswer((_) async {});
      when(() => cubit.softDelete(any())).thenAnswer((_) async {});
      when(() => cubit.state).thenReturn(
        TransactionLoaded(
          transactions: [_transaction(7)],
          categories: const [],
        ),
      );
      whenListen(
        cubit,
        const Stream<TransactionState>.empty(),
        initialState: TransactionLoaded(
          transactions: [_transaction(7)],
          categories: const [],
        ),
      );

      await tester.pumpWidget(
        _app(
          BlocProvider<TransactionCubit>.value(
            value: cubit,
            child: const Scaffold(body: TransactionListScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('tx-7')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(7)).called(1);
      expect(find.text(l10n.transactionDeleted), findsOneWidget,
          reason: 'undo SnackBar should be visible immediately after swipe');

      await tester.pump(_pastUndoWindow);
      await tester.pumpAndSettle();

      expect(find.text(l10n.transactionDeleted), findsNothing,
          reason: 'SnackBar must auto-dismiss once the undo window expires');
    });

    testWidgets('TaskDetailScreen undo SnackBar disappears after the undo '
        'window', (tester) async {
      final cubit = MockTaskListCubit();
      when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
      when(() => cubit.softDelete(3)).thenAnswer((_) async {});
      whenListen(
        cubit,
        const Stream<TaskListState>.empty(),
        initialState: const TaskListLoaded(items: []),
      );

      await tester.pumpWidget(
        BlocProvider<TaskListCubit>.value(
          value: cubit,
          child: _app(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TaskDetailScreen(item: _item(3)),
                      ),
                    ),
                    child: const Text('open detail'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteButton).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskDeleted), findsOneWidget,
          reason: 'undo SnackBar should be visible after confirmed delete');

      await tester.pump(_pastUndoWindow);
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskDeleted), findsNothing,
          reason: 'SnackBar must auto-dismiss once the undo window expires');
    });
  });
}
