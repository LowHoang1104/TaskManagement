import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_entity.dart';
import '../../application/i_services/i_project_service.dart';
import '../../../core/di/injection_container.dart' as di;

final projectServiceProvider = Provider<IProjectService>((ref) {
  return di.sl<IProjectService>();
});

class ProjectState {
  final bool isLoading;
  final String? error;
  final List<ProjectEntity> projects;

  ProjectState({
    this.isLoading = false,
    this.error,
    this.projects = const [],
  });

  ProjectState copyWith({
    bool? isLoading,
    String? error,
    List<ProjectEntity>? projects,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      projects: projects ?? this.projects,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final IProjectService _service;

  ProjectNotifier(this._service) : super(ProjectState());

  Future<void> fetchProjects(String workspaceId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.getProjects(workspaceId);
    
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (projects) => state.copyWith(isLoading: false, projects: projects),
    );
  }

  Future<void> createProject(String workspaceId, String name, String description) async {
    final result = await _service.createProject(workspaceId, name, description);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (newProject) => state = state.copyWith(projects: [...state.projects, newProject]),
    );
  }

  Future<bool> deleteProject(String workspaceId, String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.deleteProject(workspaceId, id);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        final updatedProjects = state.projects.where((p) => p.id != id).toList();
        state = state.copyWith(isLoading: false, projects: updatedProjects);
        return true;
      },
    );
  }

  Future<bool> leaveProject(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.leaveProject(id);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        final updatedProjects = state.projects.where((p) => p.id != id).toList();
        state = state.copyWith(isLoading: false, projects: updatedProjects);
        return true;
      },
    );
  }
}

final projectNotifierProvider = StateNotifierProvider.family<ProjectNotifier, ProjectState, String>((ref, workspaceId) {
  final notifier = ProjectNotifier(ref.watch(projectServiceProvider));
  notifier.fetchProjects(workspaceId);
  return notifier;
});
