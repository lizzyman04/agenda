<!-- GSD:GENERATED -->
<!-- generated-by: gsd-doc-writer -->

# Testing

AGENDA uses `flutter_test` as the base framework, `bloc_test` for Cubit/BLoC unit tests, and `mocktail` for mock creation — no code generation required for mocks.

---

## Test Framework and Setup

| Tool | Version | Role |
|------|---------|------|
| `flutter_test` | SDK bundle | Base test runner, widget testing, `testWidgets`, assertions |
| `bloc_test` | 10.0.0 | `blocTest()` helper for Cubit state emission assertions |
| `mocktail` | 1.0.5 | Interface mocking without code generation |

No global test setup file is required. Mocks are instantiated directly inside each test file with `setUp()`. Fallback values for abstract types are registered with `registerFallbackValue()` inside `setUpAll()`.

Run `flutter pub get` once after cloning before executing any test command.

---

## Running Tests

**Full test suite:**

```bash
flutter test --no-pub
```

**Full suite with line-by-line output:**

```bash
flutter test --no-pub --reporter expanded
```

**Single file:**

```bash
flutter test --no-pub test/application/tasks/task_list_cubit_test.dart
```

**Single directory:**

```bash
flutter test --no-pub test/application/
```

**With coverage report:**

```bash
flutter test --no-pub --coverage
```

The coverage data is written to `coverage/lcov.info`. To generate an HTML report (requires `lcov` installed on the host):

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Test Structure

Tests mirror the `lib/` directory structure under `test/`. Each layer has its own subdirectory:

```
test/
├── application/
│   └── tasks/
│       ├── day_planner_cubit_test.dart   # DayPlannerCubit (1-3-5 Rule slots)
│       ├── project_cubit_test.dart       # ProjectCubit (subtask management)
│       └── task_list_cubit_test.dart     # TaskListCubit (search, filter, CRUD)
├── config/
│   └── di/
│       └── di_test.dart                  # GetIt DI graph smoke tests
├── core/
│   ├── config/
│   │   └── app_config_test.dart          # AppConfig constants
│   └── failures/
│       └── failure_test.dart             # Failure hierarchy + Result pattern
├── data/
│   ├── database/
│   │   └── migration_runner_test.dart    # MigrationRunner schema version logic
│   └── tasks/
│       ├── item_dao_test.dart            # ItemDao (stub — not yet populated)
│       └── item_mapper_test.dart         # ItemMapper round-trip + enum mapping
├── domain/
│   └── tasks/
│       ├── eisenhower_quadrant_test.dart # EisenhowerQuadrant enum values
│       ├── item_test.dart                # Item domain model defaults + Eisenhower getter
│       └── recurrence_engine_test.dart   # RecurrenceEngine.parse() interface contract
├── infrastructure/
│   └── tasks/
│       ├── item_repository_impl_test.dart    # ItemRepositoryImpl DAO delegation
│       └── recurrence_engine_impl_test.dart  # RecurrenceEngineImpl.parse() + nextOccurrence()
├── l10n/
│   └── l10n_test.dart                    # ARB key parity + LocaleCubit locale persistence
├── presentation/
│   └── tasks/
│       ├── day_planner_test.dart         # DayPlannerScreen widget tests
│       ├── eisenhower_board_test.dart    # EisenhowerScreen quadrant rendering
│       ├── gtd_test.dart                 # GtdChip + GtdFilterScreen widget tests
│       ├── task_form_test.dart           # TaskFormScreen validation + submit
│       └── task_list_screen_test.dart    # TaskListScreen empty state, SnackBar, delete
└── widget_test.dart                      # Root smoke test
```

---

## What Existing Tests Cover

