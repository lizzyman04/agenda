/// The entities a backup can carry, as the UI and import preview name them.
enum BackupEntity {
  tasks('items', 'tasks'),
  transactions('transactions', 'transactions'),
  categories('categories', null),
  budgets('budgets', 'budgets'),
  goals('goals', 'goals'),
  debts('debts', 'debts'),
  recurringPayments('recurringPayments', 'recurring_payments');

  const BackupEntity(this.jsonKey, this.csvStem);

  /// Key of the entity's collection in the JSON envelope. Tasks are stored in
  /// the `items` collection (projects, tasks and subtasks).
  final String jsonKey;

  /// File stem of the entity's CSV export, or null when it has no CSV file
  /// (categories travel only in JSON).
  final String? csvStem;
}
