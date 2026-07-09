import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../application/i_services/i_workspace_service.dart';
import '../../../core/di/injection_container.dart' as di;

final workspaceServiceProvider = Provider<IWorkspaceService>((ref) {
  return di.sl<IWorkspaceService>();
});

class WorkspaceState {
  final bool isLoading;
  final String? error;
  final List<WorkspaceEntity> workspaces;

  WorkspaceState({
    this.isLoading = false,
    this.error,
    this.workspaces = const [],
  });

  WorkspaceState copyWith({
    bool? isLoading,
    String? error,
    List<WorkspaceEntity>? workspaces,
  }) {
    return WorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      workspaces: workspaces ?? this.workspaces,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final IWorkspaceService _service;

  WorkspaceNotifier(this._service) : super(WorkspaceState()) {
    fetchWorkspaces();
  }

  Future<void> fetchWorkspaces() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.getWorkspaces();
    
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (workspaces) => state.copyWith(isLoading: false, workspaces: workspaces),
    );
  }

  Future<void> createWorkspace(String name, String description) async {
    final result = await _service.createWorkspace(name, description);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (newWorkspace) => state = state.copyWith(workspaces: [...state.workspaces, newWorkspace]),
    );
  }

  Future<bool> deleteWorkspace(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.deleteWorkspace(id);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (_) {
        final updatedWorkspaces = state.workspaces.where((w) => w.id != id).toList();
        state = state.copyWith(isLoading: false, workspaces: updatedWorkspaces);
        return true;
      },
    );
  }
}

final workspaceNotifierProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier(ref.watch(workspaceServiceProvider));
});
