import '../i_services/i_project_service.dart';
import '../../domain/i_repositories/i_project_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/entities.dart';

class ProjectService implements IProjectService {
  final IProjectRepository _repository;

  ProjectService(this._repository);

  @override
  Future<Either<String, List<ProjectEntity>>> getProjects(String workspaceId) async {
    return await _repository.getProjects(workspaceId);
  }
  @override
  Future<Either<String, ProjectEntity>> createProject(String workspaceId, String name, String description) async {
    return await _repository.createProject(workspaceId, name, description);
  }
  @override
  Future<Either<String, List<UserEntity>>> getProjectMembers(String projectId) async {
    return await _repository.getProjectMembers(projectId);
  }
  @override
  Future<Either<String, UserEntity>> inviteProjectMember(String projectId, String email) async {
    return await _repository.inviteProjectMember(projectId, email);
  }
  @override
  Future<Either<String, UserEntity>> updateProjectMemberRole(String projectId, String userId, String newRole) async {
    return await _repository.updateProjectMemberRole(projectId, userId, newRole);
  }
  @override
  Future<Either<String, bool>> acceptProjectInvitation(String projectId) async {
    return await _repository.acceptProjectInvitation(projectId);
  }
  @override
  Future<Either<String, bool>> declineProjectInvitation(String projectId) async {
    return await _repository.declineProjectInvitation(projectId);
  }
  @override
  Future<Either<String, bool>> deleteProject(String workspaceId, String id) async {
    return await _repository.deleteProject(workspaceId, id);
  }
  @override
  Future<Either<String, bool>> leaveProject(String projectId) {
    return _repository.leaveProject(projectId);
  }

  @override
  Future<Either<String, bool>> removeProjectMember(String projectId, String userId) {
    return _repository.removeProjectMember(projectId, userId);
  }
}
