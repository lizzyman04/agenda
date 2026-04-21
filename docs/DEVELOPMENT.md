<!-- GSD:GENERATED -->

# Development Guide

## Daily commands

| Task | Command |
|------|---------|
| Install dependencies | `flutter pub get` |
| Code generation (Isar + DI) | `dart run build_runner build --delete-conflicting-outputs` |
| Generate localizations | `flutter gen-l10n` |
| Run app | `flutter run` |
| Lint | `flutter analyze --no-fatal-infos` |
| Format | `dart format .` |
| Tests | `flutter test --no-pub` |

Run code generation after any change to `@Collection`, `@embedded`, `@injectable`, `@singleton`, or `@module` annotated code.

---

## Code generation workflow

Two generators run via `build_runner`:

1. **Isar Community** (`isar_community_generator`) — reads `@Collection` and `@embedded` annotations, writes `*.g.dart` schema files
2. **Injectable** (`injectable_generator`) — reads `@injectable`, `@singleton`, `@lazySingleton`, `@module` annotations, writes `lib/config/di/injection.config.dart`

```bash
# After modifying any annotated class:
dart run build_runner build --delete-conflicting-outputs

# Watch mode during active development:
dart run build_runner watch --delete-conflicting-outputs
```

Generated files are excluded from analysis (`analysis_options.yaml`) — never edit them manually.

---

## Adding a new feature (layered architecture)

The architecture has five layers: **domain → data → infrastructure → application → presentation**. Always implement top-down.

### 1. Domain layer (`lib/domain/<feature>/`)

Define the entity and repository interface:

```dart
// lib/domain/finance/transaction.dart
class Transaction {
  const Transaction({required this.id, required this.amount, ...});
  final int id;
  final double amount;
  // ...
}

// lib/domain/finance/transaction_repository.dart
abstract interface class TransactionRepository {
  AsyncResult<List<Transaction>> getAll();
  AsyncResult<void> save(Transaction transaction);
}
```

### 2. Data layer (`lib/data/<feature>/`)

Define the Isar model with `@Collection`, run `build_runner`:

```dart
// lib/data/finance/transaction_model.dart
import 'package:isar_community/isar.dart';
part 'transaction_model.g.dart';

@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;
  late double amount;
  @Index()
  DateTime? date;
  // ...
}
```

Add a DAO for read/write operations using `IsarService`.

### 3. Infrastructure layer (`lib/infrastructure/<feature>/`)

Implement the repository interface with the `@LazySingleton(as: ...)` annotation:

```dart
// lib/infrastructure/finance/transaction_repository_impl.dart
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dao, this._mapper);
  final TransactionDao _dao;
  final TransactionMapper _mapper;

  @override
  AsyncResult<List<Transaction>> getAll() async {
    try {
      final models = await _dao.getAll();
      return Success(models.map(_mapper.toDomain).toList());
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }
}
```

### 4. Application layer (`lib/application/<feature>/`)

Create a Cubit with `@injectable`:

```dart
// lib/application/finance/transaction_list/transaction_list_cubit.dart
@injectable
class TransactionListCubit extends Cubit<TransactionListState> {
  TransactionListCubit(this._repository) : super(TransactionListInitial());
  final TransactionRepository _repository;

  Future<void> load() async {
    emit(TransactionListLoading());
    final result = await _repository.getAll();
    switch (result) {
      case Success(:final value): emit(TransactionListLoaded(value));
      case Err(:final failure): emit(TransactionListError(failure.message));
    }
  }
}
```

Register factory dependencies (Cubits) in a DI module if they don't auto-register.

### 5. Presentation layer (`lib/presentation/<feature>/`)

Provide the Cubit via `BlocProvider`, inject from `getIt`:

```dart
BlocProvider(
  create: (_) => getIt<TransactionListCubit>()..load(),
  child: const TransactionListScreen(),
)
```

---

## Dependency injection reference

All DI registrations are in `lib/config/di/`. The `@InjectableInit()` annotation on `configureDependencies()` triggers code generation.

