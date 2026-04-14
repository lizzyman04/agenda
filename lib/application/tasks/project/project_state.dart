import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:equatable/equatable.dart';

sealed class ProjectState extends Equatable {
  const ProjectState();
}

final class ProjectInitial extends ProjectState {
  const ProjectInitial();
  @override
  List<Object?> get props => [];
}

final class ProjectLoading extends ProjectState {
  const ProjectLoading();
  @override
  List<Object?> get props => [];
}

/// Loaded state — holds project, its subtasks, and rollup counts.
final class ProjectLoaded extends ProjectState {
  const ProjectLoaded({
    required this.project,
    required this.subtasks,
    required this.completedCount,
    required this.totalCount,
  });

  final Item project;
  final List<Item> subtasks;
  final int completedCount;
  final int totalCount;

  /// Completion ratio 0.0..1.0; 0.0 when no subtasks.
  double get completionRatio =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  @override
  List<Object?> get props => [project, subtasks, completedCount, totalCount];
}

final class ProjectError extends ProjectState {
  const ProjectError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
