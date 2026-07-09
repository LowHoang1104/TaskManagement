import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/entities.dart';
import '../../application/i_services/i_project_service.dart';

class ProjectMembersState {
  final bool isLoading;
  final String? error;
  final List<UserEntity> members;

  const ProjectMembersState({
    this.isLoading = false,
    this.error,
    this.members = const [],
  });

  ProjectMembersState copyWith({
    bool? isLoading,
    String? error,
    List<UserEntity>? members,
  }) {
    return ProjectMembersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members ?? this.members,
    );
  }
}

class ProjectMembersNotifier extends StateNotifier<ProjectMembersState> {
  final String projectId;
  
  ProjectMembersNotifier(this.projectId) : super(const ProjectMembersState()) {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IProjectService>().getProjectMembers(projectId);
    
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (members) => state = state.copyWith(isLoading: false, members: members),
    );
  }

  Future<bool> inviteMember(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IProjectService>().inviteProjectMember(projectId, email);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (newMember) {
        state = state.copyWith(
          isLoading: false,
          members: [...state.members, newMember],
        );
        return true;
      },
    );
  }

  Future<bool> updateRole(String userId, String newRole) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IProjectService>().updateProjectMemberRole(projectId, userId, newRole);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (updatedMember) {
        final updatedMembers = state.members.map((m) {
          if (m.id == userId) return updatedMember;
          return m;
        }).toList();
        
        state = state.copyWith(
          isLoading: false,
          members: updatedMembers,
        );
        return true;
      },
    );
  }
}

final projectMembersProvider = StateNotifierProvider.family<ProjectMembersNotifier, ProjectMembersState, String>(
  (ref, projectId) => ProjectMembersNotifier(projectId),
);
