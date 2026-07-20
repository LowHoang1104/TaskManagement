import 'package:dartz/dartz.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class IWorkspaceRepository {
  Future<Either<String, List<WorkspaceEntity>>> getWorkspaces();
  Future<Either<String, WorkspaceEntity>> createWorkspace(String name, String? description);
  Future<Either<String, bool>> deleteWorkspace(String id);
  
  Future<Either<String, List<UserEntity>>> getWorkspaceMembers(String workspaceId);
  Future<Either<String, UserEntity>> inviteWorkspaceMember(String workspaceId, String email);

  /// Joining a workspace is invite-based: the invitee must accept (or decline)
  /// before they are actually in.
  Future<Either<String, bool>> acceptWorkspaceInvite(String workspaceId);
  Future<Either<String, bool>> declineWorkspaceInvite(String workspaceId);
  Future<Either<String, UserEntity>> updateWorkspaceMemberRole(String workspaceId, String userId, String newRole);
  Future<Either<String, bool>> removeWorkspaceMember(String workspaceId, String userId);
}
