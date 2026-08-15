import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/task_detail_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Regression suite for CR-03 — the task-detail undo closure read a cubit
/// off a popped route's context.
///
/// `_confirmDelete` pops the detail route and THEN shows a SnackBar whose
/// Undo action used to call `context.read<TaskListCubit>().restoreItem(...)`
/// straight from the widget's own `context`. By the time a user taps Undo,
/// up to `AppConstants.undoSnackbarDuration` (5s) later, that context
/// belongs to a defunct element and the ancestor lookup throws — so
/// `restoreItem` never ran and the task stayed deleted.
///
/// The existing `task_detail_screen_test.dart` never taps Undo, only
/// confirms the delete dialog, so it never exercised this path. The test
/// below pushes the real route (so the pop is real) and actually TAPS
/// Undo — the whole point, since letting the SnackBar merely expire is
/// exactly what let the defect through the first time.
class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

Item _item(int id, {String title = 'Delete me'}) => Item(
      id: id,
      type: ItemType.task,
      title: title,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

/// Pushes the detail screen onto a real back stack so
/// `Navigator.of(context).pop()` (called after a confirmed delete) has
/// somewhere to go and genuinely defuncts the route's context — mirroring
/// how the screen is reached from the task list in production.
Widget _app(TaskListCubit cubit, Item item) =>
    BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: MaterialApp(
        // Explicit locale: a locale-less MaterialApp resolves to `en` in
        // this project's widget tests, but stating it avoids relying on
        // that default.
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
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

/// Drives the screen through delete confirm + pop, leaving the Undo
/// SnackBar on screen without tapping it or letting it expire.
Future<void> _deleteAndConfirm(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.text('open detail'));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.tap(find.text(l10n.deleteButton).last);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;
  late MockTaskListCubit cubit;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    cubit = MockTaskListCubit();
    when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
    whenListen(
      cubit,
      const Stream<TaskListState>.empty(),
      initialState: const TaskListLoaded(items: []),
    );
    when(() => cubit.softDelete(any())).thenAnswer((_) async {});
    when(() => cubit.restoreItem(any())).thenAnswer((_) async {});
  });

  group('TaskDetailScreen undo after a real route pop', () {
    testWidgets(
        'tapping Undo after the route has popped restores the task via '
        'the pre-captured cubit', (tester) async {
      final item = _item(9);

      await tester.pumpWidget(_app(cubit, item));
      await _deleteAndConfirm(tester, l10n);

      // The route is genuinely gone; TaskDetailScreen's own element is
      // defunct here, which is exactly the condition CR-03 needed.
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect(find.text(l10n.taskDeleted), findsOneWidget);

      await tester.tap(find.text(l10n.undo));
      await tester.pumpAndSettle();

      verify(() => cubit.softDelete(9)).called(1);
      verify(() => cubit.restoreItem(9)).called(1);
    });

    testWidgets(
        'the undo SnackBar still auto-dismisses on its own when Undo is '
        'NOT tapped', (tester) async {
      final item = _item(11);

      await tester.pumpWidget(_app(cubit, item));
      await _deleteAndConfirm(tester, l10n);

      expect(find.text(l10n.taskDeleted), findsOneWidget);

      // One second past the undo window — long enough for the timeout to
      // fire, short enough that a regression cannot pass by accident.
      await tester.pump(
        AppConstants.undoSnackbarDuration + const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskDeleted), findsNothing,
          reason: 'SnackBar must auto-dismiss once the undo window expires');
      verifyNever(() => cubit.restoreItem(11));
    });
  });
}
