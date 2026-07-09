import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/i_repositories/i_task_repository.dart';
import '../../../core/di/injection_container.dart' as di;

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  return di.sl<ITaskRepository>();
});

class TaskState {
  final bool isLoading;
  final String? error;
  final List<TaskEntity> tasks;

  TaskState({
    this.isLoading = false,
    this.error,
    this.tasks = const [],
  });

  TaskState copyWith({
    bool? isLoading,
    String? error,
    List<TaskEntity>? tasks,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  final ITaskRepository _repository;
  final String projectId;

  TaskNotifier(this._repository, this.projectId) : super(TaskState());

  Future<void> fetchTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getTasks(projectId);
    
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (tasks) => state.copyWith(isLoading: false, tasks: tasks),
    );
  }

  Future<void> updateTaskStatusLocally(String taskId, TaskStatus newStatus) async {
    final oldTasks = state.tasks;
    final updatedTasks = oldTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(status: newStatus);
      }
      return t;
    }).toList();
    
    state = state.copyWith(tasks: updatedTasks);
    
    // Call API in background
    final result = await _repository.updateTaskStatus(projectId, taskId, newStatus);
    result.fold(
      (error) {
        // Revert on error
        state = state.copyWith(error: error, tasks: oldTasks);
      },
      (task) {
        // Updated correctly on server
      }
    );
  }

  Future<void> createTask(String title, String description, TaskStatus status, TaskPriority priority) async {
    final result = await _repository.createTask(projectId, title, description, status, priority);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (newTask) => state = state.copyWith(tasks: [...state.tasks, newTask]),
    );
  }

  Future<bool> deleteTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.deleteTask(projectId, taskId);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(isLoading: false, tasks: updatedTasks);
        return true;
      },
    );
  }
}

// Pass projectId dynamically
final taskNotifierProvider = StateNotifierProvider.family<TaskNotifier, TaskState, String>((ref, projectId) {
  final notifier = TaskNotifier(ref.watch(taskRepositoryProvider), projectId);
  notifier.fetchTasks();
  return notifier;
});
