import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Reminder-planning reads over [ItemModel].
///
/// These are deliberately NOT display-list reads. Every list query on
/// `ItemDao` applies `.limit(500)` with no `sortBy`; Isar returns unsorted
/// rows in id order, so that cap silently keeps the OLDEST 500 and drops the
/// rest (the BL-01 / CR-04 defect class, which already corrupted money totals
/// twice). A reminder or briefing count built on such a read would ignore
/// every task past row 500 without any error. The two functions below avoid
/// that: one sorts BEFORE it limits, the other does not limit at all.

/// Returns the [limit] soonest remindable items, ascending by due date.
///
/// Remindable means: not soft-deleted, not completed, not a project, with a
/// due date on or after [from] (inclusive).
///
/// The sort precedes the limit on purpose: the cap must keep the SOONEST rows,
/// not the lowest ids. Not for display lists.
Future<List<ItemModel>> findRemindableItems(
  IsarCollection<ItemModel> collection, {
  required DateTime from,
  required int limit,
}) =>
    collection
        .filter()
        .deletedAtIsNull()
        .and()
        .isCompletedEqualTo(false)
        .and()
        .not()
        .typeEqualTo(ItemType.project)
        .and()
        .dueDateIsNotNull()
        .and()
        .dueDateGreaterThan(from, include: true)
        .sortByDueDate()
        .limit(limit)
        .findAll();

/// Returns EVERY remindable item due in `[from, toExclusive)`, ascending by
/// due date, with no cap.
///
/// Uses the same four filters as [findRemindableItems]. There is intentionally
/// no `.limit` call: the briefing counts what is due in the window, and a
/// count that stops at 500 is wrong. Not for display lists.
Future<List<ItemModel>> findItemsDueInWindow(
  IsarCollection<ItemModel> collection, {
  required DateTime from,
  required DateTime toExclusive,
}) =>
    collection
        .filter()
        .deletedAtIsNull()
        .and()
        .isCompletedEqualTo(false)
        .and()
        .not()
        .typeEqualTo(ItemType.project)
        .and()
        .dueDateIsNotNull()
        .and()
        .dueDateBetween(from, toExclusive, includeUpper: false)
        .sortByDueDate()
        .findAll();
