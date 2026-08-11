import 'package:agenda/application/tasks/project/project_cubit.dart';
import 'package:agenda/application/tasks/project/project_state.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/project_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectCubit extends MockCubit<ProjectState>
    implements ProjectCubit {}

Item _makeProject(int id) => Item(
      id: id,
      type: ItemType.project,
      title: 'My Project',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _buildTestWidget(ProjectCubit cubit) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ProjectCubit>.value(
      value: cubit,
      child: const ProjectScreen(projectId: 1),
    ),
  );
}

void main() {
  group('ProjectScreen', () {
    late MockProjectCubit cubit;

    setUp(() {
      cubit = MockProjectCubit();
      when(() => cubit.loadProject(any())).thenAnswer((_) async {});
    });

    testWidgets(
        'tapping FAB opens AddSubtaskSheet with a title field and submit '
        'button', (tester) async {
      final project = _makeProject(1);
      final loaded = ProjectLoaded(
        project: project,
        subtasks: const [],
        completedCount: 0,
        totalCount: 0,
      );
      when(() => cubit.state).thenReturn(loaded);
      whenListen(
        cubit,
        Stream<ProjectState>.fromIterable([loaded]),
        initialState: loaded,
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Subtask title'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add subtask'),
          findsOneWidget);
    });

    testWidgets(
        'submitting a non-empty title calls cubit.addSubtask and closes '
        'the sheet without disposing the controller prematurely',
        (tester) async {
      final project = _makeProject(1);
      final loaded = ProjectLoaded(
        project: project,
        subtasks: const [],
        completedCount: 0,
        totalCount: 0,
      );
      when(() => cubit.state).thenReturn(loaded);
      whenListen(
        cubit,
        Stream<ProjectState>.fromIterable([loaded]),
        initialState: loaded,
      );
      when(
        () => cubit.addSubtask(projectId: 1, title: 'Buy milk'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add subtask'));
      await tester.pumpAndSettle();

      verify(() => cubit.addSubtask(projectId: 1, title: 'Buy milk'))
          .called(1);
      // Sheet closed — no TextField left in the tree, no dispose crash.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('submitting an empty title keeps the sheet open',
        (tester) async {
      final project = _makeProject(1);
      final loaded = ProjectLoaded(
        project: project,
        subtasks: const [],
        completedCount: 0,
        totalCount: 0,
      );
      when(() => cubit.state).thenReturn(loaded);
      whenListen(
        cubit,
        Stream<ProjectState>.fromIterable([loaded]),
        initialState: loaded,
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add subtask'));
      await tester.pumpAndSettle();

      verifyNever(
        () => cubit.addSubtask(
          projectId: any(named: 'projectId'),
          title: any(named: 'title'),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
