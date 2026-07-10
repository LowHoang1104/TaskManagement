import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_dependency_entity.dart';
import '../../application/i_services/i_task_service.dart';
import 'task_provider.dart';

class TaskDependenciesState {
  final bool isLoading;
  final String? error;
  final List<TaskDependencyEntity> dependencies;

  TaskDependenciesState({
    this.isLoading = false,
    this.error,
    this.dependencies = const [],
  });

  TaskDependenciesState copyWith({
    bool? isLoading,
    String? error,
    List<TaskDependencyEntity>? dependencies,
  }) {
    return TaskDependenciesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dependencies: dependencies ?? this.dependencies,
    );
  }
}

class TaskDependenciesNotifier extends StateNotifier<TaskDependenciesState> {
  final ITaskService _service;
  final String taskId;

  TaskDependenciesNotifier(this._service, this.taskId) : super(TaskDependenciesState());

  Future<void> fetchDependencies() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.getTaskDependencies(taskId);
    
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (deps) => state.copyWith(isLoading: false, dependencies: deps),
    );
  }

  Future<bool> setDependency(String predecessorTaskId, String dependencyType) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.setTaskDependency(taskId, predecessorTaskId, dependencyType);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        fetchDependencies(); // refresh after success
        return true;
      },
    );
  }
}

final taskDependenciesProvider = StateNotifierProvider.family<TaskDependenciesNotifier, TaskDependenciesState, String>((ref, taskId) {
  final notifier = TaskDependenciesNotifier(ref.watch(taskServiceProvider), taskId);
  notifier.fetchDependencies();
  return notifier;
});
