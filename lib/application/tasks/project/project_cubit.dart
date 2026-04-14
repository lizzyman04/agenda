import 'package:agenda/application/tasks/project/project_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Manages a single project — its data and subtask rollup (TASK-01, TASK-02).
///
/// Factory (not singleton) — one per project screen.
@injectable
class ProjectCubit extends Cubit<ProjectState> {
  ProjectCubit(this._repository) : super(const ProjectInitial());

  final ItemRepository _repository;

  /// Loads the project with [projectId] and its subtasks.
  Future<void> loadProject(int projectId) async {
    emit(const ProjectLoading());
    final projectResult = await _repository.getItem(projectId);
    if (projectResult is Err<Item>) {
      emit(ProjectError(projectResult.failure));
      return;
    }
    final project = (projectResult as Success<Item>).value;
    await _refreshSubtasks(project);
  }

  /// Creates a new subtask under [projectId] (TASK-02).
  Future<void> addSubtask({
    required int projectId,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now();
    final subtask = Item(
      id: 0,
      type: ItemType.subtask,
      title: title,
      description: description,
      parentId: projectId,
      createdAt: now,
      updatedAt: now,
    );
    final result = await _repository.createItem(subtask);
    if (result is Err<Item>) {
      emit(ProjectError(result.failure));
      return;
    }
    if (state case ProjectLoaded(:final project)) {
      await _refreshSubtasks(project);
    }
  }

  /// Marks a subtask as complete and refreshes the rollup (TASK-06).
  Future<void> completeSubtask(Item subtask) async {
    final updated = subtask.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final result = await _repository.updateItem(updated);
    if (result is Err<Item>) {
      emit(ProjectError(result.failure));
      return;
    }
    if (state case ProjectLoaded(:final project)) {
      await _refreshSubtasks(project);
    }
  }

  /// Soft-deletes a subtask and refreshes the rollup (TASK-05).
  Future<void> deleteSubtask(int subtaskId) async {
    final result = await _repository.softDelete(subtaskId);
    if (result is Err<Item>) {
      emit(ProjectError(result.failure));
      return;
    }
    if (state case ProjectLoaded(:final project)) {
      await _refreshSubtasks(project);
    }
  }

  Future<void> _refreshSubtasks(Item project) async {
    final countsResult = await _repository.getSubtaskCounts(project.id);
    final subtasksResult = await _repository.getSubtasks(project.id);

    if (countsResult is Err<(int, int)>) {
      emit(ProjectError(countsResult.failure));
      return;
    }
    if (subtasksResult is Err<List<Item>>) {
      emit(ProjectError(subtasksResult.failure));
      return;
    }

    final (completed, total) = (countsResult as Success<(int, int)>).value;
    final subtasks = (subtasksResult as Success<List<Item>>).value;

    emit(ProjectLoaded(
      project: project,
      subtasks: subtasks,
      completedCount: completed,
      totalCount: total,
    ));
  }
}
