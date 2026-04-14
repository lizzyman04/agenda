import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_dao.dart';
import 'package:agenda/data/tasks/item_mapper.dart';
import 'package:injectable/injectable.dart';

/// DI registrations for the Task domain.
///
/// ItemRepositoryImpl and RecurrenceEngineImpl are registered via their
/// @LazySingleton(as: ...) annotations — injectable_generator picks them up.
/// This module registers ItemDao and ItemMapper which have no annotations.
@module
abstract class TasksModule {
  /// Registers [ItemDao] as a lazy singleton.
  ///
  /// IsarService is injected from CoreModule — always resolved before this.
  @lazySingleton
  ItemDao itemDao(IsarService isarService) => ItemDao(isarService);

  /// Registers [ItemMapper] as a lazy singleton.
  ///
  /// Pure converter — no dependencies.
  @lazySingleton
  ItemMapper get itemMapper => const ItemMapper();
}
