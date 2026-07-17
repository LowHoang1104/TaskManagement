import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/enums.dart';
import '../../application/i_services/i_task_service.dart';
import '../../../core/di/injection_container.dart' as di;

final taskServiceProvider = Provider<ITaskService>((ref) {
  return di.sl<ITaskService>();
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
  final ITaskService _service;
  final String projectId;

  TaskNotifier(this._service, this.projectId) : super(TaskState());

  Future<void> fetchTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.getTasks(projectId);
    
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
    final result = await _service.updateTaskStatus(projectId, taskId, newStatus);
    result.fold(
      (error) {
        // Revert on error
        state = state.copyWith(error: error, tasks: oldTasks);
      },
      (task) {
        // Updated correctly on server
      },
    );
  }

  Future<void> updateTaskAssignee(String taskId, String? assigneeId) async {
    final result = await _service.updateTaskAssignee(projectId, taskId, assigneeId);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (updatedTask) {
        final updatedTasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
        state = state.copyWith(tasks: updatedTasks);
      },
    );
  }

  void updateTaskAssigneeLocally(TaskEntity updatedTask) => replaceTaskLocally(updatedTask);

  /// Swaps a task in the board list with an updated copy (after it was changed
  /// from the detail screen), without refetching.
  void replaceTaskLocally(TaskEntity updatedTask) {
    final updatedTasks = state.tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  Future<TaskEntity?> createTask(String title, String description, TaskStatus status, TaskPriority priority) async {
    final result = await _service.createTask(projectId, title, description, status, priority);
    return result.fold(
      (error) {
        state = state.copyWith(error: error);
        return null;
      },
      (newTask) {
        state = state.copyWith(tasks: [...state.tasks, newTask]);
        return newTask;
      },
    );
  }

  Future<bool> deleteTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.deleteTask(projectId, taskId);
    
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
  final notifier = TaskNotifier(ref.watch(taskServiceProvider), projectId);
  notifier.fetchTasks();
  return notifier;
});
