import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/workspace_entity.dart';
import '../providers/workspace_provider.dart';
import '../providers/workspace_members_provider.dart';
import '../providers/project_members_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

/// Cross-cutting Riverpod glue for the redesigned TaskFlow shell.

/// Roles allowed to create/modify content. Members get a read-only view, so
/// the app hides the create buttons for them (the API enforces this too — a
/// member's write request comes back 403).
bool _isManagerRole(String? role) => role == 'Owner' || role == 'Admin';

/// True when the signed-in user is Owner/Admin of [workspaceId] — the roles
/// allowed to create projects. The workspace owner always qualifies, even
/// before the member list has finished loading.
final canManageWorkspaceProvider =
    Provider.autoDispose.family<bool, String>((ref, workspaceId) {
  final me = ref.watch(authNotifierProvider).user;
  if (me == null) return false;

  final workspaces = ref.watch(workspaceNotifierProvider).workspaces;
  for (final w in workspaces) {
    if (w.id == workspaceId && w.ownerId == me.id) return true;
  }

  final members = ref.watch(workspaceMembersProvider(workspaceId)).members;
  for (final m in members) {
    if (m.id == me.id) return _isManagerRole(m.role);
  }
  return false;
});

/// True when the signed-in user is Owner/Admin of [projectId] — the roles
/// allowed to create tasks on that project's board.
final canManageProjectProvider =
    Provider.autoDispose.family<bool, String>((ref, projectId) {
  final me = ref.watch(authNotifierProvider).user;
  if (me == null) return false;

  final members = ref.watch(projectMembersProvider(projectId)).members;
  for (final m in members) {
    if (m.id == me.id) return _isManagerRole(m.role);
  }
  return false;
});

/// The currently selected bottom-nav tab of [TaskFlowShell]
/// (0 = Home, 1 = Projects, 2 = Tasks, 3 = Inbox). Exposed as a provider so
/// other screens (e.g. the Home notification bell) can switch tabs.
final shellIndexProvider = StateProvider<int>((ref) => 0);

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

/// A task paired with the name of its project and its owning workspace (for the
/// "My Tasks" list, which spans multiple projects and workspaces).
class TaskWithProject {
  final TaskEntity task;
  final String projectName;
  final String workspaceId;
  const TaskWithProject(this.task, this.projectName, this.workspaceId);
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
        out.add(TaskWithProject(task, project.name, workspaceId));
      }
    }
  }
  return out;
});

/// Aggregates the current user's tasks across ALL workspaces (not just the one
/// currently selected). Reuses [myTasksProvider] so each workspace stays cached.
final allMyTasksProvider = FutureProvider<List<TaskWithProject>>((ref) async {
  final workspaces = ref.watch(workspaceNotifierProvider).workspaces;
  final out = <TaskWithProject>[];
  for (final ws in workspaces) {
    final tasks = await ref.watch(myTasksProvider(ws.id).future);
    out.addAll(tasks);
  }
  return out;
});
