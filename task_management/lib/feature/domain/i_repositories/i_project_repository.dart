import 'package:dartz/dartz.dart';
import '../../domain/entities/entities.dart';

abstract class IProjectRepository {
  Future<Either<String, List<ProjectEntity>>> getProjects(String workspaceId);
  Future<Either<String, ProjectEntity>> createProject(String workspaceId, String name, String description);
  Future<Either<String, List<UserEntity>>> getProjectMembers(String projectId);
  Future<Either<String, UserEntity>> inviteProjectMember(String projectId, String email);
  Future<Either<String, UserEntity>> updateProjectMemberRole(String projectId, String userId, String newRole);
  Future<Either<String, bool>> acceptProjectInvitation(String projectId);
  Future<Either<String, bool>> declineProjectInvitation(String projectId);
  Future<Either<String, bool>> deleteProject(String workspaceId, String id);
  Future<Either<String, bool>> leaveProject(String projectId);
  Future<Either<String, bool>> removeProjectMember(String projectId, String userId);
}
