// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AGENDA';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get privacyStatement => 'Your data never leaves this device.';

  @override
  String get emptyStateTitle => 'Nothing here yet';

  @override
  String get emptyStateAction => 'Tap to add';

  @override
  String get tasksScreenTitle => 'Tasks';

  @override
  String get noTasks => 'No tasks';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get undo => 'Undo';

  @override
  String get quadrantEmpty => 'Empty';

  @override
  String get slotLimitExceeded => 'Limit exceeded';

  @override
  String get slotLimitWarning => 'Slot limit exceeded';

  @override
  String get addTask => 'Add';

  @override
  String get bigTask => '1 Big Task';

  @override
  String get mediumTasks => '3 Medium Tasks';

  @override
  String get smallTasks => '5 Small Tasks';

  @override
  String get dayPlannerTitle => '1-3-5 Day Planner';

  @override
  String get eisenhowerTitle => 'Eisenhower Matrix';

  @override
  String get eisenhowerDoNow => 'Do Now';

  @override
  String get eisenhowerSchedule => 'Schedule';

  @override
  String get eisenhowerDelegate => 'Delegate';

  @override
  String get eisenhowerEliminate => 'Eliminate';

  @override
  String get taskFormTitleCreate => 'New Task';

  @override
  String get taskFormTitleEdit => 'Edit Task';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldTitleRequired => 'Title is required';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get fieldDueDate => 'Due date';

  @override
  String get fieldDueTime => 'Due time';

  @override
  String get noDueDate => 'No due date';

  @override
  String get noDueTime => 'No time';

  @override
  String get fieldUrgent => 'Urgent';

  @override
  String get fieldImportant => 'Important';

  @override
  String get fieldSize => 'Size';

  @override
  String get fieldNextAction => 'Next action';

  @override
  String get fieldGtdContext => 'GTD Context';

  @override
  String get fieldWaitingFor => 'Waiting for';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get saveButton => 'Save';

  @override
  String get projectScreenTitle => 'Project';

  @override
  String subtasksProgress(int completed, int total) {
    return '$completed/$total subtasks';
  }

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get subtaskTitleHint => 'Subtask title';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityCritical => 'Critical';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get sizeBig => 'Big';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeNone => 'None';

  @override
  String get typeTask => 'Task';

  @override
  String get typeProject => 'Project';

  @override
  String get searchTasks => 'Search tasks';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get noRecurrence => 'Does not repeat';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get gtdFilterTitle => 'GTD Filter';

  @override
  String get noGtdContexts => 'No GTD contexts found';

  @override
  String get applyFilter => 'Apply';

  @override
  String get clearFilter => 'Clear';
}
