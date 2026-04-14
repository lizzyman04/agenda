/// Discriminator for the unified Item collection.
///
/// Persisted in Isar as a string via @enumerated(EnumType.name) —
/// see ItemModel. The domain layer holds the enum definition;
/// the data layer annotates it.
enum ItemType { project, task, subtask }
