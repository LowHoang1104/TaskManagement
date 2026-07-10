import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/entities.dart';
import '../../application/i_services/i_workspace_service.dart';

class WorkspaceMembersState {
  final bool isLoading;
  final String? error;
  final List<UserEntity> members;

  const WorkspaceMembersState({
    this.isLoading = false,
    this.error,
    this.members = const [],
  });

  WorkspaceMembersState copyWith({
    bool? isLoading,
    String? error,
    List<UserEntity>? members,
  }) {
    return WorkspaceMembersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members ?? this.members,
    );
  }
}

class WorkspaceMembersNotifier extends StateNotifier<WorkspaceMembersState> {
  final String workspaceId;
  
  WorkspaceMembersNotifier(this.workspaceId) : super(const WorkspaceMembersState()) {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IWorkspaceService>().getWorkspaceMembers(workspaceId);
    
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (members) => state = state.copyWith(isLoading: false, members: members),
    );
  }

  Future<bool> inviteMember(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IWorkspaceService>().inviteWorkspaceMember(workspaceId, email);
    
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
    final result = await sl<IWorkspaceService>().updateWorkspaceMemberRole(workspaceId, userId, newRole);
    
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

  Future<bool> removeMember(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await sl<IWorkspaceService>().removeWorkspaceMember(workspaceId, userId);
    
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
      (success) {
        final updatedMembers = state.members.where((m) => m.id != userId).toList();
        state = state.copyWith(
          isLoading: false,
          members: updatedMembers,
        );
        return true;
      },
    );
  }
}

final workspaceMembersProvider = StateNotifierProvider.family<WorkspaceMembersNotifier, WorkspaceMembersState, String>(
  (ref, workspaceId) => WorkspaceMembersNotifier(workspaceId),
);
