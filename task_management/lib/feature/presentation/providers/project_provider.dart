import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/i_repositories/i_project_repository.dart';
import '../../../core/di/injection_container.dart' as di;

final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  return di.sl<IProjectRepository>();
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
  final IProjectRepository _repository;

  ProjectNotifier(this._repository) : super(ProjectState());

  Future<void> fetchProjects(String workspaceId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getProjects(workspaceId);
    
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (projects) => state.copyWith(isLoading: false, projects: projects),
    );
  }

  Future<void> createProject(String workspaceId, String name, String description) async {
    final result = await _repository.createProject(workspaceId, name, description);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (newProject) => state = state.copyWith(projects: [...state.projects, newProject]),
    );
  }

  Future<bool> deleteProject(String workspaceId, String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.deleteProject(workspaceId, id);
    
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
    final result = await _repository.leaveProject(id);
    
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
  final notifier = ProjectNotifier(ref.watch(projectRepositoryProvider));
  notifier.fetchProjects(workspaceId);
  return notifier;
});
