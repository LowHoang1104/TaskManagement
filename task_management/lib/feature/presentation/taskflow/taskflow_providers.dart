import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/workspace_entity.dart';
import '../providers/workspace_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

/// Cross-cutting Riverpod glue for the redesigned TaskFlow shell.

/// The workspace the user is currently browsing (Projects / Tasks tabs). When
/// null, [currentWorkspaceProvider] falls back to the first workspace.
final selectedWorkspaceIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the effective current workspace from the loaded list + selection.
final currentWorkspaceProvider = Provider<WorkspaceEntity?>((ref) {
  final workspaces = ref.watch(workspaceNotifierProvider).workspaces;
  if (workspaces.isEmpty) return null;
  final selectedId = ref.watch(selectedWorkspaceIdProvider);
  return workspaces.firstWhere(
    (w) => w.id == selectedId,
    orElse: () => workspaces.first,
  );
});

/// A task paired with the name of its project (for the "My Tasks" list, which
/// spans multiple projects).
class TaskWithProject {
  final TaskEntity task;
  final String projectName;
  const TaskWithProject(this.task, this.projectName);
}

/// Aggregates the current user's tasks across every project in [workspaceId].
/// Falls back to all tasks when no signed-in user id is available.
final myTasksProvider =
    FutureProvider.family<List<TaskWithProject>, String>((ref, workspaceId) async {
  final projectService = ref.watch(projectServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  final userId = ref.watch(authNotifierProvider).user?.id;

  final projectsRes = await projectService.getProjects(workspaceId);
  final projects = projectsRes.fold<List<ProjectEntity>>((_) => const [], (r) => r);

  final out = <TaskWithProject>[];
  for (final project in projects) {
    final tasksRes = await taskService.getTasks(project.id);
    final tasks = tasksRes.fold<List<TaskEntity>>((_) => const [], (r) => r);
    for (final task in tasks) {
      if (userId == null || userId.isEmpty || task.assigneeId == userId) {
        out.add(TaskWithProject(task, project.name));
      }
    }
  }
  return out;
});
