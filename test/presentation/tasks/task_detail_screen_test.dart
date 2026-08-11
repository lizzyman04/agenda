import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
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

    setUp(() {
      cubit = MockTaskListCubit();
      when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
      whenListen(
        cubit,
        const Stream<TaskListState>.empty(),
        initialState: const TaskListLoaded(items: []),
      );
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
  });
}
