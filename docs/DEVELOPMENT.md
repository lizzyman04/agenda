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
| Format | `dart format <files you touched>` |
| Tests | `flutter test --no-pub` |
| Architecture guard | `dart run tool/check_architecture.dart` |

Run code generation after any change to `@Collection`, `@embedded`, `@injectable`, `@singleton`, or `@module` annotated code.

---

## House rules (enforced in CI)

`dart run tool/check_architecture.dart` checks the hand-written `lib/` tree, and CI runs it right after the Analyze step:

- **150-line cap** — no hand-written file exceeds 150 lines. Generated files are exempt, and one documented exemption exists in `tool/architecture_exemptions.dart`.
- **At most 10 hand-written files per directory** — nest by domain instead of growing a flat folder.
- **A `README.md` in every directory** under `lib/presentation/` and `lib/application/`, stating its responsibility and contents.

Worked example of a compliant slice: [`lib/presentation/finance/goals/README.md`](../lib/presentation/finance/goals/README.md). More detail in [ARCHITECTURE.md](ARCHITECTURE.md).

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

Generated code is committed to the repository (`lib/generated/l10n`, every `.g.dart`, `lib/config/di/injection.config.dart`) and excluded from analysis only (`analysis_options.yaml`) — never edit it manually. Commit the regenerated output together with the change that caused it.

---

## Adding a new feature (layered architecture)

The architecture has five layers: **domain → data → infrastructure → application → presentation**. Always implement top-down. Mirror an existing slice and follow the house rules above. The paths below are the real transactions slice.

### 1. Domain layer (`lib/domain/finance/transaction/`)

Define the entity and repository interface:

```dart
// lib/domain/finance/transaction/transaction.dart
class Transaction {
  const Transaction({required this.id, required this.amountCents, ...});
  final int id;
  final int amountCents; // money is stored as integer cents
  // ...
}

// lib/domain/finance/transaction/transaction_repository.dart
abstract class TransactionRepository {
  AsyncResult<Transaction> createTransaction(Transaction transaction);
  AsyncResult<List<Transaction>> getTransactions();
  // ...
}
```

### 2. Data layer (`lib/data/finance/transaction/`)

Define the Isar model with `@Collection`, then run `build_runner`. Add a DAO (`transaction_dao.dart`) for read/write operations using `IsarService`, and a mapper (`transaction_mapper.dart`) between model and domain entity:

```dart
// lib/data/finance/transaction/transaction_model.dart
import 'package:isar_community/isar.dart';
part 'transaction_model.g.dart';

@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;
  late int amountCents;
  // ...
}
```

A new collection also needs a schema version bump and a `MigrationRunner` case (see [CONFIGURATION.md](CONFIGURATION.md)).

### 3. Infrastructure layer (`lib/infrastructure/finance/`)

Implement the repository interface with the `@LazySingleton(as: ...)` annotation. Finance implementations sit flat in `lib/infrastructure/finance/`:

```dart
// lib/infrastructure/finance/transaction_repository_impl.dart
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dao, this._mapper);
  final TransactionDao _dao;
  final TransactionMapper _mapper;
  // every method wraps the DAO call in try/catch and returns Result<T>
}
```

Register the DAO and mapper in the matching DI module (`lib/config/di/finance_module.dart`).

### 4. Application layer (`lib/application/finance/transaction/`)

Create a Cubit with `@injectable` (`TransactionCubit` and its state classes):

```dart
// lib/application/finance/transaction/transaction_cubit.dart
@injectable
class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._repository, this._categoryRepository)
      : super(const TransactionInitial());
  // ...
}
```

Add a `README.md` to every new directory under `lib/application/`.

### 5. Presentation layer (`lib/presentation/finance/`)

Screens live in `screens/`, reusable widgets in `widgets/`. Finance cubits are provided above `MaterialApp` in `lib/app.dart`; a screen that owns a cubit creates it with `BlocProvider(create: (_) => getIt<SomeCubit>())`. Add a `README.md` to every new directory under `lib/presentation/`.

---

## Dependency injection reference

All DI registrations are in `lib/config/di/`. The `@InjectableInit()` annotation on `configureDependencies()` triggers code generation.

| Annotation | Scope | Use case |
|-----------|-------|---------|
| `@singleton` | App lifetime, eager | Services initialized at startup |
| `@lazySingleton` | App lifetime, lazy | Services initialized on first use |
| `@injectable` | New instance per resolution | Cubits (one per screen) |
| `@LazySingleton(as: Interface)` | Lazy singleton bound to interface | Repository implementations |
| `@preResolve` | Resolved before `getIt.init()` returns | Async startup services (e.g. `SharedPreferences`) |
| `@module` | Class containing factory methods | Manual registrations with constructor args |

Module files:

| Module | File | Registers |
|--------|------|-----------|
| `CoreModule` | `lib/config/di/core_module.dart` | `IsarService`, `SharedPreferences` |
| `TasksModule` | `lib/config/di/tasks_module.dart` | `ItemDao`, `ItemMapper` |
| `FinanceModule` | `lib/config/di/finance_module.dart` | Finance DAOs and mappers |
| `InfrastructureModule` | `lib/config/di/infrastructure_module.dart` | Empty placeholder until Phases 4-5 |

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
4. Access in widgets via `AppLocalizations.of(context).taskCreated`.

Config is in `l10n.yaml` at the project root. The generated output is committed and excluded from analysis only.

---

## Linting

`very_good_analysis` 10.2.0 is the lint ruleset (strict). Two rules are overridden:

- `public_member_api_docs: false` — doc comments are not required on every public member
- `todo: ignore` — TODO comments do not produce warnings

Promoted errors: `missing_required_param`, `missing_return`.

Excluded from analysis (not from git): `lib/generated/**`, `lib/config/di/injection.config.dart`, `**/*.g.dart`.

```bash
flutter analyze --no-fatal-infos   # lint check
dart format <files you touched>     # auto-format
```

Formatting is not enforced in CI, because the tree is not uniformly format-clean — format only the files you touch.

---

## Phase-gated dependencies

Several packages are declared in `pubspec.yaml` but commented out, to be enabled in future phases (the finance charting package is already active):

| Package | Phase | Purpose |
|---------|-------|---------|
| `csv` | 04 | CSV export/import |
| `file_picker` | 04 | File selection for import |
| `flutter_local_notifications` | 04 | Task reminders |
| `flutter_timezone` + `timezone` | 04 | Notification scheduling |
| `flutter_screen_lock` | 05 | PIN lock screen UI |
| `flutter_secure_storage` | 05 | Secure PIN hash storage |
| `local_auth` | 05 | Biometric authentication |

Uncomment the relevant packages and run `flutter pub get` when the phase starts.