| Area | File(s) | Key assertions |
|------|---------|----------------|
| **Domain model** | `item_test.dart` | Default field values, `eisenhowerQuadrant` getter for all four quadrants, subtask with `parentId` |
| **Eisenhower enum** | `eisenhower_quadrant_test.dart` | Exactly four values: `doNow`, `schedule`, `delegate`, `eliminate` |
| **Recurrence (interface)** | `recurrence_engine_test.dart` | `parse()` contract: null, invalid, DAILY, WEEKLY with BYDAY, MONTHLY with BYMONTHDAY, YEARLY |
| **Recurrence (impl)** | `recurrence_engine_impl_test.dart` | `parse()` + `nextOccurrence()` for all four frequencies and BYDAY variants |
| **Failure + Result** | `failure_test.dart` | All five `Failure` subtypes carry messages; `Success`/`Err` pattern matching with Dart 3 sealed classes |
| **AppConfig constants** | `app_config_test.dart` | `appName`, `packageName`, `schemaVersion`, notification base IDs are distinct |
| **Data mapper** | `item_mapper_test.dart` | Full `toDomain`/`toModel` field round-trip; `timeInfo` and `moneyInfo` embedded objects; all five `Priority` and four `SizeCategory` enum mappings |
| **Migration runner** | `migration_runner_test.dart` | Fresh install runs v1→v2 migrations; already-at-target is a no-op; future version is a no-op |
| **Repository impl** | `item_repository_impl_test.dart` | `createItem` delegates to DAO and returns `Success<Item>`; parent type validation returns `Err(ValidationFailure)`; `softDelete`, `restoreItem`, `searchByTitle` delegate to DAO |
| **TaskListCubit** | `task_list_cubit_test.dart` | Initial state; `start()` emits `TaskListLoaded`; `search()` delegates to repo; `applyFilter()` passes correct params; `softDelete()` emits `TaskListWithPendingUndo`; `restoreItem()` returns to `TaskListLoaded`; `completeItem()` sets `isCompleted = true`; repo error emits `TaskListError` |
| **DayPlannerCubit** | `day_planner_cubit_test.dart` | Initial state; `assignBig/Medium/Small()` fill slots; slot limit warning fires on overflow; `remove()` targets correct slot; `clearAll()` resets to initial |
| **ProjectCubit** | `project_cubit_test.dart` | `loadProject()` emits `ProjectLoaded` with rollup counts; `addSubtask()` creates with correct `ItemType.subtask` and `parentId`; `completeSubtask()` increments `completedCount`; `deleteSubtask()` calls `softDelete` and refreshes |
| **DI graph** | `di_test.dart` | `IsarService` and `SharedPreferences` resolve without error; `IsarService` is a singleton |
| **Localization** | `l10n_test.dart` | EN and PT-BR ARB files have identical keys; `LocaleCubit` initial locale, `setLocale`, unsupported locale is a no-op |
| **TaskListScreen** | `task_list_screen_test.dart` | Empty state message; item renders; `TaskListWithPendingUndo` triggers SnackBar + Undo; delete button calls `cubit.softDelete` |
| **TaskFormScreen** | `task_form_test.dart` | Title field present; empty-title submission shows validation error; valid title calls `cubit.createItem` |
| **EisenhowerScreen** | `eisenhower_board_test.dart` | All four quadrant labels render; urgent+important task appears in "Do Now" section |
| **DayPlannerScreen** | `day_planner_test.dart` | Three slot section headers render; warning banner visible/absent based on `slotLimitWarning` |
| **GtdChip + GtdFilterScreen** | `gtd_test.dart` | Chip label renders; selected chip shows checkmark; tapping chip fires `onSelected(true)`; screen renders distinct context chips; Apply passes selected context to `cubit.applyFilter`; empty-contexts state shows placeholder text |

---

## BLoC/Cubit Testing with `bloc_test`

Use `blocTest()` from `package:bloc_test/bloc_test.dart` for all state emission assertions. Plain `test()` is acceptable for initial-state and computed-property checks that do not require emitting states.

**Standard pattern:**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

blocTest<MyCubit, MyState>(
  'description of expected behavior',
  build: () => MyCubit(mockRepository),
  act: (cubit) => cubit.doSomething(),
  expect: () => [isA<MyLoadedState>()],
);
```

**Anatomy of a `blocTest` call:**

| Parameter | Purpose |
|-----------|---------|
| `build` | Constructs and returns a fresh Cubit instance. Called before `act`. |
| `setUp` | Optional: runs before `build`. Use for mock stubbing shared across the test. |
| `act` | Invokes Cubit methods. Awaited before assertions run. |
| `expect` | List of state matchers emitted after build. Uses `isA<T>()` for type checks or `having()` for field-level assertions. |
| `verify` | Called after `act` completes. Use `verify(() => mock.method()).called(n)` to assert DAO/repository call counts. |

**Using `having()` for precise field assertions:**

```dart
expect: () => [
  isA<TaskListWithPendingUndo>()
      .having((s) => s.deletedItemId, 'deletedItemId', 1)
      .having((s) => s.items.length, 'items.length', 1),
],
```

**Capturing arguments passed to mocks:**

```dart
verify: (_) {
  final captured =
      verify(() => repository.updateItem(captureAny())).captured;
  final updatedItem = captured.last as Item;
  expect(updatedItem.isCompleted, isTrue);
},
```

**Testing sequential calls that return different values** (see `project_cubit_test.dart`):

```dart
when(() => repository.getSubtaskCounts(10))
    .thenAnswerMany([
  (_) async => const Success<(int, int)>((0, 1)),
  (_) async => const Success<(int, int)>((1, 1)),
]);
```

The `thenAnswerMany` extension is defined locally in `project_cubit_test.dart` — copy it into your own test file if you need it.

---

## Mocking Repositories with `mocktail`

`mocktail` is preferred over `mockito` because it requires no code generation.

**Step 1 — Declare mock and fallback classes at the top of the test file:**

```dart
class MockItemRepository extends Mock implements ItemRepository {}

