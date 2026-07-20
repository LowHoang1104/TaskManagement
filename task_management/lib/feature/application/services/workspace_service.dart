import '../i_services/i_workspace_service.dart';
import '../../domain/i_repositories/i_workspace_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/user_entity.dart';

class WorkspaceService implements IWorkspaceService {
  final IWorkspaceRepository _repository;

  WorkspaceService(this._repository);

  @override
  Future<Either<String, List<WorkspaceEntity>>> getWorkspaces() async {
    return await _repository.getWorkspaces();
  }
  @override
  Future<Either<String, WorkspaceEntity>> createWorkspace(String name, String? description) async {
    return await _repository.createWorkspace(name, description);
  }
  @override
  Future<Either<String, bool>> deleteWorkspace(String id) async {
    return await _repository.deleteWorkspace(id);
  }

  @override
  Future<Either<String, List<UserEntity>>> getWorkspaceMembers(String workspaceId) async {
    return await _repository.getWorkspaceMembers(workspaceId);
  }

  @override
  Future<Either<String, UserEntity>> inviteWorkspaceMember(String workspaceId, String email) async {
    return await _repository.inviteWorkspaceMember(workspaceId, email);
  }

  @override
  Future<Either<String, bool>> acceptWorkspaceInvite(String workspaceId) async {
    return await _repository.acceptWorkspaceInvite(workspaceId);
  }

  @override
  Future<Either<String, bool>> declineWorkspaceInvite(String workspaceId) async {
    return await _repository.declineWorkspaceInvite(workspaceId);
  }

  @override
  Future<Either<String, UserEntity>> updateWorkspaceMemberRole(String workspaceId, String userId, String newRole) async {
    return await _repository.updateWorkspaceMemberRole(workspaceId, userId, newRole);
  }

  @override
  Future<Either<String, bool>> removeWorkspaceMember(String workspaceId, String userId) async {
    return await _repository.removeWorkspaceMember(workspaceId, userId);
  }
}
