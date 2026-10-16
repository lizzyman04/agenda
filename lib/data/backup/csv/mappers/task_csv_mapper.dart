import 'package:agenda/data/backup/csv/csv_amount.dart';
import 'package:agenda/data/backup/csv/csv_format.dart';
import 'package:agenda/data/backup/csv/csv_row_reader.dart';
import 'package:agenda/data/backup/csv/csv_text_guard.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Encodes and decodes [ItemModel] rows (projects, tasks, subtasks) for
/// `tasks.csv`, including the embedded time and money info.
final class TaskCsvMapper {
  const TaskCsvMapper();

  static const String fileStem = 'tasks';

  /// Columns that must all be present for a file to be read as tasks.
  static const Set<String> signature = {'title', 'type'};

  static const List<String> header = [
    'id',
    'type',
    'title',
    'description',
    'parent_id',
    'priority',
    'is_urgent',
    'is_important',
    'size',
    'is_next_action',
    'gtd_context',
    'waiting_for',
    'is_completed',
    'completed_at',
    'due_date',
    'due_time_minutes',
    'recurrence_rule',
    'money_amount',
    'money_currency',
    'linked_goal_id',
    'linked_debt_id',
    'created_at',
    'updated_at',
  ];

  static String _text(String? s) => guardCsvText(s ?? '');

  List<Object?> toRow(ItemModel m, CsvContext ctx) {
    final amount = m.moneyInfo?.amount;
    return [
      m.id,
      m.type.name,
      _text(m.title),
      _text(m.description),
      m.parentId,
      m.priority.name,
      m.isUrgent,
      m.isImportant,
      m.sizeCategory.name,
      m.isNextAction,
      _text(m.gtdContext),
      _text(m.waitingFor),
      m.isCompleted,
      formatCsvDateOrEmpty(m.completedAt),
      formatCsvDateOrEmpty(m.dueDate),
      m.timeInfo?.dueTimeMinutes,
      _text(m.timeInfo?.recurrenceRule),
      if (amount == null)
        ''
      else
        formatAmountCell((amount * 100).round(), ctx.dialect.decimalSeparator),
      _text(m.moneyInfo?.currencyCode),
      m.linkedGoalId,
      m.linkedDebtId,
      formatCsvDate(m.createdAt),
      formatCsvDate(m.updatedAt),
    ];
  }

  ParsedCsvRow<ItemModel> fromRow(CsvRowReader r, {required DateTime now}) {
    final minutes = r.optInt('due_time_minutes');
    final rule = r.optText('recurrence_rule');
    final cents = r.amountCents(null, 'money_amount');
    final currency = r.optText('money_currency');
    final model =
        ItemModel()
          ..id = r.optInt('id') ?? Isar.autoIncrement
          ..type = r.enumByName('type', ItemType.values)
          ..title = r.requireText('title')
          ..description = r.optText('description')
          ..parentId = r.optInt('parent_id')
          ..priority = r.enumByName(
            'priority',
            Priority.values,
            fallback: Priority.medium,
          )
          ..isUrgent = r.boolOr('is_urgent', fallback: false)
          ..isImportant = r.boolOr('is_important', fallback: false)
          ..sizeCategory = r.enumByName(
            'size',
            SizeCategory.values,
            fallback: SizeCategory.none,
          )
          ..isNextAction = r.boolOr('is_next_action', fallback: false)
          ..gtdContext = r.optText('gtd_context')
          ..waitingFor = r.optText('waiting_for')
          ..isCompleted = r.boolOr('is_completed', fallback: false)
          ..completedAt = r.optDate('completed_at')
          ..dueDate = r.optDate('due_date')
          ..timeInfo =
              minutes == null && rule == null
                  ? null
                  : TimeInfo(dueTimeMinutes: minutes, recurrenceRule: rule)
          ..moneyInfo =
              cents == null && currency == null
                  ? null
                  : MoneyInfo(
                    amount: cents == null ? null : cents / 100,
                    currencyCode: currency,
                  )
          ..linkedGoalId = r.optInt('linked_goal_id')
          ..linkedDebtId = r.optInt('linked_debt_id')
          ..createdAt = r.optDate('created_at') ?? now
          ..updatedAt = r.optDate('updated_at') ?? now;
    return ParsedCsvRow(model: model, rowNumber: r.rowNumber);
  }
}
