import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/goal/goal_mapper.dart';
import 'package:agenda/data/finance/goal/savings_goal_dao.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:agenda/infrastructure/finance/goal_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSavingsGoalDao extends Mock implements SavingsGoalDao {}

class FakeSavingsGoalModel extends Fake implements SavingsGoalModel {}

/// Builds a model whose `contributions` is FIXED-LENGTH, exactly as Isar's
/// generated deserializer produces it. `SavingsGoalModel`'s field initializer
/// is growable, but `readObjectList`'s result is assigned over it on every
/// read — so any model coming back from `findById` behaves like this one.
SavingsGoalModel _loadedModel({List<GoalContribution> existing = const []}) {
  return SavingsGoalModel()
    ..id = 1
    ..title = 'Fundo Emergencia'
    ..targetAmountCents = 100000
    ..contributions = List<GoalContribution>.unmodifiable(existing)
    ..isCompleted = false
    ..createdAt = DateTime(2026)
    ..updatedAt = DateTime(2026);
}

GoalContribution _existing() => GoalContribution()
  ..amountCents = 5000
  ..date = DateTime(2026, 2)
  ..note = 'primeira';

void main() {
  setUpAll(() => registerFallbackValue(FakeSavingsGoalModel()));

  late MockSavingsGoalDao dao;
  late GoalRepositoryImpl repo;

  setUp(() {
    dao = MockSavingsGoalDao();
    repo = GoalRepositoryImpl(dao, const GoalMapper());
    when(() => dao.save(any())).thenAnswer((_) async => 1);
  });

  test('appends to a fixed-length contributions list without throwing',
      () async {
    // findById returns the fixed-length model; save echoes whatever was built.
    var stored = _loadedModel();
    when(() => dao.findById(1)).thenAnswer((_) async => stored);
    when(() => dao.save(any())).thenAnswer((invocation) async {
      stored = invocation.positionalArguments.first as SavingsGoalModel;
      return 1;
    });

    final result = await repo.addContribution(
      1,
      SavingsGoalContribution(amountCents: 25000, date: DateTime(2026, 8, 11)),
    );

    // Before the fix this returned Err(DatabaseFailure('addContribution
    // failed: Unsupported operation: Cannot add to a fixed-length list')).
    expect(result, isA<Success<SavingsGoal>>());
    expect(stored.contributions, hasLength(1));
    expect(stored.contributions.single.amountCents, 25000);
  });

  test('preserves existing contributions when appending', () async {
    var stored = _loadedModel(existing: [_existing()]);
    when(() => dao.findById(1)).thenAnswer((_) async => stored);
    when(() => dao.save(any())).thenAnswer((invocation) async {
      stored = invocation.positionalArguments.first as SavingsGoalModel;
      return 1;
    });

    final result = await repo.addContribution(
      1,
      SavingsGoalContribution(amountCents: 25000, date: DateTime(2026, 8, 11)),
    );

    expect(result, isA<Success<SavingsGoal>>());
    expect(stored.contributions, hasLength(2));
    expect(
      stored.contributions.map((c) => c.amountCents),
      containsAllInOrder(<int>[5000, 25000]),
    );
  });

  test('rejects a non-positive amount before touching the dao', () async {
    when(() => dao.findById(1)).thenAnswer((_) async => _loadedModel());

    final result = await repo.addContribution(
      1,
      SavingsGoalContribution(amountCents: 0, date: DateTime(2026, 8, 11)),
    );

    expect(result, isA<Err<SavingsGoal>>());
    verifyNever(() => dao.save(any()));
  });
}
