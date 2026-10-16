import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/rules/payload_codec.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/routing/notification_tap_listener.dart';
import 'package:agenda/presentation/shell/shell_navigation.dart';
import 'package:agenda/presentation/tasks/screens/task_detail_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../infrastructure/notifications/fake_notification_gateway.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

class MockItemRepository extends Mock implements ItemRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

Item _item(int id) => Item(
  id: id,
  type: ItemType.task,
  title: 'Pay rent',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

String _taskPayload(int id) => encodePayload(
  kind: NotificationKind.taskReminder,
  entityId: id,
  fireAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  exact: true,
);

void main() {
  late MockTaskListCubit cubit;
  late MockItemRepository items;
  late MockGoalRepository goals;
  late FakeNotificationGateway gateway;

  setUp(() {
    appTabIndex.value = 0;
    financeSubTabRequest.value = null;
    cubit = MockTaskListCubit();
    items = MockItemRepository();
    goals = MockGoalRepository();
    gateway = FakeNotificationGateway();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(const TaskListLoaded(items: []));
    whenListen(
      cubit,
      const Stream<TaskListState>.empty(),
      initialState: const TaskListLoaded(items: []),
    );
    when(() => items.getItem(7)).thenAnswer((_) async => Success(_item(7)));
    when(
      () => items.getItem(99),
    ).thenAnswer((_) async => const Err(DatabaseFailure('missing')));
  });

  tearDown(() => gateway.dispose());

  Widget build() => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: NotificationTapListener(
        gateway: gateway,
        itemRepository: items,
        goalRepository: goals,
        child: const TaskListScreen(),
      ),
    ),
  );

  testWidgets('a tap on a task payload opens its detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(build());
    gateway.tap(_taskPayload(7));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
  });

  testWidgets('a tap for a missing task stays on the tasks tab', (
    tester,
  ) async {
    appTabIndex.value = 3;
    await tester.pumpWidget(build());
    gateway.tap(_taskPayload(99));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsNothing);
    expect(find.byType(TaskListScreen), findsOneWidget);
    expect(appTabIndex.value, 0);
  });

  testWidgets('a soft-deleted task is not opened', (tester) async {
    when(() => items.getItem(7)).thenAnswer(
      (_) async => Success(_item(7).copyWith(deletedAt: DateTime(2024, 2))),
    );
    await tester.pumpWidget(build());
    gateway.tap(_taskPayload(7));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsNothing);
  });

  testWidgets('a launch payload is handled once after the first frame', (
    tester,
  ) async {
    gateway.launch = _taskPayload(7);
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
    verify(() => items.getItem(7)).called(1);
  });

  testWidgets('invalid payloads change nothing and throw nothing', (
    tester,
  ) async {
    appTabIndex.value = 2;
    await tester.pumpWidget(build());
    gateway
      ..tap('garbage')
      ..tap('v9|tk|7|1700000000|e')
      ..tap('');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TaskDetailScreen), findsNothing);
    expect(appTabIndex.value, 2);
    verifyNever(() => items.getItem(any()));
  });

  testWidgets('a debt payload selects Finance on the Debts sub-tab', (
    tester,
  ) async {
    await tester.pumpWidget(build());
    gateway.tap(
      encodePayload(
        kind: NotificationKind.debtReminder,
        entityId: 3,
        fireAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        exact: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(appTabIndex.value, 4);
    expect(financeSubTabRequest.value, 4);
  });
}
