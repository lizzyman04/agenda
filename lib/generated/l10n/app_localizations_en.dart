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

  @override
  String get navTasks => 'Tasks';

  @override
  String get navEisenhower => 'Matrix';

  @override
  String get navDayPlanner => 'Planner';

  @override
  String get navGtd => 'GTD';

  @override
  String get advancedOptions => 'Advanced options';

  @override
  String get gtdGuide => 'GTD Guide';

  @override
  String get gtdQ1 => 'What needs to be done?';

  @override
  String get gtdQ2 => 'Does this task really need to be done?';

  @override
  String get gtdQ2bQuestion => 'Why do you want to add it anyway?';

  @override
  String get gtdQ2bSomedayMaybe => 'It\'s a future reminder (Someday/Maybe)';

  @override
  String get gtdQ2bIdea => 'It\'s an idea I don\'t want to forget';

  @override
  String get gtdQ2bDelegated =>
      'Someone asked me, but it\'s not my responsibility';

  @override
  String get gtdQ2bKeepAnyway => 'I want to add it anyway';

  @override
  String get gtdQ3 => 'Can someone else do this task for you?';

  @override
  String get gtdQ3DelegateTo => 'Who will you delegate this to?';

  @override
  String get gtdQ3DelegateHint => 'Person\'s name';

  @override
  String get gtdQ3FollowUp =>
      'Do you want a reminder to follow up with this person?';

  @override
  String get gtdQ4 => 'Can this task be done in under 10 minutes?';

  @override
  String get gtdQ4bQuestion => 'Why not do it now?';

  @override
  String get gtdQ4bBusy => 'I\'m busy right now';

  @override
  String get gtdQ4bNeedContext => 'I need more context or information';

  @override
  String get gtdQ4bNotRightTime => 'It\'s not the right time';

  @override
  String get gtdQ4bDoItNow => 'You\'re right, I\'ll do it now';

  @override
  String get gtdQ4bOther => 'Other reason';

  @override
  String get gtdQ5 => 'Is this task important for your goals and projects?';

  @override
  String get gtdQ5bQuestion => 'Why do you want to keep it?';

  @override
  String get gtdQ5bObligation => 'It\'s an obligation or boring task';

  @override
  String get gtdQ5bSomeoneAsking => 'Someone is pushing me to do it';

  @override
  String get gtdQ5bReminder => 'I just don\'t want to forget';

  @override
  String get gtdQ5bCancelTask => 'Cancel task';

  @override
  String get gtdQ5bOther => 'Other reason';

  @override
  String get gtdQ6 => 'What\'s the deadline for completing this task?';

  @override
  String get gtdDeadlineNext20Days => 'Next 20 days';

  @override
  String get gtdQ6bQuestion => 'Why no deadline?';

  @override
  String get gtdQ6bHabit => 'It\'s a habit or ongoing activity';

  @override
  String get gtdQ6bNotUrgent => 'Not urgent, but I need a reminder';

  @override
  String get gtdQ6bWhenever => 'Whenever I get the chance';

  @override
  String get gtdQ6bOther => 'Other reason';

  @override
  String get gtdQ7 => 'What\'s the impact if this task isn\'t completed?';

  @override
  String get gtdImpactVeryNegative =>
      'Very negative — everything depends on this';

  @override
  String get gtdImpactNegative => 'Negative — important goals compromised';

  @override
  String get gtdImpactModerate => 'Moderate — some goals affected';

  @override
  String get gtdImpactLight => 'Light — few goals affected';

  @override
  String get gtdImpactVeryLight => 'Very light — minimal delays';

  @override
  String get gtdQ7bQuestion => 'Why keep the task?';

  @override
  String get gtdQ7bPersonalWish => 'It\'s a personal wish';

  @override
  String get gtdQ7bSomeoneExpects => 'Someone expects me to do it';

  @override
  String get gtdQ7bCancelTask => 'Cancel task';

  @override
  String get gtdQ7bOther => 'Other reason';

  @override
  String get gtdReviewTitle => 'Task summary';

  @override
  String get gtdReviewDeadlineLabel => 'Deadline';

  @override
  String get gtdReviewPriorityLabel => 'Priority';

  @override
  String get gtdReviewImportantLabel => 'Important';

  @override
  String get gtdReviewUrgentLabel => 'Urgent';

  @override
  String get gtdReviewDelegatedLabel => 'Delegated to';

  @override
  String get gtdReviewEdit => 'Back to edit';

  @override
  String get gtdReviewSave => 'Save task';

  @override
  String get gtdCancelTitle => 'Cancel guide?';

  @override
  String get gtdCancelMessage => 'Your progress will be lost.';

  @override
  String get gtdCancelContinue => 'Keep going';

  @override
  String get gtdCancelDiscard => 'Discard';

  @override
  String get gtdSomedayMessage => 'Saved as Someday/Maybe.';

  @override
  String get gtdIdeaSavedMessage => 'Saved as an idea.';

  @override
  String get gtdDoItNowMessage => 'Do it now! Under 10 minutes — just do it. ✅';

  @override
  String get gtdAnswerYes => 'Yes';

  @override
  String get gtdAnswerNo => 'No';

  @override
  String get gtdSkip => 'Skip';

  @override
  String get gtdDiscardMessage =>
      'Parked in Someday/Maybe. Come back to it later.';

  @override
  String get gtdDelegateMessage =>
      'Delegated. A \'Waiting For\' note has been added.';

  @override
  String get gtdDeadlineToday => 'Today';

  @override
  String get gtdDeadlineTomorrow => 'Tomorrow';

  @override
  String get gtdDeadlineThisWeek => 'This week';

  @override
  String get gtdDeadlineThisMonth => 'This month';

  @override
  String get gtdDeadlineNoDeadline => 'No deadline';

  @override
  String get gtdDeadlineCustom => 'Custom date';

  @override
  String get gtdImpactCritical => 'Critical — everything depends on it';

  @override
  String get gtdImpactHigh => 'High — major consequences';

  @override
  String get gtdImpactMedium => 'Medium — noticeable consequences';

  @override
  String get gtdImpactLow => 'Low — minor consequences';

  @override
  String get gtdImpactNone => 'None — can be dropped';

  @override
  String get gtdQ3Hint => 'e.g. Send email, Call back, Draft report';

  @override
  String get gtdQ8 => 'What context does this task belong to?';

  @override
  String get gtdQ8Hint => '@home, @computer, @office';

  @override
  String get filterApplied => 'Filter applied';

  @override
  String get taskDetailTitle => 'Task';

  @override
  String get editButton => 'Edit';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete task?';

  @override
  String get deleteConfirmBody =>
      'The task will be removed. You\'ll have a few seconds to undo.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get labelStatus => 'Status';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Pending';
}
