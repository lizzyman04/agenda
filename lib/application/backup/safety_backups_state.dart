import 'package:equatable/equatable.dart';

/// Result of the last save or delete request, shown once as a message.
enum SafetyBackupsOutcome { saved, cancelled, none, deleted, failed }

/// State of the safety-backups section on the Backup screen.
final class SafetyBackupsState extends Equatable {
  const SafetyBackupsState({this.count = 0, this.busy = false, this.outcome});

  /// How many safety backups exist on the device.
  final int count;

  /// True while a save or delete is running.
  final bool busy;

  /// The outcome to announce, or null once acknowledged.
  final SafetyBackupsOutcome? outcome;

  /// Copy with changes. [outcome] is replaced by the given value, and cleared
  /// when [clearOutcome] is true (null is a valid new value, so it needs a
  /// flag).
  SafetyBackupsState copyWith({
    int? count,
    bool? busy,
    SafetyBackupsOutcome? outcome,
    bool clearOutcome = false,
  }) => SafetyBackupsState(
    count: count ?? this.count,
    busy: busy ?? this.busy,
    outcome: clearOutcome ? null : (outcome ?? this.outcome),
  );

  @override
  List<Object?> get props => [count, busy, outcome];
}
