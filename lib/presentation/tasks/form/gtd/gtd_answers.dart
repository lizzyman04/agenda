import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';

/// Answers accumulated while walking the GTD decision tree.
///
/// Deliberately mutable: the tree writes to it as the user answers, and the
/// sheet reads it to render the review step. Holding this outside the widget
/// keeps the tree free of `setState` and makes the whole flow unit-testable.
class GtdAnswers {
  DateTime? dueDate;
  Priority priority = Priority.medium;
  bool isUrgent = false;
  bool isImportant = false;
  String? waitingFor;
  String? gtdContext;
  String? description;

  /// Lowers a still-default priority without overriding an explicit choice
  /// made earlier in the tree.
  void demoteIfUnset() {
    if (priority == Priority.medium) priority = Priority.low;
  }

  /// Builds the value returned to the task form. [title] comes from the
  /// sheet's own controller rather than being stored here.
  GtdResult toResult(String title) => GtdResult(
        title: title,
        priority: priority,
        isUrgent: isUrgent,
        isImportant: isImportant,
        dueDate: dueDate,
        waitingFor: waitingFor,
        gtdContext: gtdContext,
        description: description,
      );

  /// Today at midnight — deadlines are date-only.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Best-effort GTD context guessed from the task title.
  ///
  /// Matches the PT-BR phrasings a user is likely to type; returns null when
  /// nothing matches, leaving the context unset rather than guessing wrong.
  static String? inferContext(String text) {
    final t = text.toLowerCase();
    if (t.contains('@casa') || t.contains('em casa')) return '@casa';
    if (t.contains('@trabalho') ||
        t.contains('@escritório') ||
        t.contains('no trabalho')) {
      return '@trabalho';
    }
    if (t.contains('@computador') || t.contains('@pc')) return '@computador';
    if (t.contains('@telefone') || t.contains('ligar para')) return '@telefone';
    if (t.contains('@compras') || t.contains('comprar')) return '@compras';
    return null;
  }

  /// PT-BR display label for the chosen priority.
  String get priorityLabel => switch (priority) {
        Priority.urgent => 'Urgente',
        Priority.critical => 'Crítica',
        Priority.high => 'Alta',
        Priority.medium => 'Média',
        Priority.low => 'Baixa',
      };
}