class FakeItem extends Fake implements Item {}
```

Use `Mock` for the class you want to stub. Use `Fake` for concrete types passed as arguments — `mocktail` requires a registered fallback for any type used with `any()` or `captureAny()`.

**Step 2 — Register fallbacks in `setUpAll`:**

```dart
setUpAll(() {
  registerFallbackValue(FakeItem());
});
```

**Step 3 — Instantiate mocks in `setUp`:**

```dart
setUp(() {
  repository = MockItemRepository();
});
```

**Step 4 — Stub methods before they are called:**

```dart
when(() => repository.filterItems(
  type: any(named: 'type'),
  quadrant: any(named: 'quadrant'),
  // ... remaining named params
)).thenAnswer((_) async => Success<List<Item>>([]));
```

Use `any(named: 'paramName')` for named parameters. Use `any()` for positional parameters.

**Step 5 — Assert calls in `verify` or after `act`:**

```dart
verify(() => repository.searchByTitle('meeting')).called(1);
verifyNever(() => repository.updateItem(any()));
```

---

## Writing Widget Tests

Widget tests use `testWidgets()` with a `WidgetTester`. To test screens that depend on a Cubit, inject a `MockCubit` created with `bloc_test`'s `MockCubit<State>` mixin.

**Standard widget test scaffold:**

```dart
class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

Widget _buildTestWidget(TaskListCubit cubit) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TaskListCubit>.value(
      value: cubit,
      child: const MyScreen(),
    ),
  );
}
```

Always supply `AppLocalizations.delegate` and the Flutter localizations delegates — AGENDA screens use localized strings and will throw a `MissingMaterialLocalizations` error without them.

**Controlling state and stream for `MockCubit`:**

```dart
setUp(() {
  cubit = MockTaskListCubit();
  when(() => cubit.state).thenReturn(
    const TaskListLoaded(items: [], filter: TaskListFilter.empty),
  );
  whenListen(
    cubit,
    Stream<TaskListState>.fromIterable([
      const TaskListLoaded(items: [], filter: TaskListFilter.empty),
    ]),
    initialState: const TaskListLoaded(items: [], filter: TaskListFilter.empty),
  );
});
```

`when(() => cubit.state)` controls what `BlocBuilder` and `context.watch` read synchronously. `whenListen` drives the stream that `BlocListener` and `BlocConsumer` react to.

For screens that resolve dependencies through `GetIt` (e.g., `GtdFilterScreen`), register mocks directly in `setUp` and reset in `tearDown`:

```dart
setUp(() {
  GetIt.instance.registerSingleton<ItemRepository>(mockRepository);
});
tearDown(() async {
  await GetIt.instance.reset();
});
```

---

## Writing New Tests

**Naming conventions:**

- Test files: `{source_file_name}_test.dart` mirroring the lib path under `test/`.
- Test descriptions: plain English sentence describing observable behavior, not implementation details.
- Groups: name after the class or function under test (e.g., `group('TaskListCubit', () {`).

**Helper factories:**

Each test file defines a local `makeItem()` factory to create domain objects with sensible defaults. Copy and adapt the pattern from any existing Cubit test:

```dart
Item makeItem({required int id, String title = 'Task'}) {
  final now = DateTime(2026);
  return Item(
    id: id,
    type: ItemType.task,
    title: title,
    createdAt: now,
    updatedAt: now,
  );
}
```

Use fixed `DateTime` values (e.g., `DateTime(2026)`) rather than `DateTime.now()` to keep tests deterministic.

**Checklist for a new Cubit test file:**

1. Declare `Mock*` and `Fake*` classes for all injected interfaces.
2. Call `registerFallbackValue()` for each `Fake*` in `setUpAll`.
3. Instantiate mocks and stub `watchChanges()` (if used) in `setUp`.
4. Use `blocTest()` for state emission tests; `test()` for initial state and computed properties.
5. Use `verify()` inside the `verify` parameter of `blocTest()` — not after `await cubit.close()`.

**Checklist for a new widget test file:**

1. Declare `MockCubit` classes via `MockCubit<State>`.
2. Wrap the widget under test in `MaterialApp` with all localization delegates.
3. Stub `cubit.state` and call `whenListen` in `setUp`.
4. Call `await tester.pump()` after `pumpWidget` to process the first frame.
5. Use `await tester.pumpAndSettle()` only when the widget performs async operations in `initState` (e.g., `GtdFilterScreen` loading contexts).

---

## Coverage Requirements

No minimum coverage threshold is configured. Run `flutter test --no-pub --coverage` to generate `coverage/lcov.info` and inspect coverage manually.

---

## CI Integration

No CI pipeline is configured for this repository. Tests are run locally with `flutter test --no-pub`. When a CI workflow is added, the recommended test step is:

```yaml
- name: Run tests
  run: flutter test --no-pub --reporter expanded
```