| Annotation | Scope | Use case |
|-----------|-------|---------|
| `@singleton` | App lifetime, eager | Services initialized at startup |
| `@lazySingleton` | App lifetime, lazy | Services initialized on first use |
| `@injectable` | New instance per resolution | Cubits (one per screen) |
| `@LazySingleton(as: Interface)` | Lazy singleton bound to interface | Repository implementations |
| `@preResolve` | Resolved before `getIt.init()` returns | Async startup services (e.g. `IsarService`) |
| `@module` | Class containing factory methods | Manual registrations with constructor args |

Module files:

| Module | File | Registers |
|--------|------|-----------|
| `CoreModule` | `lib/config/di/core_module.dart` | `IsarService`, `SharedPreferences` |
| `TasksModule` | `lib/config/di/tasks_module.dart` | `ItemDao`, `ItemMapper` |
| `FinanceModule` | `lib/config/di/finance_module.dart` | Finance DAOs and mappers |
| `InfrastructureModule` | `lib/config/di/infrastructure_module.dart` | Infrastructure-level singletons |

---

## Error handling (`Result<T>` / `Failure`)

All domain and data operations that can fail return `Result<T>` — never throw.

```dart
// Returning a result
AsyncResult<List<Item>> getItems() async {
  try {
    final items = await _dao.getAll();
    return Success(items.map(_mapper.toDomain).toList());
  } catch (e) {
    return Err(DatabaseFailure(e.toString()));
  }
}

// Pattern matching at call sites (exhaustive — compiler enforced)
final result = await repository.getItems();
switch (result) {
  case Success(:final value): emit(TaskListLoaded(value));
  case Err(:final failure): emit(TaskListError(failure.message));
}
```

Failure subtypes:

| Subtype | Use case |
|---------|---------|
| `DatabaseFailure` | Isar read/write or transaction failure |
| `ValidationFailure` | Missing fields, value out of range |
| `NotificationFailure` | Notification scheduling or permission failure |
| `BackupFailure` | CSV/JSON export or import failure |
| `SecurityFailure` | PIN or biometric authentication failure |

Never display `failure.message` raw to users — map to localized strings at the presentation layer.

---

## Localization (ARB workflow)

Strings live in ARB files under `lib/config/l10n/`. PT-BR (`app_pt_BR.arb`) is the template locale.

```
lib/config/l10n/
├── app_pt_BR.arb   ← template (add new strings here first)
├── app_pt.arb
└── app_en.arb      ← translate after adding to template
```

To add a new string:

1. Add the key to `app_pt_BR.arb`:
   ```json
   "taskCreated": "Tarefa criada com sucesso",
   "@taskCreated": { "description": "Shown after a task is saved" }
   ```
2. Add the same key to `app_en.arb`:
   ```json
   "taskCreated": "Task created successfully"
   ```
3. Run `flutter gen-l10n` to regenerate `lib/generated/l10n/`.
4. Access in widgets via `AppLocalizations.of(context)!.taskCreated`.

Config is in `l10n.yaml` at the project root. Generated files are excluded from analysis.

---

## Linting

`very_good_analysis` 10.2.0 is the lint ruleset (strict). Two rules are overridden:

- `public_member_api_docs: false` — doc comments are not required on every public member
- `todo: ignore` — TODO comments do not produce warnings

Promoted errors: `missing_required_param`, `missing_return`.

Excluded from analysis: `lib/generated/**`, `lib/config/di/injection.config.dart`, `**/*.g.dart`.

```bash
flutter analyze --no-fatal-infos   # lint check
dart format .                       # auto-format
dart format --output=none --set-exit-if-changed .  # CI format check
```

---

## Phase-gated dependencies

Several packages are declared in `pubspec.yaml` but commented out, to be enabled in future phases:

| Package | Phase | Purpose |
|---------|-------|---------|
| `fl_chart` | 03 | Finance dashboard charts |
| `csv` | 04 | CSV export/import |
| `file_picker` | 04 | File selection for import |
| `flutter_local_notifications` | 04 | Task reminders |
| `flutter_timezone` + `timezone` | 04 | Notification scheduling |
| `flutter_screen_lock` | 05 | PIN lock screen UI |
| `flutter_secure_storage` | 05 | Secure PIN hash storage |
| `local_auth` | 05 | Biometric authentication |

Uncomment the relevant packages and run `flutter pub get` when the phase starts.
