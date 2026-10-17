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

  @override
  String get financeTabLabel => 'Finance';

  @override
  String get dashboardTabLabel => 'Summary';

  @override
  String get transactionsTabLabel => 'Transactions';

  @override
  String get budgetsTabLabel => 'Budgets';

  @override
  String get goalsTabLabel => 'Goals';

  @override
  String get debtsTabLabel => 'Debts';

  @override
  String get recurringTabLabel => 'Recurring';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get addGoal => 'Create goal';

  @override
  String get addDebt => 'Add debt';

  @override
  String get addRecurring => 'Add payment';

  @override
  String get addContribution => 'Add contribution';

  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get saveGoal => 'Save goal';

  @override
  String get saveDebt => 'Save debt';

  @override
  String get saveRecurringPayment => 'Save payment';

  @override
  String get setBudgetLimit => 'Set limit';

  @override
  String get emptyTransactions => 'No transactions';

  @override
  String get emptyTransactionsBody => 'Log your first income or expense.';

  @override
  String get emptyBudgets => 'No budgets';

  @override
  String get emptyBudgetsBody => 'Set a monthly limit per category.';

  @override
  String get emptyGoals => 'No goals';

  @override
  String get emptyGoalsBody => 'Create your first savings goal.';

  @override
  String get emptyDebts => 'No debts';

  @override
  String get emptyDebtsBody => 'Log amounts to pay or receive.';

  @override
  String get emptyRecurring => 'No recurring payments';

  @override
  String get emptyRecurringBody => 'Add subscriptions and fixed bills.';

  @override
  String get emptyDashboard => 'No financial data';

  @override
  String get emptyDashboardBody => 'Add transactions to see your summary.';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get netWorth => 'Net worth';

  @override
  String noExpensesInMonth(String month) {
    return 'No expenses in $month';
  }

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get errorLoadFailed => 'Could not load data. Please try again.';

  @override
  String get errorSaveFailed =>
      'Could not save. Check the fields and try again.';

  @override
  String get errorAmountRequired => 'Enter an amount greater than zero.';

  @override
  String get errorTitleRequired => 'Title is required.';

  @override
  String get errorCategoryRequired => 'Select a category.';

  @override
  String get fieldNote => 'Note';

  @override
  String get fieldCategory => 'Category';

  @override
  String get noLimitSet => 'No limit set';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get debtDeleted => 'Debt deleted';

  @override
  String get recurringActive => 'Active';

  @override
  String get recurringPaused => 'Paused';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get deleteGoal => 'Delete goal';

  @override
  String get toPay => 'To pay';

  @override
  String get toReceive => 'To receive';

  @override
  String get linkToFinance => 'Link to...';

  @override
  String get linkedTo => 'Linked to';

  @override
  String get categoryAlimentacao => 'Food';

  @override
  String get categoryTransporte => 'Transport';

  @override
  String get categoryMoradia => 'Housing';

  @override
  String get categorySaude => 'Health';

  @override
  String get categoryEducacao => 'Education';

  @override
  String get categoryLazer => 'Leisure';

  @override
  String get categoryRoupas => 'Clothes';

  @override
  String get categoryTecnologia => 'Technology';

  @override
  String get categoryOutros => 'Other';

  @override
  String get categorySalario => 'Salary';

  @override
  String get categoryFreelance => 'Freelance';

  @override
  String get categoryInvestimentos => 'Investments';

  @override
  String get notifChannelTasksName => 'Task reminders';

  @override
  String get notifChannelTasksDesc => 'Reminders shortly before a task is due';

  @override
  String get notifChannelRecurringName => 'Recurring task reminders';

  @override
  String get notifChannelRecurringDesc => 'Reminders for tasks that repeat';

  @override
  String get notifChannelBriefingName => 'Morning briefing';

  @override
  String get notifChannelBriefingDesc => 'A summary of the tasks due today';

  @override
  String get notifChannelBudgetName => 'Budget alerts';

  @override
  String get notifChannelBudgetDesc =>
      'Alerts when spending reaches 80% and 100% of a budget';

  @override
  String get notifChannelDebtsName => 'Debt reminders';

  @override
  String get notifChannelDebtsDesc => 'A reminder the day before a debt is due';

  @override
  String get notifChannelGoalsName => 'Goal alerts';

  @override
  String get notifChannelGoalsDesc =>
      'Alerts when a savings goal falls behind schedule';

  @override
  String get notifChannelPaymentsName => 'Bills and subscriptions';

  @override
  String get notifChannelPaymentsDesc =>
      'A reminder the day before a recurring payment';

  @override
  String get notifChannelQuotesName => 'Motivational quotes';

  @override
  String get notifChannelQuotesDesc => 'An occasional motivational quote';

  @override
  String get notifTaskReminderTitle => 'Task due soon';

  @override
  String notifTaskReminderBody(String title, String time) {
    return '$title is due at $time';
  }

  @override
  String notifTaskDueTodayBody(String title) {
    return '$title is due today';
  }

  @override
  String get notifRecurringTaskTitle => 'Recurring task due soon';

  @override
  String notifBriefingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks due today',
      one: '$count task due today',
    );
    return '$_temp0';
  }

  @override
  String notifBriefingBody(String titles) {
    return '$titles';
  }

  @override
  String notifBriefingBodyMore(String titles, int remaining) {
    return '$titles and $remaining more';
  }

  @override
  String notifBudget80Title(String category) {
    return '$category: 80% of the budget used';
  }

  @override
  String get notifBudget80Body => 'You have used 80% of this month\'s limit.';

  @override
  String notifBudget100Title(String category) {
    return '$category: budget limit reached';
  }

  @override
  String get notifBudget100Body => 'You have reached this month\'s limit.';

  @override
  String get notifDebtDueTitle => 'Payment due tomorrow';

  @override
  String get notifDebtReceiveTitle => 'Money to receive tomorrow';

  @override
  String notifDebtBody(String title) {
    return '$title';
  }

  @override
  String get notifGoalOffTrackTitle => 'Goal falling behind';

  @override
  String notifGoalOffTrackBody(String title) {
    return '$title is behind schedule. A small contribution can help.';
  }

  @override
  String get notifPaymentDueTitle => 'Bill due tomorrow';

  @override
  String notifPaymentBody(String title) {
    return '$title';
  }

  @override
  String get notifQuoteTitle => 'Daily motivation';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String get notifSettingsTypesHeader => 'Notification types';

  @override
  String get notifSettingsBriefingTime => 'Briefing time';

  @override
  String get notifSettingsQuotesHeader => 'Motivational quotes';

  @override
  String get notifSettingsQuotesOffHint =>
      'Turn on motivational quotes to choose how often they arrive.';

  @override
  String get notifSettingsQuoteFrequency => 'Frequency';

  @override
  String get notifSettingsQuoteDaily => 'Daily';

  @override
  String get notifSettingsQuoteWeekly => 'Weekly (Mondays)';

  @override
  String get notifSettingsQuoteTime => 'Quote time';

  @override
  String get notifSettingsQuietHeader => 'Quiet hours';

  @override
  String get notifSettingsQuietEnabled =>
      'Hold notifications during quiet hours';

  @override
  String get notifSettingsQuietDesc =>
      'Anything scheduled inside this window is delivered when it ends.';

  @override
  String get notifSettingsQuietStart => 'From';

  @override
  String get notifSettingsQuietEnd => 'Until';

  @override
  String get notifSettingsPermissionDeniedTitle =>
      'Notifications are turned off';

  @override
  String get notifSettingsPermissionDeniedBody =>
      'Allow notifications for AGENDA in your device settings to receive reminders.';

  @override
  String get notifSettingsAllowButton => 'Allow notifications';

  @override
  String get notifSettingsOpenSettingsButton => 'Open settings';

  @override
  String get notifSettingsExactTitle => 'Exact reminder times';

  @override
  String get notifSettingsExactBody =>
      'Android may delay reminders unless exact alarms are allowed.';

  @override
  String get notifSettingsExactButton => 'Allow exact alarms';

  @override
  String notifSettingsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders are waiting for a free slot',
      one: '$count reminder is waiting for a free slot',
    );
    return '$_temp0';
  }

  @override
  String get notifSettingsPrivacyNote =>
      'Reminders are scheduled on this device only. Nothing is sent anywhere.';

  @override
  String get backupMenuLabel => 'Backup and restore';

  @override
  String get backupScreenTitle => 'Backup and restore';

  @override
  String get backupExportHeader => 'Export';

  @override
  String get backupExportJson => 'Export full backup (JSON)';

  @override
  String get backupExportJsonDesc =>
      'One file with every task, transaction, budget, goal, debt and recurring payment.';

  @override
  String get backupExportCsv => 'Export spreadsheets (CSV)';

  @override
  String get backupExportCsvDesc =>
      'One CSV file per type of data, readable in any spreadsheet app.';

  @override
  String get backupExportSaveTitle => 'Save backup';

  @override
  String get backupExportDone => 'Backup saved.';

  @override
  String backupExportCsvDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files saved.',
      one: '$count file saved.',
    );
    return '$_temp0';
  }

  @override
  String get backupExportCancelled => 'Export cancelled.';

  @override
  String get backupImportHeader => 'Import';

  @override
  String get backupImportAction => 'Import a backup file';

  @override
  String get backupImportDesc =>
      'Choose a JSON backup, or one or more CSV files. A safety backup of your current data is created first.';

  @override
  String get backupPrivacyNote =>
      'Backups are not encrypted. Keep them somewhere safe. AGENDA never uploads your data.';

  @override
  String get backupReinstallNote =>
      'Cloud backup is turned off for AGENDA: Android Auto Backup and iCloud backup on iOS. After reinstalling, restore from an exported JSON file.';

  @override
  String get backupSafetyHeader => 'Safety backups';

  @override
  String get backupSafetyDesc =>
      'Before each import AGENDA keeps a private copy of your current data (the newest 3). Save a copy to a place you choose, or delete them.';

  @override
  String backupSafetyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count safety backups',
      one: '$count safety backup',
      zero: 'No safety backups',
    );
    return '$_temp0';
  }

  @override
  String get backupSafetySaveButton => 'Save latest copy';

  @override
  String get backupSafetyDeleteButton => 'Delete all';

  @override
  String get backupSafetyDeleteTitle => 'Delete safety backups?';

  @override
  String get backupSafetyDeleteBody =>
      'These private copies will be removed for good. Your current data is not affected.';

  @override
  String get backupSafetySaved => 'Safety backup saved.';

  @override
  String get backupSafetyNone => 'There is no safety backup yet.';

  @override
  String get backupSafetyDeleted => 'Safety backups deleted.';

  @override
  String get backupSafetyFailed =>
      'Could not finish. Your data was not changed.';

  @override
  String get backupWorking => 'Working…';

  @override
  String get backupConfirmTitle => 'Confirm import';

  @override
  String get backupConfirmWarning =>
      'This replaces the data listed below. A safety backup is created first.';

  @override
  String get backupConfirmPartial =>
      'Only the types of data present in your files are replaced. Everything else is kept.';

  @override
  String backupConfirmDateRange(String from, String to) {
    return 'Records from $from to $to';
  }

  @override
  String backupConfirmExportedAt(String date) {
    return 'Exported on $date';
  }

  @override
  String backupConfirmDeletedIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Includes $count deleted records.',
      one: 'Includes $count deleted record.',
    );
    return '$_temp0';
  }

  @override
  String get backupConfirmWarningsTitle => 'Warnings';

  @override
  String backupWarnDanglingLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records point to data that is not in the file.',
      one: '$count record points to data that is not in the file.',
    );
    return '$_temp0';
  }

  @override
  String get backupConfirmButton => 'Replace my data';

  @override
  String backupCountLine(String label, int count) {
    return '$label: $count';
  }

  @override
  String get backupEntityTasks => 'Tasks';

  @override
  String get backupEntityTransactions => 'Transactions';

  @override
  String get backupEntityCategories => 'Categories';

  @override
  String get backupEntityBudgets => 'Budgets';

  @override
  String get backupEntityGoals => 'Goals';

  @override
  String get backupEntityDebts => 'Debts';

  @override
  String get backupEntityPayments => 'Recurring payments';

  @override
  String get backupImportDone => 'Import complete.';

  @override
  String backupImportDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records imported.',
      one: '$count record imported.',
    );
    return '$_temp0';
  }

  @override
  String get backupErrorUnsupported =>
      'This file is not a valid AGENDA backup.';

  @override
  String get backupErrorTooLarge => 'This selection is too large to import.';

  @override
  String get backupErrorNewerVersion =>
      'This backup was created by a newer version of AGENDA.';

  @override
  String get backupErrorMixed =>
      'Choose either one JSON backup or CSV files, not both.';

  @override
  String get backupErrorDuplicate =>
      'Two of the selected files contain the same type of data.';

  @override
  String get backupErrorGeneric =>
      'Something went wrong. Your data was not changed.';

  @override
  String backupErrorImportFailed(String path) {
    return 'Import failed. Your data is unchanged. Safety backup: $path';
  }
}
