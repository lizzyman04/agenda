import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/gtd_filter_screen.dart';
import 'package:agenda/presentation/tasks/widgets/gtd_chip.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

class MockItemRepository extends Mock implements ItemRepository {}

Widget _buildGtdChipWidget({
  required String label,
  required bool isSelected,
  required ValueChanged<bool> onSelected,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: GtdChip(
        label: label,
        isSelected: isSelected,
        onSelected: onSelected,
      ),
    ),
  );
}

Widget _buildFilterScreenWidget(TaskListCubit cubit) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: const GtdFilterScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(TaskListFilter.empty);
  });

  group('GtdChip', () {
    testWidgets('renders with given label text', (tester) async {
      await tester.pumpWidget(
        _buildGtdChipWidget(
          label: '@home',
          isSelected: false,
          onSelected: (_) {},
        ),
      );
      await tester.pump();

      expect(find.text('@home'), findsOneWidget);
    });

    testWidgets('shows checkmark when isSelected is true', (tester) async {
      await tester.pumpWidget(
        _buildGtdChipWidget(
          label: '@office',
          isSelected: true,
          onSelected: (_) {},
        ),
      );
      await tester.pump();

      // Selected FilterChip renders with a check icon
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('calls onSelected(true) when tapped while unselected',
        (tester) async {
      bool? receivedValue;

      await tester.pumpWidget(
        _buildGtdChipWidget(
          label: '@phone',
          isSelected: false,
          onSelected: (val) => receivedValue = val,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      expect(receivedValue, isTrue);
    });
  });

  group('GtdFilterScreen', () {
    late MockTaskListCubit cubit;
    late MockItemRepository repository;

    setUp(() {
      cubit = MockTaskListCubit();
      repository = MockItemRepository();

      when(() => cubit.state).thenReturn(
        const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );
      whenListen(
        cubit,
        Stream<TaskListState>.empty(),
        initialState:
            const TaskListLoaded(items: [], filter: TaskListFilter.empty),
      );
      when(() => cubit.applyFilter(any())).thenAnswer((_) async {});

      // Register mock in GetIt so GtdFilterScreen can resolve ItemRepository
      GetIt.instance.registerSingleton<ItemRepository>(repository);
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('renders chips for each distinct GTD context', (tester) async {
      when(() => repository.getDistinctGtdContexts()).thenAnswer(
        (_) async => const Success<List<String>>(['@home', '@office', '@phone']),
      );

      await tester.pumpWidget(_buildFilterScreenWidget(cubit));
      // Wait for async initState to complete
      await tester.pumpAndSettle();

      expect(find.text('@home'), findsOneWidget);
      expect(find.text('@office'), findsOneWidget);
      expect(find.text('@phone'), findsOneWidget);
    });

    testWidgets(
        'tapping a chip and pressing Apply calls cubit.applyFilter with selected context',
        (tester) async {
      when(() => repository.getDistinctGtdContexts()).thenAnswer(
        (_) async =>
            const Success<List<String>>(['@home', '@work']),
      );

      await tester.pumpWidget(_buildFilterScreenWidget(cubit));
      await tester.pumpAndSettle();

      // Tap the @work chip
      await tester.tap(find.text('@work'));
      await tester.pump();

      // Tap Apply button (l10n.applyFilter = "Apply")
      await tester.tap(find.text('Apply'));
      await tester.pump();

      verify(
        () => cubit.applyFilter(
          const TaskListFilter(gtdContext: '@work'),
        ),
      ).called(1);
    });

    testWidgets('shows empty state text when no contexts exist', (tester) async {
      when(() => repository.getDistinctGtdContexts()).thenAnswer(
        (_) async => const Success<List<String>>([]),
      );

      await tester.pumpWidget(_buildFilterScreenWidget(cubit));
      await tester.pumpAndSettle();

      // l10n.noGtdContexts = "No GTD contexts found"
      expect(find.text('No GTD contexts found'), findsOneWidget);
    });
  });
}
