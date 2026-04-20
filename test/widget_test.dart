import 'package:agenda/app.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub repository that never touches Isar.
///
/// Used in widget tests so the full app shell can render without requiring
/// the native Isar binary (libisar.so) which is unavailable in VM test mode.
class _StubItemRepository implements ItemRepository {
  @override
  AsyncResult<Item> createItem(Item item) async =>
      Success(item.copyWith(id: 1));

  @override
  AsyncResult<Item> getItem(int id) async =>
      Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Item>> getItemsByType(ItemType type) async =>
      const Success([]);

  @override
  AsyncResult<List<Item>> getSubtasks(int projectId) async =>
      const Success([]);

  @override
  AsyncResult<Item> updateItem(Item item) async => Success(item);

  @override
  AsyncResult<Item> softDelete(int id) async =>
      Err(DatabaseFailure('stub'));

  @override
  AsyncResult<Item> restoreItem(int id) async =>
      Err(DatabaseFailure('stub'));

  @override
  AsyncResult<List<Item>> searchByTitle(String query) async =>
      const Success([]);

  @override
  AsyncResult<List<Item>> filterItems({
    ItemType? type,
    EisenhowerQuadrant? quadrant,
    String? gtdContext,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? parentId,
    bool showCompleted = false,
  }) async =>
      const Success([]);

  @override
  AsyncResult<(int, int)> getSubtaskCounts(int projectId) async =>
      const Success((0, 0));

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  AsyncResult<List<String>> getDistinctGtdContexts() async =>
      const Success([]);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    // Replace the real Isar-backed repository with a stub so the widget tree
    // can render without the native libisar.so binary (unavailable in VM tests).
    getIt.unregister<ItemRepository>();
    getIt.registerLazySingleton<ItemRepository>(() => _StubItemRepository());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('App renders bottom navigation shell', (tester) async {
    await tester.pumpWidget(const AgendaApp());
    // The Phase 2 home shell replaced the old single-screen layout.
    // Verify the bottom NavigationBar is present.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
